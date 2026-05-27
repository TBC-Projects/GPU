// Multiply/Divide Unit: handles MUL and DIV operations for the ALU.
//
// MUL (op=0): computes A * B as a full 64-bit product.
//   The ALU uses result[31:0] as the output and checks result[63:32]
//   for overflow (non-zero upper half means the product exceeds 32 bits).
//
// DIV (op=1): computes A / B (quotient) and A % B (remainder).
//   result = { remainder[31:0], quotient[31:0] }
//   The ALU uses result[31:0] as the quotient output.
//   Division by zero produces 'x to signal an invalid operation.
//
// Note: operations are unsigned. Signed behavior can be added by
// pre-negating inputs and post-correcting the sign of the result.

module MultiplyDivide (
    input  logic [31:0] A, B,
    input  logic        op,         // 0=Multiply, 1=Divide
    output logic [63:0] result
);

    logic [63:0] product;
    logic [31:0] quotient, remainder;
    logic        div_by_zero;

    always_comb begin
        product     = A * B;
        div_by_zero = (B == 32'b0);

        if (div_by_zero) begin
            quotient  = 32'bx; // undefined — ALU sets overflow flag
            remainder = 32'bx;
        end else begin
            quotient  = A / B;
            remainder = A % B;
        end

        if (~op)
            result = product;               // MUL: full 64-bit product
        else
            result = {remainder, quotient}; // DIV: upper=remainder, lower=quotient
    end

endmodule
