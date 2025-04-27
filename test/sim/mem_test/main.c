// #include "tb_cxxrtl_io.h"

// extern void memt(int a[10]);

int main() {
	// RISC-V assembly inline
	asm volatile (
		"li x6, 6;"
		"li x7, 0;"
		"nop;"
		"vsetvli	 x5,x6,e32,m1,ta,ma;"
		"nop;"
		"vsetvl x5, x6, x7;"
		"nop;"
		"vsetivli x5,4,e32,m1,ta,ma;"
	);


	// tb_puts("Hello world from Hazard3 + CXXRTL!\n");
	// int a[10];

	// // tb_put_u32(&a);
	// memt(a);
	return 0;
}