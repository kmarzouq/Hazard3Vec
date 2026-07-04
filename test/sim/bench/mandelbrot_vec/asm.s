.global mandelbrot4v

.section .text

# void mandelbrot4v(int32_t real[4], int32_t imag[4], int32_t iters[4], int32_t max_iter)
#
# Computes the Mandelbrot escape-iteration count for 4 pixels in parallel
# (SEW=32, vl=4), fixed-point scaled by 2^13 (=8192) like the scalar
# reference in ../mandelbrot/main.c. Each pixel is an independent SIMD lane;
# lanes that have already escaped are frozen (not updated) using vmerge with
# a per-iteration "still escaping" mask from vmsle.vx, instead of a per-pixel
# early-exit branch (there isn't one -- this is the point of doing it in
# vector form).
mandelbrot4v:
	# a0 = real[4], a1 = imag[4], a2 = iters[4] (output), a3 = max_iter

	vsetivli zero, 4, e32, m1

	vle32.v v1, (a0)      # real (constant per pixel)
	nop;nop;nop;nop;nop;nop;nop;
	vle32.v v2, (a1)      # imag (constant per pixel)
	nop;nop;nop;nop;nop;nop;nop;
	vmv.v.i v3, 0         # r state, init 0
	nop;nop;nop;nop;nop;nop;nop;
	vmv.v.i v4, 0         # i state, init 0
	nop;nop;nop;nop;nop;nop;nop;
	vmv.v.i v5, 0         # iteration count, init 0
	nop;nop;nop;nop;nop;nop;nop;

	li t3, 32768          # threshold = 4 * SCALE_FACTOR(8192), for the escape test
	mv t0, a3             # iteration counter (counts down from max_iter)

.iterloop:
	vmul.vv v6, v3, v3    # r*r (raw)
	nop;nop;nop;nop;nop;nop;nop;
	vsra.vi v6, v6, 13    # r2 = (r*r) / SCALE_FACTOR
	nop;nop;nop;nop;nop;nop;nop;
	vmul.vv v7, v4, v4    # i*i (raw)
	nop;nop;nop;nop;nop;nop;nop;
	vsra.vi v7, v7, 13    # i2
	nop;nop;nop;nop;nop;nop;nop;
	vadd.vv v8, v6, v7    # mag2 = r2 + i2
	nop;nop;nop;nop;nop;nop;nop;

	vmsle.vx v0, v8, t3   # mask = (mag2 <= threshold), i.e. "still escaping"
	nop;nop;nop;nop;nop;nop;nop;

	vadd.vi v12, v5, 1        # candidate incremented count (unmasked scratch)
	nop;nop;nop;nop;nop;nop;nop;
	vmerge.vvm v5, v5, v12, v0  # commit: only still-escaping lanes get +1
	nop;nop;nop;nop;nop;nop;nop;

	vmul.vv v11, v3, v4   # r*i (raw)
	nop;nop;nop;nop;nop;nop;nop;
	vsra.vi v11, v11, 13  # scaled
	nop;nop;nop;nop;nop;nop;nop;
	vsll.vi v11, v11, 1   # 2*r*i
	nop;nop;nop;nop;nop;nop;nop;
	vadd.vv v9, v11, v2   # new_i = 2*r*i + imag (unmasked scratch)
	nop;nop;nop;nop;nop;nop;nop;

	vsub.vv v10, v6, v7   # r2 - i2
	nop;nop;nop;nop;nop;nop;nop;
	vadd.vv v10, v10, v1  # new_r = r2 - i2 + real (unmasked scratch)
	nop;nop;nop;nop;nop;nop;nop;

	vmerge.vvm v4, v4, v9, v0   # commit new_i, freezing already-escaped lanes
	nop;nop;nop;nop;nop;nop;nop;
	vmerge.vvm v3, v3, v10, v0  # commit new_r, freezing already-escaped lanes
	nop;nop;nop;nop;nop;nop;nop;

	addi t0, t0, -1
	bnez t0, .iterloop

	vse32.v v5, (a2)      # spill the 4 iteration counts to the output array
	nop;nop;nop;nop;nop;nop;nop;

	ret
