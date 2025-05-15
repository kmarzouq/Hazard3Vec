module vsub32_vv #( 
    parameter MAX_VECWIDTH=16, //Maximum LMUL-supported vector width, up to VLEN
    parameter XLEN = 32 //variable length XLEN, initially set to 32
)(
  input [XLEN-1:0] vtype, //XLEN = 32
  input [1:0] vxrm,
  input [XLEN-1:0] vl,
  input [XLEN-1:0] vlenb, // VLEN/8
  input [MAX_VECWIDTH-1:0]vm, //vector mask
  input vxsat,
  input [MAX_VECWIDTH*XLEN-1:0] S_old, //Previous S value
  input [MAX_VECWIDTH*XLEN-1:0] A,
  input [MAX_VECWIDTH*XLEN-1:0] B,
  output [MAX_VECWIDTH*XLEN-1:0] S,
  output [MAX_VECWIDTH-1:0] Ovflw
);

// Decode SEW in bits
wire [2:0] vsew = vtype[5:3];
wire [2:0] vlmul = vtype[2:0];

wire [31:0] sew = 1 << ({1'b0, vsew} + 3);
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

wire vma = vtype[7];
wire vta = vtype[6];

reg [MAX_VECWIDTH*XLEN-1:0] temp;
reg [MAX_VECWIDTH-1:0] Ovflw_reg;

//add a case statement for each version of sew
integer j;

always@(*) begin
    Ovflw_reg = 0;
    temp = 0;

    for(j=0; j<vecwidth; j=j+1) begin
        case(sew)
            8: begin //16 elements per vector (128)
                temp[XLEN/4*j +: XLEN/4] = A[XLEN/4*j +: XLEN/4] - B[XLEN/4*j +: XLEN/4];
                Ovflw_reg[j] = (A[XLEN/4*j + (XLEN/4)-1] != B[XLEN/4*j + (XLEN/4)-1]) && (A[XLEN/4*j + (XLEN/4)-1] != temp[XLEN/4*j + (XLEN/4)-1]);

            end
            16: begin //8 elements per vector
                temp[XLEN/2*j +: XLEN/2] = A[XLEN/2*j +: XLEN/2] - B[XLEN/2*j +: XLEN/2];
                Ovflw_reg[j] = (A[XLEN/2*j + (XLEN/2)-1] != B[XLEN/2*j + (XLEN/2)-1]) && (A[XLEN/2*j + (XLEN/2)-1] != temp[XLEN/2*j + (XLEN/2)-1]);
            end
            32: begin //4 elements per vector
                temp[XLEN*j +: XLEN] = A[XLEN*j +: XLEN] - B[XLEN*j +: XLEN];
                Ovflw_reg[j] = (A[XLEN*j + (XLEN)-1] != B[XLEN*j + (XLEN)-1]) && (A[XLEN*j + (XLEN)-1] != temp[XLEN*j + (XLEN)-1]);
            end
            64: begin //2 elements per vector
                temp[XLEN*2*j +: XLEN*2] = A[XLEN*2*j +: XLEN*2] - B[XLEN*2*j +: XLEN*2];
                Ovflw_reg[j] = (A[XLEN*2*j + (XLEN*2)-1] != B[XLEN*2*j + (XLEN*2)-1]) && (A[XLEN*2*j + (XLEN*2)-1] != temp[XLEN*2*j + (XLEN*2)-1]);
            end
        endcase
    end
end

assign Ovflw = Ovflw_reg;

reg [MAX_VECWIDTH*XLEN-1:0] rounded;
reg [MAX_VECWIDTH*XLEN-1:0] S_comb;
reg vxsat_int;

integer i;

// Rounding and saturation logic
always @(*) begin
    S_comb = {MAX_VECWIDTH*XLEN{1'b0}};
    rounded = {MAX_VECWIDTH*XLEN{1'b0}};

    for (i = 0; i < MAX_VECWIDTH; i = i + 1) begin
        if (i < vl) begin
            if(vxsat) begin
            // Rounding Mode Implementation
                case (vxrm)
                    2'b00: rounded[XLEN*i +: XLEN] = temp[XLEN*i +: XLEN] + ((temp[XLEN*i +: XLEN] >> 1) & 1); // rnu
                    2'b01: rounded[XLEN*i +: XLEN] = temp[XLEN*i +: XLEN] + (((temp[XLEN*i +: XLEN] >> 1) & 1) & (temp[XLEN*i] != 0)); // rne
                    2'b10: rounded[XLEN*i +: XLEN] = temp[XLEN*i +: XLEN]; // rdn
                    2'b11: rounded[XLEN*i +: XLEN] = temp[XLEN*i +: XLEN] | ((temp[XLEN*i] != 0) & ~((temp[XLEN*i +: XLEN] >> 1) & 1)); // rod
                    default: rounded[XLEN*i +: XLEN] = temp[XLEN*i +: XLEN];
                endcase
            end else begin
                rounded[XLEN*i +: XLEN] = temp[XLEN*i +: XLEN];
            end
            
            // Overflow, Mask, and Saturation Handling
            if (vm[i]) begin
                if (Ovflw[i]) begin
                    S_comb[XLEN*i +: XLEN] = temp[XLEN*i + XLEN - 1] ? {{1'b1}, {(XLEN-1){1'b0}}} : {{1'b0}, {(XLEN-1){1'b1}}};
                end else begin
                    S_comb[XLEN*i +: XLEN] = rounded[XLEN*i +: XLEN];
                end
            end 
            else if (!vma) begin
                S_comb[XLEN*i +: XLEN] = S_old[XLEN*i +: XLEN]; //use previous retained value
            end else begin
                S_comb[XLEN*i +: XLEN] = {XLEN{1'b1}}; // mask agnostic
            end
        end else if (vta) begin
            S_comb[XLEN*i +: XLEN] = {XLEN{1'b1}}; // tail agnostic
        end
    end
end

assign S = S_comb;

endmodule
