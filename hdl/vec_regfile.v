module Register (clk, reset, RegW, DR, SR1, SR2, SR3, SR4, /*SR5, SR6, SR7, SR8,*/ Reg_In, ReadReg1, ReadReg2, ReadReg3, ReadReg4, ReadReg5, ReadReg6, ReadReg7, ReadReg8);
    input clk, /*RegW,*/ reset;
    input [3:0]RegW; // one-hot encoding for writes
    input [4:0] DR, SR1, SR2, SR3, SR4;//, SR5, SR6, SR7, SR8;
    input [4:0] ST1, ST2, ST3, ST4;
    input [127:0] Reg_wr_In, Reg_wb1, Reg_wb2, Reg_wb3, Reg_wb4;
    output reg [127:0] ReadReg1, ReadReg2, ReadReg3, ReadReg4;//, ReadReg5, ReadReg6, ReadReg7, ReadReg8;

    reg [127:0] REG [0:31]; //needs to be 128 bits for VLEN = 128
    integer i;

    //always block for reset + write
    always@(posedge clk or posedge reset) begin
        if(reset) begin
            for (i = 0; i < 32; i=i+1) begin
                REG[i] <= 0;
            end
        end
        else begin
        if (RegW /*&& DR != 0*/) begin // why can't DR be 0?
            REG[DR] <= Reg_wr_In; // write data in from memory
        end
        if (RegW[0] && ST1) begin //for writing back the result of the ALU
            REG[ST1] <= Reg_wb1;
        end
        if (RegW[1] && ST1) begin
            REG[ST2] <= Reg_wb2;
        end
        if (RegW[2] && ST1) begin
            REG[ST3] <= Reg_wb3;
        end
        if (RegW[3] && ST1) begin
            REG[ST4] <= Reg_wb4;
        end

        end
    end

    //always block for read
    always@(*) begin
        ReadReg1 = REG[SR1];
        ReadReg2 = REG[SR2];
        ReadReg3 = REG[SR3];
        ReadReg4 = REG[SR4];
        // ReadReg5 = REG[SR5];
        // ReadReg6 = REG[SR6];
        // ReadReg7 = REG[SR7];
        // ReadReg8 = REG[SR8];
    end
    
endmodule
