module testbench();
    `timescale 1ns / 1ps

    // Inputs
    reg clk;
    reg reset;
    reg RegW;
    reg [4:0] DR, SR1, SR2;
    reg [31:0] Reg_In;

    // Outputs
    wire [31:0] ReadReg1, ReadReg2;

    // Instantiate the Register File
    Register uut (
        .clk(clk),
        .reset(reset),
        .RegW(RegW),
        .DR(DR),
        .SR1(SR1),
        .SR2(SR2),
        .Reg_In(Reg_In),
        .ReadReg1(ReadReg1),
        .ReadReg2(ReadReg2)
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
        SR1 = 0;
        SR2 = 0;
        Reg_In = 0;

        // === 1. Apply Reset at the Start ===
        reset = 1;
        #15;  // Hold reset for a few cycles
        reset = 0;
        #10;

        // === 2. Verify Registers are Cleared After Reset ===
        SR1 = 5; SR2 = 10;
        #10;
        $display("RESET CHECK: REG[5] = %h, REG[10] = %h (Expected: 0, 0)", ReadReg1, ReadReg2);
        if (ReadReg1 !== 0 || ReadReg2 !== 0) 
            $display("ERROR: Registers not cleared after reset!");

        // === 3. Write to a Register and Read Back ===
        DR = 5;
        Reg_In = 32'hA5A5A5A5;
        RegW = 1;
        #10;
        RegW = 0;
        #10;
        SR1 = 5;
        #10;
        $display("WRITE & READ CHECK: REG[5] = %h (Expected: A5A5A5A5)", ReadReg1);
        if (ReadReg1 !== 32'hA5A5A5A5) 
            $display("ERROR: Write failed!");

        // === 4. Read Before Write (RBW) Condition ===
        SR1 = 6;
        #10;
        $display("RBW CHECK: REG[6] = %h (Expected: 0)", ReadReg1);
        if (ReadReg1 !== 0) 
            $display("ERROR: Read before write failed!");

        // === 5. Read After Write (RAW) Hazard ===
        DR = 6;
        Reg_In = 32'hDEADBEEF;
        RegW = 1;
        #10;
        RegW = 0;
        SR1 = 6;
        #10;
        $display("RAW CHECK: REG[6] = %h (Expected: DEADBEEF)", ReadReg1);
        if (ReadReg1 !== 32'hDEADBEEF) 
            $display("ERROR: Read after write failed!");

        // === 6. Apply Reset Again to Verify Clearing ===
        reset = 1;
        #15;
        reset = 0;
        #10;

        // Read after reset
        SR1 = 5; SR2 = 6;
        #10;
        $display("SECOND RESET CHECK: REG[5] = %h, REG[6] = %h (Expected: 0, 0)", ReadReg1, ReadReg2);
        if (ReadReg1 !== 0 || ReadReg2 !== 0) 
            $display("ERROR: Registers not cleared after second reset!");

        // === 7. Write and Read from the Same Register in One Cycle ===
        DR = 7;
        Reg_In = 32'h12345678;
        RegW = 1;
        SR1 = 7;
        #10;
        RegW = 0;
        #10;
        $display("WRITE & READ SAME REG: REG[7] = %h (Expected: 12345678)", ReadReg1);
        if (ReadReg1 !== 32'h12345678) 
            $display("ERROR: Simultaneous write/read failed!");

        // === 8. Writing to All Registers ===
        for (int i = 0; i < 32; i = i + 1) begin
            DR = i;
            Reg_In = i * 32'h11111111; // Unique value for each register
            RegW = 1;
            #10;
        end
        RegW = 0;

        // Read Back All Registers
        for (int i = 0; i < 32; i = i + 1) begin
            SR1 = i;
            #10;
            $display("FULL WRITE CHECK: REG[%0d] = %h (Expected: %h)", i, ReadReg1, i * 32'h11111111);
            if (ReadReg1 !== (i * 32'h11111111))
                $display("ERROR: REG[%0d] has wrong value!", i);
        end

        // === 9. Writing Maximum and Minimum Values ===
        DR = 8;
        Reg_In = 32'hFFFFFFFF;
        RegW = 1;
        #10;
        RegW = 0;
        SR1 = 8;
        #10;
        $display("MAX VALUE CHECK: REG[8] = %h (Expected: FFFFFFFF)", ReadReg1);
        if (ReadReg1 !== 32'hFFFFFFFF) 
            $display("ERROR: Writing max value failed!");

        DR = 9;
        Reg_In = 32'h00000000;
        RegW = 1;
        #10;
        RegW = 0;
        SR1 = 9;
        #10;
        $display("MIN VALUE CHECK: REG[9] = %h (Expected: 00000000)", ReadReg1);
        if (ReadReg1 !== 32'h00000000) 
            $display("ERROR: Writing min value failed!");

        // === 10. Write to Register 0 (If it should stay 0) ===
        DR = 0;
        Reg_In = 32'hABCD1234;
        RegW = 1;
        #10;
        RegW = 0;
        SR1 = 0;
        #10;
        $display("WRITE REG[0]: REG[0] = %h (Expected: 00000000 or ABCD1234)", ReadReg1);
        
        if (ReadReg1 !== 0) 
            $display("WARNING: REG[0] is not zero! Some architectures enforce REG[0] as 0.");

        // === 11. Simultaneous Reads ===
        SR1 = 10;
        SR2 = 20;
        RegW = 1;
        #10;
        RegW = 0;
        $display("DUAL READ CHECK: REG[10] = %h, REG[20] = %h (Expected: 10101010, 20202020)", ReadReg1, ReadReg2);
        if (ReadReg1 !== (10 * 32'h11111111) || ReadReg2 !== (20 * 32'h11111111))
            $display("ERROR: Simultaneous read failed!");

        // === 12. Final Reset Test ===
        reset = 1;
        #15;
        reset = 0;
        #10;

        $display("TESTBENCH COMPLETE!");

        // End Simulation
        $finish;
    end

endmodule
