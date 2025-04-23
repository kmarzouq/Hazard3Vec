module vmul32_vv #( 
    parameter MAX_VECWIDTH=32, // Maximum LMUL-supported vector width
    parameter XLEN = 32 // variable XLEN, initially set to 32
)(
  input [XLEN-1:0] vtype,
  input [1:0] vxrm,
  input [XLEN-1:0] vl,
  input [XLEN-1:0] vlenb,
  input [MAX_VECWIDTH*XLEN-1:0] A,
  input [MAX_VECWIDTH*XLEN-1:0] B,
  input [MAX_VECWIDTH-1:0] vmask,
  output [MAX_VECWIDTH*XLEN-1:0] P,
  output [MAX_VECWIDTH-1:0] Ovflw,
  output reg vxsat_comb
);

// Decode SEW and LMUL
wire [2:0] vsew = vtype[5:3];
wire [2:0] vlmul = vtype[2:0];

wire [31:0] sew = 1 << ({1'b0, vsew} + 3); // e.g., SEW=3 => 2^(3+3)=64 bits
wire [31:0] vlen = vlenb * 8; // bytes -> bits

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

// Wires for multiplication results
wire [MAX_VECWIDTH*2*XLEN-1:0] mul_raw;
wire [MAX_VECWIDTH-1:0] overflow_flags;

genvar i;
generate
    for (i = 0; i < MAX_VECWIDTH; i = i + 1) begin : MUL_LOOP
        wire signed [XLEN-1:0] a_lane = A[XLEN*i +: XLEN];
        wire signed [XLEN-1:0] b_lane = B[XLEN*i +: XLEN];
        wire signed [2*XLEN-1:0] p_lane;

        assign p_lane = a_lane * b_lane;
        assign mul_raw[2*XLEN*i +: 2*XLEN] = p_lane;

        // Overflow detection: if upper 32 bits are not a sign-extension of bit 31
        assign overflow_flags[i] = |p_lane[2*XLEN-1:XLEN] ^ {XLEN{p_lane[XLEN-1]}};
    end
endgenerate

// Combinational rounding, saturation, and output
reg [MAX_VECWIDTH*XLEN-1:0] rounded;
reg [MAX_VECWIDTH*XLEN-1:0] P_comb;

integer j;

always @(*) begin
    vxsat_comb = 1'b0;
    P_comb = {MAX_VECWIDTH*XLEN{1'b0}};
    rounded = {MAX_VECWIDTH*XLEN{1'b0}};

    for (j = 0; j < MAX_VECWIDTH; j = j + 1) begin
      if (j < vecwidth) begin
        if (j < vl) begin
          // Rounding logic (simple rounding from 64 to 32 bits)
          case (vxrm)
            2'b00: rounded[XLEN*j +: XLEN] = mul_raw[2*XLEN*j +: XLEN] + mul_raw[2*XLEN*j + XLEN]; // rnu
            2'b01: rounded[XLEN*j +: XLEN] = mul_raw[2*XLEN*j +: XLEN] + (mul_raw[2*XLEN*j + XLEN] & (|mul_raw[2*XLEN*j +: XLEN])); // rne
            2'b10: rounded[XLEN*j +: XLEN] = mul_raw[2*XLEN*j +: XLEN]; // rdn
            2'b11: rounded[XLEN*j +: XLEN] = mul_raw[2*XLEN*j +: XLEN] | ((|mul_raw[2*XLEN*j +: XLEN]) & ~mul_raw[2*XLEN*j + XLEN]); // rod
            default: rounded[XLEN*j +: XLEN] = mul_raw[2*XLEN*j +: XLEN];
          endcase

          // Overflow handling and vmask
          if (vmask[j]) begin
            if (overflow_flags[j]) begin
              vxsat_comb = 1'b1;
              P_comb[XLEN*j +: XLEN] = mul_raw[2*XLEN*j + XLEN-1] ? {1'b1, {(XLEN-1){1'b0}}} : {1'b0, {(XLEN-1){1'b1}}};
            end else begin
              P_comb[XLEN*j +: XLEN] = rounded[XLEN*j +: XLEN];
            end
          end else if (!vma) begin
            P_comb[XLEN*j +: XLEN] = rounded[XLEN*j +: XLEN];
          end else begin
            P_comb[XLEN*j +: XLEN] = {XLEN{1'b1}};
          end
        end else if (vta) begin
          P_comb[XLEN*j +: XLEN] = {XLEN{1'b1}};
        end
      end
    end
end

assign P = P_comb;
assign Ovflw = overflow_flags;

endmodule
