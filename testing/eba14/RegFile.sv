// Register File: 16 entries x 32 bits wide, with 1 write port and 2 read ports.
//
// Structurally built to reflect actual gate-level hardware:
//   Write path: write_address → Decoder → 16-bit one-hot write_select → DFF array
//               Only the register whose bit is high in write_select latches write_data.
//   Read path:  All 32 register bits at position [b] are collected into a 16-bit bus,
//               then fed into a Mux16to1 instance. 32 such muxes per read port (one
//               per bit position) reconstruct the full 32-bit read_data output.
//
// This mirrors how a real register file is built: the decoder selects which register
// to write, and the mux tree selects which register to read — both at the bit level.

module RegFile (
    input  logic        clk,
    input  logic        reset,          // synchronous active-high reset, clears all registers to 0

    // Write port
    input  logic [3:0]  write_address,  // selects which of the 16 registers to write
    input  logic [31:0] write_data,     // 32-bit data to write
    input  logic        write_enable,   // must be high for write to occur

    // Read port 1
    input  logic [3:0]  read_address_1,
    output logic [31:0] read_data_1,

    // Read port 2
    input  logic [3:0]  read_address_2,
    output logic [31:0] read_data_2
);

    // Decoder produces a one-hot 16-bit signal: only bit [write_address] is high
    logic [15:0] write_select;

    Decoder write_decoder (
        .in    (write_address),
        .enable(write_enable),
        .out   (write_select)
    );

    // 16 registers, each 32 bits wide
    logic [31:0] registers [0:15];

    // Write logic: each register latches write_data only when its write_select bit is high
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 16; i++)
                registers[i] <= 32'b0;
        end else begin
            for (int i = 0; i < 16; i++)
                if (write_select[i])
                    registers[i] <= write_data;
        end
    end

    // Read logic: for each bit position b, collect that bit from all 16 registers
    // into a 16-bit bus, then use Mux16to1 to select the correct register's bit.
    // 32 Mux16to1 instances per read port reconstruct the full 32-bit output.
    genvar b;
    generate
        for (b = 0; b < 32; b++) begin : read1_mux
            logic [15:0] bit_bus_1;
            // bit_bus_1[r] = registers[r][b] for r=0..15
            assign bit_bus_1 = {
                registers[15][b], registers[14][b], registers[13][b], registers[12][b],
                registers[11][b], registers[10][b], registers[9][b],  registers[8][b],
                registers[7][b],  registers[6][b],  registers[5][b],  registers[4][b],
                registers[3][b],  registers[2][b],  registers[1][b],  registers[0][b]
            };
            Mux16to1 mux1 (.in(bit_bus_1), .sel(read_address_1), .out(read_data_1[b]));
        end

        for (b = 0; b < 32; b++) begin : read2_mux
            logic [15:0] bit_bus_2;
            assign bit_bus_2 = {
                registers[15][b], registers[14][b], registers[13][b], registers[12][b],
                registers[11][b], registers[10][b], registers[9][b],  registers[8][b],
                registers[7][b],  registers[6][b],  registers[5][b],  registers[4][b],
                registers[3][b],  registers[2][b],  registers[1][b],  registers[0][b]
            };
            Mux16to1 mux2 (.in(bit_bus_2), .sel(read_address_2), .out(read_data_2[b]));
        end
    endgenerate

endmodule
