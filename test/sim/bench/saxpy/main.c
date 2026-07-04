#include "tb_cxxrtl_io.h"

// SAXPY (y = a*x + y): the classic level-1 BLAS kernel, and the natural next
// step up from a dot product / matrix-vector multiply -- exercises vmacc in
// a real program for the first time (the RTL directed test only drives it
// with hand-picked signals, not through the real toolchain/pipeline).

#define N 16

extern void saxpyv(int32_t a, int32_t x[N], int32_t y[N]);

int main() {
	int32_t x[N], y[N], expect[N];
	int32_t a = 3;

	for (int i = 0; i < N; i++) {
		x[i] = i + 1;
		y[i] = 100 - i;
		expect[i] = a * x[i] + y[i];
	}

	saxpyv(a, x, y);

	int32_t ok = 1;
	for (int i = 0; i < N; i++) {
		tb_put_u32((uint32_t)y[i]);
		if (y[i] != expect[i]) ok = 0;
	}
	tb_put_u32(ok);
	return ok ? 0 : 1;
}
