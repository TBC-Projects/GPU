module program_counter (
    // Clock that increments 
    input logic             clk, 

    // 1 running/paused/reset, 0 if not
    input logic             running,
    input logic             pause,
    input logic             reset,

    // If the ALU passed in 
    input logic             branch_taken,
    input logic [31:0]      branch_data,

    output logic [31:0]     pc
);

    logic [31:0] next_pc;

    always_ff @(posedge clk) begin
        if (reset)
            pc <= 32'd0;
        else if (running) begin
            if (pause)
                pc <= pc;
            else
                if (branch_taken)
                    pc <= branch_data;
                else 
                    pc <= pc + 32'd4;
        end
    end

endmodule
