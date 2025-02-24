module Register (clk, reset, RegW, DR, SR1, SR2, Reg_In, ReadReg1, ReadReg2,mask);
    input clk, reset;
    input RegW[7:0];
    input [4:0] DR, SR1, SR2;
    input [127:0] Reg_In[0:2];
    output reg [127:0] ReadReg1, ReadReg2;
    output [127:0]mask;
    reg [127:0] REG [0:31];
    integer i;

    //always block for reset + write

    always@(posedge clk or posedge reset) begin
        if(reset) begin
            for (i = 0; i < 32; i=i+1) begin
                REG[i] <= 0;
            end
        end
        else begin 
            if (RegW[0]) begin
                REG[DR] <= Reg_In[0];
            end
            if (RegW[1]) begin
                REG[DR] <= Reg_In[1];
            end
            if (RegW[2]) begin
                REG[DR] <= Reg_In[2];
            end
            if (RegW[3]) begin
                REG[DR] <= Reg_In[3];
            end
            if (RegW[4]) begin
                REG[DR] <= Reg_In[4];
            end
            if (RegW[5]) begin
                REG[DR] <= Reg_In[5];
            end
            if (RegW[6]) begin
                REG[DR] <= Reg_In[6];
            end
            if (RegW[7]) begin
                REG[DR] <= Reg_In[7];
            end
        end
    end
    //always block for read
    always@(posedge clk) begin
        ReadReg1 <= REG[SR1];
        ReadReg2 <= REG[SR2];
    end
    assign mask = REG[0];


    


endmodule