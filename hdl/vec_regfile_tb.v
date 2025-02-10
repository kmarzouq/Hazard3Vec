module testbench();
    `timescale 1ns / 1ps

    // Inputs
    reg clk;
    reg reset;
    reg RegW;
    reg [4:0] DR, SR1, SR2, SR3, SR4, SR5, SR6, SR7, SR8;
    reg [31:0] Reg_In;

    // Outputs
    wire [31:0] ReadReg1, ReadReg2, ReadReg3, ReadReg4, ReadReg5, ReadReg6, ReadReg7, ReadReg8;

    // Instantiate the Register File with 8 outputs
    Register uut (
        .clk(clk),
        .reset(reset),
        .RegW(RegW),
        .DR(DR),
        .SR1(SR1),
        .SR2(SR2),
        .SR3(SR3),
        .SR4(SR4),
        .SR5(SR5),
        .SR6(SR6),
        .SR7(SR7),
        .SR8(SR8),
        .Reg_In(Reg_In),
        .ReadReg1(ReadReg1),
        .ReadReg2(ReadReg2),
        .ReadReg3(ReadReg3),
        .ReadReg4(ReadReg4),
        .ReadReg5(ReadReg5),
        .ReadReg6(ReadReg6),
        .ReadReg7(ReadReg7),
        .ReadReg8(ReadReg8)
    );

    // Clock Generation
    always #5 clk = ~clk;  // 10ns period

    initial begin
        $dumpfile("Register_tb.vcd");
        $dumpvars(0, testbench);

        // Initialize Inputs
        clk = 0;
        RegW = 0;
        DR = 0;
        SR1 = 0; SR2 = 0; SR3 = 0; SR4 = 0; SR5 = 0; SR6 = 0; SR7 = 0; SR8 = 0;
        Reg_In = 0;

        // === 1. Apply Reset at the Start ===
        reset = 1;
        #15;  // Hold reset for a few cycles
        reset = 0;
        #10;

        // === 2. Verify Registers are Cleared After Reset ===
        SR1 = 1; SR2 = 2; SR3 = 3; SR4 = 4; SR5 = 5; SR6 = 6; SR7 = 7; SR8 = 8;
        #10;
        $display("RESET CHECK: REG[1-8] = %h %h %h %h %h %h %h %h (Expected: 0s)", 
                 ReadReg1, ReadReg2, ReadReg3, ReadReg4, ReadReg5, ReadReg6, ReadReg7, ReadReg8);
        
        // === 3. Write to 8 Registers and Read Back ===
        for (int i = 1; i <= 8; i = i + 1) begin
            DR = i;
            Reg_In = i * 32'h11111111; // Unique value
            RegW = 1;
            #10;
        end
        RegW = 0;
        #10;

        // Read back all 8 registers
        #10;
        $display("WRITE & READ CHECK: REG[1-8] = %h %h %h %h %h %h %h %h (Expected: Unique values)", 
                 ReadReg1, ReadReg2, ReadReg3, ReadReg4, ReadReg5, ReadReg6, ReadReg7, ReadReg8);

        // === 4. Writing & Reading Maximum and Minimum Values ===
        DR = 9; Reg_In = 32'hFFFFFFFF; RegW = 1; #10; RegW = 0;
        DR = 10; Reg_In = 32'h00000000; RegW = 1; #10; RegW = 0;
        #10;
        SR1 = 9; SR2 = 10;
        #10;
        $display("MAX/MIN CHECK: REG[9] = %h, REG[10] = %h (Expected: FFFFFFFF, 00000000)", ReadReg1, ReadReg2);

        // === 5. Read 8 Random Registers Simultaneously ===
        SR1 = 3; SR2 = 6; SR3 = 9; SR4 = 12; SR5 = 15; SR6 = 18; SR7 = 21; SR8 = 24;
        #10;
        $display("MULTI-READ CHECK: REG[3,6,9,12,15,18,21,24] = %h %h %h %h %h %h %h %h", 
                 ReadReg1, ReadReg2, ReadReg3, ReadReg4, ReadReg5, ReadReg6, ReadReg7, ReadReg8);

        // === 6. Apply Reset Again ===
        reset = 1;
        #15;
        reset = 0;
        #10;

        // Verify all registers are cleared again
        SR1 = 1; SR2 = 2; SR3 = 3; SR4 = 4; SR5 = 5; SR6 = 6; SR7 = 7; SR8 = 8;
        #10;
        $display("SECOND RESET CHECK: REG[1-8] = %h %h %h %h %h %h %h %h (Expected: 0s)", 
                 ReadReg1, ReadReg2, ReadReg3, ReadReg4, ReadReg5, ReadReg6, ReadReg7, ReadReg8);

        // === 7. Simultaneous Read & Write Test ===
        DR = 7; Reg_In = 32'h12345678; RegW = 1;
        SR1 = 7; SR2 = 6; SR3 = 5; SR4 = 4; SR5 = 3; SR6 = 2; SR7 = 1; SR8 = 0;
        #10;
        RegW = 0;
        #10;
        $display("SIMULTANEOUS READ & WRITE: REG[7] = %h (Expected: 12345678)", ReadReg1);

        // === 8. Writing to All Registers ===
        for (int i = 0; i < 32; i = i + 1) begin
            DR = i;
            Reg_In = i * 32'h22222222; // Unique pattern
            RegW = 1;
            #10;
        end
        RegW = 0;

        // Read Back 8 Registers at a Time
        for (int i = 0; i < 32; i = i + 8) begin
            SR1 = i; SR2 = i+1; SR3 = i+2; SR4 = i+3;
            SR5 = i+4; SR6 = i+5; SR7 = i+6; SR8 = i+7;
            #10;
            $display("BULK READ: REG[%0d-%0d] = %h %h %h %h %h %h %h %h", i, i+7, 
                     ReadReg1, ReadReg2, ReadReg3, ReadReg4, ReadReg5, ReadReg6, ReadReg7, ReadReg8);
        end

        // === 9. Final Reset ===
        reset = 1;
        #15;
        reset = 0;
        #10;

        $display("TESTBENCH COMPLETE!");
        $finish;
    end

endmodule
