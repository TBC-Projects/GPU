module MutliplyDivide_tb ();

    logic [31:0] A, B;
    logic op;
    logic [63:0] result;

    logic clk;

    // define parameters
    parameter T = 20;

    // define simulated clock
    initial begin
        clk <= 0;
        forever  #(T/2)  clk <= ~clk;
    end // initial

    MultiplyDivide dut (.A(A), .B(B), .op(op), .result(result));

    initial begin

        // Test multiplication
        A = 32'h00000004; // 4
        B = 32'h00000002; // 2

        op = 1'b0; // multiplication, expecting result = 8
        #10;

        // Test division
        op = 1'b1; // division, expecting result = {remainder, quotient} = {0, 2}
        #10;

        // Test division by zero
        B = 32'h00000000; // 0
        
        op = 1'b1; // division, expecting result = {x, x}
        #10;

        $stop; // stop the simulation

    end // initial

endmodule // MultiplyDivide_tb