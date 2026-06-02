module ALU_tb ();

    logic [31:0] input1, input2, input3;
    logic [2:0] operation;
    logic [31:0] output1, output2;

    logic clk;

    // define parameters
	parameter T = 20;
	
	// define simulated clock
	initial begin
		clk <= 0;
		forever  #(T/2)  clk <= ~clk;
	end // initial

    ALU dut (.input1(input1), .input2(input2), .input3(input3), 
    .output1(output1), .output2(output2), .operation(operation));

    initial begin
        // Test addition
        input1 = 32'h00000005; // 5
        input2 = 32'h00000003; // 3
        input3 = 32'h00000000; // carry in = 0

        operation = 3'b000; // addition, expecting output1 = 8 and output2 = 0 (no carry out)
        #10;

        // Test subtraction
        operation = 3'b001; // subtraction, expecting output1 = 2 and output2 = 0 (no borrow)
        #10;

        // Test sign extension
        input1 = 32'hFFFFFFFF; // -1 in 32-bit signed

        operation = 3'b010; // sign extension, expecting output1 = 0xFFFFFFFF
        #10;

        // Test zero extension
        operation = 3'b011; // zero extension, expecting output1 = 0x000000FF
        #10;

        // Test multiplication
        input1 = 32'h00000004; // 4
        input2 = 32'h00000002; // 2
        
        operation = 3'b100; // multiplication, expecting output1 = 8 and output2 = 0 (no overflow)
        #10;

        // Test division
        operation = 3'b101; // division, expecting quotient = 2 and remainder = 0
        #10;

        $stop; // stop the simulation

    end // initial

endmodule // ALU_tb
