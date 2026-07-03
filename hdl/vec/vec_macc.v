// === AI-GENERATED FILE ===
// RVV 1.0 integer multiply-add (funct6, OPMVV/OPMVX only, no OPIVI):
//   101101 vmacc.vv/vx    vd = +(vs1*vs2) + vd
//   101111 vnmsac.vv/vx   vd = -(vs1*vs2) + vd
//   101001 vmadd.vv/vx    vd = (vs1*vd) + vs2   (vd itself is a multiplicand!)
//   101011 vnmsub.vv/vx   vd = -(vs1*vd) + vs2
// A = vs1 (vv) or scalar (vx), B = vs2, S_old = vd's value before this
// instruction, matching the existing A/B/S_old convention.
// verilator lint_off WIDTH
module vec_macc #(
    parameter MAX_VECWIDTH = 16,
    parameter XLEN = 32
)(
    input  [5:0] op,
    input        vx_mode,
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

// mac_op(op, a, b, vd_old) -> new vd value, all at native width (caller truncates)
function [63:0] mac_op;
    input [5:0]  f6;
    input [63:0] a;   // vs1/scalar
    input [63:0] b;   // vs2
    input [63:0] vd;  // vd's old value
    begin
        case (f6)
            6'b101101: mac_op =  (a * b) + vd; // vmacc
            6'b101111: mac_op = vd - (a * b);  // vnmsac
            6'b101001: mac_op =  (a * vd) + b; // vmadd
            6'b101011: mac_op = b - (a * vd);  // vnmsub
            default:   mac_op = vd;
        endcase
    end
endfunction

integer j;
reg [63:0] tmp;

always @(*) begin
    S = 0;
    case (sew)
        8: for (j = 0; j < vecwidth; j = j + 1) begin
            if (j < vl) begin
                if (mask_out[j]) begin
                    tmp = mac_op(op, {56'b0, vx_mode ? A[7:0] : A[8*j+:8]}, {56'b0,B[8*j+:8]}, {56'b0,S_old[8*j+:8]});
                    S[8*j+:8] = tmp[7:0];
                end else if (!vma) S[8*j+:8] = S_old[8*j+:8];
                else S[8*j+:8] = 8'hFF;
            end else if (vta) S[8*j+:8] = 8'hFF;
        end
        16: for (j = 0; j < vecwidth; j = j + 1) begin
            if (j < vl) begin
                if (mask_out[j]) begin
                    tmp = mac_op(op, {48'b0, vx_mode ? A[15:0] : A[16*j+:16]}, {48'b0,B[16*j+:16]}, {48'b0,S_old[16*j+:16]});
                    S[16*j+:16] = tmp[15:0];
                end else if (!vma) S[16*j+:16] = S_old[16*j+:16];
                else S[16*j+:16] = 16'hFFFF;
            end else if (vta) S[16*j+:16] = 16'hFFFF;
        end
        32: for (j = 0; j < vecwidth; j = j + 1) begin
            if (j < vl) begin
                if (mask_out[j]) begin
                    tmp = mac_op(op, {32'b0, vx_mode ? A[31:0] : A[32*j+:32]}, {32'b0,B[32*j+:32]}, {32'b0,S_old[32*j+:32]});
                    S[32*j+:32] = tmp[31:0];
                end else if (!vma) S[32*j+:32] = S_old[32*j+:32];
                else S[32*j+:32] = 32'hFFFFFFFF;
            end else if (vta) S[32*j+:32] = 32'hFFFFFFFF;
        end
        default: for (j = 0; j < vecwidth; j = j + 1) begin // 64
            if (j < vl) begin
                if (mask_out[j]) begin
                    tmp = mac_op(op, vx_mode ? A[63:0] : A[64*j+:64], B[64*j+:64], S_old[64*j+:64]);
                    S[64*j+:64] = tmp;
                end else if (!vma) S[64*j+:64] = S_old[64*j+:64];
                else S[64*j+:64] = 64'hFFFFFFFFFFFFFFFF;
            end else if (vta) S[64*j+:64] = 64'hFFFFFFFFFFFFFFFF;
        end
    endcase
end

endmodule
// verilator lint_on WIDTH
// === END AI-GENERATED FILE ===
