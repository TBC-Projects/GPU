module decoder (
    input logic [3:0] in,
    output logic [15:0] out
);

    assign out[0]  = (!in[3] & !in[2] & !in[1] & !in[0]);
    assign out[1]  = (!in[3] & !in[2] & !in[1] &  in[0]);
    assign out[2]  = (!in[3] & !in[2] &  in[1] & !in[0]);
    assign out[3]  = (!in[3] & !in[2] &  in[1] &  in[0]);

    assign out[4]  = (!in[3] &  in[2] & !in[1] & !in[0]);
    assign out[5]  = (!in[3] &  in[2] & !in[1] &  in[0]);
    assign out[6]  = (!in[3] &  in[2] &  in[1] & !in[0]);
    assign out[7]  = (!in[3] &  in[2] &  in[1] &  in[0]);

    assign out[8]  = ( in[3] & !in[2] & !in[1] & !in[0]);
    assign out[9]  = ( in[3] & !in[2] & !in[1] &  in[0]);
    assign out[10] = ( in[3] & !in[2] &  in[1] & !in[0]);
    assign out[11] = ( in[3] & !in[2] &  in[1] &  in[0]);

    assign out[12] = ( in[3] &  in[2] & !in[1] & !in[0]);
    assign out[13] = ( in[3] &  in[2] & !in[1] &  in[0]);
    assign out[14] = ( in[3] &  in[2] &  in[1] & !in[0]);
    assign out[15] = ( in[3] &  in[2] &  in[1] &  in[0]);


endmodule
