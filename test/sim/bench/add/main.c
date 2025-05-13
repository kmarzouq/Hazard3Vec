#include "tb_cxxrtl_io.h"

#define VL 4000

// void addv(char a[VL], char b[VL]) {
// 	for (int i = 0; i<VL; i++)
// 		a[i] = a[i] + b[i];
// }

extern void addv(char *a, char *b);

int main() {
	char a[VL], b[VL];
	b[20] = 2;
	a[20] = 1;
	addv(a, b);
	tb_put_u32(a[20]);

	return 0;
}
