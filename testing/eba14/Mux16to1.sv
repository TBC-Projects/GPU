// 16-to-1 Multiplexer (1-bit output)
//
// Selects one of 16 input bits based on a 4-bit selector.
// Used by RegFile as the read-port selection mechanism:
// 32 instances of this mux (one per bit position) reconstruct a full
// 32-bit register value from the 16-register storage array.
//
// in[r]  = bit value from register r at a given bit position
// sel    = read_address (which register to output)
// out    = the selected register's bit at this position

module Mux16to1 (
    input  logic [15:0] in,   // 16 input bits (one per register at a given bit position)
    input  logic [3:0]  sel,  // 4-bit select: chooses which input bit to output
    output logic        out   // selected bit
);

    always_comb begin
        case (sel)
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
            default: out = 1'bx; // x for invalid selector (should never happen with 4-bit sel)
        endcase
    end

endmodule
