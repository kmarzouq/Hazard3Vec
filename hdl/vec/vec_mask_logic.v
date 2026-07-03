// === AI-GENERATED FILE ===
// RVV 1.0 mask-register logical instructions (funct6, OPMVV only, .mm suffix):
//   011000 vmandn, 011001 vmand, 011010 vmor, 011011 vmxor,
//   011100 vmorn, 011101 vmnand, 011110 vmnor, 011111 vmxnor
// vd.mask[i] = vs2.mask[i] <op> vs1.mask[i] for i < vl; operates directly on
// the packed per-element bits (A=vs1, B=vs2), independent of SEW. Per spec
// these are always unmasked (vm is reused as part of the funct6 space, so
// there is no v0-predication concept here) and the tail is agnostic-only.
module vec_mask_logic #(
    parameter MAX_VECWIDTH = 16,
    parameter XLEN = 32
)(
    input  [5:0] op,
    input  [XLEN-1:0] vl,
    input  [MAX_VECWIDTH*XLEN-1:0] S_old,
    input  [MAX_VECWIDTH*XLEN-1:0] A, // vs1
    input  [MAX_VECWIDTH*XLEN-1:0] B, // vs2
    output reg [MAX_VECWIDTH*XLEN-1:0] S
);

integer j;
reg [MAX_VECWIDTH-1:0] Sbit;

always @(*) begin
    S = S_old;
    Sbit = S_old[MAX_VECWIDTH-1:0];
    for (j = 0; j < MAX_VECWIDTH; j = j + 1) begin
        if (j < vl) begin
            case (op)
                6'b011000: Sbit[j] = B[j] & ~A[j]; // vmandn
                6'b011001: Sbit[j] = B[j] &  A[j]; // vmand
                6'b011010: Sbit[j] = B[j] |  A[j]; // vmor
                6'b011011: Sbit[j] = B[j] ^  A[j]; // vmxor
                6'b011100: Sbit[j] = B[j] | ~A[j]; // vmorn
                6'b011101: Sbit[j] = ~(B[j] & A[j]); // vmnand
                6'b011110: Sbit[j] = ~(B[j] | A[j]); // vmnor
                6'b011111: Sbit[j] = ~(B[j] ^ A[j]); // vmxnor
                default:   Sbit[j] = Sbit[j];
            endcase
        end else Sbit[j] = 1'b1; // tail is always agnostic for mask-logic results
    end
    S[MAX_VECWIDTH-1:0] = Sbit;
end

endmodule
// === END AI-GENERATED FILE ===
