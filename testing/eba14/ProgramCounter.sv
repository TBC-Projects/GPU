// Program Counter: tracks the current instruction address for all threads.
//
// A single shared PC lives at the GPU level — all threads execute the same
// kernel program. The PC advances by 4 each cycle (32-bit word-addressed memory).
//
// Branch/jump: if any thread asserts branch_taken, the PC loads branch_target
// instead of incrementing. Since all threads run the same code path (divergence
// is handled via tid-based data indexing, not control flow divergence), a single
// shared branch signal is sufficient.
//
// Pause: the PC holds its value when pause is asserted (e.g. memory stall).
// Running: the PC only advances when running is high (kernel is active).

module ProgramCounter (
    input  logic        clk,
    input  logic        running,       // high when kernel is active (from Dispatch)
    input  logic        pause,         // holds PC when high (e.g. all threads stalled)
    input  logic        reset,         // synchronous reset, returns PC to 0
    input  logic        branch_taken,  // asserted by Control when a branch/jump executes
    input  logic [31:0] branch_target, // target address for branch/jump
    output logic [31:0] pc             // current instruction address
);

    always_ff @(posedge clk) begin
        if (reset)
            pc <= 32'd0;
        else if (running && !pause) begin
            if (branch_taken)
                pc <= branch_target;  // jump to branch target
            else
                pc <= pc + 32'd4;     // advance to next 32-bit word
        end
        // if !running or pause: PC holds its current value
    end

endmodule
