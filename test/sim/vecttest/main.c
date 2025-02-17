#include "tb_cxxrtl_io.h"

// __attribute__((optimize("O3")))
uint32_t dot(int * restrict a, int * restrict b) {
    int result = 0;
    for (int i = 0; i < 10; i++) {
        result += a[i] * b[i];
    }
    return result;
}

int main() {
    tb_puts("Hello world from Hazard3 + CXXRTL!\n");
    int a[10], b[10];
    for (int i = 0; i < 10; i++) {
        a[i] = i * i * 13 % 2;
    }
    tb_put_u32(dot(a, b));
    
    return 0;
}