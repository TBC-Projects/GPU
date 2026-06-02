// 16-to-1 Multiplexer
module mux16to1 (
    input  logic [15:0] in,  
    input  logic [3:0]  sel, 
    output logic        out    
);
    
    // The index 'sel' selects the correct bit to output based on the input 'in'
    assign out = in[sel];

endmodule

module mux16to1_testbench;
    logic [15:0] in;
    logic [3:0] sel;
    logic out;
    
    mux16to1 dut(.in, .sel, .out);
    
    initial begin
       in = 16'b0101010101010101; #10;
        for (int i=0; i < 16, i++) begin
            sel = i; #10;
        end
    end
    endmodule 
