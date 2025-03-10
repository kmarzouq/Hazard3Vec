module testbench();
    `timescale 1ns / 1ps
    parameter vecwidth = 32;
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
    //reg  Cin [vecwidth-1:0];      // subtract control
    wire [31:0] S [vecwidth-1:0]; // Array of 32 32-bit outputs
    wire Cout [vecwidth-1:0];     // Array of 32 carry-out values
    wire Ovflw [vecwidth-1:0];

    reg [32:0] expected; // Used to calculate the expected sum and carry-out
    //reg subtract;
    reg [31:0] expected_S [vecwidth-1:0];
    reg expected_vxsat;
    reg vta, vma;


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
        //.Cin(Cin),
        .S(S),
        .Cout(Cout),
        .Ovflw(Ovflw),
        .vxsat(vxsat)
    );
    


    //adder32bitby32 #(.vecwidth(vecwidth)) uut (.A(A), .B(B), .Cin(Cin), .S(S), .Cout(Cout), .Ovflw(Ovflw));
    

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
        vtype = 32'h00000080;
        vstart = 0;
        vxrm = 2'b00; // Round to Nearest Up
        vl = vecwidth;
        //vsew = 3'b010; // SEW = 32 bits
        //vlmul = 3'b000; // LMUL = 1
        vta = vtype[7]; //tail agnostic
        vma = vtype[6]; //mask not agnostic
        //vta = 1;
        //vma = 0;

        // Reset the design
        #10 reset = 0;

        // Initialize inputs
        //assign subtract = 0;
    end

        always @(posedge clk) begin
            if (reset) begin
                count <= 0;
                //subtract <= 0;
            end else if (count < vecwidth) begin
                // Initialization Phase
                //Cin[count] <= subtract;
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
            #10000; // Wait for the outputs to stabilize

        expected_vxsat = 0;
        for (i = 0; i < vecwidth; i = i + 1) begin
            if (i < vl) begin
                reg [31:0] sum = A[i] + B[i];
                reg [31:0] rounded;
                case (vxrm)
                    2'b00: rounded = sum + ((sum >> 1) & 1); // Round to nearest up
                    2'b01: rounded = sum + (((sum >> 1) & 1) & ((sum & 1) | ((sum >> 1) & 1))); // Round to nearest even
                    2'b10: rounded = sum; // Truncate
                    2'b11: rounded = sum | (!((sum >> 1) & 1) & (sum & 1)); // Round to odd
                endcase

                // Handle overflow and saturation
                if (Ovflw[i]) begin
                    expected_vxsat = 1;
                    expected_S[i] = sum[31] ? 32'h80000000 : 32'h7FFFFFFF;
                end else if (!vma) begin
                    expected_S[i] = rounded;
                end else begin
                    expected_S[i] = rounded;
                end
            end else if (i >= vl && vta) begin
                expected_S[i] = S[i];
            end
        end

        // Check results
        for (i = 0; i < vecwidth; i = i + 1) begin
            if (S[i] == expected_S[i]) begin
                $display("Match at index %d: Expected %h, Got %h", i, expected_S[i], S[i]);
            end
            else if (S[i] !== expected_S[i]) begin
                $display("Mismatch at index %d: Expected %h, Got %h", i, expected_S[i], S[i]);
            end
        end

        if (vxsat == expected_vxsat) begin
            $display("vxsat Match: Expected %b, Got %b", expected_vxsat, vxsat);
        end
        else if (vxsat !== expected_vxsat) begin
            $display("vxsat Mismatch: Expected %b, Got %b", expected_vxsat, vxsat);
        end


        //$display("End of the 32x32-bit adder array test");
        $finish;
    end
endmodule
