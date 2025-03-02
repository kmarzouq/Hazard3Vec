module testbench();
    `timescale 1ns / 1ps
    parameter vecwidth = 4;
    reg clk;
    reg reset;
    reg [31:0] vtype;
    reg [31:0] vstart;
    reg [1:0] vxrm;
    reg [31:0] vl;
    reg [2:0] vsew;
    reg [2:0] vlmul;
    wire vxsat;

    reg  [31:0] A [vecwidth-1:0]; // Array of 32 32-bit inputs
    reg  [31:0] B [vecwidth-1:0]; // Array of 32 32-bit inputs
    reg  Cin [vecwidth-1:0];      // subtract control
    wire [31:0] S [vecwidth-1:0]; // Array of 32 32-bit outputs
    wire Cout [vecwidth-1:0];     // Array of 32 carry-out values
    wire Ovflw [vecwidth-1:0];

    reg [32:0] expected; // Used to calculate the expected sum and carry-out
    reg subtract;


    // Instantiate the DUT
    //adder32bitby32 #(.vecwidth(vecwidth)) dut (Cout, S, A, B, Cin, Ovflw);
    vadd_vv #(
        .vecwidth(vecwidth)
    ) dut (
        .clk(clk),
        .reset(reset),
        .vtype(vtype),
        .vstart(vstart),
        .vxrm(vxrm),
        .vl(vl),
        .vsew(vsew),
        .vlmul(vlmul),
        .A(A),
        .B(B),
        .Cin(Cin),
        .S(S),
        .Cout(Cout),
        .Ovflw(Ovflw),
        .vxsat(vxsat)
    );
    

    //Clock generation
    initial begin
      clk = 0;
      forever #5 clk = ~clk; // 10 time units period
    end

    integer i, j, k, count;

    initial begin
        $display("Start of the 32x32-bit adder array test");

        // Initialize inputs
        reset = 1;
        vtype = 32'h00000000;
        vstart = 0;
        vxrm = 2'b00; // Round to Nearest Up
        vl = vecwidth;
        vsew = 3'b010; // SEW = 32 bits
        vlmul = 3'b000; // LMUL = 1

        // Reset the design
        #10 reset = 0;

        // Initialize inputs
        assign subtract = 0;
        /*
        for (i = 0; i < vecwidth; i = i + 1) begin
            Cin[i] = subtract;
            A[i] = 32'd0; // Initialize A to 0
            B[i] = 32'd0; // Initialize B to 0
        end

        #10;
        // Apply test vectors
            for (j = 0; j < vecwidth; j = j + 1) begin // Iterate over all 32 adders
                A[j] = $random; // Generate random inputs for A
                B[j] = $random; // Generate random inputs for B
            end
        */
    end

        always @(posedge clk) begin
            if (reset) begin
                count <= 0;
                subtract <= 0;
            end else if (count < vecwidth) begin
                // Initialization Phase
                Cin[count] <= subtract;
                A[count] <= 32'd0;
                B[count] <= 32'd0;
                count <= count + 1;
            end else if (count < 2 * vecwidth) begin
                // Random Test Vector Phase
                A[count - vecwidth] <= $random;
                B[count - vecwidth] <= $random;
                count <= count + 1;
            end
        end

    initial begin
            #2600; // Wait for the outputs to stabilize

            // Check results for all adders
            for (k = 0; k < vecwidth; k = k + 1) begin
                if(subtract == 1) begin
                    expected = A[k] - B[k];
                end
                else begin
                    expected = A[k] + B[k];
                end
                if (S[k] == expected[32-1:0]) begin
                    $display("Test passed at adder[%0d]: A=%h, B=%h, S=%h, Cout=%b, Ovflw=%b, Expected S=%h, Expected Cout=%b",
                             k, A[k], B[k], S[k], Cout[k], Ovflw[k], expected[32-1:0], expected[32]);
                end
                else if (S[k] !== expected[32-1:0]) begin
                    $display("Test failed at adder[%0d]: A=%h, B=%h, S=%h, Cout=%b, Ovflw=%b, Expected S=%h, Expected Cout=%b",
                             k, A[k], B[k], S[k], Cout[k], Ovflw[k], expected[32-1:0], expected[32]);
                end
            end

        $display("End of the 32x32-bit adder array test");
        $finish;
    end
endmodule
