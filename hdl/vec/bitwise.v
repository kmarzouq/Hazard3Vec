// verilator lint_off multitop

module vand #(parameter VSIZE = 32)(
    input  [31:0][VSIZE-1:0] Va,
    input  [31:0][VSIZE-1:0] Vb,
    output [31:0][VSIZE-1:0] Vout 
);

    genvar i;
    generate
      for (i = 0; i < VSIZE; i = i + 1)
			assign Vout[i] = Va[i] & Vb[i];
     endgenerate
endmodule

module vor #(parameter VSIZE = 32)(
    input [31:0][VSIZE-1:0] Va,
    input [31:0][VSIZE-1:0] Vb,
    output [31:0][VSIZE-1:0] Vout
);

    genvar i;
    generate
        for (i = 0; i < VSIZE; i = i + 1)
            assign Vout[i] = Va[i] | Vb[i];
    endgenerate
endmodule


module vxor #(parameter VSIZE = 32)(
    input [31:0][VSIZE-1:0] Va,
    input [31:0][VSIZE-1:0] Vb,
    output [31:0][VSIZE-1:0] Vout
);

    genvar i;
    generate
        for (i = 0; i < VSIZE; i = i + 1)
            assign Vout[i] = Va[i] ^ Vb[i];
    endgenerate
endmodule