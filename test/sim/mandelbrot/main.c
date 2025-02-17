#include "tb_cxxrtl_io.h"

#define MAX_ITER 50
#define SCALE_FACTOR 8192 // Large denominator for fixed-point arithmetic
#define WIDTH 40
#define HEIGHT 20

int32_t mul(int32_t a, int32_t b) {
	int32_t aa = a < 0 ? a : -a;
	int32_t bb = b < 0 ? b : -b;
	return aa * bb < aa ? (a / SCALE_FACTOR) * b : (a * b) / SCALE_FACTOR;
}
int32_t div(int32_t a, int32_t b) { return a * SCALE_FACTOR / b; }

int32_t mandelbrot(int32_t real, int32_t imag) {
   int32_t r = 0, i = 0;
	int n;

	for (n = 0; n < MAX_ITER; n++)	{
		int32_t r2 = mul(r, r);
		int32_t i2 = mul(i, i);


		if (r2 + i2 > 4 * SCALE_FACTOR)
			break;

		i = (mul(r, i) << 1) + imag;
		r = r2 - i2 + real;
	}

	return n;
}

int draw() {
	char out[WIDTH+1];
	out[WIDTH] = '\0';
	tb_putc('h');
	for (int y = 0; y < HEIGHT * SCALE_FACTOR; y += SCALE_FACTOR) {
		for (int x = 0, i = 0; x < WIDTH * SCALE_FACTOR; x += SCALE_FACTOR, i++) {

			int32_t real = (x - WIDTH*SCALE_FACTOR / 2 << 2) / WIDTH;
			int32_t imag = (y - HEIGHT*SCALE_FACTOR / 2 << 2) / HEIGHT;

			int value = mandelbrot(real, imag);
			char c = (value == MAX_ITER) ? '#' : ' ';

			out[i] = c;
			tb_putc(c);
		}
		tb_putc('\n');
   }
		return 0;
}

int main() {
	return draw();
}
