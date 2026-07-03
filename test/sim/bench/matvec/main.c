#include "tb_cxxrtl_io.h"

// Matrix-vector multiply benchmark (y = A*x, 4x4 * 4x1), inspired by the
// thesis's framing of dot products as "a special case of matrix
// multiplications" -- this is that generalization, exercising vle32.v,
// vmul.vv and vredsum.vs (a row of A dotted with x) together.

extern void matvecv(int32_t A[4][4], int32_t x[4], int32_t scratch[16]);

int32_t scalar_matvec(int32_t A[4][4], int32_t x[4], int32_t y[4]) {
	int32_t check = 0;
	for (int i = 0; i < 4; i++) {
		int32_t sum = 0;
		for (int j = 0; j < 4; j++)
			sum += A[i][j] * x[j];
		y[i] = sum;
		check += y[i];
	}
	return check;
}

int main() {
	int32_t A[4][4] = {
		{ 1,  2,  3,  4},
		{ 5,  6,  7,  8},
		{ 9, 10, 11, 12},
		{13, 14, 15, 16},
	};
	int32_t x[4] = {1, 2, 3, 4};
	int32_t scratch[16];
	int32_t y[4];

	matvecv(A, x, scratch);
	for (int i = 0; i < 4; i++)
		y[i] = scratch[i * 4];

	int32_t expect[4];
	scalar_matvec(A, x, expect); // cross-check against a plain scalar implementation

	tb_put_u32(y[0]);
	tb_put_u32(y[1]);
	tb_put_u32(y[2]);
	tb_put_u32(y[3]);

	int32_t ok = 1;
	for (int i = 0; i < 4; i++)
		if (y[i] != expect[i]) ok = 0;
	tb_put_u32(ok); // 1 = PASS, 0 = FAIL

	return ok ? 0 : 1;
}
