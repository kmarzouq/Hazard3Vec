module vmul32hu_vx #( 
    parameter MAX_VECWIDTH=16, //Maximum LMUL-supported vector width, up to VLEN
    parameter XLEN = 32 //variable length XLEN, initially set to 32
)(
  input [XLEN-1:0] vtype, //XLEN = 32
  input [1:0] vxrm,
  input [XLEN-1:0] vl,
  input [XLEN-1:0] vlenb, // VLEN/8
  input vm_bit,
  input [MAX_VECWIDTH-1:0] v0_mask,
  input vxsat,
  input [MAX_VECWIDTH*XLEN-1:0] S_old, //Previous S value
  input [MAX_VECWIDTH*XLEN-1:0] A,
  input [MAX_VECWIDTH*XLEN-1:0] B,
  output reg [MAX_VECWIDTH*XLEN-1:0] S
);

reg [MAX_VECWIDTH-1:0] vm;
wire [MAX_VECWIDTH-1:0] mask_out;

mask #(.VLEN(MAX_VECWIDTH)) mask_inst (
    .vm(vm_bit),
    .v0_mask(v0_mask),
    .mask_out(mask_out)
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

//when sew = 8
//reg [7:0] A8 [MAX_VECWIDTH-1:0];
reg [7:0] B8 [MAX_VECWIDTH-1:0];
reg [7:0] S8 [MAX_VECWIDTH-1:0];
reg [7:0] S8_old [MAX_VECWIDTH-1:0];
reg [7:0] temp8 [MAX_VECWIDTH-1:0];
reg [7:0] rounded8 [MAX_VECWIDTH-1:0];

//when sew = 16
//reg [15:0] A16    [MAX_VECWIDTH-1:0];
reg [15:0] B16    [MAX_VECWIDTH-1:0];
reg [15:0] S16    [MAX_VECWIDTH-1:0];
reg [15:0] S16_old[MAX_VECWIDTH-1:0];
reg [15:0] temp16 [MAX_VECWIDTH-1:0];
reg [15:0] rounded16 [MAX_VECWIDTH-1:0];

//when sew = 32
//reg [31:0] A32    [MAX_VECWIDTH-1:0];
reg [31:0] B32    [MAX_VECWIDTH-1:0];
reg [31:0] S32    [MAX_VECWIDTH-1:0];
reg [31:0] S32_old[MAX_VECWIDTH-1:0];
reg [31:0] temp32 [MAX_VECWIDTH-1:0];
reg [31:0] rounded32 [MAX_VECWIDTH-1:0];

//when sew = 64
//reg [63:0] A64    [MAX_VECWIDTH-1:0];
reg [63:0] B64    [MAX_VECWIDTH-1:0];
reg [63:0] S64    [MAX_VECWIDTH-1:0];
reg [63:0] S64_old[MAX_VECWIDTH-1:0];
reg [63:0] temp64 [MAX_VECWIDTH-1:0];
reg [63:0] rounded64 [MAX_VECWIDTH-1:0];

//multiplication registers
reg [15:0] P8m_long    [MAX_VECWIDTH-1:0];
reg [31:0] P16m_long    [MAX_VECWIDTH-1:0];
reg [63:0] P32m_long    [MAX_VECWIDTH-1:0];
reg [127:0] P64m_long    [MAX_VECWIDTH-1:0];

reg [7:0] Aext8;
reg [15:0] Aext16;
reg [31:0] Aext32;
reg [63:0] Aext64;

//add a case statement for each version of sew
integer j;

