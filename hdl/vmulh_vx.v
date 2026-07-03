// Compute signed vector-scalar multiplication between a vector of length XLEN bits with a SEW bits size (single element width) and a scalar of SEW-width length. Returns the upper bits of the product
// XLEN is determined in the testbench & SEW can be 8, 16, 32, and 64 bits based on what's defined in the Zve32x specification for the RISC-V Vector Extension
// funct3: 110 (OPMVX) for Vector Aritmetic Instruction Encoding
// funct6: 100111 (vmulh) for Vector Instruction Listing

module vmul32h_vx #( 
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
reg [7:0] S8 [MAX_VECWIDTH-1:0];
reg [7:0] S8_old [MAX_VECWIDTH-1:0];
reg [7:0] temp8 [MAX_VECWIDTH-1:0];
reg [7:0] rounded8 [MAX_VECWIDTH-1:0];

//when sew = 16
reg [15:0] B16    [MAX_VECWIDTH-1:0];
reg [15:0] S16    [MAX_VECWIDTH-1:0];
reg [15:0] S16_old[MAX_VECWIDTH-1:0];
reg [15:0] temp16 [MAX_VECWIDTH-1:0];
reg [15:0] rounded16 [MAX_VECWIDTH-1:0];

//when sew = 32
reg [31:0] B32    [MAX_VECWIDTH-1:0];
reg [31:0] S32    [MAX_VECWIDTH-1:0];
reg [31:0] S32_old[MAX_VECWIDTH-1:0];
reg [31:0] temp32 [MAX_VECWIDTH-1:0];
reg [31:0] rounded32 [MAX_VECWIDTH-1:0];

//when sew = 64
reg [63:0] B64    [MAX_VECWIDTH-1:0];
reg [63:0] S64    [MAX_VECWIDTH-1:0];
reg [63:0] S64_old[MAX_VECWIDTH-1:0];
reg [63:0] temp64 [MAX_VECWIDTH-1:0];
reg [63:0] rounded64 [MAX_VECWIDTH-1:0];

//multiplication registers
reg SignA8     [MAX_VECWIDTH-1:0];
reg SignB8     [MAX_VECWIDTH-1:0];
reg Sign8Out   [MAX_VECWIDTH-1:0];
reg SignA16    [MAX_VECWIDTH-1:0];
reg SignB16    [MAX_VECWIDTH-1:0];
reg Sign16Out  [MAX_VECWIDTH-1:0];
reg SignA32 [MAX_VECWIDTH-1:0];
reg SignB32 [MAX_VECWIDTH-1:0];
reg Sign32Out [MAX_VECWIDTH-1:0];
reg SignA64    [MAX_VECWIDTH-1:0];
reg SignB64    [MAX_VECWIDTH-1:0];
reg Sign64Out  [MAX_VECWIDTH-1:0];

