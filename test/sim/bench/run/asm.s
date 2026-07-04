.global rsumv

.section .text

# a0 = pointer to array a
# a1 = pointer to array b
# Using v0-v3 for accumulating sums
# Using v8 for loading data

rsumv:
	vsetivli zero, 4, e32, m1 # Configure vector length to 4, e32, m1

   vle32.v v0, (a1)        # Load all 4 values from b[] into v0
    
	# Initialize pointer and counter
	mv t1, a0               # t0 = pointer to current a[] element
	li t0, 996
    
loop:
	vle32.v v8, (t1)       # Load 4 elements from a[]
	
	vadd.vv v0, v0, v8     # Add loaded values to accumulators
	
	# Update pointer and counter
	addi t1, t1, 16        # Move pointer (4 elements * 4 bytes)
	addi t0, t0, -4        # Decrement counter by 4
	
	bnez t0, loop
    
done:
   #  vse32.v v0, (a1)       # Store accumulated sums back to b[]
	nop; nop; nop; nop; nop; nop; nop;
   ret
