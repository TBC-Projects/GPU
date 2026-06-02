// Each thread has an ALU, Register File, Program Counter, and memory load/store unit.
// 'running' controls whether this thread's PC advances each cycle (set by the scheduler).
// 'halt' goes high when the thread has finished executing and should no longer run.

module Thread (
    input  logic clk,
    input  logic reset,
    input  logic running, // high when this thread is scheduled to execute this cycle
    output logic halt     // high when this thread has completed (executed a HALT instruction)
);

    // Register File:
    logic [3:0]  write_address;
    logic [31:0] write_data;
    logic        write_enable;
    logic [3:0]  read_address_1;
    logic [31:0] read_data_1;
    logic [3:0]  read_address_2;
    logic [31:0] read_data_2;

    // ALU:
    logic [2:0]  alu_op; // 3-bit opcode: 000=ADD 001=SUB 010=MUL 011=DIV 100=AND 101=OR 110=XOR
    logic [31:0] alu_result;
    logic        overflow;
    logic        negative;
    logic        carry_out;
    logic        zero;

    ALU alu_unit (
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

    // Program Counter:
    logic [31:0] pc;
    logic        running;
    logic        pause;
    logic        branch_taken;
    logic [31:0] branch_target;

    program_counter pc_unit (
        .clk          (clk),
        .reset        (reset),
        .running      (running), // thread only advances PC when the scheduler selects it
        .pause        (pause),
        .branch_taken (branch_taken),
        .branch_target(branch_target),
        .pc           (pc)
    );

    // halt is driven high when this thread executes a HALT instruction.
    // Instruction decoding is not yet implemented in Thread -- placeholder for now.
    assign halt = 1'b0;

    // Memory Load/Store:
    logic [3:0]  mem_address;
    logic        mem_write_enable;
    logic        mem_read_enable;
    logic [31:0] mem_data_out;

    mem_load_store mem_controller (
        .clk             (clk),
        .reset           (reset),
        .reg_address     (mem_address),
        .reg_data_in     (read_data_1),
        .reg_data_out    (mem_data_out),
        .mem_write_enable(mem_write_enable),
        .mem_read_enable (mem_read_enable)
    );

    // Writeback mux: selects what gets written back to the register file.
    // wb_sel = 0 → ALU result, wb_sel = 1 → memory load data
    logic wb_sel;
    assign write_data = wb_sel ? mem_data_out : alu_result;

endmodule