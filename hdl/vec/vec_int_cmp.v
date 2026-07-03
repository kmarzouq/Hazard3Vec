// === AI-GENERATED FILE ===
// RVV 1.0 integer compare instructions (funct6, per riscv-v-spec inst-table.adoc):
//   011000 vmseq, 011001 vmsne, 011010 vmsltu, 011011 vmslt,
//   011100 vmsleu, 011101 vmsle, 011110 vmsgtu (vx/vi only), 011111 vmsgt (vx/vi only)
// Semantics: vd[i] = (vs2[i] <op> vs1[i]) ie. B <op> A, matching the existing
// A=vs1(or scalar)/B=vs2 convention used throughout vector_core.v.
//
// Unlike ordinary arithmetic, the destination is a *packed bitmask*: one bit
// per element regardless of SEW (Section "Mask Register Layout"), so this
// module writes bit j of S for element j instead of an SEW-wide lane. Per
// spec, inactive/tail policy still applies (undisturbed unless vma/vta=1,
// in which case those bits may be set to 1) -- bits at/above `vecwidth` are
// simply carried over unchanged from S_old, since they are outside this
// instruction's element range entirely.
// verilator lint_off WIDTH
module vec_int_cmp #(
    parameter MAX_VECWIDTH = 16,
    parameter XLEN = 32
)(
    input  [5:0] op,      // funct6
    input        vx_mode, // 0: A is vs1 (per-lane), 1: A is scalar/imm (broadcast)
    input  [XLEN-1:0] vtype,
    input  [XLEN-1:0] vl,
    input  [XLEN-1:0] vlenb,
    input        vm_bit,
    input  [MAX_VECWIDTH-1:0] v0_mask,
    input  [MAX_VECWIDTH*XLEN-1:0] S_old,
    input  [MAX_VECWIDTH*XLEN-1:0] A,
    input  [MAX_VECWIDTH*XLEN-1:0] B,
    output reg [MAX_VECWIDTH*XLEN-1:0] S
);

wire [MAX_VECWIDTH-1:0] mask_out;
mask #(.VLEN(MAX_VECWIDTH)) mask_inst (
    .vm(vm_bit),
    .v0_mask(v0_mask),
    .mask_out(mask_out)
);

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

function cmp_bit;
    input [5:0]  f6;
    input [63:0] a; // vs1 or scalar/imm
    input [63:0] b; // vs2
    input [63:0] signmask; // 1 << (sew-1)
    reg signed [64:0] as, bs;
    begin
        as = $signed({1'b0,a} ^ {1'b0,signmask}) - $signed({1'b0,signmask}); // sign-extend to (sew+1) bits worth
        bs = $signed({1'b0,b} ^ {1'b0,signmask}) - $signed({1'b0,signmask});
        case (f6)
            6'b011000: cmp_bit = (b == a);          // vmseq
            6'b011001: cmp_bit = (b != a);          // vmsne
            6'b011010: cmp_bit = (b <  a);          // vmsltu
            6'b011011: cmp_bit = (bs <  as);         // vmslt
            6'b011100: cmp_bit = (b <=  a);          // vmsleu
            6'b011101: cmp_bit = (bs <=  as);         // vmsle
            6'b011110: cmp_bit = (b >  a);          // vmsgtu
            6'b011111: cmp_bit = (bs >  as);         // vmsgt
            default:   cmp_bit = 1'b0;
        endcase
    end
endfunction

integer j;
reg [MAX_VECWIDTH-1:0] Sbit;

always @(*) begin
    S = S_old; // outside vecwidth (and by default, everywhere) carry the prior value
    Sbit = S_old[MAX_VECWIDTH-1:0];

    case (sew)
        8: for (j = 0; j < vecwidth; j = j + 1) begin
            if (j < vl) begin
                if (mask_out[j]) Sbit[j] = cmp_bit(op, vx_mode ? {56'b0,A[7:0]} : {56'b0,A[8*j+:8]}, {56'b0,B[8*j+:8]}, 64'h80);
                else if (vma) Sbit[j] = 1'b1;
            end else if (vta) Sbit[j] = 1'b1;
        end
        16: for (j = 0; j < vecwidth; j = j + 1) begin
            if (j < vl) begin
                if (mask_out[j]) Sbit[j] = cmp_bit(op, vx_mode ? {48'b0,A[15:0]} : {48'b0,A[16*j+:16]}, {48'b0,B[16*j+:16]}, 64'h8000);
                else if (vma) Sbit[j] = 1'b1;
            end else if (vta) Sbit[j] = 1'b1;
        end
        32: for (j = 0; j < vecwidth; j = j + 1) begin
            if (j < vl) begin
                if (mask_out[j]) Sbit[j] = cmp_bit(op, vx_mode ? {32'b0,A[31:0]} : {32'b0,A[32*j+:32]}, {32'b0,B[32*j+:32]}, 64'h80000000);
                else if (vma) Sbit[j] = 1'b1;
            end else if (vta) Sbit[j] = 1'b1;
        end
        default: for (j = 0; j < vecwidth; j = j + 1) begin // 64
            if (j < vl) begin
                if (mask_out[j]) Sbit[j] = cmp_bit(op, vx_mode ? A[63:0] : A[64*j+:64], B[64*j+:64], 64'h8000000000000000);
                else if (vma) Sbit[j] = 1'b1;
            end else if (vta) Sbit[j] = 1'b1;
        end
    endcase

    S[MAX_VECWIDTH-1:0] = Sbit;
end

endmodule
// verilator lint_on WIDTH
// === END AI-GENERATED FILE ===
