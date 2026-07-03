// Compute widening unsigned vector-scalar subtraction between a vector of length XLEN bits with a SEW bits size (single element width) and a scalar of SEW-width length, resulting in a 2*SEW bit output
// XLEN is determined in the testbench & SEW can be 8, 16, 32, and 64 bits based on what's defined in the Zve32x specification for the RISC-V Vector Extension
// funct3: 110 (OPMVX) for Vector Aritmetic Instruction Encoding
// funct6: 110010 (vwsub) for Vector Instruction Listing

module vwsubu32_vx #( 
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

// Vecwidth determined by size of LMUL
// LMUL = 1, vector operation kept to 1 vector register of XLEN sized bits
// LMUL > 1, vector operation extended to >1 vector registers 
// LMUL < 1, vector operation kept to 1 vector register of XLEN sized bits with extended 0's or 1's
wire [31:0] vecwidth = (raw_vecwidth > MAX_VECWIDTH) ? MAX_VECWIDTH : raw_vecwidth;

wire vma = vtype[7];
wire vta = vtype[6];

//when sew = 8
reg [7:0] B8 [MAX_VECWIDTH-1:0];
reg [15:0] S8 [MAX_VECWIDTH-1:0];
reg [15:0] S8_old [MAX_VECWIDTH-1:0];
reg [15:0] temp8 [MAX_VECWIDTH-1:0];
reg [15:0] rounded8 [MAX_VECWIDTH-1:0];

//when sew = 16
reg [15:0] B16    [MAX_VECWIDTH-1:0];
reg [31:0] S16    [MAX_VECWIDTH-1:0];
reg [31:0] S16_old[MAX_VECWIDTH-1:0];
reg [31:0] temp16 [MAX_VECWIDTH-1:0];
reg [31:0] rounded16 [MAX_VECWIDTH-1:0];

//when sew = 32
reg [31:0] B32    [MAX_VECWIDTH-1:0];
reg [63:0] S32    [MAX_VECWIDTH-1:0];
reg [63:0] S32_old[MAX_VECWIDTH-1:0];
reg [63:0] temp32 [MAX_VECWIDTH-1:0];
reg [63:0] rounded32 [MAX_VECWIDTH-1:0];

//when sew = 64
reg [63:0] B64    [MAX_VECWIDTH-1:0];
reg [127:0] S64    [MAX_VECWIDTH-1:0];
reg [127:0] S64_old[MAX_VECWIDTH-1:0];
reg [127:0] temp64 [MAX_VECWIDTH-1:0];
reg [127:0] rounded64 [MAX_VECWIDTH-1:0];

