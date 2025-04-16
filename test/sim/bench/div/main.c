#include "tb_cxxrtl_io.h"

#define VL 1000

void divv(int a[VL], int b[VL]) {
	for (int i = 0; i<VL; i++)
		a[i] = a[i] / b[i];

}

int main() {
	int a[VL], b[VL];
	b[20] = 3;
	a[20] = 24;
	divv(a, b);
	tb_put_u32(a[20]);

	return 0;
}
