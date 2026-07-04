#include "tb_cxxrtl_io.h"

#define VL 1000

// __attribute__((noinline)) int dot(int a[VL], int b[VL]) {
// 	int sum = 0;
// 	for (int i = 0; i<VL; i++) {
// 		sum += a[i] * b[i];
// 	}
// 	return sum;
// }

extern int dotv(int *a, int *b);

int main() {
	int a[VL], b[VL];
	b[20] = 2;
	a[20] = 1;
	

	return dotv(a, b);
}
