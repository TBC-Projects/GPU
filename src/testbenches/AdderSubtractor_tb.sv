module AdderSubtractor_tb ();

    logic A, B, Cin, op;
    logic Cout, S;

    logic clk;

    // define parameters
    parameter T = 20;

    // define simulated clock
    initial begin
        clk <= 0;
        forever  #(T/2)  clk <= ~clk;
    end // initial

    AdderSubtractor dut (.A(A), .B(B), .Cin(Cin), .op(op), .Cout(Cout), .S(S));

    initial begin
        // Test addition
        A = 1'b0; B = 1'b0; Cin = 1'b0; op = 1'b0; #10; // Expect S=0, Cout=0
        A = 1'b0; B = 1'b0; Cin = 1'b1; op = 1'b0; #10; // Expect S=1, Cout=0
        A = 1'b0; B = 1'b1; Cin = 1'b0; op = 1'b0; #10; // Expect S=1, Cout=0
        A = 1'b0; B = 1'b1; Cin = 1'b1; op = 1'b0; #10; // Expect S=0, Cout=1
        A = 1'b1; B = 1'b0; Cin = 1'b0; op = 1'b0; #10; // Expect S=1, Cout=0
        A = 1'b1; B = 1'b0; Cin = 1'b1; op = 1'b0; #10; // Expect S=0, Cout=1
        A = 1'b1; B = 1'b1; Cin = 1'b0; op = 1'b0; #10; // Expect S=0, Cout=1
        A = 1'b1; B = 1'b1; Cin = 1'b1; op = 1'b0; #10; // Expect S=1, Cout=1

        // Test subtraction
        A = 1'b0; B = 1'b0; Cin = 1'b0; op = 1'b1; #10; // Expect S=0, Cout=0
        A = 1'b0; B = 1'b0; Cin = 1'b1; op = 1'b1; #10; // Expect S=11111111 (or -128 in signed), Cout=11111111 (or -128 in signed)
        A = 1'b0; B = 1'b1; Cin = 1'b0; op = 1'b1; #10; // Expect S=11111111 (or -128 in signed), Cout=11111111 (or -128 in signed)
        A = 1'b0; B = 1'b1; Cin = 1'b1; op = 1'b1; #10; // Expect S=11111110 (or -127 in signed), Cout=11111111 (or -128 in signed)
        A = 1'b1; B = 1'b0; Cin = 1'b0; op = 1'b1; #10; // Expect S=1, Cout=0
        A = 1'b1; B = 1'b0; Cin = 1'b1; op = 1'b1; #10; // Expect S=0, Cout=0
        A = 1'b1; B = 1'b1; Cin = 1'b0; op = 1'b1; #10; // Expect S=0, Cout=0
        A = 1'b1; B = 1'b1; Cin = 1'b1; op = 1'b1; #10; // Expect S=11111111 (or -128 in signed), Cout=11111111 (or -128 in signed)

        $stop; // stop the simulation

    end // initial

endmodule // AdderSubtractor_tb