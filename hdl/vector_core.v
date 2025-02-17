module Vec_Main (
    input vecop

    
);

    wire clk, /*RegW,*/ reset;
    wire [4:0]RegW; // one-hot encoding for writes
    wire [4:0] DR, SR1, SR2, SR3, SR4;//, SR5, SR6, SR7, SR8; // for reading regs
    wire [4:0] ST1, ST2, ST3, ST4; // for writing back the result of the ALU
    wire [127:0] Reg_wr_In, Reg_wb1, Reg_wb2, Reg_wb3, Reg_wb4;
    wire [127:0] ReadReg1, ReadReg2, ReadReg3, ReadReg4;//, ReadReg5, ReadReg6, ReadReg7, ReadReg8;
    
endmodule