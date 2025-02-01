.section .text
.global dot

dot:
vsetivli        zero,4,e32,m1,ta,ma
addi    a4,a0,16
addi    a5,a1,16
vle32.v v2,0(a4)
vle32.v v4,0(a5)
vle32.v v1,0(a0)
vle32.v v3,0(a1)
lw      a5,32(a0)
lw      a2,32(a1)
li      a3,0
vmul.vv v2,v2,v4
mul     a5,a5,a2
vmadd.vv        v1,v3,v2
vsetvli zero,zero,e32,m1,ta,ma
vmv.s.x v2,a3
lw      a3,36(a0)
lw      a0,36(a1)
vredsum.vs      v1,v1,v2
mul     a0,a0,a3
vmv.x.s a4,v1
add     a5,a5,a4
add     a0,a0,a5
ret