module testbench();
    `timescale 1ns/1ps
    // Parameters
    localparam n = 32;

    // Inputs
    reg [n-1:0] DataA;
    reg [n-1:0] DataB;

    // Outputs
    wire [2*n-1:0] Pout;
    wire Overflow;

    // Instantiate the Unit Under Test (UUT)
    multiply32bitparallel uut (
        .DataA(DataA),
        .DataB(DataB),
        .Pout(Pout),
        .Overflow(Overflow)
    );

    // Test procedure
    initial begin
        $display("Starting multiply32bitparallel testbench...");
        $display("Time\t\tDataA\t\tDataB\t\tPout\t\t\t\tOverflow");

        // Test 1: 0 x 0
        DataA = 32'd0;
        DataB = 32'd0;
        #10;
        $display("%0t\t%h\t%h\t%h\t%b", $time, DataA, DataB, Pout, Overflow);

        // Test 2: 1 x 1
        DataA = 32'd1;
        DataB = 32'd1;
        #10;
        $display("%0t\t%h\t%h\t%h\t%b", $time, DataA, DataB, Pout, Overflow);

        // Test 3: 12345 x 6789
        DataA = 32'd12345;
        DataB = 32'd6789;
        #10;
        $display("%0t\t%h\t%h\t%h\t%b", $time, DataA, DataB, Pout, Overflow);

        // Test 4: -12345 x 6789
        DataA = -32'd12345;
        DataB = 32'd6789;
        #10;
        $display("%0t\t%h\t%h\t%h\t%b", $time, DataA, DataB, Pout, Overflow);

        // Test 5: 12345 x -6789
        DataA = 32'd12345;
        DataB = -32'd6789;
        #10;
        $display("%0t\t%h\t%h\t%h\t%b", $time, DataA, DataB, Pout, Overflow);

        // Test 6: -12345 x -6789
        DataA = -32'd12345;
        DataB = -32'd6789;
        #10;
        $display("%0t\t%h\t%h\t%h\t%b", $time, DataA, DataB, Pout, Overflow);

        // Test 7: Maximum positive number × 2
        DataA = 32'h7FFFFFFF; // 2^31 - 1
        DataB = 32'd2;
        #10;
        $display("%0t\t%h\t%h\t%h\t%b", $time, DataA, DataB, Pout, Overflow);

        // Test 8: Minimum negative number × 1
        DataA = 32'h80000000; // -2^31
        DataB = 32'd1;
        #10;
        $display("%0t\t%h\t%h\t%h\t%b", $time, DataA, DataB, Pout, Overflow);

        // Test 9: Random large values
        DataA = 32'hDEADBEEF;
        DataB = 32'hCAFEBABE;
        #10;
        $display("%0t\t%h\t%h\t%h\t%b", $time, DataA, DataB, Pout, Overflow);

        $display("Testbench completed.");
        $finish;
    end

endmodule
