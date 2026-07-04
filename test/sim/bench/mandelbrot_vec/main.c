#include "tb_cxxrtl_io.h"

// Vectorized Mandelbrot set benchmark. The thesis (section 3.7.2) describes
// having "manually optimized vector assembly versions" of this benchmark,
// but the committed ../mandelbrot/main.c is scalar-only -- this fills that
// gap, computing 4 pixels per SIMD group via mandelbrot4v (asm.s) and
// cross-checking every pixel against the scalar algorithm.

#define MAX_ITER 50
#define SCALE_FACTOR 8192
#define WIDTH 40
#define HEIGHT 20

extern void mandelbrot4v(int32_t real[4], int32_t imag[4], int32_t iters[4], int32_t max_iter);

// Arithmetic shift, not '/', to bit-exactly match vsra.vi in asm.s (integer
// division truncates toward zero; an arithmetic shift floors toward -infinity,
// so they disagree by 1 for negative products with a nonzero remainder).
static int32_t smul(int32_t a, int32_t b) { return (a * b) >> 13; }

static int32_t mandelbrot_scalar(int32_t real, int32_t imag) {
	int32_t r = 0, i = 0;
	int n;
	for (n = 0; n < MAX_ITER; n++) {
		int32_t r2 = smul(r, r);
		int32_t i2 = smul(i, i);
		if (r2 + i2 > 4 * SCALE_FACTOR)
			break;
		i = (smul(r, i) << 1) + imag;
		r = r2 - i2 + real;
	}
	return n;
}

int main() {
	int32_t mismatches = 0;

	for (int y = 0; y < HEIGHT; y++) {
		char row[WIDTH + 1];
		row[WIDTH] = '\0';

		for (int x0 = 0; x0 < WIDTH; x0 += 4) {
			int32_t real[4], imag[4], iters[4];

			for (int k = 0; k < 4; k++) {
				int x = x0 + k;
				// Map pixel (x,y) to a fixed-point complex coordinate, same scaling
				// convention as ../mandelbrot/main.c's draw(), just with a plain
				// pixel index instead of a pre-scaled loop variable.
				real[k] = (((x - WIDTH / 2) * SCALE_FACTOR) << 2) / WIDTH;
				imag[k] = (((y - HEIGHT / 2) * SCALE_FACTOR) << 2) / HEIGHT;
			}

			mandelbrot4v(real, imag, iters, MAX_ITER);

			for (int k = 0; k < 4; k++) {
				int32_t expect = mandelbrot_scalar(real[k], imag[k]);
				if (iters[k] != expect)
					mismatches++;
				row[x0 + k] = (iters[k] >= MAX_ITER) ? '#' : ' ';
			}
		}

		tb_puts(row);
		tb_putc('\n');
	}

	tb_put_u32(mismatches); // 0 = every pixel matched the scalar reference
	return mismatches == 0 ? 0 : 1;
}
