// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtestbench.h for the primary calling header

#ifndef VERILATED_VTESTBENCH___024ROOT_H_
#define VERILATED_VTESTBENCH___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vtestbench__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtestbench___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    CData/*1:0*/ testbench__DOT__vxrm;
    CData/*0:0*/ testbench__DOT__vxsat_comb;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ testbench__DOT__vtype;
    IData/*31:0*/ testbench__DOT__vl;
    IData/*31:0*/ testbench__DOT__vlenb;
    VlWide<32>/*1023:0*/ testbench__DOT__A;
    VlWide<32>/*1023:0*/ testbench__DOT__B;
    IData/*31:0*/ testbench__DOT__vmask;
    IData/*31:0*/ testbench__DOT__Ovflw;
    VlWide<32>/*1023:0*/ testbench__DOT__dut__DOT__P_comb;
    IData/*31:0*/ __VactIterCount;
    VlDelayScheduler __VdlySched;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtestbench__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vtestbench___024root(Vtestbench__Syms* symsp, const char* v__name);
    ~Vtestbench___024root();
    VL_UNCOPYABLE(Vtestbench___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
