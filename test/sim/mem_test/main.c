// #include "tb_cxxrtl_io.h"

// extern void memt(int a[10]);

int main() {
	// RISC-V assembly inline
	asm volatile (
		"li x6, 6;"
		"li x7, 0b11000000;"
		"nop;"
		"vsetvli	 x5,x6,e32,m1,ta,ma;"
		// "nop;"
		// "vsetvl x5, x6, x7;"
		// "nop;"
		// "vsetivli x5,4,e32,m1,ta,ma;"
		// "nop;"
		// "vsetvli	 x5,x0,e16,m1,ta,ma;" // vl should be vlmax
		// "nop;"
		// "vsetvli	 x0,x0,e8,m1,ta,ma;" // vl should remain
		"li x5, 4;"
		"vle32.v v0, (x5);"
	);


	// tb_puts("Hello world from Hazard3 + CXXRTL!\n");
	// int a[10];

	// // tb_put_u32(&a);
	// memt(a);
	return 0;
}