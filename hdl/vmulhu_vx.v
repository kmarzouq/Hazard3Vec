// Compute unsigned vector-scalar multiplication between a vector of length XLEN bits with a SEW bits size (single element width) and a scalar of SEW-width length. Returns the upper bits of the product
// XLEN is determined in the testbench & SEW can be 8, 16, 32, and 64 bits based on what's defined in the Zve32x specification for the RISC-V Vector Extension
// funct3: 110 (OPMVX) for Vector Aritmetic Instruction Encoding
// funct6: 100100 (vmulhu) for Vector Instruction Listing

module vmul32hu_vx #( 
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
  input [MAX_VECWIDTH*XLEN-1:0] A,
  input [MAX_VECWIDTH*XLEN-1:0] B,
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
// LMUL = 1, vector operation kept to 1 vector register of XLEN sized bits
// LMUL > 1, vector operation extended to >1 vector registers 
// LMUL < 1, vector operation kept to 1 vector register of XLEN sized bits with extended 0's or 1's
wire [31:0] vecwidth = (raw_vecwidth > MAX_ELEMENTS) ? MAX_ELEMENTS : raw_vecwidth;

wire vma = vtype[7];
wire vta = vtype[6];

//when sew = 8
reg [7:0] B8 [MAX_ELEMENTS-1:0];
reg [7:0] S8 [MAX_ELEMENTS-1:0];
reg [7:0] S8_old [MAX_ELEMENTS-1:0];
reg [7:0] temp8 [MAX_ELEMENTS-1:0];
reg [7:0] rounded8 [MAX_ELEMENTS-1:0];

//when sew = 16
reg [15:0] B16    [MAX_ELEMENTS-1:0];
reg [15:0] S16    [MAX_ELEMENTS-1:0];
reg [15:0] S16_old[MAX_ELEMENTS-1:0];
reg [15:0] temp16 [MAX_ELEMENTS-1:0];
reg [15:0] rounded16 [MAX_ELEMENTS-1:0];

//when sew = 32
reg [31:0] B32    [MAX_ELEMENTS-1:0];
reg [31:0] S32    [MAX_ELEMENTS-1:0];
reg [31:0] S32_old[MAX_ELEMENTS-1:0];
reg [31:0] temp32 [MAX_ELEMENTS-1:0];
reg [31:0] rounded32 [MAX_ELEMENTS-1:0];

//when sew = 64
reg [63:0] B64    [MAX_ELEMENTS-1:0];
reg [63:0] S64    [MAX_ELEMENTS-1:0];
reg [63:0] S64_old[MAX_ELEMENTS-1:0];
reg [63:0] temp64 [MAX_ELEMENTS-1:0];
reg [63:0] rounded64 [MAX_ELEMENTS-1:0];

