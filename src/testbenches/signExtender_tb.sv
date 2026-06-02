module signExtender_tb ();

    parameter N = 16; // Example input width, can be changed as needed
    logic [N-1:0] data_in;
    logic [31:0] data_out;

    logic clk;

    // define parameters
    parameter T = 20;

    // define simulated clock
    initial begin
        clk <= 0;
        forever  #(T/2)  clk <= ~clk;
    end // initial

    signExtender #(.N(16)) dut (.data_in(data_in), .data_out(data_out));

    initial begin

        // Test sign extension
        data_in = 16'hABCD; // Expect data_out = 32'hFFFFABCD
        #10;

        data_in = 16'h7BCD; // Expect data_out = 32'h00007BCD
        #10;

        $stop; // stop the simulation

    end // initial

endmodule // signExtender_tb