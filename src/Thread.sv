// Each thread has an ALU, Register, Program counter, and memory load/store unit.
// This module also contains the control FSM and instruction decoder that drive
// those submodules. One Thread = one lane of work inside a Core (CUDA "thread").
//
// ── Instruction format (16-bit) ─────────────────────────────────────────────
//   [15:12] opcode | [11:8] rd | [7:4] rn | [3:0] rm
//
//   4'h0  NOP     no operation
//   4'h1  ADD     rd <- rn + rm          (via alu_exec, op=00)
//   4'h2  SUB     rd <- rn - rm          (via alu_exec, op=01)
//   4'h3  MUL     rd <- rn * rm          (via alu_exec, op=10)
//   4'h4  DIV     rd <- rn / rm          (via alu_exec, op=11)
//   4'h5  LOAD    rd <- mem[rm]         (1-cycle stall; see LOAD_WAIT state)
//   4'h6  STORE   mem[rm] <- rn         (writes read port 1 into mem[rm])
//   4'h7  BEQ     if (zero_flag) pc <- {26'b0, rm, 2'b00}
//   4'h8  BNE     if (!zero_flag) pc <- {26'b0, rm, 2'b00}
//   4'hF  HALT    stop; assert done until reset
//
// ── Register conventions (from GPU Arch slides) ─────────────────────────────
//   X15 = read-only thread identifier (Core should write before start)
//   X14 = block dimension
//   X13 = read-only 0 (convention only; not enforced in hardware here)
//   X0–X12 = general purpose
//
// ── Instruction fetch (external) ────────────────────────────────────────────
//   pc_out drives the address port of an external instruction_memory module.
//   instr is the 16-bit word returned combinatorially from that memory.
//   In a testbench you can tie instr directly without instantiating instrmem.
//
// ── Ports to Core / Scheduler (later) ───────────────────────────────────────
//   start  : pulsed (or held) by Core when this thread should begin executing
//   done   : high after HALT until reset; Core can use this for block completion
//   pc_out : current program counter value
//   instr  : fetched instruction word for this cycle

