// Filename: instruction_memory.sv
// Description: Instruction ROM, adapted from material provided in ECE 469 at UW.
//
// `define KERNEL <path to kernel>
//
// Bytes in memory (power of two)

`define MEM_SIZE 1024

module instruction_memory (
	input logic [31:0] address,
	output logic [15:0] instruction,
	input logic clk // for error checking
	);
	
	// Power of two, reasonable
	initial assert ((`MEM_SIZE & (MEM_SIZE-1)) == 0 && `MEM_SIZE > 4);

	always_ff @(posedge clk) begin
		if (address !== 'x) begin
			assert(address[1:0] == 0);
			assert(address + 3 < `MEM_SIZE);
		end
	end

	logic [31:0] mem [`MEM_SIZE/4-1:0];

	initial begin
		$readmemb(`KERNEL, mem);
		$display("Running Kernel: ", `BENCHMARK);
	end

	int i;
	always_comb begin
		if (address + 3 >= MEM_SIZE)
			instruction = 'x;
		else
			instruction = mem[address/4];
	end
endmodule

module instruction_memory_testbench;
	logic [31:0] address,
	logic [15:0] instruction,
	logic clk,
	
	instruction_memory dut (
		.address		(address),
		.instruction	(instruction),
		.clk 			(clk)
	);
		
	
endmodule
	
