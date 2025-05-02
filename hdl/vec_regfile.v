module vec_regfile (clk, reset, RegW, DR, SR1, SR2, Reg_In, ReadReg1, ReadReg2,mask);
    input clk, RegW, reset;
    input [4:0] DR, SR1, SR2;
    input [127:0] Reg_In;
    output reg [127:0] ReadReg1, ReadReg2;
    output [127:0]mask;
    reg [127:0] REG [0:31];
    integer i;

    //always block for reset + write

    always@(negedge clk or negedge reset) begin
        if(!reset) begin
            for (i = 0; i < 32; i=i+1) begin
                REG[i] <= 128'd0;
            end
        end
        else if (RegW) begin
            REG[DR] <= Reg_In;
        end
    end
    //always block for read
    always @(posedge clk) begin
        ReadReg1 <= REG[SR1];
        ReadReg2 <= REG[SR2];
    end
    assign mask = REG[0];


    


endmodule