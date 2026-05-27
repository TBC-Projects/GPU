// ALU: Arithmetic Logic Unit
//
// Structurally composed of two submodules:
//   - AdderSubtractor: 32 1-bit instances chained as a ripple-carry adder/subtractor
//   - MultiplyDivide:  handles MUL (64-bit product) and DIV (quotient + remainder)
//
// Logic operations (AND, OR, XOR) are implemented directly — they have no
// meaningful gate-level submodule decomposition beyond basic gates.
//
// Operation encoding (3-bit):
//   000=ADD  001=SUB  010=MUL  011=DIV  100=AND  101=OR  110=XOR
//
// Output flags:
//   overflow  — signed arithmetic overflow (ADD/SUB), or divide-by-zero (DIV),
//               or product exceeds 32 bits (MUL)
//   negative  — result[31] is set (two's complement sign bit)
//   carry_out — unsigned carry/borrow out of bit 31 (ADD/SUB only)
//   zero      — result is exactly 0 (used by Control for BEQ/BNE branches)

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

    // -------------------------------------------------------------------------
    // 32-bit Ripple-Carry Adder/Subtractor
    // 32 AdderSubtractor instances are chained: carry[i+1] = Cout of bit i.
    // For subtraction, Cin=1 implements two's complement negation of B.
    // op_is_sub is driven by operation[0]: ADD=000→0, SUB=001→1
    // -------------------------------------------------------------------------
    logic [31:0] add_sub_S;  // per-bit sum/difference outputs
    logic [32:0] carry;      // carry chain: carry[0]=Cin, carry[32]=final Cout

    logic op_is_sub;
    assign op_is_sub = operation[0]; // 1 for SUB, 0 for ADD
    assign carry[0]  = op_is_sub;    // inject 1 as Cin for two's complement subtraction

    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : adder_chain
            // Each bit slice: computes one bit of the sum and propagates carry
            AdderSubtractor bit_adder (
                .A   (a[i]),
                .B   (b[i]),
                .Cin (carry[i]),
                .op  (op_is_sub),
                .S   (add_sub_S[i]),
                .Cout(carry[i+1])
            );
        end
    endgenerate

    // Signed overflow detection for ADD and SUB:
    // ADD overflows if two positives produce a negative, or two negatives produce a positive
    // SUB overflows if positive - negative = negative, or negative - positive = positive
    logic add_sub_overflow;
    assign add_sub_overflow =
        (~op_is_sub & ~a[31] & ~b[31] &  add_sub_S[31]) |  // ADD: +,+ → -
        (~op_is_sub &  a[31] &  b[31] & ~add_sub_S[31]) |  // ADD: -,- → +
        ( op_is_sub &  a[31] & ~b[31] & ~add_sub_S[31]) |  // SUB: -,+ → +
        ( op_is_sub & ~a[31] &  b[31] &  add_sub_S[31]);   // SUB: +,- → -

    // -------------------------------------------------------------------------
    // Multiply/Divide Unit
    // MUL (op=0): returns full 64-bit product; ALU uses lower 32 bits
    // DIV (op=1): returns {remainder[31:0], quotient[31:0]}; ALU uses quotient
    // muldiv_op: MUL=010→operation[0]=0, DIV=011→operation[0]=1
    // -------------------------------------------------------------------------
    logic [63:0] muldiv_result;
    logic        muldiv_op;
    assign muldiv_op = operation[0];

    MultiplyDivide muldiv (
        .A     (a),
        .B     (b),
        .op    (muldiv_op),
        .result(muldiv_result)
    );

    // -------------------------------------------------------------------------
    // Output mux: select result and flags based on operation
    // -------------------------------------------------------------------------
    always_comb begin
        result    = 32'b0;
        overflow  = 1'b0;
        carry_out = 1'b0;

        case (operation)
            3'b000: begin // ADD
                result    = add_sub_S;
                carry_out = carry[32];
                overflow  = add_sub_overflow;
            end
            3'b001: begin // SUB
                result    = add_sub_S;
                carry_out = carry[32];
                overflow  = add_sub_overflow;
            end
            3'b010: begin // MUL — lower 32 bits of 64-bit product
                result   = muldiv_result[31:0];
                // Overflow if upper 32 bits are not a sign extension of bit 31
                overflow = (muldiv_result[63:32] != {32{muldiv_result[31]}});
            end
            3'b011: begin // DIV — quotient in lower 32 bits
                result   = muldiv_result[31:0];
                overflow = (b == 32'b0); // divide by zero
            end
            3'b100: result = a & b; // AND — bitwise
            3'b101: result = a | b; // OR  — bitwise
            3'b110: result = a ^ b; // XOR — bitwise
            default: result = 32'b0;
        endcase

        // Flags derived from final result
        negative = result[31];           // MSB is sign bit in two's complement
        zero     = (result == 32'b0);    // used by Control.sv for BEQ/BNE
    end

endmodule
