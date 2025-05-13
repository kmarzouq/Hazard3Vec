#include "tb_cxxrtl_io.h"

#define VL 1000

// void rsum(int a[VL], int b[4]) {
// 	int sum;
// 	for (int i = 0; i<VL-4; i+=4) {
// 		b[0] += a[i];
// 		b[1] += a[i+1];
// 		b[2] += a[i+2];
// 		b[3] += a[i+3];
// 	}
// }

extern void rsumv(int *a, int *b);

int main() {
	int a[VL], b[4];
	b[0] = 1;
	// b[1] = 2;
	// b[2] = 3;
	// b[3] = 4;
	a[20] = 1;
	rsumv(a, b);
	// tb_put_u32(a[20]);

	return b[2];
}
