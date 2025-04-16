#include "tb_cxxrtl_io.h"

#define VL 1000

void orv(int a[VL], int b[VL]) {
	for (int i = 0; i<VL; i++)
		a[i] |= b[i];

}

int main() {
	int a[VL], b[VL];
	b[20] = 2;
	a[20] = 1;
	orv(a, b);
	tb_put_u32(a[20]);

	return 0;
}
