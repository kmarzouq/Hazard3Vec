module testbench();
    reg  [31:0] A [31:0]; // Array of 32 32-bit inputs
    reg  [31:0] B [31:0]; // Array of 32 32-bit inputs
    reg  Cin [31:0];      // subtract control
    wire [31:0] S [31:0]; // Array of 32 32-bit outputs
    wire Cout [31:0];     // Array of 32 carry-out values
    wire Ovflw [31:0];

    reg [32:0] expected; // Used to calculate the expected sum and carry-out
    reg subtract;


    // Instantiate the DUT
    adder32bitby32 dut (Cout, S, A, B, Cin, Ovflw);

    integer i, j, k;

    initial begin
        $display("Start of the 32x32-bit adder array test");

        // Initialize inputs
        assign subtract = 1;
        for (i = 0; i < 32; i = i + 1) begin
            Cin[i] = subtract;
            A[i] = 32'd0; // Initialize A to 0
            B[i] = 32'd0; // Initialize B to 0
        end

        // Apply test vectors
            for (j = 0; j < 32; j = j + 1) begin // Iterate over all 32 adders
                A[j] = $random; // Generate random inputs for A
                B[j] = $random; // Generate random inputs for B
            end

            #10; // Wait for the outputs to stabilize

            // Check results for all adders
            for (k = 0; k < 32; k = k + 1) begin
                if(subtract == 1) begin
                    expected = A[k] - B[k];
                end
                else begin
                    expected = A[k] + B[k];
                end
                if (S[k] == expected[31:0]) begin
                    $display("Test passed at adder[%0d]: A=%h, B=%h, S=%h, Cout=%b, Ovflw=%b, Expected S=%h, Expected Cout=%b",
                             k, A[k], B[k], S[k], Cout[k], Ovflw[k], expected[31:0], expected[32]);
                end
                else if (S[k] !== expected[31:0]) begin
                    $display("Test failed at adder[%0d]: A=%h, B=%h, S=%h, Cout=%b, Ovflw=%b, Expected S=%h, Expected Cout=%b",
                             k, A[k], B[k], S[k], Cout[k], Ovflw[k], expected[31:0], expected[32]);
                end
            end

        $display("End of the 32x32-bit adder array test");
        $finish;
    end
endmodule
