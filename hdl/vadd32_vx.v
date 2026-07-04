// Compute vector-scalar addition between a vector of length XLEN bits with a SEW bits size (single element width) and a scalar of SEW-width length
// XLEN is determined in the testbench & SEW can be 8, 16, 32, and 64 bits based on what's defined in the Zve32x specification for the RISC-V Vector Extension
// funct3: 100 (OPIVX) for Vector Aritmetic Instruction Encoding
// funct6: 000000 (vadd) for Vector Instruction Listing

module vadd32_vx #( 
    parameter MAX_VECWIDTH=16, //Maximum LMUL-supported vector width, up to VLEN
    parameter XLEN = 32 //variable length XLEN, initially set to 32
)(
  input [XLEN-1:0] vtype, //XLEN = 32
  input [1:0] vxrm,
  input [XLEN-1:0] vl,
  input [XLEN-1:0] vlenb, // VLEN/8
  input vm_bit,
  input [MAX_ELEMENTS-1:0] v0_mask,
  input vxsat,
  input [MAX_VECWIDTH*XLEN-1:0] S_old, //Previous S value
  input [MAX_VECWIDTH*XLEN-1:0] A, //scalar value
  input [MAX_VECWIDTH*XLEN-1:0] B, //vector
  output reg [MAX_VECWIDTH*XLEN-1:0] S
);

// === AI-GENERATED BEGIN: fix MAX_VECWIDTH element-count bug ===
// MAX_VECWIDTH as passed in from vector_core.v is really "VLEN/32" (sized
// for SEW=32 only). At SEW=8/16 there are up to 4x more real elements in the
// same 128-bit register, and every array/clamp/mask-width below that used
// MAX_VECWIDTH directly as an element count was silently only computing the
// first few lanes (e.g. only 4 of 16 at SEW=8) and leaving the rest at their
// reset value of 0. MAX_ELEMENTS recovers the true per-SEW-8 element count
// from the total bit width MAX_VECWIDTH*XLEN (always correct, since that
// product is what's actually wired to a fixed 128-bit bus), independent of
// how the two factors happen to be split.
localparam MAX_ELEMENTS = (MAX_VECWIDTH*XLEN)/8;
// === AI-GENERATED END ===

reg [MAX_ELEMENTS-1:0] vm;
wire [MAX_ELEMENTS-1:0] mask_out;

mask #(.VLEN(MAX_ELEMENTS)) mask_inst (
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
// LMUL = 1, vector addition kept to 1 vector register of XLEN sized bits
// LMUL > 1, vector addition extended to >1 vector registers 
// LMUL < 1, vector addition kept to 1 vector register of XLEN sized bits with extended 0's or 1's
wire [31:0] vecwidth = (raw_vecwidth > MAX_ELEMENTS) ? MAX_ELEMENTS : raw_vecwidth;

wire vma = vtype[7];
wire vta = vtype[6];

//when sew = 8
reg signed [7:0] A8 [MAX_ELEMENTS-1:0];
reg signed [7:0] B8 [MAX_ELEMENTS-1:0];
reg signed [7:0] S8 [MAX_ELEMENTS-1:0];
reg signed [7:0] S8_old [MAX_ELEMENTS-1:0];
reg signed [7:0] temp8 [MAX_ELEMENTS-1:0];
reg signed [7:0] rounded8 [MAX_ELEMENTS-1:0];

//when sew = 16
reg signed [15:0] A16    [MAX_ELEMENTS-1:0];
reg signed [15:0] B16    [MAX_ELEMENTS-1:0];
reg signed [15:0] S16    [MAX_ELEMENTS-1:0];
reg signed [15:0] S16_old[MAX_ELEMENTS-1:0];
reg signed [15:0] temp16 [MAX_ELEMENTS-1:0];
reg signed [15:0] rounded16 [MAX_ELEMENTS-1:0];

//when sew = 32
reg signed [31:0] A32    [MAX_ELEMENTS-1:0];
reg signed [31:0] B32    [MAX_ELEMENTS-1:0];
reg signed [31:0] S32    [MAX_ELEMENTS-1:0];
reg signed [31:0] S32_old[MAX_ELEMENTS-1:0];
reg signed [31:0] temp32 [MAX_ELEMENTS-1:0];
reg signed [31:0] rounded32 [MAX_ELEMENTS-1:0];

