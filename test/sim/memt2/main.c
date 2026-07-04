int main() {
    // RISC-V assembly inline
    int a[8];
    asm volatile (
        "mv t0, %0\n"
        "nop\n"
        "nop\n"
        "li t1, 1\n"
        "li t2, 2\n"
        "li t3, 3\n"
        "li t4, 4\n"
        "sw t1, 0(t0)\n"
        "sw t2, 4(t0)\n"
        "sw t3, 8(t0)\n"
        "sw t4, 12(t0)\n"
        "li t1, 6\n"
        "li t2, 7\n"
        "li t3, 8\n"
        "li t4, 9\n"
        "sw t1, 16(t0)\n"
        "sw t2, 20(t0)\n"
        "sw t3, 24(t0)\n"
        "sw t4, 28(t0)\n"
        "li t1, 8;\n"
        "vsetvli     t2,t1,e32,m2,ta,ma;\n"
        //"vle32.v v0, (t0)\n"
        "nop\n"
        "nop\n"
        "vle32.v v0, (t0)\n"
        "nop\n"
        "nop\n"
		"li t1, 4;\n"
        "vsetvli     t2,t1,e32,m1,ta,ma;\n"
        "nop\n"
        "nop\n"
        "vadd.vv v0, v0, v0\n"
		"nop\n"
        "nop\n"
		"vse32.v v0, (t0)\n"
		"nop\n"
        "nop\n"
		"vle32.v v1, (t0)\n"
        : // outputs
        : "r"(a)              // Input: address of array 'a'
        : "t0", "t1", "t2", "t3" 
    );

    return 0;
}