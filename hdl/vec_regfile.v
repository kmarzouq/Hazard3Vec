// AI-GENERATED: added SR3/ReadReg3, a third read port addressed by the
// destination register so callers can recover vd's pre-instruction value
// for the mask/tail-undisturbed policy (previously nothing read vd back,
// so S_old in vector_core.v was permanently 0 instead of vd's old contents).
module vec_regfile (clk, reset, RegW, DR, SR1, SR2, SR3, Reg_In, ReadReg1, ReadReg2, ReadReg3, mask);
    input clk, RegW, reset;
    input [4:0] DR, SR1, SR2, SR3;
    input [127:0] Reg_In;
    output reg [127:0] ReadReg1, ReadReg2, ReadReg3;
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
        ReadReg3 <= REG[SR3]; // AI-GENERATED
    end
    assign mask = REG[0];


    


endmodule