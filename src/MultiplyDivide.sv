module MultiplyDivide (
    input logic [31:0] A, B,
    input logic op,           // op=0 for Multiply, op=1 for Divide
    output logic [63:0] result
);

    logic [63:0] product;
    logic [31:0] quotient, remainder;
    logic div_by_zero;

    always_comb begin
        // Multiplication: A * B
        product = A * B;

        // Division: A / B with remainder
        div_by_zero = (B == 32'b0);
        
        if (div_by_zero) begin
            quotient = 32'bx;
            remainder = 32'bx;
        end 
        else begin
            quotient = A / B;
            remainder = A % B;
        end

        // Select output based on operation
        if (~op) begin
            // Multiply
            result = product;

        end 
        else begin

            // Divide
            result = {remainder, quotient};

        end
    end

endmodule
