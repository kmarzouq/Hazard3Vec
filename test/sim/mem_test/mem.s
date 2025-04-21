.section .text
.global memt

memt:
	nop
	nop
	addi a0, a0, 0
	vsetivli	zero,4,e32,m1,ta,ma # config vector to 4 32 bit elements
	vle32.v  v1, (a0)
	ret