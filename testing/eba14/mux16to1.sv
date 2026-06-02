// 16-to-1 Multiplexer
module Mux16to1 (
    input  logic [15:0] in,  
    input  logic [3:0]  sel, 
    output logic        out    
);
    
    always_comb begin
        case (sel) // Select the output based on the 4-bit selector combination, which equals the corresponding input value
            4'b0000: out = in[0];
            4'b0001: out = in[1];
            4'b0010: out = in[2];
            4'b0011: out = in[3];
            4'b0100: out = in[4];
            4'b0101: out = in[5];
            4'b0110: out = in[6];
            4'b0111: out = in[7];
            4'b1000: out = in[8];
            4'b1001: out = in[9];
            4'b1010: out = in[10];
            4'b1011: out = in[11];
            4'b1100: out = in[12];
            4'b1101: out = in[13];
            4'b1110: out = in[14];
            4'b1111: out = in[15];
            default: out = 1'bX; // default case to handle invalid selector values 
        endcase
    end
endmodule

// Testbench for Mux16to1
module Mux16to1_tb ();

    logic [15:0] in;
    logic [3:0]  sel;
    logic        out;

    Mux16to1 dut (.in(in), .sel(sel), .out(out));

    initial begin
        // Case 1: All inputs 0 - output must be 0 for any select
        in = 16'h0000;
        sel = 4'd0;  #10; assert(out == 1'b0);
        sel = 4'd7;  #10; assert(out == 1'b0);
        sel = 4'd15; #10; assert(out == 1'b0);

        // Case 2: All inputs 1 - output must be 1 for any select
        in = 16'hFFFF;
        sel = 4'd0;  #10; assert(out == 1'b1);
        sel = 4'd15; #10; assert(out == 1'b1);

        // Case 3: Only bit 0 set - sel=0 high, sel=1 low
        in = 16'h0001;
        sel = 4'd0; #10; assert(out == 1'b1);
        sel = 4'd1; #10; assert(out == 1'b0);

        // Case 4: Only bit 15 set - sel=15 high, sel=14 low
        in = 16'h8000;
        sel = 4'd15; #10; assert(out == 1'b1);
        sel = 4'd14; #10; assert(out == 1'b0);

        // Case 5: Alternating bits set - verifying correct output for each select
        in = 16'hAAAA; // 1010_1010_1010_1010
        sel = 4'd0;  #10; assert(out == 1'b0);
        sel = 4'd1;  #10; assert(out == 1'b1);
        sel = 4'd2;  #10; assert(out == 1'b0);
        sel = 4'd3;  #10; assert(out == 1'b1);
        sel = 4'd4;  #10; assert(out == 1'b0);
        sel = 4'd5;  #10; assert(out == 1'b1);
        sel = 4'd6;  #10; assert(out == 1'b0);
        sel = 4'd7;  #10; assert(out == 1'b1);
        sel = 4'd8;  #10; assert(out == 1'b0);
        sel = 4'd9;  #10; assert(out == 1'b1);
        sel = 4'd10; #10; assert(out == 1'b0);
        sel = 4'd11; #10; assert(out == 1'b1);
        sel = 4'd12; #10; assert(out == 1'b0);
        sel = 4'd13; #10; assert(out == 1'b1);
        sel = 4'd14; #10; assert(out == 1'b0);
        sel = 4'd15; #10; assert(out == 1'b1);

        $finish;
    end
endmodule
