module Vec_Main (
    input clk,
    input rst,
    input [W_ALUOP-1:0]aluop,
    input [W_VECOP-1:0]vecop,

    output [127:0] d_Reg_str_out, // for memory interface
    output store128
    
);

    reg todo; // if there is a task to do


    //wire RegW;
    wire [4:0]RegW; // one-hot encoding for writes
    wire [4:0] DR, SR1, SR2, SR3, SR4;//, SR5, SR6, SR7, SR8; // for reading regs
    wire [4:0] ST1, ST2, ST3, ST4; // for writing back the result of the ALU
    wire [127:0] Reg_wr_In, Reg_wb1, Reg_wb2, Reg_wb3, Reg_wb4;
    wire [127:0] ReadReg1, ReadReg2, ReadReg3, ReadReg4;//, ReadReg5, ReadReg6, ReadReg7, ReadReg8;

    wire str;
    wire [127:0] Reg_str_out;

    Vec_RF VRF(clk, rst,RegW, DR, SR1, SR2, SR3, SR4, ST1, ST2, ST3, ST4, /*SR5, SR6, SR7, SR8,*/ Reg_wr_In, Reg_wb1, Reg_wb2, Reg_wb3, Reg_wb4, str, ReadReg1, ReadReg2, ReadReg3, ReadReg4/*, ReadReg5, ReadReg6, ReadReg7, ReadReg8*/,Reg_str_out);

always @(posedge clk or posedge rst) begin
    if(rst) begin
        todo <=0;
    end
end



    
endmodule