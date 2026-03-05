module regfile(
    input  logic        clk,
    input  logic        rst_n,        // active-low async reset

    // write port
    input  logic        we,
    input  logic [3:0]  waddr,        // 16 regs -> 4-bit address
    input  logic [31:0] wdata,

    // read port 1
    input  logic [3:0]  raddr1,
    output logic [31:0] rdata1,

    // read port 2
    input  logic [3:0]  raddr2,
    output logic [31:0] rdata2
);

    logic [31:0] regs [15:0];   // 16 registers, 32-bit wide

    // reset + write (write-first behavior is handled by read logic below if you want)
    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 16; i++) begin
                regs[i] <= 32'b0;
            end
        end else begin
            if (we) begin
                regs[waddr] <= wdata;
            end
        end
    end

    // async reads
    always_comb begin
        rdata1 = regs[raddr1];
        rdata2 = regs[raddr2];
    end

endmodule
