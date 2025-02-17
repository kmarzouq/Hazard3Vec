#include "tb_cxxrtl_io.h"

extern uint32_t dot(int a[10], int b[10]);

int main() {
	tb_puts("Hello world from Hazard3 + CXXRTL!\n");
	int a[10], b[10];
	for (int i = 0; i < 10; i++)	{
		a[i] = b[i] = i * i * 13 % 2;
	}

	tb_put_u32(dot(a, b));
	
	return 0;
}
