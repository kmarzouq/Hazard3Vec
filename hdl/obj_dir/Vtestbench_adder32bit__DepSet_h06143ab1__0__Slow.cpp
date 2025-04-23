// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtestbench.h for the primary calling header

#include "Vtestbench__pch.h"
#include "Vtestbench_adder32bit.h"

VL_ATTR_COLD void Vtestbench_adder32bit___ctor_var_reset(Vtestbench_adder32bit* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtestbench__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtestbench_adder32bit___ctor_var_reset\n"); );
    // Body
    vlSelf->Cout = VL_RAND_RESET_I(1);
    vlSelf->S = VL_RAND_RESET_I(32);
    vlSelf->A = VL_RAND_RESET_I(32);
    vlSelf->Bin = VL_RAND_RESET_I(32);
    vlSelf->Cin = VL_RAND_RESET_I(1);
    vlSelf->Ovflw = VL_RAND_RESET_I(1);
    vlSelf->cla1__DOT____Vcellout__c1____pinNumber6 = VL_RAND_RESET_I(1);
    vlSelf->cla1__DOT____Vcellout__c2____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla1__DOT____Vcellout__c3____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla1__DOT____Vcellinp__c3____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla1__DOT____Vcellout__c4____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla1__DOT____Vcellinp__c4____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla2__DOT____Vcellout__c1____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla2__DOT____Vcellinp__c1____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla2__DOT____Vcellout__c2____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla2__DOT____Vcellinp__c2____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla2__DOT____Vcellout__c3____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla2__DOT____Vcellinp__c3____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla2__DOT____Vcellout__c4____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla2__DOT____Vcellinp__c4____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla3__DOT____Vcellout__c1____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla3__DOT____Vcellinp__c1____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla3__DOT____Vcellout__c2____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla3__DOT____Vcellinp__c2____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla3__DOT____Vcellout__c3____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla3__DOT____Vcellinp__c3____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla3__DOT____Vcellout__c4____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla3__DOT____Vcellinp__c4____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla4__DOT____Vcellout__c1____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla4__DOT____Vcellinp__c1____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla4__DOT____Vcellout__c2____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla4__DOT____Vcellinp__c2____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla4__DOT____Vcellout__c3____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla4__DOT____Vcellinp__c3____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla4__DOT____Vcellout__c4____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla4__DOT____Vcellinp__c4____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla5__DOT____Vcellout__c1____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla5__DOT____Vcellinp__c1____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla5__DOT____Vcellout__c2____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla5__DOT____Vcellinp__c2____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla5__DOT____Vcellout__c3____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla5__DOT____Vcellinp__c3____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla5__DOT____Vcellout__c4____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla5__DOT____Vcellinp__c4____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla6__DOT____Vcellout__c1____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla6__DOT____Vcellinp__c1____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla6__DOT____Vcellout__c2____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla6__DOT____Vcellinp__c2____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla6__DOT____Vcellout__c3____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla6__DOT____Vcellinp__c3____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla6__DOT____Vcellout__c4____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla6__DOT____Vcellinp__c4____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla7__DOT____Vcellout__c1____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla7__DOT____Vcellinp__c1____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla7__DOT____Vcellout__c2____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla7__DOT____Vcellinp__c2____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla7__DOT____Vcellout__c3____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla7__DOT____Vcellinp__c3____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla7__DOT____Vcellout__c4____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla7__DOT____Vcellinp__c4____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla8__DOT____Vcellout__c1____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla8__DOT____Vcellinp__c1____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla8__DOT____Vcellout__c2____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla8__DOT____Vcellinp__c2____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla8__DOT____Vcellout__c3____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla8__DOT____Vcellinp__c3____pinNumber1 = VL_RAND_RESET_I(1);
    vlSelf->cla8__DOT____Vcellout__c4____pinNumber5 = VL_RAND_RESET_I(1);
    vlSelf->cla8__DOT____Vcellinp__c4____pinNumber1 = VL_RAND_RESET_I(1);
}