//multiplication registers
reg [15:0] P8m_long    [MAX_ELEMENTS-1:0];
reg [31:0] P16m_long    [MAX_ELEMENTS-1:0];
reg [63:0] P32m_long    [MAX_ELEMENTS-1:0];
reg [127:0] P64m_long    [MAX_ELEMENTS-1:0];

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
                Aext8 = A[7:0];                         // Extract single 8-bit scalar element from A
                B8[j] = B[8*j +: 8];                    // Extract 8-bit vector element from B

                S8_old[j] = S_old[8*j +: 8];            // Extract old destination value
                P8m_long[j] = Aext8 * B8[j];            // Perform 8x8-bit multiplication (16-bit result)
                temp8[j] = P8m_long[j][15:8];           // Take upper 8 bits of product as fixed-point result

                if (j < vl) begin
                    // Apply rounding based on vxrm if saturation mode (vxsat) is enabled
                    if (vxsat) begin
                        case (vxrm)
                            2'b00: rounded8[j] = temp8[j] + ((temp8[j] >> 1) & 1);                           // Round to nearest, up (rnu)
                            2'b01: rounded8[j] = temp8[j] + (((temp8[j] >> 1) & 1) & (temp8[j][0] != 0));    // Round to nearest, even (rne)
                            2'b10: rounded8[j] = temp8[j];                                                  // Round down (rdn)
                            2'b11: rounded8[j] = temp8[j] | ((temp8[j][0] != 0) & ~((temp8[j] >> 1) & 1));   // Round to odd (rod)
                            default: rounded8[j] = temp8[j];
                        endcase
                    end else begin
                        rounded8[j] = temp8[j]; // No rounding
                    end

                    // Masked assignment
                    if (mask_out[j]) begin
                        S8[j] = rounded8[j];
                    end else if (!vma) S8[j] = S8_old[j];  // Retain previous value
                    else S8[j] = 8'hFF;                    // Set to all 1s if vma is true
                end else if (vta) S8[j] = 8'hFF;           // Tail elements set to all 1s if vta is true
            end

            // Repack result vector S from 8-bit elements
            for (j = 0; j < vecwidth; j = j + 1)
                S[8*j +: 8] = S8[j];
        end

        16: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                Aext16 = A[15:0];                         // Extract single 16-bit scalar element from A
                B16[j] = B[16*j +: 16];                   // Extract 16-bit vector element from B

                S16_old[j] = S_old[16*j +: 16];           // Extract old destination value
                P16m_long[j] = Aext16 * B16[j];           // Perform 16x16-bit multiplication (32-bit result)
                temp16[j] = P16m_long[j][31:16];          // Take upper 16 bits of product as fixed-point result

                if (j < vl) begin
                    // Apply rounding based on vxrm if saturation mode (vxsat) is enabled
                    if (vxsat) begin
                        case (vxrm)
                            2'b00: rounded16[j] = temp16[j] + ((temp16[j] >> 1) & 1); // rnu
                            2'b01: rounded16[j] = temp16[j] + (((temp16[j] >> 1) & 1) & (temp16[j][0] != 0)); // rne
                            2'b10: rounded16[j] = temp16[j]; // rdn
                            2'b11: rounded16[j] = temp16[j] | ((temp16[j][0] != 0) & ~((temp16[j] >> 1) & 1)); // rod
                            default: rounded16[j] = temp16[j];
                        endcase
                    end else begin
                        rounded16[j] = temp16[j]; // No rounding
                    end

                    // Masked assignment
                    if (mask_out[j]) begin
                        S16[j] = rounded16[j];
                    end else if (!vma) S16[j] = S16_old[j]; // Retain previous value
                    else S16[j] = 16'hFFFF;                 // Set to all 1s if vma is true
                end else if (vta) S16[j] = 16'hFFFF;        // Tail elements set to all 1s if vta is true
            end

            // Repack result vector S from 16-bit elements
            for (j = 0; j < vecwidth; j = j + 1)
                S[16*j +: 16] = S16[j];
        end

        32: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                Aext32 = A[31:0];                         // Extract single 32-bit scalar element from A
                B32[j] = B[32*j +: 32];                   // Extract 32-bit vector element from B

                S32_old[j] = S_old[32*j +: 32];           // Extract old destination value
                P32m_long[j] = Aext32 * B32[j];           // Perform 32x32-bit multiplication (64-bit result)
                temp32[j] = P32m_long[j][63:32];          // Take upper 32 bits of product as fixed-point result

                if (j < vl) begin
                    // Apply rounding based on vxrm if saturation mode (vxsat) is enabled
                    if (vxsat) begin
                        case (vxrm)
                            2'b00: rounded32[j] = temp32[j] + ((temp32[j] >> 1) & 1); // rnu
                            2'b01: rounded32[j] = temp32[j] + (((temp32[j] >> 1) & 1) & (temp32[j][0] != 0)); // rne
                            2'b10: rounded32[j] = temp32[j]; // rdn
                            2'b11: rounded32[j] = temp32[j] | ((temp32[j][0] != 0) & ~((temp32[j] >> 1) & 1)); // rod
                            default: rounded32[j] = temp32[j];
                        endcase
                    end else begin
                        rounded32[j] = temp32[j]; // No rounding
                    end

                    // Masked assignment
                    if (mask_out[j]) begin
                        S32[j] = rounded32[j];
                    end else if (!vma) S32[j] = S32_old[j]; // Retain previous value
                    else S32[j] = 32'hFFFFFFFF;             // Set to all 1s if vma is true
                end else if (vta) S32[j] = 32'hFFFFFFFF;    // Tail elements set to all 1s if vta is true
            end

            // Repack result vector S from 32-bit elements
            for (j = 0; j < vecwidth; j = j + 1)
                S[32*j +: 32] = S32[j];
        end

        64: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                Aext64 = A[63:0];                         // Extract single 64-bit scalar element from A
                B64[j] = B[64*j +: 64];                   // Extract 64-bit vector element from B

                S64_old[j] = S_old[64*j +: 64];           // Extract old destination value
                P64m_long[j] = Aext64 * B64[j];           // Perform 64x64-bit multiplication (128-bit result)
                temp64[j] = P64m_long[j][127:64];         // Take upper 64 bits of product as fixed-point result

                if (j < vl) begin
                    // Apply rounding based on vxrm if saturation mode (vxsat) is enabled
                    if (vxsat) begin
                        case (vxrm)
                            2'b00: rounded64[j] = temp64[j] + ((temp64[j] >> 1) & 1); // rnu
                            2'b01: rounded64[j] = temp64[j] + (((temp64[j] >> 1) & 1) & (temp64[j][0] != 0)); // rne
                            2'b10: rounded64[j] = temp64[j]; // rdn
                            2'b11: rounded64[j] = temp64[j] | ((temp64[j][0] != 0) & ~((temp64[j] >> 1) & 1)); // rod
                            default: rounded64[j] = temp64[j];
                        endcase
                    end else begin
                        rounded64[j] = temp64[j]; // No rounding
                    end

                    // Masked assignment
                    if (mask_out[j]) begin
                        S64[j] = rounded64[j];
                    end else if (!vma) S64[j] = S64_old[j]; // Retain previous value
                    else S64[j] = 64'hFFFFFFFFFFFFFFFF;     // Set to all 1s if vma is true
                end else if (vta) S64[j] = 64'hFFFFFFFFFFFFFFFF; // Tail elements set to all 1s if vta is true
            end

            // Repack result vector S from 64-bit elements
            for (j = 0; j < vecwidth; j = j + 1)
                S[64*j +: 64] = S64[j];
        end
    endcase
end

endmodule
