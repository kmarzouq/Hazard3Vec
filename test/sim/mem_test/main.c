int main() {
	// RISC-V assembly inline
	int a[3];
	asm volatile (
		"mv t0, %0\n"
		"nop\n"
		"nop\n"
		"li t1, 1\n"
		"li t2, 2\n"
		"li t3, 3\n"
		"sw t1, 0(t0)\n"
		"sw t2, 4(t0)\n"
		"sw t3, 8(t0)\n"
		"li t1, 3;\n"
		"vsetvli	 t2,t1,e32,m2,ta,ma;\n"
		"vle32.v v0, (t0)\n"
		"vadd.vv v1, v0, v0\n"
		"vsub.vv v1, v0, v1\n"
		"nop\n"
		"nop\n"
		"vmul.vv v1, v0, v0\n"
		"vdiv.vv v1, v1, v0\n"
		// "lw t1, 8(t0);"
		: // outputs
		: "r"(a)              // Input: address of array 'a'
		: "t0", "t1", "t2", "t3"
	);

	return 0;
}