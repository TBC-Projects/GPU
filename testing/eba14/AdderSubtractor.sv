// AdderSubtractor: 1-bit full adder/subtractor building block.
//
// 32 of these are chained together in ALU to form a 32-bit ripple-carry
// adder/subtractor. The carry chain connects Cout[i] → Cin[i+1].
//
// ADD (op=0): S = A ^ B ^ Cin,  Cout = (A&B) | ((A^B)&Cin)
// SUB (op=1): Uses borrow logic. Cin=1 injected at bit 0 implements
//             two's complement negation: A - B = A + (~B) + 1

module AdderSubtractor (
    input  logic A, B,   // 1-bit operands
    input  logic Cin,    // carry/borrow in from previous bit
    input  logic op,     // 0=Add, 1=Subtract
    output logic S,      // sum/difference bit output
    output logic Cout    // carry/borrow out to next bit
);

    logic B_eff;      // effective B: inverted for subtraction (two's complement)
    logic carry_gen;  // carry generate: A & B_eff
    logic carry_prop; // carry propagate: A ^ B_eff

    always_comb begin
        B_eff      = op ? ~B : B;  // invert B for subtraction; ALU injects Cin=1 at bit 0
        carry_prop = A ^ B_eff;
        carry_gen  = A & B_eff;
        S          = carry_prop ^ Cin;
        Cout       = carry_gen | (carry_prop & Cin);
    end

endmodule
