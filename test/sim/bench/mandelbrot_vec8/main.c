#include "tb_cxxrtl_io.h"

// 8-bit vectorized Mandelbrot: same problem size as ../mandelbrot_vec (so
// cycle counts are directly comparable), but SEW=8 packs 16 pixels per
// vector register instead of 4. The point is to see whether the extra
// per-instruction nop overhead (paid once per instruction regardless of
// SEW) gets amortized well enough by the 4x lane count to actually win.

#define MAX_ITER 50
#define SCALE_FACTOR 8   // 2^3 -- see asm.s for why this (not 32, like the SEW=32 version)
#define WIDTH 48         // must be a multiple of 16 (one SEW=8 group); ../mandelbrot_vec uses 40 --
                         // not a multiple of 4 and 16 both, so this is 960 px vs its 800 (normalize
                         // per-pixel-iteration when comparing cycle counts)
#define HEIGHT 20

extern void mandelbrot16v(int8_t real[16], int8_t imag[16], int8_t iters[16], int32_t max_iter);

// Mirrors the hardware's funnel-shifted fixed multiply exactly: int8_t
// arithmetic in C wraps modulo 256 on assignment (same as the vector ALU),
// so this reference is bit-exact with the vector kernel, not just close.
static int8_t smul8(int8_t a, int8_t b) {
	int16_t p = (int16_t)a * (int16_t)b;
	return (int8_t)(p >> 3);
}

static int32_t mandelbrot_scalar8(int8_t real, int8_t imag) {
	int8_t r = 0, i = 0;
	int n;
	for (n = 0; n < MAX_ITER; n++) {
		int8_t r2 = smul8(r, r);
		int8_t i2 = smul8(i, i);
		uint8_t mag2 = (uint8_t)r2 + (uint8_t)i2; // unsigned: r2,i2 are always >= 0
		if (mag2 > 4 * SCALE_FACTOR)
			break;
		int8_t new_i = (int8_t)((smul8(r, i) << 1) + imag);
		int8_t new_r = (int8_t)(r2 - i2 + real);
		i = new_i;
		r = new_r;
	}
	return n;
}

int main() {
	int32_t mismatches = 0;

	for (int y = 0; y < HEIGHT; y++) {
		char row[WIDTH + 1];
		row[WIDTH] = '\0';

		for (int x0 = 0; x0 < WIDTH; x0 += 16) {
			int8_t real[16], imag[16], iters[16];

			for (int k = 0; k < 16; k++) {
				int x = x0 + k;
				real[k] = (int8_t)((((x - WIDTH / 2) * SCALE_FACTOR) << 2) / WIDTH);
				imag[k] = (int8_t)((((y - HEIGHT / 2) * SCALE_FACTOR) << 2) / HEIGHT);
			}

			mandelbrot16v(real, imag, iters, MAX_ITER);

			for (int k = 0; k < 16; k++) {
				int32_t expect = mandelbrot_scalar8(real[k], imag[k]);
				if (iters[k] != expect)
					mismatches++;
				row[x0 + k] = (iters[k] >= MAX_ITER) ? '#' : ' ';
			}
		}

		tb_puts(row);
		tb_putc('\n');
	}

	tb_put_u32(mismatches);
	return mismatches == 0 ? 0 : 1;
}
