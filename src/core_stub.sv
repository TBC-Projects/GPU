// Placeholder core: asserts busy for a fixed number of cycles after start.
// Use until real Core.sv + Thread.sv export start/block_id/busy.

module core_stub #(
    parameter int BLOCK_ID_W  = 4,
    parameter int BUSY_CYCLES = 8
) (
    input  logic clk,
    input  logic reset,

    input  logic                  start,
    input  logic [BLOCK_ID_W-1:0] block_id_in,

    output logic                  busy,
    output logic [BLOCK_ID_W-1:0] block_id_out
);

    localparam int COUNT_W = $clog2(BUSY_CYCLES + 1);

    logic [COUNT_W-1:0] countdown;
    logic             active;

    assign block_id_out = block_id_in;

    always_ff @(posedge clk) begin
        if (reset) begin
            active    <= 1'b0;
            countdown <= '0;
            busy      <= 1'b0;
        end else begin
            if (start && !busy) begin
                active    <= 1'b1;
                countdown <= BUSY_CYCLES[COUNT_W-1:0];
                busy      <= 1'b1;
            end else if (active) begin
                if (countdown == '0) begin
                    active <= 1'b0;
                    busy   <= 1'b0;
                end else begin
                    countdown <= countdown - 1'b1;
                end
            end
        end
    end

endmodule