//when sew = 64
reg signed [63:0] A64    [MAX_ELEMENTS-1:0];
reg signed [63:0] B64    [MAX_ELEMENTS-1:0];
reg signed [63:0] S64    [MAX_ELEMENTS-1:0];
reg signed [63:0] S64_old[MAX_ELEMENTS-1:0];
reg signed [63:0] temp64 [MAX_ELEMENTS-1:0];
reg signed [63:0] rounded64 [MAX_ELEMENTS-1:0];

reg Ovflw8 [MAX_ELEMENTS-1:0];
reg Ovflw16 [MAX_ELEMENTS-1:0];
reg Ovflw32 [MAX_ELEMENTS-1:0];
reg Ovflw64 [MAX_ELEMENTS-1:0];

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
                Aext8 = A[7:0];
                B8[j] = B[8*j +: 8];
                S8_old[j] = S_old[8*j +: 8];
                temp8[j] = B8[j] + Aext8; //addition for each 8-bit element and scalar
                Ovflw8[j]  = (Aext8[7] == B8[j][7]) && (temp8[j][7] != Aext8[7]); //signed overflow detection

                if (j < vl) begin
                    if (vxsat) begin //for fixed point i.e. fractional math 
                        case (vxrm)
                            2'b00: rounded8[j] = temp8[j] + ((temp8[j] >> 1) & 1); // rnu (round nearest up)
                            2'b01: rounded8[j] = temp8[j] + (((temp8[j] >> 1) & 1) & (temp8[j][0] != 0)); // rne (round nearest even)
                            2'b10: rounded8[j] = temp8[j]; // rdn (round nearest down)
                            2'b11: rounded8[j] = temp8[j] | ((temp8[j][0] != 0) & ~((temp8[j] >> 1) & 1)); // rod (round to odd)
                            default: rounded8[j] = temp8[j];
                        endcase
                    end else begin
                        rounded8[j] = temp8[j];
                    end

                    if (mask_out[j]) begin // determines which SEW elements to mask out
                        if (Ovflw8[j]) S8[j] = temp8[j][7] ? 8'h80 : 8'h7F; //Replace if overflow occurs
                        else S8[j] = rounded8[j];
                    end else if (!vma) S8[j] = S8_old[j]; //if set is marked agnostic, destination vector can retain previous value or be overwritten by 1's
                    else S8[j] = 8'hFF;
                end else if (vta) S8[j] = 8'hFF; //additional tail elements that are tail agnostic are overwritten as 1's
            end

            for (j = 0; j < vecwidth; j = j + 1) //output consisting vecwidth*SEW sized register
                S[8*j +: 8] = S8[j];
        end

        16: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                Aext16 = A[15:0];
                B16[j] = B[16*j +: 16];
                S16_old[j] = S_old[16*j +: 16];
                temp16[j] = B16[j] + Aext16; //addition for each 16-bit element and scalar
                Ovflw16[j] = (Aext16[15] == B16[j][15]) && (temp16[j][15] != Aext16[15]); //signed overflow detection

                if (j < vl) begin
                    if (vxsat) begin //for fixed point i.e. fractional math
                        case (vxrm)
                            2'b00: rounded16[j] = temp16[j] + ((temp16[j] >> 1) & 1); // rnu (round nearest up)
                            2'b01: rounded16[j] = temp16[j] + (((temp16[j] >> 1) & 1) & (temp16[j][0] != 0)); // rne (round nearest even)
                            2'b10: rounded16[j] = temp16[j]; // rdn (round nearest down)
                            2'b11: rounded16[j] = temp16[j] | ((temp16[j][0] != 0) & ~((temp16[j] >> 1) & 1)); // rod (round to odd)
                            default: rounded16[j] = temp16[j];
                        endcase
                    end else begin
                        rounded16[j] = temp16[j];
                    end

                    if (mask_out[j]) begin // determines which SEW elements to mask out
                        if (Ovflw16[j]) S16[j] = temp16[j][15] ? 16'h8000 : 16'h7FFF; //Replace if overflow occurs
                        else S16[j] = rounded16[j];
                    end else if (!vma) S16[j] = S16_old[j]; //if set is marked agnostic, destination vector can retain previous value or be overwritten by 1's
                    else S16[j] = 16'hFFFF;
                end else if (vta) S16[j] = 16'hFFFF; //additional tail elements that are tail agnostic are overwritten as 1's
            end

            for (j = 0; j < vecwidth; j = j + 1) //output consisting vecwidth*SEW sized register
                S[16*j +: 16] = S16[j];
        end

        32: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                Aext32 = A[31:0];
                B32[j] = B[32*j +: 32];
                S32_old[j] = S_old[32*j +: 32];
                temp32[j] = B32[j] + Aext32; //addition for each 32-bit element and scalar
                Ovflw32[j] = (Aext32[31] == B32[j][31]) && (temp32[j][31] != Aext32[31]); //signed overflow detection

                if (j < vl) begin
                    if (vxsat) begin //for fixed point i.e. fractional math
                        case (vxrm)
                            2'b00: rounded32[j] = temp32[j] + ((temp32[j] >> 1) & 1); // rnu (round nearest up)
                            2'b01: rounded32[j] = temp32[j] + (((temp32[j] >> 1) & 1) & (temp32[j][0] != 0)); // rne (round nearest even)
                            2'b10: rounded32[j] = temp32[j]; // rdn (round nearest down)
                            2'b11: rounded32[j] = temp32[j] | ((temp32[j][0] != 0) & ~((temp32[j] >> 1) & 1)); // rod (round to odd)
                            default: rounded32[j] = temp32[j];
                        endcase
                    end else begin
                        rounded32[j] = temp32[j];
                    end

                    if (mask_out[j]) begin // determines which SEW elements to mask out
                        if (Ovflw32[j]) S32[j] = temp32[j][31] ? 32'h80000000 : 32'h7FFFFFFF; //Replace if overflow occurs
                        else S32[j] = rounded32[j];
                    end else if (!vma) S32[j] = S32_old[j]; //if set is marked agnostic, destination vector can retain previous value or be overwritten by 1's
                    else S32[j] = 32'hFFFFFFFF;
                end else if (vta) S32[j] = 32'hFFFFFFFF; //additional tail elements that are tail agnostic are overwritten as 1's
            end

            for (j = 0; j < vecwidth; j = j + 1) //output consisting vecwidth*SEW sized register
                S[32*j +: 32] = S32[j];
        end

        64: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                Aext64 = A[63:0];
                B64[j] = B[64*j +: 64];
                S64_old[j] = S_old[64*j +: 64];
                temp64[j] = B64[j] + Aext64; //addition for each 64-bit element and scalar
                Ovflw64[j] = (Aext64[63] == B64[j][63]) && (temp64[j][63] != Aext64[63]); //signed overflow detection

                if (j < vl) begin
                    if (vxsat) begin //for fixed point i.e. fractional math
                        case (vxrm)
                            2'b00: rounded64[j] = temp64[j] + ((temp64[j] >> 1) & 1); // rnu (round nearest up)
                            2'b01: rounded64[j] = temp64[j] + (((temp64[j] >> 1) & 1) & (temp64[j][0] != 0)); // rne (round nearest even)
                            2'b10: rounded64[j] = temp64[j]; // rdn (round nearest down)
                            2'b11: rounded64[j] = temp64[j] | ((temp64[j][0] != 0) & ~((temp64[j] >> 1) & 1)); // rod (round to odd)
                            default: rounded64[j] = temp64[j];
                        endcase
                    end else begin
                        rounded64[j] = temp64[j];
                    end

                    if (mask_out[j]) begin // determines which SEW elements to mask out
                        if (Ovflw64[j]) S64[j] = temp64[j][63] ? 64'h8000000000000000 : 64'h7FFFFFFFFFFFFFFF; //Replace if overflow occurs
                        else S64[j] = rounded64[j];
                    end else if (!vma) S64[j] = S64_old[j]; //if set is marked agnostic, destination vector can retain previous value or be overwritten by 1's
                    else S64[j] = 64'hFFFFFFFFFFFFFFFF;
                end else if (vta) S64[j] = 64'hFFFFFFFFFFFFFFFF; //additional tail elements that are tail agnostic are overwritten as 1's
            end

            for (j = 0; j < vecwidth; j = j + 1) //output consisting vecwidth*SEW sized register
                S[64*j +: 64] = S64[j];
        end
    endcase
end

endmodule
