//`include "adders_common.v"


module vadd64_vv #( 
    parameter MAX_VECWIDTH=16, //Maximum LMUL-supported vector width, up to VLEN
    parameter XLEN = 32 //variable length XLEN, initially set to 32
)(
  input [XLEN-1:0] vtype, //XLEN = 32
  input [1:0] vxrm,
  input [XLEN-1:0] vl,
  input [XLEN-1:0] vlenb, // VLEN/8
  input [2*MAX_VECWIDTH*XLEN-1:0] A,
  input [2*MAX_VECWIDTH*XLEN-1:0] B,
  output [2*MAX_VECWIDTH*XLEN-1:0] S,
  output [MAX_VECWIDTH-1:0] Cout,
  output [MAX_VECWIDTH-1:0] Ovflw,
  output reg vxsat_comb
);

//include mask
reg [MAX_VECWIDTH-1:0] vmask = vtype[25];

// Decode SEW in bits
wire [2:0] vsew = vtype[5:3];
wire [2:0] vlmul = vtype[2:0];

wire [31:0] sew = 1 << ({1'b0, vsew} + 3); //64
wire [31:0] vlen = vlenb * 8;

wire [31:0] raw_vecwidth = (vlmul == 3'b000) ? vlen / sew :
                           (vlmul == 3'b001) ? (2 * vlen) / sew :
                           (vlmul == 3'b010) ? (4 * vlen) / sew :
                           (vlmul == 3'b011) ? (8 * vlen) / sew :
                           (vlmul == 3'b101) ? vlen / (8 * sew) :
                           (vlmul == 3'b110) ? vlen / (4 * sew) :
                           (vlmul == 3'b111) ? vlen / (2 * sew) :
                           vlen / sew;

wire [31:0] vecwidth = (raw_vecwidth > MAX_VECWIDTH) ? MAX_VECWIDTH : raw_vecwidth;

wire [MAX_VECWIDTH-1:0] Cin;
wire vma = vtype[7];
wire vta = vtype[6];
wire [MAX_VECWIDTH*2*XLEN-1:0] temp;

assign Cin = {MAX_VECWIDTH{1'b0}}; 

genvar j;
generate 
    for (j = 0; j < MAX_VECWIDTH; j = j + 1) begin : LOOP64
                adder64bit adder_inst (
                    .A(A[2*XLEN*j +: 2*XLEN]), 
                    .Bin(B[2*XLEN*j +: 2*XLEN]), 
                    .Cin(Cin[j]), 
                    .S(temp[2*XLEN*j +: 2*XLEN]), 
                    .Cout(Cout[j]), 
                    .Ovflw(Ovflw[j])
                );
        end
endgenerate

reg [MAX_VECWIDTH*2*XLEN-1:0] rounded;
reg [MAX_VECWIDTH*2*XLEN-1:0] S_comb;
//reg vxsat_comb;

integer i;

// Rounding and saturation logic
always @(*) begin
    vxsat_comb = 1'b0;
    S_comb = {MAX_VECWIDTH*2*XLEN{1'b0}};
    rounded = {MAX_VECWIDTH*2*XLEN{1'b0}};

    for (i = 0; i < MAX_VECWIDTH; i = i + 1) begin
      if(i < vecwidth) begin //masks out extra adders
        if (i < vl) begin
            // Rounding Mode Implementation
            case (vxrm)
                2'b00: rounded[2*XLEN*i +: 2*XLEN] = temp[2*XLEN*i +: 2*XLEN] + ((temp[2*XLEN*i +: 2*XLEN] >> 1) & 1); // rnu
                2'b01: rounded[2*XLEN*i +: 2*XLEN] = temp[2*XLEN*i +: 2*XLEN] + (((temp[2*XLEN*i +: 2*XLEN] >> 1) & 1) & (temp[2*XLEN*i] != 0)); // rne
                2'b10: rounded[2*XLEN*i +: 2*XLEN] = temp[2*XLEN*i +: 2*XLEN]; // rdn
                2'b11: rounded[2*XLEN*i +: 2*XLEN] = temp[2*XLEN*i +: 2*XLEN] | ((temp[2*XLEN*i] != 0) & ~((temp[2*XLEN*i +: 2*XLEN] >> 1) & 1)); // rod
                default: rounded[2*XLEN*i +: 2*XLEN] = temp[2*XLEN*i +: 2*XLEN];
            endcase
            
            // Overflow and Saturation Handling
            if (vmask[i]) begin
                    if (Ovflw[i]) begin
                        vxsat_comb = 1'b1;
                        S_comb[2*XLEN*i +: 2*XLEN] = temp[2*XLEN*i + 2*XLEN - 1] ? {{1'b1}, {(2*XLEN-1){1'b0}}} : {{1'b0}, {(2*XLEN-1){1'b1}}};
                    end else begin
                        S_comb[2*XLEN*i +: 2*XLEN] = rounded[2*XLEN*i +: 2*XLEN];
                    end
                end else if (!vma) begin
                    S_comb[2*XLEN*i +: 2*XLEN] = rounded[2*XLEN*i +: 2*XLEN];
                end else begin
                    S_comb[2*XLEN*i +: 2*XLEN] = {2*XLEN{1'b1}}; // mask agnostic
                end
            end else if (vta) begin
                S_comb[2*XLEN*i +: 2*XLEN] = {2*XLEN{1'b1}}; // tail agnostic
            end
        end
    end
end

assign S = S_comb;
//assign vxsat = vxsat_comb;

endmodule