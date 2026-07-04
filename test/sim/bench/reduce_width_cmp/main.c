#include "tb_cxxrtl_io.h"

// Direct throughput comparison: sum the same 64 elements (same values) via
// vredsum.vs at SEW=8 (16 elements/instruction, 4 groups) vs SEW=32 (4
// elements/instruction, 16 groups), to measure how much narrower SEW
// actually helps when the reduction itself (not a synthetic microbenchmark)
// is the workload.

#define N 64

extern void sum8v_out(int8_t data[N], int32_t out[4]);
extern void sum32v_out(int32_t data[N], int32_t out[4]);

static inline uint32_t rdcycle(void) {
	uint32_t c;
	asm volatile ("csrr %0, mcycle" : "=r"(c));
	return c;
}

int main() {
	int8_t data8[N];
	int32_t data32[N];
	int32_t out[4];
	uint32_t t0, t1;

	int32_t expect = 0;
	for (int i = 0; i < N; i++) {
		data8[i] = (int8_t)(i + 1);
		data32[i] = i + 1;
		expect += i + 1;
	}

	t0 = rdcycle();
	sum8v_out(data8, out);
	t1 = rdcycle();
	int32_t sum8 = out[0]; // fits in the low word; expect=2080 well within 32 bits
	tb_puts("sum8v cycles: ");
	tb_put_u32(t1 - t0);

	t0 = rdcycle();
	sum32v_out(data32, out);
	t1 = rdcycle();
	int32_t sum32 = out[0];
	tb_puts("sum32v cycles: ");
	tb_put_u32(t1 - t0);

	tb_puts("sum8=");
	tb_put_u32((uint32_t)sum8);
	tb_puts("sum32=");
	tb_put_u32((uint32_t)sum32);

	int32_t ok = (sum8 == expect) && (sum32 == expect);
	tb_puts("ok=");
	tb_put_u32(ok);
	return ok ? 0 : 1;
}
