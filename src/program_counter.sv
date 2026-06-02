module program_counter (
    // Clock that increments 
    input logic             clk, 

    // 1 running/paused/reset, 0 if not
    input logic             running
    input logic             pause,
    input logic             reset,

    // If the ALU passed in 
    input logic             branch_taken,
    input logic [31:0]      branch_data,

    output logic [31:0]     pc
);

    logic [31:0] next_pc;

    always_ff @(posedge clk) begin
        if (reset)
            pc <= 32'd0;
        else if (running) begin
            if (pause)
                pc <= pc;
            else
                if (branch_taken)
                    pc <= branch_data;
                else 
                    pc <= pc + 32'd4;
        end
    end

endmodule

module program_counter_testbench();
	logic clk;
	logic running;
	logic pause;
	logic reset;
	logic branch_taken;
	logic [31:0] branch_data;
	logic [31:0] pc;
	parameter ClockDelay = 5000;

	program_counter dut(.clk, .running, .reset, .pause, .branch_taken, .branch_data, .pc);
	
	initial begin
		clk <= 0;
		forever clk <= (ClockDelay/2) clk <= ~clk;
	end
	
	initial begin
		reset <= 1'b1;
		@(posedge clk); 
		reset <= 1'b0;
		running <= 1'b1;
		$display("Now testing: 16 cycles of nothing");
		for (int i = 0; i < 16; i++) begin
			@(posedge clk); $display("pc = %d", pc);
		end
		@(posedge clk);
		$display("Now testing: 8 cycles paused");
		pause <= 1'b1;
		for (int i = 0; i < 8; i++) begin
			@(posedge clk); $display("pc = %d", pc);
		end
		@(posedge clk);
		$display("Now testing: branch taken");
		$display("pc = %d", pc);
		pause <= 1'b0;
		branch_taken <= 1'b1;
		branch_data <= 32'd0; // goto beginning
		@(posedge clk); $display("pc = %d", pc);
	end
endmodule
