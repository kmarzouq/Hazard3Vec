#include "tb_cxxrtl_io.h"

int dot(int a[10], int b[10]) {
	int result = 0;
	for (int i = 0; i < 10; i++) {
		result += a[i] * b[i];
	}
	return result;
}


int main() {
	tb_puts("Hello world from Hazard3 + CXXRTL!\n");
	int a[10], b[10];
	for (int i = 0; i < 10; i++)	{
		a[i] = b[i] = i * i * 13 % 2;
	}
	
	return dot(a, b);
}
