.global sum8v_out
.global sum32v_out

.section .text

# void sum8v_out(int8_t data[64], int64_t *out)
#
# Sums 64 int8 elements, 16 (one full register) at a time, chaining the
# running sum through vredsum.vs's scalar seed operand each group. The
# destination register always holds the full 64-bit accumulator in its low
# 64 bits regardless of SEW (see hdl/vec/reduction.v), so chaining across
# groups loses no precision even though each individual element is only 8
# bits and the running total (up to 2080 for this benchmark's data) would
# overflow an 8-bit lane on its own.
sum8v_out:
	# a0 = data[64] (int8), a1 = out (8 bytes)
	vsetivli zero, 16, e8, m1

	vmv.v.i v2, 0          # running sum seed, starts at 0
	nop;nop;nop;nop;nop;nop;nop;

	mv t0, a0
	li t1, 4               # 4 groups of 16

.loop8:
	vle8.v v1, (t0)
	nop;nop;nop;nop;nop;nop;nop;
	vredsum.vs v2, v1, v2
	nop;nop;nop;nop;nop;nop;nop;

	addi t0, t0, 16
	addi t1, t1, -1
	bnez t1, .loop8

	vse32.v v2, (a1)       # spill the whole register; low 64 bits (2 words) are the real sum
	nop;nop;nop;nop;nop;nop;nop;
	ret

# void sum32v_out(int32_t data[64], int64_t *out)
#
# Same total element count (64) and same values, but as SEW=32 (4
# elements/group instead of 16), so 16 groups instead of 4.
sum32v_out:
	# a0 = data[64] (int32), a1 = out (8 bytes)
	vsetivli zero, 4, e32, m1

	vmv.v.i v2, 0
	nop;nop;nop;nop;nop;nop;nop;

	mv t0, a0
	li t1, 16

.loop32:
	vle32.v v1, (t0)
	nop;nop;nop;nop;nop;nop;nop;
	vredsum.vs v2, v1, v2
	nop;nop;nop;nop;nop;nop;nop;

	addi t0, t0, 16
	addi t1, t1, -1
	bnez t1, .loop32

	vse32.v v2, (a1)
	nop;nop;nop;nop;nop;nop;nop;
	ret
