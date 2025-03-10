// verilator lint_off multitop

module vand #(parameter VSIZE = 32)(
    input  [VSIZE-1:0][31:0] Va,
    input  [VSIZE-1:0][31:0] Vb,
    output [VSIZE-1:0][31:0] Vout
);
    genvar i;
    generate
        for (i = 0; i < VSIZE; i = i + 1)
            assign Vout[i] = Va[i] & Vb[i];
    endgenerate
endmodule

module vor #(parameter VSIZE = 32)(
    input  [VSIZE-1:0][31:0] Va,
    input  [VSIZE-1:0][31:0] Vb,
    output [VSIZE-1:0][31:0] Vout
);
    genvar i;
    generate
        for (i = 0; i < VSIZE; i = i + 1)
            assign Vout[i] = Va[i] | Vb[i];
    endgenerate
endmodule

module vxor #(parameter VSIZE = 32)(
    input  [VSIZE-1:0][31:0] Va,
    input  [VSIZE-1:0][31:0] Vb,
    output [VSIZE-1:0][31:0] Vout
);
    genvar i;
    generate
        for (i = 0; i < VSIZE; i = i + 1)
            assign Vout[i] = Va[i] ^ Vb[i];
    endgenerate
endmodule
