// ALU: supports 7 operations selected by a 3-bit opcode.
//
// Operation encoding:
//   000=ADD  001=SUB  010=MUL  011=DIV  100=AND  101=OR  110=XOR
//
// Output flags:
//   overflow  -- signed overflow for ADD/SUB; upper bits non-zero for MUL; divide-by-zero for DIV
//   negative  -- result bit 31 is set (two's complement sign bit)
//   carry_out -- unsigned carry out of bit 31 (ADD/SUB only)
//   zero      -- result is exactly 0
//
// MUL and DIV are handled by the MultiplyDivide submodule from src/.

module ALU (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [2:0]  operation,
    output logic [31:0] result,
    output logic        overflow,
    output logic        negative,
    output logic        carry_out,
    output logic        zero
);

    // ADD/SUB: extend both operands to 33 bits so the extra bit captures carry/borrow.
    // {1'b0, a} zero-extends a to 33 bits -- the result overflows into bit[32].
    logic [32:0] add_sub_result;

    // MUL/DIV: handled by the MultiplyDivide submodule.
    // op=0 returns the full 64-bit product; op=1 returns {remainder[31:0], quotient[31:0]}.
    logic [63:0] muldiv_result;
    logic        muldiv_op;
    assign muldiv_op = operation[0]; // MUL=010 -> bit0=0, DIV=011 -> bit0=1

    MultiplyDivide muldiv (
        .A     (a),
        .B     (b),
        .op    (muldiv_op),
        .result(muldiv_result)
    );

    always_comb begin
        result         = 32'b0;
        overflow       = 1'b0;
        carry_out      = 1'b0;
        add_sub_result = 33'b0;

        case (operation)
            3'b000: begin // ADD
                add_sub_result = {1'b0, a} + {1'b0, b};
                result    = add_sub_result[31:0];
                carry_out = add_sub_result[32];
                // Signed overflow: two positives sum to negative, or two negatives sum to positive
                overflow  = (~a[31] & ~b[31] & result[31]) |
                            ( a[31] &  b[31] & ~result[31]);
            end

            3'b001: begin // SUB
                add_sub_result = {1'b0, a} - {1'b0, b};
                result    = add_sub_result[31:0];
                carry_out = add_sub_result[32];
                // Signed overflow: positive minus negative gives negative, or vice versa
                overflow  = ( a[31] & ~b[31] & ~result[31]) |
                            (~a[31] &  b[31] &  result[31]);
            end

            3'b010: begin // MUL -- lower 32 bits of the 64-bit product
                result   = muldiv_result[31:0];
                // Overflow if the upper 32 bits are not a sign extension of bit 31
                overflow = (muldiv_result[63:32] != {32{muldiv_result[31]}});
            end

            3'b011: begin // DIV -- quotient in lower 32 bits
                result   = muldiv_result[31:0];
                overflow = (b == 32'b0); // divide by zero
            end

            3'b100: result = a & b; // AND
            3'b101: result = a | b; // OR
            3'b110: result = a ^ b; // XOR

            default: result = 32'b0;
        endcase

        negative = result[31];
        zero     = (result == 32'b0);
    end

endmodule
