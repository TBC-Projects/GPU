// Testbench for dispatch.sv with synthetic core_busy (no Thread/Core DUT).
// Models each core as busy for BUSY_CYCLES after a core_start pulse.

`timescale 1ns/1ps

module dispatch_tb;

    localparam int NUM_CORES   = 4;
    localparam int QUEUE_DEPTH = 8;
    localparam int BLOCK_ID_W  = 4;
    localparam int BUSY_CYCLES = 6;

    logic clk;
    logic reset;

    logic task_valid;
    logic [BLOCK_ID_W-1:0] task_block_id;
    logic task_ready;

    logic [NUM_CORES-1:0] core_busy;
    logic [NUM_CORES-1:0] core_start;
    logic [NUM_CORES-1:0][BLOCK_ID_W-1:0] core_block_id;

    logic assign_valid;
    logic [BLOCK_ID_W-1:0] assigned_block_id;
    logic [$clog2(NUM_CORES)-1:0] assigned_core_id;

    localparam int COUNT_W = $clog2(BUSY_CYCLES + 2);
    logic [NUM_CORES-1:0][COUNT_W-1:0] busy_countdown;

    int errors;
    int assignments;
    logic [NUM_CORES-1:0] saw_start_while_busy;

    dispatch #(
        .NUM_CORES(NUM_CORES),
        .QUEUE_DEPTH(QUEUE_DEPTH),
        .BLOCK_ID_W(BLOCK_ID_W)
    ) dut (
        .clk,
        .reset,
        .task_valid,
        .task_block_id,
        .task_ready,
        .core_busy,
        .core_start,
        .core_block_id,
        .assign_valid,
        .assigned_block_id,
        .assigned_core_id
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Synthetic core_busy: asserted the cycle after core_start, held for BUSY_CYCLES
    logic [NUM_CORES-1:0] pending_start;

    always_ff @(posedge clk) begin
        if (reset) begin
            core_busy      <= '0;
            busy_countdown <= '0;
            pending_start  <= '0;
        end else begin
            for (int i = 0; i < NUM_CORES; i++) begin
                if (pending_start[i]) begin
                    core_busy[i]      <= 1'b1;
                    busy_countdown[i] <= BUSY_CYCLES[COUNT_W-1:0];
                end else if (core_busy[i]) begin
                    if (busy_countdown[i] == '0)
                        core_busy[i] <= 1'b0;
                    else
                        busy_countdown[i] <= busy_countdown[i] - 1'b1;
                end
            end
            pending_start <= core_start;
        end
    end

    // Check combinational pick uses current core_busy (before go_busy registers)
    always_ff @(posedge clk) begin
        if (!reset && assign_valid && core_busy[assigned_core_id]) begin
            $error("assign to busy core %0d", assigned_core_id);
            errors++;
        end
        if (!reset && assign_valid)
            assignments++;
    end

    task automatic enqueue(input logic [BLOCK_ID_W-1:0] id);
        @(posedge clk);
        task_valid    <= 1'b1;
        task_block_id <= id;
        @(posedge clk);
        if (!task_ready) begin
            $error("enqueue %0d rejected (queue full)", id);
            errors++;
        end
        task_valid <= 1'b0;
    endtask

    initial begin
        errors      = 0;
        assignments = 0;
        task_valid  = 0;
        reset       = 1;
        repeat (3) @(posedge clk);
        reset = 0;

        // All cores free: three tasks should spread across cores (RR)
        enqueue(4'd1);
        enqueue(4'd2);
        enqueue(4'd3);
        repeat (BUSY_CYCLES + 2) @(posedge clk);

        // All busy: queue two more, then free one core at a time
        core_busy <= 4'b1111;
        busy_countdown <= '1;
        enqueue(4'd4);
        enqueue(4'd5);

        if (!task_ready) begin
            enqueue(4'd6);
            $error("expected task_ready low when queue full");
            errors++;
        end

        core_busy[0] <= 1'b0;
        repeat (BUSY_CYCLES + 4) @(posedge clk);

        repeat (40) @(posedge clk);
        reset = 1;
        @(posedge clk);
        reset = 0;
        repeat (5) @(posedge clk);

        if (assignments < 3) begin
            $error("expected at least 3 assignments, got %0d", assignments);
            errors++;
        end

        if (errors == 0)
            $display("dispatch_tb: PASSED (%0d assignments observed)", assignments);
        else
            $display("dispatch_tb: FAILED (%0d errors)", errors);

        $finish;
    end

endmodule
