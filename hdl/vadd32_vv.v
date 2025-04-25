//`include "adders_common.v"


module vadd32_vv #( 
    parameter MAX_VECWIDTH=4, //Maximum LMUL-supported vector width, up to VLEN
    parameter XLEN = 32 //variable length XLEN, initially set to 32
)(
  input [XLEN-1:0] vtype, //XLEN = 32
  input [1:0] vxrm,
  input [XLEN-1:0] vl,
  input [XLEN-1:0] vlenb, // VLEN/8
  input [MAX_VECWIDTH-1:0]vmask,
  input vxsat,
  input [MAX_VECWIDTH*XLEN-1:0] A,
  input [MAX_VECWIDTH*XLEN-1:0] B,
  output [MAX_VECWIDTH*XLEN-1:0] S,
  output [MAX_VECWIDTH-1:0] Cout,
  output [MAX_VECWIDTH-1:0] Ovflw,
  output vxsat_out
);

// Decode SEW in bits
wire [2:0] vsew = vtype[5:3];
wire [2:0] vlmul = vtype[2:0];

wire [MAX_VECWIDTH-1:0] Cin;
wire vma = vtype[7];
wire vta = vtype[6];
wire [MAX_VECWIDTH*XLEN-1:0] temp;

assign Cin = {MAX_VECWIDTH{1'b0}}; 

genvar j;
generate 
    for (j = 0; j < MAX_VECWIDTH; j = j + 1) begin : LOOP32
                adder32bit adder_inst (
                    .A(A[XLEN*j +: XLEN]), 
                    .Bin(B[XLEN*j +: XLEN]), 
                    .Cin(Cin[j]), 
                    .S(temp[XLEN*j +: XLEN]), 
                    .Cout(Cout[j]), 
                    .Ovflw(Ovflw[j])
                );
        end
endgenerate

reg [MAX_VECWIDTH*XLEN-1:0] rounded;
reg [MAX_VECWIDTH*XLEN-1:0] S_comb;
reg vxsat_int;

integer i;

// Rounding and saturation logic
always @(*) begin
    S_comb = {MAX_VECWIDTH*XLEN{1'b0}};
    rounded = {MAX_VECWIDTH*XLEN{1'b0}};
    vxsat_int = 1'b0;

    for (i = 0; i < MAX_VECWIDTH; i = i + 1) begin
        if (i < vl) begin
            // Rounding Mode Implementation
            case (vxrm)
                2'b00: rounded[XLEN*i +: XLEN] = temp[XLEN*i +: XLEN] + ((temp[XLEN*i +: XLEN] >> 1) & 1); // rnu
                2'b01: rounded[XLEN*i +: XLEN] = temp[XLEN*i +: XLEN] + (((temp[XLEN*i +: XLEN] >> 1) & 1) & (temp[XLEN*i] != 0)); // rne
                2'b10: rounded[XLEN*i +: XLEN] = temp[XLEN*i +: XLEN]; // rdn
                2'b11: rounded[XLEN*i +: XLEN] = temp[XLEN*i +: XLEN] | ((temp[XLEN*i] != 0) & ~((temp[XLEN*i +: XLEN] >> 1) & 1)); // rod
                default: rounded[XLEN*i +: XLEN] = temp[XLEN*i +: XLEN];
            endcase
            
            // Overflow and Saturation Handling
            if (vmask[i]) begin
                    if (Ovflw[i]) begin
                        S_comb[XLEN*i +: XLEN] = temp[XLEN*i + XLEN - 1] ? {{1'b1}, {(XLEN-1){1'b0}}} : {{1'b0}, {(XLEN-1){1'b1}}};
                        vxsat_int = 1'b1;
                    end else begin
                        S_comb[XLEN*i +: XLEN] = rounded[XLEN*i +: XLEN];
                    end
                end else if (!vma) begin
                    S_comb[XLEN*i +: XLEN] = rounded[XLEN*i +: XLEN];
                end else begin
                    S_comb[XLEN*i +: XLEN] = {XLEN{1'b1}}; // mask agnostic
                end
            end else if (vta) begin
                S_comb[XLEN*i +: XLEN] = {XLEN{1'b1}}; // tail agnostic
            end
        end
end

assign S = S_comb;
assign vxsat_out = vxsat | vxsat_int;

endmodule