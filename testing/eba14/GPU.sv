// GPU: top-level module.
// Instantiates NUM_CORES cores, each containing THREADS_PER_BLOCK threads.
//
// Responsibilities:
//   - Launches all cores simultaneously when kernel_start is pulsed
//   - Runs a round-robin scheduler that selects one thread per cycle across all cores
//   - Asserts kernel_done when every core has finished
//
// Hierarchy:
//   GPU
//   └── Core[0..NUM_CORES-1]
//       └── Thread[0..THREADS_PER_BLOCK-1]
//           ├── RegFile         -- 16x32-bit registers
//           ├── ALU             -- arithmetic and logic
//           ├── program_counter -- per-thread PC
//           └── mem_load_store  -- memory interface

module GPU #(parameter NUM_CORES = 4, parameter THREADS_PER_BLOCK = 4) (
    input  logic clk,
    input  logic reset,
    input  logic kernel_start,  // pulse high for one cycle to launch the kernel
    output logic kernel_done    // goes high when all cores have finished
);

    localparam TOTAL_THREADS = NUM_CORES * THREADS_PER_BLOCK;

    // -------------------------------------------------------------------------
    // Kernel launch and completion tracking
    // -------------------------------------------------------------------------
    logic [NUM_CORES-1:0] core_done;

    // kernel_running stays high from launch until all cores report done
    logic kernel_running;
    always_ff @(posedge clk) begin
        if (reset)             kernel_running <= 1'b0;
        else if (kernel_start) kernel_running <= 1'b1;
        else if (&core_done)   kernel_running <= 1'b0;
    end

    assign kernel_done = &core_done; // all cores done = kernel done

    // core_start is a one-cycle pulse forwarded directly from kernel_start
    logic [NUM_CORES-1:0] core_start;
    assign core_start = {NUM_CORES{kernel_start}};

    // -------------------------------------------------------------------------
    // Round-robin scheduler
    // Cycles a pointer through all TOTAL_THREADS slots, one per clock cycle.
    // Only the thread at sched_ptr has its running bit set high.
    // -------------------------------------------------------------------------
    logic [$clog2(TOTAL_THREADS)-1:0] sched_ptr;

    always_ff @(posedge clk) begin
        if (reset)
            sched_ptr <= '0;
        else if (kernel_running)
            sched_ptr <= (sched_ptr == TOTAL_THREADS - 1) ? '0 : sched_ptr + 1;
    end

    // running_flat[t] is 1 for the currently scheduled thread, 0 for all others
    logic [TOTAL_THREADS-1:0] running_flat;
    always_comb begin
        running_flat = '0;
        if (kernel_running)
            running_flat[sched_ptr] = 1'b1;
    end

    // -------------------------------------------------------------------------
    // Core instances
    // Each core receives a THREADS_PER_BLOCK-wide slice of running_flat.
    // core_gen[0] gets threads 0..THREADS_PER_BLOCK-1,
    // core_gen[1] gets threads THREADS_PER_BLOCK..2*THREADS_PER_BLOCK-1, etc.
    // -------------------------------------------------------------------------
    genvar c;
    generate
        for (c = 0; c < NUM_CORES; c++) begin : core_gen
            Core #(.THREADS_PER_BLOCK(THREADS_PER_BLOCK)) core_inst (
                .clk    (clk),
                .reset  (reset),
                .start  (core_start[c]),
                .done   (core_done[c]),
                .running(running_flat[c*THREADS_PER_BLOCK +: THREADS_PER_BLOCK])
            );
        end
    endgenerate

endmodule
