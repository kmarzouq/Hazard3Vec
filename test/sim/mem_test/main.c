#include "tb_cxxrtl_io.h"

extern void memt(int a[10]);

int main() {
	tb_puts("Hello world from Hazard3 + CXXRTL!\n");
	int a[10];

	// tb_put_u32(&a);
	memt(a);
	return 0;
}
