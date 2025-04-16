#include "tb_cxxrtl_io.h"

#define VL 1000

void addv(int a[VL], int b[VL]) {
	for (int i = 0; i<VL; i++)
		a[i] = a[i] + b[i];

}

int main() {
	int a[VL], b[VL];
	addv(a, b);
	tb_put_u32(a[20]);

	return 0;
}
