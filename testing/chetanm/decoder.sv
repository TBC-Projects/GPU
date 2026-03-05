module decoder (
    input  logic [3:0]  in,
    input  logic        en,
    output logic [15:0] out
);

    always_comb begin
        out = 16'b0;          // default: all outputs low
        if (en)
            out[in] = 1'b1;   // one-hot output
    end

endmodule
