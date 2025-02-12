//`timescale 1ns / 1ps

module testbench();
    `timescale 1ns / 1ps
    parameter n = 32; // Width of each multiplier
    parameter vecwidth = 32; // Number of parallel multipliers

    reg Clock;
    reg [vecwidth-1:0] Resetn, LA, LB, s; // Corrected: Now vectors instead of arrays
    //reg Resetn [vecwidth-1:0];
    //reg LA [vecwidth-1:0];
    //reg LB [vecwidth-1:0];
    //reg s [vecwidth-1:0];
    reg [n-1:0] DataA [vecwidth-1:0];
    reg [n-1:0] DataB [vecwidth-1:0];
    wire [n-1:0] Pout [vecwidth-1:0];
    wire [vecwidth-1:0] Done, Overflow; // Corrected: Now vectors
    //wire Done [vecwidth-1:0];
    //wire Overflow [vecwidth-1:0];

    // Instantiate the multiplier32bitby32 module
    multiplier32bitby32 uut (
        .Clock(Clock),
        .Resetn(Resetn),
        .LA(LA),
        .LB(LB),
        .s(s),
        .DataA(DataA),
        .DataB(DataB),
        .Pout(Pout),
        .Done(Done),
        .Overflow(Overflow)
    );

    // Generate a clock signal (50MHz)
    always #10 Clock = ~Clock;

    // Task for running a test case on all 32 multipliers
    task run_test(input [n-1:0] A, input [n-1:0] B);
        integer i;
        begin
            for (i = 0; i < vecwidth; i = i + 1) begin
                DataA[i] = A + i;  // Slight variation across multipliers
                DataB[i] = B + i;
            end

            LA = {vecwidth{1'b1}};
            LB = {vecwidth{1'b1}};
            s = {vecwidth{1'b1}};
            #20; // Wait for registers to load
            LA = 0;
            LB = 0;

            // Wait until all multipliers complete
            wait (&Done);
            for (i = 0; i < vecwidth; i = i + 1) begin
                $display("Multiplier %0d: %0d * %0d = %0d, Expected: %0d, Overflow: %d", 
                    i, $signed(DataA[i]), $signed(DataB[i]), $signed(Pout[i]), 
                    $signed(DataA[i]) * $signed(DataB[i]), Overflow[i]);
            end

            #20; // Allow time to observe results
        end
    endtask

    initial begin
        // Initialize signals
        Clock = 0;
        Resetn = {vecwidth{1'b0}};
        LA = 0;
        LB = 0;
        s = 0;
        for (int i = 0; i < vecwidth; i = i + 1) begin
            DataA[i] = 0;
            DataB[i] = 0;
        end

        // Reset sequence
        #20 Resetn = {vecwidth{1'b1}};

        // Test Cases
        $display("Starting Test Cases...");

        run_test(32'h00000000, 32'h00000000); // 0 * 0
        Resetn = 0;
        #20 Resetn = {vecwidth{1'b1}};
        run_test(32'h00000001, 32'h00000001); // 1 * 1
        Resetn = 0;
        #20 Resetn = {vecwidth{1'b1}};
        run_test(32'h00000002, 32'h00000003); // 2 * 3
        Resetn = 0;
        #20 Resetn = {vecwidth{1'b1}};
        run_test(32'h7FFFFFFF, 32'h00000002); // Largest positive int * 2
        Resetn = 0;
        #20 Resetn = {vecwidth{1'b1}};
        run_test(32'hFFFFFFFF, 32'h00000002); // -1 * 2
        Resetn = 0;
        #20 Resetn = {vecwidth{1'b1}};
        run_test(32'h80000000, 32'h00000002); // Smallest negative * 2
        Resetn = 0;
        #20 Resetn = {vecwidth{1'b1}};
        run_test(32'hFFFFFFFF, 32'hFFFFFFFF); // -1 * -1
        Resetn = 0;
        #20 Resetn = {vecwidth{1'b1}};
        run_test(32'h00000010, 32'h00000008); // 16 * 8 (power of 2 test)
        Resetn = 0;
        #20 Resetn = {vecwidth{1'b1}};
        run_test(32'h12345678, 32'h87654321); // Random values
        Resetn = 0;
        #20 Resetn = {vecwidth{1'b1}};

        $display("All test cases completed.");
        $stop;
    end

endmodule
