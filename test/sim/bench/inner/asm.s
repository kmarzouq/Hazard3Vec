.global addv

.section .text

addv:
	# a0: int* a
	# a1: int* b

	mv a2, a0 # Copy a to a2 for clarity as destination

	li t0,4000 # Loop counter (VL)
	li t1, 16
	vsetivli zero, 16, e8, m1 # Configure vector length to 4, e32, m1

.loop:
	vle8.v v8, (a0) # Load vector from a
	vle8.v v9, (a1) # Load vector from b

	vadd.vv v8, v8, v9 # Vector add: v8 = v8 + v9

	#vse.v v8, (a2) # Store result back to a (a2)
	nop;nop;nop;nop;nop;nop;nop;
 
	# slli t2, t1, 2  # Bytes processed = VL * 4 (size of int)
	addi a0, a0, 1 # Advance pointer a
	addi a1, a1, 1 # Advance pointer b
	# addi a2, a2, 1 # Advance pointer a2

	sub t0, t0, t1 # Decrement loop counter
	bnez t0, .loop # Loop if counter is not zero

	ret