always@(*) begin
    S = 0;
    for (j = 0; j < vecwidth; j = j + 1) begin
        temp8[j] = 0;
        rounded8[j] = 0;
        temp16[j] = 0;
        rounded16[j] = 0;
        temp32[j] = 0;
        rounded32[j] = 0;
        temp64[j] = 0;
        rounded64[j] = 0;
    end

    case(sew)
        8: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                //A8[j] = A[8*j +: 8];
                Aext8 = A[7:0];
                B8[j] = B[8*j +: 8];

                S8_old[j] = S_old[8*j +: 8];
                P8m_long[j] = Aext8 * B8[j];         // 16-bit result
                temp8[j] = P8m_long[j][15:8];           // upper 8 bits


                if (j < vl) begin
                    if (vxsat) begin //for fixed point 
                        case (vxrm)
                            2'b00: rounded8[j] = temp8[j] + ((temp8[j] >> 1) & 1); // rnu
                            2'b01: rounded8[j] = temp8[j] + (((temp8[j] >> 1) & 1) & (temp8[j][0] != 0)); // rne
                            2'b10: rounded8[j] = temp8[j]; // rdn
                            2'b11: rounded8[j] = temp8[j] | ((temp8[j][0] != 0) & ~((temp8[j] >> 1) & 1)); // rod
                            default: rounded8[j] = temp8[j];
                        endcase
                    end else begin
                        rounded8[j] = temp8[j];
                    end

                    if (mask_out[j]) begin
                        S8[j] = rounded8[j];
                    end else if (!vma) S8[j] = S8_old[j];
                    else S8[j] = 8'hFF;
                end else if (vta) S8[j] = 8'hFF;
            end

            for (j = 0; j < vecwidth; j = j + 1)
                S[8*j +: 8] = S8[j];
        end

        16: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                //A16[j] = A[16*j +: 16];
                Aext16 = A[15:0];
                B16[j] = B[16*j +: 16];

                S16_old[j] = S_old[16*j +: 16];
                P16m_long[j] = Aext16 * B16[j];     // 32-bit result
                temp16[j] = P16m_long[j][31:16];       // upper 16 bits


                if (j < vl) begin
                    if (vxsat) begin //for fixed point
                        case (vxrm)
                            2'b00: rounded16[j] = temp16[j] + ((temp16[j] >> 1) & 1); // rnu
                            2'b01: rounded16[j] = temp16[j] + (((temp16[j] >> 1) & 1) & (temp16[j][0] != 0)); // rne
                            2'b10: rounded16[j] = temp16[j]; // rdn
                            2'b11: rounded16[j] = temp16[j] | ((temp16[j][0] != 0) & ~((temp16[j] >> 1) & 1)); // rod
                            default: rounded16[j] = temp16[j];
                        endcase
                    end else begin
                        rounded16[j] = temp16[j];
                    end

                    if (mask_out[j]) begin
                        S16[j] = rounded16[j];
                    end else if (!vma) S16[j] = S16_old[j];
                    else S16[j] = 16'hFFFF;
                end else if (vta) S16[j] = 16'hFFFF;
            end

            for (j = 0; j < vecwidth; j = j + 1)
                S[16*j +: 16] = S16[j];
        end

        32: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                //A32[j] = A[32*j +: 32];
                Aext32 = A[31:0];
                B32[j] = B[32*j +: 32];

                S32_old[j] = S_old[32*j +: 32];
                P32m_long[j] = Aext32 * B32[j];
                temp32[j] = P32m_long[j][63:32];


                if (j < vl) begin
                    if (vxsat) begin //for fixed point
                        case (vxrm)
                            2'b00: rounded32[j] = temp32[j] + ((temp32[j] >> 1) & 1); // rnu
                            2'b01: rounded32[j] = temp32[j] + (((temp32[j] >> 1) & 1) & (temp32[j][0] != 0)); // rne
                            2'b10: rounded32[j] = temp32[j]; // rdn
                            2'b11: rounded32[j] = temp32[j] | ((temp32[j][0] != 0) & ~((temp32[j] >> 1) & 1)); // rod
                            default: rounded32[j] = temp32[j];
                        endcase
                    end else begin
                        rounded32[j] = temp32[j];
                    end

                    if (mask_out[j]) begin
                        S32[j] = rounded32[j];
                    end else if (!vma) S32[j] = S32_old[j];
                    else S32[j] = 32'hFFFFFFFF;
                end else if (vta) S32[j] = 32'hFFFFFFFF;
            end

            for (j = 0; j < vecwidth; j = j + 1)
                S[32*j +: 32] = S32[j];
        end

        64: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                //A64[j] = A[64*j +: 64];
                Aext64 = A[63:0];
                B64[j] = B[64*j +: 64];

                S64_old[j] = S_old[64*j +: 64];
                P64m_long[j] = Aext64 * B64[j];     // 128-bit result
                temp64[j] = P64m_long[j][127:64];      // upper 64 bits


                if (j < vl) begin
                    if (vxsat) begin //for fixed point
                        case (vxrm)
                            2'b00: rounded64[j] = temp64[j] + ((temp64[j] >> 1) & 1); // rnu
                            2'b01: rounded64[j] = temp64[j] + (((temp64[j] >> 1) & 1) & (temp64[j][0] != 0)); // rne
                            2'b10: rounded64[j] = temp64[j]; // rdn
                            2'b11: rounded64[j] = temp64[j] | ((temp64[j][0] != 0) & ~((temp64[j] >> 1) & 1)); // rod
                            default: rounded64[j] = temp64[j];
                        endcase
                    end else begin
                        rounded64[j] = temp64[j];
                    end

                    if (mask_out[j]) begin
                        S64[j] = rounded64[j];
                    end else if (!vma) S64[j] = S64_old[j];
                    else S64[j] = 64'hFFFFFFFFFFFFFFFF;
                end else if (vta) S64[j] = 64'hFFFFFFFFFFFFFFFF;
            end

            for (j = 0; j < vecwidth; j = j + 1)
                S[64*j +: 64] = S64[j];
        end
    endcase
end

endmodule
