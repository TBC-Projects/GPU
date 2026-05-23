// Thread execution ALU: ADD, SUB, MUL, DIV (signed).
// Used by Thread.sv. Kept separate from src/ALU.sv, which is a different
// (mux-based) ALU design for another datapath style.
//
// operation encoding:
//   2'b00 = ADD
//   2'b01 = SUB
//   2'b10 = MUL  (lower 32 bits of signed product)
//   2'b11 = DIV  (signed; overflow=1 on divide-by-zero)

module alu_exec (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [1:0]  operation,
    output logic [31:0] result,
    output logic        overflow,
    output logic        negative,
    output logic        carry_out,
    output logic        zero
);

    // 33-bit path captures carry/borrow for ADD and SUB
    logic [32:0]        add_sub_result;
    logic signed [63:0] mul_full;

    always_comb begin
        result         = 32'b0;
        overflow       = 1'b0;
        carry_out      = 1'b0;
        add_sub_result = 33'b0;
        mul_full       = 64'b0;

        case (operation)
            2'b00: begin // ADD
                add_sub_result = {1'b0, a} + {1'b0, b};
                result    = add_sub_result[31:0];
                carry_out = add_sub_result[32];
                overflow  = (~a[31] & ~b[31] & result[31]) |
                            ( a[31] &  b[31] & ~result[31]);
            end

            2'b01: begin // SUB
                add_sub_result = {1'b0, a} - {1'b0, b};
                result    = add_sub_result[31:0];
                carry_out = add_sub_result[32];
                overflow  = ( a[31] & ~b[31] & ~result[31]) |
                            (~a[31] &  b[31] &  result[31]);
            end

            2'b10: begin // MUL (signed, lower 32 bits)
                mul_full = $signed(a) * $signed(b);
                result   = mul_full[31:0];
                overflow = (mul_full[63:32] != {32{mul_full[31]}});
            end

            2'b11: begin // DIV (signed)
                if (b == 32'b0) begin
                    result   = 32'b0;
                    overflow = 1'b1;
                end else begin
                    result = $signed(a) / $signed(b);
                end
            end
        endcase

        negative = result[31];
        zero     = (result == 32'b0);
    end

endmodule
