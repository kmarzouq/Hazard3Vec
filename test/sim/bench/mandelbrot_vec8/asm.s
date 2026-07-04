.global mandelbrot16v

.section .text

# void mandelbrot16v(int8_t real[16], int8_t imag[16], int8_t iters[16], int32_t max_iter)
#
# Same algorithm as ../mandelbrot_vec/asm.s but at SEW=8 (16 pixels per group
# instead of 4), to see whether packing 4x more lanes per instruction is
# where this vector unit actually wins over the scalar pipeline.
#
# There's no widening multiply wired up yet, and a plain 8-bit vmul.vv only
# keeps the low 8 bits of the product (not enough range for the fixed-point
# scaling this needs), so each "scaled multiply" (a*b) >> 3 is built from the
# low half (vmul.vv) and signed high half (vmulh.vv) of the real 16-bit
# product, funnel-shifted back together:
#   result = (mulh << (8-3)) | (mul >>u 3)
# which is exactly the low 8 bits of the true arithmetic-shifted product.
#
# Fixed-point scale is 8 (not 32, like the SEW=32 version) because the
# escape-radius growth in the iteration that first exceeds the threshold can
# reach roughly 10x the scale factor in the worst case, and that has to fit
# in signed 8 bits (+/-127) -- see the writeup for the derivation.
mandelbrot16v:
	# a0 = real[16], a1 = imag[16], a2 = iters[16] (output), a3 = max_iter

	vsetivli zero, 16, e8, m1

	vle8.v v1, (a0)       # real
	nop;nop;nop;nop;nop;nop;nop;
	vle8.v v2, (a1)       # imag
	nop;nop;nop;nop;nop;nop;nop;
	vmv.v.i v3, 0         # r state
	nop;nop;nop;nop;nop;nop;nop;
	vmv.v.i v4, 0         # i state
	nop;nop;nop;nop;nop;nop;nop;
	vmv.v.i v5, 0         # iteration count
	nop;nop;nop;nop;nop;nop;nop;

	li t3, 32             # threshold = 4 * SCALE_FACTOR(8)
	mv t0, a3

.iterloop:
	# --- r2 = (r*r) >> 3, into v6 ---
	vmul.vv v13, v3, v3
	nop;nop;nop;nop;nop;nop;nop;
	vmulh.vv v14, v3, v3
	nop;nop;nop;nop;nop;nop;nop;
	vsrl.vi v13, v13, 3
	nop;nop;nop;nop;nop;nop;nop;
	vsll.vi v14, v14, 5
	nop;nop;nop;nop;nop;nop;nop;
	vor.vv v6, v13, v14
	nop;nop;nop;nop;nop;nop;nop;

	# --- i2 = (i*i) >> 3, into v7 ---
	vmul.vv v13, v4, v4
	nop;nop;nop;nop;nop;nop;nop;
	vmulh.vv v14, v4, v4
	nop;nop;nop;nop;nop;nop;nop;
	vsrl.vi v13, v13, 3
	nop;nop;nop;nop;nop;nop;nop;
	vsll.vi v14, v14, 5
	nop;nop;nop;nop;nop;nop;nop;
	vor.vv v7, v13, v14
	nop;nop;nop;nop;nop;nop;nop;

	# --- mag2 = r2 + i2, escape mask (unsigned compare: r2,i2 are both >= 0) ---
	vadd.vv v8, v6, v7
	nop;nop;nop;nop;nop;nop;nop;
	vmsleu.vx v0, v8, t3
	nop;nop;nop;nop;nop;nop;nop;

	# --- iteration count: +1 only for lanes still escaping ---
	vadd.vi v12, v5, 1
	nop;nop;nop;nop;nop;nop;nop;
	vmerge.vvm v5, v5, v12, v0
	nop;nop;nop;nop;nop;nop;nop;

	# --- ri = (r*i) >> 3, then new_i = 2*ri + imag ---
	vmul.vv v13, v3, v4
	nop;nop;nop;nop;nop;nop;nop;
	vmulh.vv v14, v3, v4
	nop;nop;nop;nop;nop;nop;nop;
	vsrl.vi v13, v13, 3
	nop;nop;nop;nop;nop;nop;nop;
	vsll.vi v14, v14, 5
	nop;nop;nop;nop;nop;nop;nop;
	vor.vv v11, v13, v14
	nop;nop;nop;nop;nop;nop;nop;
	vsll.vi v11, v11, 1
	nop;nop;nop;nop;nop;nop;nop;
	vadd.vv v9, v11, v2
	nop;nop;nop;nop;nop;nop;nop;

	# --- new_r = r2 - i2 + real ---
	vsub.vv v10, v6, v7
	nop;nop;nop;nop;nop;nop;nop;
	vadd.vv v10, v10, v1
	nop;nop;nop;nop;nop;nop;nop;

	# --- commit new state, freezing already-escaped lanes ---
	vmerge.vvm v4, v4, v9, v0
	nop;nop;nop;nop;nop;nop;nop;
	vmerge.vvm v3, v3, v10, v0
	nop;nop;nop;nop;nop;nop;nop;

	addi t0, t0, -1
	bnez t0, .iterloop

	vse8.v v5, (a2)
	nop;nop;nop;nop;nop;nop;nop;

	ret
