int main() {
	int a[4];
	asm volatile (
		  "mv t0, %0\n"         // Load address of array 'a' into t0
		  "li t1, 1\n"
		  "li t2, 2\n"
		  "li t3, 3\n"
		  "sw t1, 0(t0)\n"
		  "sw t2, 4(t0)\n"
		  "sw t3, 8(t0)\n"
		  "nop\n"
		  "lw t1, 0(t0)\n"      // Load from a[0]
		  "lw t1, 4(t0)\n"      // Load from a[1]
		  "lw t1, 8(t0)\n"      // Load from a[2]
		  "vsetvli x5,x6,e32,m2,ta,ma"
		  : // outputs
		  : "r"(a)              // Input: address of array 'a'
		  : "t0", "t1", "t2", "t3" // Clobbers: tell compiler we modify these regs
	);
	return 0;
}