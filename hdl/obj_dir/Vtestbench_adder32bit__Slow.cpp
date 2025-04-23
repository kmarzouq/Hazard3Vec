// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtestbench.h for the primary calling header

#include "Vtestbench__pch.h"
#include "Vtestbench__Syms.h"
#include "Vtestbench_adder32bit.h"

void Vtestbench_adder32bit___ctor_var_reset(Vtestbench_adder32bit* vlSelf);

Vtestbench_adder32bit::Vtestbench_adder32bit(Vtestbench__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vtestbench_adder32bit___ctor_var_reset(this);
}

void Vtestbench_adder32bit::__Vconfigure(bool first) {
    if (false && first) {}  // Prevent unused
}

Vtestbench_adder32bit::~Vtestbench_adder32bit() {
}
