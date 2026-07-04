// === AI-GENERATED FILE ===
// RVV 1.0 vmerge/vmv (funct6 010111, OPIVV/OPIVX/OPIVI -- no OPMVV form).
// Unlike every other vm-bearing instruction, vm here does not mean "unmasked
// vs masked-by-v0" -- it selects between two distinct instructions:
//   vm=0: vmerge.vvm/vxm/vim  vd[i] = v0.mask[i] ? A[i] : vs2[i]
//   vm=1: vmv.v.v/v.x/v.i     vd[i] = A[i]                 (vs2 ignored)
// A is vs1 (vv) or the sign-extended scalar/immediate broadcast (vx/vi),
// same convention as the rest of vector_core.v.
// verilator lint_off WIDTH
module vec_merge #(
    parameter MAX_VECWIDTH = 16,
    parameter XLEN = 32
)(
    input        vx_mode,
    input        vm_bit, // instruction-select, NOT the usual mask-enable
    input  [XLEN-1:0] vtype,
    input  [XLEN-1:0] vl,
    input  [XLEN-1:0] vlenb,
    input  [MAX_ELEMENTS-1:0] v0_mask,
    input  [MAX_VECWIDTH*XLEN-1:0] S_old,
    input  [MAX_VECWIDTH*XLEN-1:0] A,
    input  [MAX_VECWIDTH*XLEN-1:0] B,
    output reg [MAX_VECWIDTH*XLEN-1:0] S
);

// === AI-GENERATED BEGIN: fix MAX_VECWIDTH element-count bug ===
// Same fix as vec_int_alu.v: MAX_VECWIDTH as passed in is really "VLEN/32"
// (sized for SEW=32), not a true element count -- at SEW=8/16 this silently
// dropped elements past the 4th. MAX_ELEMENTS recovers the true count from
// the always-correct total bit width MAX_VECWIDTH*XLEN.
localparam MAX_ELEMENTS = (MAX_VECWIDTH*XLEN)/8;
// === AI-GENERATED END ===

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
wire [31:0] vecwidth = (raw_vecwidth > MAX_ELEMENTS) ? MAX_ELEMENTS : raw_vecwidth;
wire vta = vtype[6]; // vmerge/vmv have no vma policy (source is always well-defined for active elements)

integer j;

always @(*) begin
    S = S_old;
    case (sew)
        8: for (j = 0; j < vecwidth; j = j + 1) begin
            if (j < vl) S[8*j+:8]  = (vm_bit || v0_mask[j]) ? (vx_mode ? A[7:0]  : A[8*j+:8])  : B[8*j+:8];
            else if (vta) S[8*j+:8] = 8'hFF;
        end
        16: for (j = 0; j < vecwidth; j = j + 1) begin
            if (j < vl) S[16*j+:16] = (vm_bit || v0_mask[j]) ? (vx_mode ? A[15:0] : A[16*j+:16]) : B[16*j+:16];
            else if (vta) S[16*j+:16] = 16'hFFFF;
        end
        32: for (j = 0; j < vecwidth; j = j + 1) begin
            if (j < vl) S[32*j+:32] = (vm_bit || v0_mask[j]) ? (vx_mode ? A[31:0] : A[32*j+:32]) : B[32*j+:32];
            else if (vta) S[32*j+:32] = 32'hFFFFFFFF;
        end
        default: for (j = 0; j < vecwidth; j = j + 1) begin // 64
            if (j < vl) S[64*j+:64] = (vm_bit || v0_mask[j]) ? (vx_mode ? A[63:0] : A[64*j+:64]) : B[64*j+:64];
            else if (vta) S[64*j+:64] = 64'hFFFFFFFFFFFFFFFF;
        end
    endcase
end

endmodule
// verilator lint_on WIDTH
// === END AI-GENERATED FILE ===
