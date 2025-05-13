.global dotv

.section .text

# Assuming VL is a power of two and configured in vtype
dotv:
	mv   t0, zero          # sum
	li t4, 4
	vsetivli zero, 4, e32, m1 
	li t0, 1000

	# Load base addresses of a and b arrays
	add  t1, s0, s1        # s1 contains offset to array a from function argument
	add  t2, s0, s3        # s3 contains offset to array b from function argument

.loop:
	vle32.v v0, (t1) 
	vle32.v v1, (t2)       
	vmul.vv v2, v0, v1  

	# Sum the elements of v2 into t0
#  vredsum.vs t0, v2, t0  # Accumulate sum of v2 into t0
	nop
	nop

	add  t1, t1, 16
	add  t2, t2, 16

	sub t0, t0, t4
	bnez t0, .loop

	mv   a0, t0
	ret