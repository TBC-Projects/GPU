// GPU-level dispatch: queue block tasks and assign each to a free core (round-robin).
// Does not depend on Thread.sv. Connect core_busy[i] / core_start[i] when Core is ready.
//
// Future hookup:
//   task_valid, task_block_id  <- host / memory controller
//   core_busy[i]               <- Core[i].busy
//   core_start[i], core_block_id[i] -> Core[i].start, Core[i].block_id

module dispatch #(
    parameter int NUM_CORES    = 4,
    parameter int QUEUE_DEPTH  = 8,
    parameter int BLOCK_ID_W   = 4
) (
    input  logic clk,
    input  logic reset,

    input  logic                     task_valid,
    input  logic [BLOCK_ID_W-1:0]    task_block_id,
    output logic                     task_ready,

    input  logic [NUM_CORES-1:0]     core_busy,
    output logic [NUM_CORES-1:0]     core_start,
    output logic [NUM_CORES-1:0][BLOCK_ID_W-1:0] core_block_id,

    output logic                     assign_valid,
    output logic [BLOCK_ID_W-1:0]    assigned_block_id,
    output logic [$clog2(NUM_CORES)-1:0] assigned_core_id
);

    localparam int QUEUE_PTR_W = (QUEUE_DEPTH > 1) ? $clog2(QUEUE_DEPTH) : 1;
    localparam int CORE_ID_W   = (NUM_CORES > 1) ? $clog2(NUM_CORES) : 1;

    logic [BLOCK_ID_W-1:0] fifo [QUEUE_DEPTH];
    logic [QUEUE_PTR_W-1:0] wr_ptr;
    logic [QUEUE_PTR_W-1:0] rd_ptr;
    logic [QUEUE_PTR_W:0]   queue_count;

    logic [NUM_CORES-1:0]  free_cores;
    logic                  can_assign;
    logic [CORE_ID_W-1:0]  selected_core;
    logic [CORE_ID_W-1:0]  rr_ptr;
    logic [BLOCK_ID_W-1:0] head_block_id;

    logic do_assign;
    logic do_enqueue;

    assign free_cores    = ~core_busy;
    assign head_block_id = fifo[rd_ptr];
    assign task_ready    = (queue_count < QUEUE_DEPTH);

    always_comb begin
        selected_core = '0;
        can_assign      = 1'b0;
        if ((queue_count != '0) && (|free_cores)) begin
            for (int offset = 0; offset < NUM_CORES; offset++) begin
                int idx = (rr_ptr + offset) % NUM_CORES;
                if (free_cores[idx]) begin
                    selected_core = CORE_ID_W'(idx);
                    can_assign    = 1'b1;
                    break;
                end
            end
        end
    end

    assign do_assign  = can_assign;
    assign do_enqueue = task_valid && task_ready;

    assign assign_valid      = do_assign;
    assign assigned_block_id = head_block_id;
    assign assigned_core_id  = selected_core;

    always_ff @(posedge clk) begin
        core_start <= '0;

        if (reset) begin
            wr_ptr        <= '0;
            rd_ptr        <= '0;
            queue_count   <= '0;
            rr_ptr        <= '0;
            core_block_id <= '0;
        end else begin
            if (do_assign) begin
                core_start[selected_core]    <= 1'b1;
                core_block_id[selected_core] <= head_block_id;
                if (rd_ptr == QUEUE_DEPTH - 1)
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;
                if (selected_core == NUM_CORES - 1)
                    rr_ptr <= '0;
                else
                    rr_ptr <= selected_core + 1'b1;
            end

            if (do_enqueue) begin
                fifo[wr_ptr] <= task_block_id;
                if (wr_ptr == QUEUE_DEPTH - 1)
                    wr_ptr <= '0;
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            if (do_assign && do_enqueue)
                queue_count <= queue_count;
            else if (do_assign)
                queue_count <= queue_count - 1'b1;
            else if (do_enqueue)
                queue_count <= queue_count + 1'b1;
        end
    end

endmodule
