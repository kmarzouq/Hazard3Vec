#include "tb_cxxrtl_io.h"

#define VL 1000

void notv(int a[VL]) {
	for (int i = 0; i<VL; i++)
		a[i] = !a[i];

}

int main() {
	int a[VL];
	notv(a);
	tb_put_u32(a[20]);

	return 0;
}
