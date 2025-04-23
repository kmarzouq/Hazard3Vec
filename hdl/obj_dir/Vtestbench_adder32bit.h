// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtestbench.h for the primary calling header

#ifndef VERILATED_VTESTBENCH_ADDER32BIT_H_
#define VERILATED_VTESTBENCH_ADDER32BIT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vtestbench__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtestbench_adder32bit final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        VL_OUT8(Cout,0,0);
        VL_IN8(Cin,0,0);
        VL_OUT8(Ovflw,0,0);
        CData/*0:0*/ cla1__DOT____Vcellout__c1____pinNumber6;
        CData/*0:0*/ cla1__DOT____Vcellout__c2____pinNumber5;
        CData/*0:0*/ cla1__DOT____Vcellout__c3____pinNumber5;
        CData/*0:0*/ cla1__DOT____Vcellinp__c3____pinNumber1;
        CData/*0:0*/ cla1__DOT____Vcellout__c4____pinNumber5;
        CData/*0:0*/ cla1__DOT____Vcellinp__c4____pinNumber1;
        CData/*0:0*/ cla2__DOT____Vcellout__c1____pinNumber5;
        CData/*0:0*/ cla2__DOT____Vcellinp__c1____pinNumber1;
        CData/*0:0*/ cla2__DOT____Vcellout__c2____pinNumber5;
        CData/*0:0*/ cla2__DOT____Vcellinp__c2____pinNumber1;
        CData/*0:0*/ cla2__DOT____Vcellout__c3____pinNumber5;
        CData/*0:0*/ cla2__DOT____Vcellinp__c3____pinNumber1;
        CData/*0:0*/ cla2__DOT____Vcellout__c4____pinNumber5;
        CData/*0:0*/ cla2__DOT____Vcellinp__c4____pinNumber1;
        CData/*0:0*/ cla3__DOT____Vcellout__c1____pinNumber5;
        CData/*0:0*/ cla3__DOT____Vcellinp__c1____pinNumber1;
        CData/*0:0*/ cla3__DOT____Vcellout__c2____pinNumber5;
        CData/*0:0*/ cla3__DOT____Vcellinp__c2____pinNumber1;
        CData/*0:0*/ cla3__DOT____Vcellout__c3____pinNumber5;
        CData/*0:0*/ cla3__DOT____Vcellinp__c3____pinNumber1;
        CData/*0:0*/ cla3__DOT____Vcellout__c4____pinNumber5;
        CData/*0:0*/ cla3__DOT____Vcellinp__c4____pinNumber1;
        CData/*0:0*/ cla4__DOT____Vcellout__c1____pinNumber5;
        CData/*0:0*/ cla4__DOT____Vcellinp__c1____pinNumber1;
        CData/*0:0*/ cla4__DOT____Vcellout__c2____pinNumber5;
        CData/*0:0*/ cla4__DOT____Vcellinp__c2____pinNumber1;
        CData/*0:0*/ cla4__DOT____Vcellout__c3____pinNumber5;
        CData/*0:0*/ cla4__DOT____Vcellinp__c3____pinNumber1;
        CData/*0:0*/ cla4__DOT____Vcellout__c4____pinNumber5;
        CData/*0:0*/ cla4__DOT____Vcellinp__c4____pinNumber1;
        CData/*0:0*/ cla5__DOT____Vcellout__c1____pinNumber5;
        CData/*0:0*/ cla5__DOT____Vcellinp__c1____pinNumber1;
        CData/*0:0*/ cla5__DOT____Vcellout__c2____pinNumber5;
        CData/*0:0*/ cla5__DOT____Vcellinp__c2____pinNumber1;
        CData/*0:0*/ cla5__DOT____Vcellout__c3____pinNumber5;
        CData/*0:0*/ cla5__DOT____Vcellinp__c3____pinNumber1;
        CData/*0:0*/ cla5__DOT____Vcellout__c4____pinNumber5;
        CData/*0:0*/ cla5__DOT____Vcellinp__c4____pinNumber1;
        CData/*0:0*/ cla6__DOT____Vcellout__c1____pinNumber5;
        CData/*0:0*/ cla6__DOT____Vcellinp__c1____pinNumber1;
        CData/*0:0*/ cla6__DOT____Vcellout__c2____pinNumber5;
        CData/*0:0*/ cla6__DOT____Vcellinp__c2____pinNumber1;
        CData/*0:0*/ cla6__DOT____Vcellout__c3____pinNumber5;
        CData/*0:0*/ cla6__DOT____Vcellinp__c3____pinNumber1;
        CData/*0:0*/ cla6__DOT____Vcellout__c4____pinNumber5;
        CData/*0:0*/ cla6__DOT____Vcellinp__c4____pinNumber1;
        CData/*0:0*/ cla7__DOT____Vcellout__c1____pinNumber5;
        CData/*0:0*/ cla7__DOT____Vcellinp__c1____pinNumber1;
        CData/*0:0*/ cla7__DOT____Vcellout__c2____pinNumber5;
        CData/*0:0*/ cla7__DOT____Vcellinp__c2____pinNumber1;
        CData/*0:0*/ cla7__DOT____Vcellout__c3____pinNumber5;
        CData/*0:0*/ cla7__DOT____Vcellinp__c3____pinNumber1;
        CData/*0:0*/ cla7__DOT____Vcellout__c4____pinNumber5;
        CData/*0:0*/ cla7__DOT____Vcellinp__c4____pinNumber1;
        CData/*0:0*/ cla8__DOT____Vcellout__c1____pinNumber5;
        CData/*0:0*/ cla8__DOT____Vcellinp__c1____pinNumber1;
        CData/*0:0*/ cla8__DOT____Vcellout__c2____pinNumber5;
        CData/*0:0*/ cla8__DOT____Vcellinp__c2____pinNumber1;
        CData/*0:0*/ cla8__DOT____Vcellout__c3____pinNumber5;
        CData/*0:0*/ cla8__DOT____Vcellinp__c3____pinNumber1;
        CData/*0:0*/ cla8__DOT____Vcellout__c4____pinNumber5;
    };
    struct {
        CData/*0:0*/ cla8__DOT____Vcellinp__c4____pinNumber1;
        VL_OUT(S,31,0);
        VL_IN(A,31,0);
        VL_IN(Bin,31,0);
    };

    // INTERNAL VARIABLES
    Vtestbench__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vtestbench_adder32bit(Vtestbench__Syms* symsp, const char* v__name);
    ~Vtestbench_adder32bit();
    VL_UNCOPYABLE(Vtestbench_adder32bit);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