reg [7:0] A8m    [MAX_VECWIDTH-1:0];
reg [7:0] B8m    [MAX_VECWIDTH-1:0];
reg [7:0] P8m    [MAX_VECWIDTH-1:0];
reg [15:0] A16m    [MAX_VECWIDTH-1:0];
reg [15:0] B16m    [MAX_VECWIDTH-1:0];
reg [15:0] P16m    [MAX_VECWIDTH-1:0];
reg [31:0] A32m    [MAX_VECWIDTH-1:0];
reg [31:0] B32m    [MAX_VECWIDTH-1:0];
reg [31:0] P32m    [MAX_VECWIDTH-1:0];
reg [63:0] A64m    [MAX_VECWIDTH-1:0];
reg [63:0] B64m    [MAX_VECWIDTH-1:0];
reg [63:0] P64m    [MAX_VECWIDTH-1:0];

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
                Aext8 = A[7:0];                            // broadcast 8-bit scalar operand A
                B8[j] = B[8*j +: 8];                       // extract 8-bit vector element B

                SignA8[j] = A[7];                          // extract sign bit of scalar A
                SignB8[j] = B[8*j + 7];                    // extract sign bit of vector B
                Sign8Out[j] = SignA8[j] ^ SignB8[j];       // determine result sign from input signs

                A8m[j] = SignA8[j] ? ~Aext8 + 1 : Aext8;   // convert scalar A to magnitude
                B8m[j] = SignB8[j] ? ~B8[j] + 1 : B8[j];   // convert vector B to magnitude

                S8_old[j] = S_old[8*j +: 8];               // load old result element
                P8m_long[j] = A8m[j] * B8m[j];             // perform unsigned multiplication (16-bit result)
                P8m[j] = P8m_long[j][15:8];                // take upper 8 bits (fractional part)
                temp8[j] = Sign8Out[j] ? ~P8m[j] + 1 : P8m[j]; // apply sign to product

                if (j < vl) begin
                    if (vxsat) begin                       // enable rounding for fixed-point
                        case (vxrm)
                            2'b00: rounded8[j] = temp8[j] + ((temp8[j] >> 1) & 1);                      // rnu (round to nearest up)
                            2'b01: rounded8[j] = temp8[j] + (((temp8[j] >> 1) & 1) & (temp8[j][0] != 0)); // rne (round to nearest even)
                            2'b10: rounded8[j] = temp8[j];                                               // rdn (round down)
                            2'b11: rounded8[j] = temp8[j] | ((temp8[j][0] != 0) & ~((temp8[j] >> 1) & 1)); // rod (round to odd)
                            default: rounded8[j] = temp8[j];
                        endcase
                    end else begin
                        rounded8[j] = temp8[j];            // no rounding
                    end

                    if (mask_out[j]) begin                 // active mask bit: write rounded result
                        S8[j] = rounded8[j];
                    end else if (!vma) S8[j] = S8_old[j];  // vma = 0: use old value
                    else S8[j] = 8'hFF;                    // vma = 1: agnostic result (overwrite with all 1's)
                end else if (vta) S8[j] = 8'hFF;           // vta = 1: tail elements agnostic
            end

            for (j = 0; j < vecwidth; j = j + 1)
                S[8*j +: 8] = S8[j];                       // write final result to output vector
        end

        16: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                Aext16 = A[15:0];                          // broadcast 16-bit scalar operand A
                B16[j] = B[16*j +: 16];                    // extract 16-bit vector element B

                SignA16[j] = A[15];                        // extract sign bit of scalar A
                SignB16[j] = B[16*j + 15];                 // extract sign bit of vector B
                Sign16Out[j] = SignA16[j] ^ SignB16[j];    // determine result sign from input signs

                A16m[j] = SignA16[j] ? ~Aext16 + 1 : Aext16; // convert scalar A to magnitude
                B16m[j] = SignB16[j] ? ~B16[j] + 1 : B16[j]; // convert vector B to magnitude

                S16_old[j] = S_old[16*j +: 16];            // load old result element
                P16m_long[j] = A16m[j] * B16m[j];          // perform unsigned multiplication (32-bit result)
                P16m[j] = P16m_long[j][31:16];             // take upper 16 bits (fractional part)
                temp16[j] = Sign16Out[j] ? ~P16m[j] + 1 : P16m[j]; // apply sign to product

                if (j < vl) begin
                    if (vxsat) begin                       // enable rounding for fixed-point
                        case (vxrm)
                            2'b00: rounded16[j] = temp16[j] + ((temp16[j] >> 1) & 1); // rnu
                            2'b01: rounded16[j] = temp16[j] + (((temp16[j] >> 1) & 1) & (temp16[j][0] != 0)); // rne
                            2'b10: rounded16[j] = temp16[j]; // rdn
                            2'b11: rounded16[j] = temp16[j] | ((temp16[j][0] != 0) & ~((temp16[j] >> 1) & 1)); // rod
                            default: rounded16[j] = temp16[j];
                        endcase
                    end else begin
                        rounded16[j] = temp16[j];          // no rounding
                    end

                    if (mask_out[j]) begin
                        S16[j] = rounded16[j];             // write result if masked in
                    end else if (!vma) S16[j] = S16_old[j]; // if not masked and vma = 0: retain old value
                    else S16[j] = 16'hFFFF;                // else write agnostic result
                end else if (vta) S16[j] = 16'hFFFF;       // tail agnostic: overwrite with 1's
            end

            for (j = 0; j < vecwidth; j = j + 1)
                S[16*j +: 16] = S16[j];                    // write result vector
        end

        32: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                Aext32 = A[31:0];                          // broadcast 32-bit scalar A
                B32[j] = B[32*j +: 32];                    // extract 32-bit vector B

                SignA32[j] = A[31];                        // sign of scalar A
                SignB32[j] = B[32*j + 31];                 // sign of vector B
                Sign32Out[j] = SignA32[j] ^ SignB32[j];    // output sign

                A32m[j] = SignA32[j] ? ~Aext32 + 1 : Aext32; // abs value of A
                B32m[j] = SignB32[j] ? ~B32[j] + 1 : B32[j]; // abs value of B

                S32_old[j] = S_old[32*j +: 32];            // load old result
                P32m_long[j] = A32m[j] * B32m[j];          // 64-bit result
                P32m[j] = P32m_long[j][63:32];             // upper 32 bits
                temp32[j] = Sign32Out[j] ? ~P32m[j] + 1 : P32m[j]; // apply output sign

                if (j < vl) begin
                    if (vxsat) begin
                        case (vxrm)
                            2'b00: rounded32[j] = temp32[j] + ((temp32[j] >> 1) & 1); // rnu
                            2'b01: rounded32[j] = temp32[j] + (((temp32[j] >> 1) & 1) & (temp32[j][0] != 0)); // rne
                            2'b10: rounded32[j] = temp32[j]; // rdn
                            2'b11: rounded32[j] = temp32[j] | ((temp32[j][0] != 0) & ~((temp32[j] >> 1) & 1)); // rod
                            default: rounded32[j] = temp32[j];
                        endcase
                    end else begin
                        rounded32[j] = temp32[j];          // no rounding
                    end

                    if (mask_out[j]) begin
                        S32[j] = rounded32[j];             // write if masked in
                    end else if (!vma) S32[j] = S32_old[j]; // vma = 0: preserve previous value
                    else S32[j] = 32'hFFFFFFFF;            // vma = 1: agnostic overwrite
                end else if (vta) S32[j] = 32'hFFFFFFFF;   // vta = 1: tail overwrite
            end

            for (j = 0; j < vecwidth; j = j + 1)
                S[32*j +: 32] = S32[j];                    // commit final result
        end

        64: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                Aext64 = A[63:0];                          // broadcast 64-bit scalar
                B64[j] = B[64*j +: 64];                    // extract 64-bit vector element

                SignA64[j] = A[63];                        // sign of scalar A
                SignB64[j] = B[64*j + 63];                 // sign of vector B
                Sign64Out[j] = SignA64[j] ^ SignB64[j];    // determine result sign

                A64m[j] = SignA64[j] ? ~Aext64 + 1 : Aext64; // abs of A
                B64m[j] = SignB64[j] ? ~B64[j] + 1 : B64[j]; // abs of B

                S64_old[j] = S_old[64*j +: 64];            // previous result
                P64m_long[j] = A64m[j] * B64m[j];          // 128-bit product
                P64m[j] = P64m_long[j][127:64];            // upper 64 bits
                temp64[j] = Sign64Out[j] ? ~P64m[j] + 1 : P64m[j]; // signed result

                if (j < vl) begin
                    if (vxsat) begin
                        case (vxrm)
                            2'b00: rounded64[j] = temp64[j] + ((temp64[j] >> 1) & 1); // rnu
                            2'b01: rounded64[j] = temp64[j] + (((temp64[j] >> 1) & 1) & (temp64[j][0] != 0)); // rne
                            2'b10: rounded64[j] = temp64[j]; // rdn
                            2'b11: rounded64[j] = temp64[j] | ((temp64[j][0] != 0) & ~((temp64[j] >> 1) & 1)); // rod
                            default: rounded64[j] = temp64[j];
                        endcase
                    end else begin
                        rounded64[j] = temp64[j];          // no rounding
                    end

                    if (mask_out[j]) begin
                        S64[j] = rounded64[j];             // valid mask -> write result
                    end else if (!vma) S64[j] = S64_old[j]; // keep old value
                    else S64[j] = 64'hFFFFFFFFFFFFFFFF;    // agnostic overwrite
                end else if (vta) S64[j] = 64'hFFFFFFFFFFFFFFFF; // tail agnostic
            end

            for (j = 0; j < vecwidth; j = j + 1)
                S[64*j +: 64] = S64[j];                    // write final output
        end
    endcase
end

endmodule
