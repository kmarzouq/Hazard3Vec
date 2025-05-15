module mask #(
    parameter VLEN = 16
)(
    input vm, // 1: unmasked, 0: use v0.mask
    input [VLEN-1:0] v0_mask,
    output [VLEN-1:0] mask_out
);

assign mask_out = (vm) ? {VLEN{1'b1}} : v0_mask;

endmodule