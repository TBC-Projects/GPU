// Core: one block of THREADS_PER_BLOCK threads.
//
// The Core groups threads into a block (like a CUDA block).
// Each thread runs independently but shares the same clk and reset.
// The scheduler at the GPU level decides which thread runs each cycle
// by driving the 'running' array -- one bit per thread, one high at a time.
// When every thread signals 'halt', the Core asserts 'done' back to the GPU.
//
// Hierarchy:
//   Core
//   └── Thread[0..THREADS_PER_BLOCK-1]
//       ├── RegFile   -- 16x32-bit register storage
//       ├── ALU       -- arithmetic and logic operations
//       ├── program_counter -- per-thread PC
//       └── mem_load_store  -- memory load/store interface

module Core #(parameter THREADS_PER_BLOCK = 4) (
    input  logic clk,
    input  logic reset,
    input  logic start,                              // pulsed by GPU to begin execution
    output logic done,                               // high when all threads have halted

    // One running bit per thread, driven by the GPU-level scheduler.
    // Packed so GPU can slice directly from its flat running bus.
    input  logic [THREADS_PER_BLOCK-1:0] running
);

    // halt[i] goes high when thread i has finished executing
    logic halt [THREADS_PER_BLOCK-1:0];

    // Track whether the kernel has actually started so 'done' is not asserted at reset
    logic started;
    always_ff @(posedge clk) begin
        if (reset)      started <= 1'b0;
        else if (start) started <= 1'b1;
    end

    // Generate one Thread instance per slot in the block.
    // thread_gen[i].thread_inst refers to the i-th thread at elaboration time.
    genvar i;
    generate
        for (i = 0; i < THREADS_PER_BLOCK; i++) begin : thread_gen
            Thread thread_inst (
                .clk    (clk),
                .reset  (reset),
                .running(running[i]),
                .halt   (halt[i])
            );
        end
    endgenerate

    // Core is done when every thread has halted and the kernel has started.
    // &halt reduces the halt array with AND -- true only when all bits are 1.
    assign done = started & (&halt);

endmodule
