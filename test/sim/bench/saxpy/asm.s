.global saxpyv

.section .text

# void saxpyv(int32_t a, int32_t x[16], int32_t y[16])
#
# y = a*x + y (SAXPY, the canonical "level 1 BLAS" kernel and the natural
# next step up from a dot product per the thesis's own framing) computed
# directly with vmacc.vx -- one instruction per group does the multiply and
# the accumulate together, reading y as vd (both source and destination).
saxpyv:
	# a0 = a (scalar), a1 = x[16], a2 = y[16]
	vsetivli zero, 4, e32, m1

	mv t1, a1              # x pointer
	mv t2, a2              # y pointer
	li t0, 4               # 4 groups of 4

.loop:
	vle32.v v1, (t1)       # x
	nop;nop;nop;nop;nop;nop;nop;
	vle32.v v2, (t2)       # y (becomes vd for the macc)
	nop;nop;nop;nop;nop;nop;nop;
	vmacc.vx v2, a0, v1    # v2 = a*x + v2(y)
	nop;nop;nop;nop;nop;nop;nop;
	vse32.v v2, (t2)       # store y = a*x + y
	nop;nop;nop;nop;nop;nop;nop;

	addi t1, t1, 16
	addi t2, t2, 16
	addi t0, t0, -1
	bnez t0, .loop

	ret
