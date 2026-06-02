// This module is created to establish logistics for Memory, Load, and Store operations. 
// Its main purpose is to manage the flow of data between the register file and memory,
// ensuring that the correct data is read FROM memory (Memory LOAD), or written TO memory
// (Memory STORE) based on the control selector signals (mem_write_enable, mem_read_enable).
module mem_load_store (
    input  logic        clk,
    input  logic        reset,
    input  logic [3:0]  reg_address,      // Indexes into the 16-entry memory array
    input  logic [31:0] reg_data_in,      // Data from register file written TO memory
    output logic [31:0] reg_data_out,     // Data FROM memory written back to register file
    input  logic        mem_write_enable,
    input  logic        mem_read_enable
);

    logic [31:0] mem [0:15];

    always_ff @(posedge clk) begin
        if (reset) begin
            reg_data_out <= 32'b0;
        end 
        else if (mem_write_enable) begin
            mem[reg_address] <= reg_data_in;
        end 
        else if (mem_read_enable) begin
            reg_data_out <= mem[reg_address];
        end 
        else begin
            reg_data_out <= 32'b0;
        end
    end

endmodule

module mem_load_store_testbench();
	logic clk;
	logic reset;
	logic [3:0] reg_address;
	logic [31:0] reg_data_in, reg_data_out;
	logic mem_write_enable;
	logic mem_read_enable;

	parameter clk_delay = 5000;

	mem_load_store dut(.clk, .reset, .reg_address, .reg_data_in, .reg_data_out,
			   .mem_write_enable, .mem_read_enable);
	initial begin
		clk <= 0;
		forever clk <= (ClockDelay/2) clk <= ~clk;
	end

	initial begin
		reset <= 1'b0;
		@(posedge clk);
		reg_data_in <= 31'hFFFFFFFF;
		// write

		mem_write_enable <= 1'b1;
		for (int i = 0; i < 16; i++) begin // for each reg address
			reg_address <= i; @(posedge clk);
		end
		mem_write_enable <= 1'b0;
		// read

		mem_read_enable <= 1'b1;
		for (int i = 0; i < 16; i++) begin
			reg_address <= i; @(posedge clk);
		end
	end
endmodule