reg Ovflw8 [MAX_VECWIDTH-1:0];
reg Ovflw16 [MAX_VECWIDTH-1:0];
reg Ovflw32 [MAX_VECWIDTH-1:0];
reg Ovflw64 [MAX_VECWIDTH-1:0];

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
        Ovflw8[j] = 0;
        Ovflw16[j] = 0;
        Ovflw32[j] = 0;
        Ovflw64[j] = 0;
    end

    case(sew)
        8: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                Aext8 = A[7:0]; // Sign-extend 8-bit scalar
                B8[j] = B[8*j +: 8]; // Extract 8-bit element from vector B
                S8_old[j] = S_old[16*j +: 16]; // Extract 16-bit old result
                temp8[j] = B8[j] - Aext8; // Widening subtraction (16-bit result)
                Ovflw8[j] = (temp8[j] < Aext8) || (temp8[j] < B8[j]); // Unsigned overflow detection

                if (j < vl) begin
                    if (vxsat) begin // For fixed-point (fractional) math
                        case (vxrm)
                            2'b00: rounded8[j] = temp8[j] + ((temp8[j] >> 1) & 1); // rnu (round nearest up)
                            2'b01: rounded8[j] = temp8[j] + (((temp8[j] >> 1) & 1) & (temp8[j][0] != 0)); // rne (round nearest even)
                            2'b10: rounded8[j] = temp8[j]; // rdn (round down)
                            2'b11: rounded8[j] = temp8[j] | ((temp8[j][0] != 0) & ~((temp8[j] >> 1) & 1)); // rod (round to odd)
                            default: rounded8[j] = temp8[j];
                        endcase
                    end else begin
                        rounded8[j] = temp8[j];
                    end

                    if (mask_out[j]) begin // Determines which SEW elements to write
                        if (Ovflw8[j] && vxsat) S8[j] = 16'hFFFF; // Saturate on overflow
                        else S8[j] = rounded8[j];
                    end else if (!vma) S8[j] = S8_old[j]; // If mask is inactive and agnostic, retain previous value
                    else S8[j] = 16'hFFFF; // Mark as agnostic if allowed
                end else if (vta) S8[j] = 16'hFFFF; // Tail agnostic values overwritten with all 1s
            end

            for (j = 0; j < vecwidth/2; j = j + 1)
                S[16*j +: 16] = S8[j]; // Pack result vector with widened 16-bit values
        end

        16: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                Aext16 = A[15:0]; // Sign-extend 16-bit scalar
                B16[j] = B[16*j +: 16]; // Extract 16-bit element from vector B
                S16_old[j] = S_old[32*j +: 32]; // Extract 32-bit old result
                temp16[j] = B16[j] - Aext16; // Widening subtraction (32-bit result)
                Ovflw16[j] = (temp16[j] < Aext16) || (temp16[j] < B16[j]); // Unsigned overflow detection

                if (j < vl) begin
                    if (vxsat) begin // For fixed-point (fractional) math
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

                    if (mask_out[j]) begin // Determines which SEW elements to write
                        if (Ovflw16[j] && vxsat) S16[j] = 32'hFFFFFFFF; // Saturate on overflow
                        else S16[j] = rounded16[j];
                    end else if (!vma) S16[j] = S16_old[j]; // Retain old value if mask is off and vma disabled
                    else S16[j] = 32'hFFFFFFFF; // Mark as agnostic if allowed
                end else if (vta) S16[j] = 32'hFFFFFFFF; // Tail agnostic
            end

            for (j = 0; j < vecwidth/2; j = j + 1)
                S[32*j +: 32] = S16[j]; // Pack 32-bit result vector
        end

        32: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                Aext32 = A[31:0]; // Sign-extend 32-bit scalar
                B32[j] = B[32*j +: 32]; // Extract 32-bit vector element
                S32_old[j] = S_old[64*j +: 64]; // Extract 64-bit old result
                temp32[j] = B32[j] - Aext32; // Widening subtraction (64-bit result)
                Ovflw32[j] = (temp32[j] < Aext32) || (temp32[j] < B32[j]); // Unsigned overflow detection

                if (j < vl) begin
                    if (vxsat) begin // For fixed-point math
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

                    if (mask_out[j]) begin // Determines which SEW elements to write
                        if (Ovflw32[j] && vxsat) S32[j] = 64'hFFFFFFFFFFFFFFFF; // Saturate on overflow
                        else S32[j] = rounded32[j];
                    end else if (!vma) S32[j] = S32_old[j]; // Retain previous result
                    else S32[j] = 64'hFFFFFFFFFFFFFFFF; // Agnostic value
                end else if (vta) S32[j] = 64'hFFFFFFFFFFFFFFFF; // Tail agnostic
            end

            for (j = 0; j < vecwidth/2; j = j + 1)
                S[64*j +: 64] = S32[j]; // Pack 64-bit result vector
        end

        64: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                Aext64 = A[63:0]; // Sign-extend 64-bit scalar
                B64[j] = B[64*j +: 64]; // Extract 64-bit vector element
                S64_old[j] = S_old[128*j +: 128]; // Extract 128-bit old result
                temp64[j] = B64[j] - Aext64; // Widening subtraction (128-bit result)
                Ovflw64[j] = (temp64[j] < Aext64) || (temp64[j] < B64[j]); // Unsigned overflow detection

                if (j < vl) begin
                    if (vxsat) begin // For fixed-point math
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

                    if (mask_out[j]) begin // Determines which SEW elements to write
                        if (Ovflw64[j] && vxsat) S64[j] = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // Saturate on overflow
                        else S64[j] = rounded64[j];
                    end else if (!vma) S64[j] = S64_old[j]; // Preserve previous value
                    else S64[j] = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // Agnostic
                end else if (vta) S64[j] = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // Tail agnostic
            end

            for (j = 0; j < vecwidth/2; j = j + 1)
                S[128*j +: 128] = S64[j]; // Pack 128-bit result vector
        end
    endcase
end

endmodule
