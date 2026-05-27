// Decoder: 4-to-16 one-hot decoder with enable.
//
// Converts a 4-bit binary address into a 16-bit one-hot output where only
// the bit at position 'in' is set high. All other bits remain 0.
// When 'enable' is low, all outputs are 0 (decoder is disabled).
//
// Used by RegFile to generate the write enable signal for each register:
// only the register addressed by write_address gets its write enable asserted.
// This mirrors the hardware reality — a decoder drives the clock enable or
// load signal of exactly one register's flip-flop array.

module Decoder (
    input  logic [3:0]  in,      // 4-bit register address (selects 1 of 16)
    input  logic        enable,  // when low, all outputs are 0
    output logic [15:0] out      // one-hot: out[in]=1, all others=0
);

    always_comb begin
        out = 16'b0; // default: all outputs low
        if (enable) begin
            case (in)
                4'b0000: out = 16'b0000_0000_0000_0001;
                4'b0001: out = 16'b0000_0000_0000_0010;
                4'b0010: out = 16'b0000_0000_0000_0100;
                4'b0011: out = 16'b0000_0000_0000_1000;
                4'b0100: out = 16'b0000_0000_0001_0000;
                4'b0101: out = 16'b0000_0000_0010_0000;
                4'b0110: out = 16'b0000_0000_0100_0000;
                4'b0111: out = 16'b0000_0000_1000_0000;
                4'b1000: out = 16'b0000_0001_0000_0000;
                4'b1001: out = 16'b0000_0010_0000_0000;
                4'b1010: out = 16'b0000_0100_0000_0000;
                4'b1011: out = 16'b0000_1000_0000_0000;
                4'b1100: out = 16'b0001_0000_0000_0000;
                4'b1101: out = 16'b0010_0000_0000_0000;
                4'b1110: out = 16'b0100_0000_0000_0000;
                4'b1111: out = 16'b1000_0000_0000_0000;
                default: out = 16'b0;
            endcase
        end
    end

endmodule
