.global matvecv

.section .text

# void matvecv(int32_t A[4][4], int32_t x[4], int32_t scratch[16])
#
# Computes y = A*x for a 4x4 matrix A and 4-vector x, one dot product per
# row via vredsum.vs (RVV has no vector->scalar move wired up yet, so each
# row's reduction result is spilled to a 4-word scratch slot with vse32.v;
# the caller picks out element 0 of each slot as y[row]).
matvecv:
	# a0 = A, a1 = x, a2 = scratch

	vsetivli zero, 4, e32, m1

	vle32.v v1, (a1)     # x, reused for every row
	nop;nop;nop;nop;nop;nop;nop;
	vmv.v.i v5, 0        # reduction seed = 0
	nop;nop;nop;nop;nop;nop;nop;

	mv t1, a0            # row pointer into A
	mv t2, a2            # scratch pointer
	li t0, 4             # row counter

.rowloop:
	vle32.v v2, (t1)       # row i of A
	nop;nop;nop;nop;nop;nop;nop;
	vmul.vv v3, v2, v1     # elementwise product
	nop;nop;nop;nop;nop;nop;nop;
	vredsum.vs v4, v3, v5  # v4[0] = sum(v3[*])
	nop;nop;nop;nop;nop;nop;nop;
	vse32.v v4, (t2)       # spill (only element 0 is used)
	nop;nop;nop;nop;nop;nop;nop;

	addi t1, t1, 16
	addi t2, t2, 16
	addi t0, t0, -1
	bnez t0, .rowloop

	ret
