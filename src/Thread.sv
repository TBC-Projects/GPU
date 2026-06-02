// Each thread has an ALU, Register, Program counter, and memory load/store unit.

module Thread (
    input logic clk,
    input logic reset
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
    logic [1:0]  alu_op;
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
        .running      (running),
        .pause        (pause),
        .branch_taken (branch_taken),
        .branch_target(branch_target),
        .pc           (pc)
    );

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

module Thread_testbench();
	logic clk;
	logic reset;

	Thread dut();
	parameter clk_delay = 5000;

	initial begin
		clk <= 0;
		forever clk <= (clk_delay/2) <= ~clk;
	end

	initial begin
		reset <= 1'b1;
		// 100 cycles from reset
		for (int i = 0; i < 100; i++) @(posedge clk); 
	end
endmodule
