module example (in, out, rst);
  input logic [7:0] in;
  output logic [7:0] out;

  logic test3, test1, test2;
  
  and (test3, test1, test2);
  
  genvar i;
    for (i = 0; i < 8; i++) begin
      assign out[i] = in[i];
    end
  endgenerate
  
endmodule

module d_ff (q, d, clk, rst);
  input logic d;
  output logic q;

  always_ff (@posedge clk) begin
    if (rst != 0) begin
      q <= 0;
    end else begin
      q <= d;
    end 
  end
endmodule
