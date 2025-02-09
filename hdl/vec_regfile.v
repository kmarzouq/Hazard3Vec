module Register (clk, reset, RegW, DR, SR1, SR2, SR3, SR4, SR5, SR6, SR7, SR8, Reg_In, ReadReg1, ReadReg2, ReadReg3, ReadReg4, ReadReg5, ReadReg6, ReadReg7, ReadReg8);
    input clk, RegW, reset;
    input [4:0] DR, SR1, SR2, SR3, SR4, SR5, SR6, SR7, SR8;
    input [31:0] Reg_In;
    output reg [31:0] ReadReg1, ReadReg2, ReadReg3, ReadReg4, ReadReg5, ReadReg6, ReadReg7, ReadReg8;

    reg [31:0] REG [0:31];
    integer i;

    //always block for reset + write
    always@(posedge clk or posedge reset) begin
        if(reset) begin
            for (i = 0; i < 32; i=i+1) begin
                REG[i] <= 0;
            end
        end
        else if (RegW && DR != 0) begin
            REG[DR] <= Reg_In;
        end
    end

    //always block for read
    always@(*) begin
        ReadReg1 = REG[SR1];
        ReadReg2 = REG[SR2];
        ReadReg3 = REG[SR3];
        ReadReg4 = REG[SR4];
        ReadReg5 = REG[SR5];
        ReadReg6 = REG[SR6];
        ReadReg7 = REG[SR7];
        ReadReg8 = REG[SR8];
    end
    
endmodule