module Thread (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,       // begin execution (IDLE -> FETCH)
    output logic        done,        // held high in HALTED state
    output logic [31:0] pc_out,      // PC value -> external instruction memory
    input  logic [15:0] instr       // instruction word <- external instruction memory
);

    // ── Instruction field decode ───────────────────────────────────────────
    // Split the 16-bit instruction into opcode and three register specifiers.
    // Default read pattern: port1 = rn, port2 = rm, write dest = rd.
    logic [3:0] opcode, rd, rn, rm;
    assign opcode = instr[15:12];
    assign rd     = instr[11:8];
    assign rn     = instr[7:4];
    assign rm     = instr[3:0];

    // ── Register File ──────────────────────────────────────────────────────
    // Two read ports (combinational) and one write port (posedge clk).
    // Addresses and write_enable are driven by the control logic below.
    logic [3:0]  write_address;
    logic [31:0] write_data;
    logic        write_enable;
    logic [3:0]  read_address_1;
    logic [31:0] read_data_1;
    logic [3:0]  read_address_2;
    logic [31:0] read_data_2;

    // ── ALU ────────────────────────────────────────────────────────────────
    // alu_exec is in src/alu_exec.sv (ADD/SUB/MUL/DIV).
    // Operands come from the register file read ports.
    // zero_flag (below) is latched after each ALU op for BEQ/BNE.
    logic [1:0]  alu_op;
    logic [31:0] alu_result;
    logic        overflow;
    logic        negative;
    logic        carry_out;
    logic        zero;
    logic        zero_flag;   // latched copy of ALU zero; used by branch instructions

    // ── Program Counter ────────────────────────────────────────────────────
    // PC increments by 4 each cycle when running && !pause.
    // pause=1 during LOAD address phase so PC does not advance before writeback.
    // branch_taken + branch_target redirect PC on BEQ/BNE taken.
    logic [31:0] pc;
    logic        running;
    logic        pause;
    logic        branch_taken;
    logic [31:0] branch_target;

    // ── Memory Load/Store ──────────────────────────────────────────────────
    // Per-thread local memory (16 x 32-bit words). Not shared across threads.
    // LOAD:  mem_read_enable, address = rm; data returns next cycle on reg_data_out
    // STORE: mem_write_enable, address = rm; data source = read_data_1 (rn)
    logic [3:0]  mem_address;
    logic        mem_write_enable;
    logic        mem_read_enable;
    logic [31:0] mem_data_out;

    // ── Writeback mux ──────────────────────────────────────────────────────
    // Selects what gets written back to the register file on write_enable.
    // wb_sel = 0 -> ALU result
    // wb_sel = 1 -> memory load data (used in LOAD_WAIT after read completes)
    logic wb_sel;
    assign write_data = wb_sel ? mem_data_out : alu_result;

    // ── Control FSM ────────────────────────────────────────────────────────
    // IDLE      : wait for start; PC held at 0 by program_counter reset/running=0
    // FETCH     : decode + execute one instruction per cycle (except LOAD/HALT)
    // LOAD_WAIT : extra cycle so mem_load_store reg_data_out is valid before WB
    // HALTED    : thread finished; done=1 until reset
    typedef enum logic [1:0] {
        IDLE      = 2'd0,
        FETCH     = 2'd1,
        LOAD_WAIT = 2'd2,
        HALTED    = 2'd3
    } state_t;
    state_t state;

    // Saved destination register during LOAD stall (rd field from LOAD opcode)
    logic [3:0] load_dest;

    // ── Submodule instances ────────────────────────────────────────────────

    alu_exec alu_unit (
        .a        (read_data_1),
        .b        (read_data_2),
        .operation(alu_op),
        .result   (alu_result),
        .overflow (overflow),
        .negative (negative),
        .carry_out(carry_out),
        .zero     (zero)
    );

    regfile register_file (
        .clk           (clk),
        .reset         (reset),
        .write_address (write_address),
        .write_data    (write_data),
        .write_enable  (write_enable),
        .read_address_1(read_address_1),
        .read_data_1   (read_data_1),
        .read_address_2(read_address_2),
        .read_data_2   (read_data_2)
    );

    program_counter pc_unit (
        .clk          (clk),
        .running      (running),
        .pause        (pause),
        .reset        (reset),
        .branch_taken (branch_taken),
        .branch_data  (branch_target),   // src program_counter names this branch_data
        .pc           (pc)
    );

    mem_load_store mem_controller (
        .clk             (clk),
        .reset           (reset),
        .reg_address     (mem_address),
        .reg_data_in     (read_data_1),   // STORE uses rn on read port 1
        .reg_data_out    (mem_data_out),
        .mem_write_enable(mem_write_enable),
        .mem_read_enable (mem_read_enable)
    );

    // Export PC to external instruction memory; done when halted
    assign pc_out = pc;
    assign done   = (state == HALTED);

    // ── Combinational control / decode ─────────────────────────────────────
    // Default every control signal to inactive each cycle, then override in
    // FETCH (and LOAD_WAIT) based on opcode. This avoids accidental latches.
    always_comb begin
        // Safe defaults: no register write, no mem access, PC not running
        running          = 1'b0;
        pause            = 1'b0;
        alu_op           = 2'b00;
        read_address_1   = rn;
        read_address_2   = rm;
        write_address    = rd;
        write_enable     = 1'b0;
        wb_sel           = 1'b0;
        mem_address      = rm;
        mem_write_enable = 1'b0;
        mem_read_enable  = 1'b0;
        branch_taken     = 1'b0;
        branch_target    = 32'b0;

        case (state)

            // ── FETCH: normal instruction execution ──────────────────────
            FETCH: begin
                running = 1'b1;   // tell PC to advance (unless pause or branch)

                case (opcode)
                    4'h1: begin // ADD  rd <- rn + rm
                        alu_op       = 2'b00;
                        write_enable = 1'b1;
                    end
                    4'h2: begin // SUB  rd <- rn - rm
                        alu_op       = 2'b01;
                        write_enable = 1'b1;
                    end
                    4'h3: begin // MUL  rd <- rn * rm
                        alu_op       = 2'b10;
                        write_enable = 1'b1;
                    end
                    4'h4: begin // DIV  rd <- rn / rm
                        alu_op       = 2'b11;
                        write_enable = 1'b1;
                    end
                    4'h5: begin // LOAD rd <- mem[rm]
                        // Issue read this cycle; stall PC; writeback next cycle
                        mem_address     = rm;
                        mem_read_enable = 1'b1;
                        pause           = 1'b1;
                    end
                    4'h6: begin // STORE mem[rm] <- rn
                        read_address_1   = rn;   // data to store comes from rn
                        mem_address      = rm;
                        mem_write_enable = 1'b1;
                    end
                    4'h7: begin // BEQ: branch if previous ALU result was zero
                        if (zero_flag) begin
                            branch_taken  = 1'b1;
                            // Target address packed in rm field (word-aligned)
                            branch_target = {26'b0, rm, 2'b00};
                        end
                    end
                    4'h8: begin // BNE: branch if previous ALU result was non-zero
                        if (!zero_flag) begin
                            branch_taken  = 1'b1;
                            branch_target = {26'b0, rm, 2'b00};
                        end
                    end
                    default: ; // NOP (4'h0) and unknown opcodes: no operation
                endcase
            end

            // ── LOAD_WAIT: complete LOAD writeback ─────────────────────────
            // mem_load_store registered the read last cycle; reg_data_out is
            // valid now. Write it into load_dest (saved rd from FETCH cycle).
            LOAD_WAIT: begin
                running       = 1'b1;
                write_address = load_dest;
                write_enable  = 1'b1;
                wb_sel        = 1'b1;   // write memory data, not ALU result
            end

            default: ; // IDLE, HALTED: all signals stay at safe defaults above

        endcase
    end

    // ── Sequential control: FSM + zero_flag latch ──────────────────────────
    always_ff @(posedge clk) begin
        if (reset) begin
            state     <= IDLE;
            load_dest <= 4'b0;
            zero_flag <= 1'b0;
        end else begin
            case (state)

                IDLE: begin
                    // Wait until Core/Scheduler asserts start
                    if (start)
                        state <= FETCH;
                end

                FETCH: begin
                    // Latch ALU zero flag after ADD/SUB/MUL/DIV for later branches
                    if (opcode >= 4'h1 && opcode <= 4'h4)
                        zero_flag <= zero;

                    if (opcode == 4'h5) begin
                        // LOAD needs an extra cycle; remember which register to fill
                        load_dest <= rd;
                        state     <= LOAD_WAIT;
                    end else if (opcode == 4'hF) begin
                        // HALT: stop fetching; done goes high via assign above
                        state <= HALTED;
                    end
                    // All other opcodes: remain in FETCH (including NOP, STORE, branches)
                end

                LOAD_WAIT: begin
                    // Writeback finished; resume normal instruction fetch
                    state <= FETCH;
                end

                HALTED: begin
                    // Stay here until reset; done output remains asserted
                end

            endcase
        end
    end

endmodule
