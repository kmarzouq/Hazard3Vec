.section .text
.global dot

dot:
	vsetivli	zero,4,e32,m1,ta,ma # config vector to 4 32 bit elements
	addi    	a4,a0,16 # offsets for loading
	addi     a5,a1,16 
	vle32.v  v2,0(a4)  # load els 5-8 from 1st array
	vle32.v  v4,0(a5)  # load els 5-8 from 2nd array
	vle32.v  v1,0(a0)  # load els 1-4 from 1st array
	vle32.v  v3,0(a1)  # load els 1-4 from 2nd array
	lw       a5,32(a0) # load el 9 from 1st array
	lw       a2,32(a1) # load el 9 from 2nd array
	li       a3,0
	vmul.vv  v2,v2,v4  # multiply els 5-8
	mul      a5,a5,a2  # multiply el 9
	vmadd.vv v1,v3,v2  # multiply els 1-4 and add to products of 5-8 (stored in v1)
	vsetvli  zero,zero,e32,m1,ta,ma # reset config
	vmv.s.x  v2,a3 # v2[0] = a3 = 0
	lw       a3,36(a0) # load el 10 from 1st array
	lw       a0,36(a1) # load el 10 from 2nd array
	vredsum.vs      v1,v1,v2 # v1[0] = sum(v1) + v2[0]
	mul      a0,a0,a3 # multiply el 10
	vmv.x.s  a4,v1 # a4 = v1[0]
	add      a5,a5,a4 # add el 9 product
	add      a0,a0,a5 # add el 10 product
	ret