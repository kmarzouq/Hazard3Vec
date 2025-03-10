module bitwise_tb();
    parameter VSIZE = 32;

    reg  [VSIZE-1:0][31:0] Va;
    reg  [VSIZE-1:0][31:0] Vb;
    wire [VSIZE-1:0][31:0] Vout;
	 
    vand #(.VSIZE(VSIZE)) tand (
        Va, Vb, Vout
    );

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, bitwise_tb);

        // Initialize arrays
        for (integer i = 0; i < VSIZE; i = i + 1) begin
            Va[i] = i;
            Vb[i] = i+1;
        end
        #10;

        #1;

        $display("Test 1:");
        for (integer i = 0; i < VSIZE; i = i + 1) begin
            $display("i=%0d Va=%h Vb=%h Vout=%h",i, Va[i], Vb[i], Vout[i]);
        end

        for (integer i = 0; i < VSIZE; i = i + 1) begin
            Va[i] = i+3;
            Vb[i] = i+1;
        end
        #1;

        for (integer i = 0; i < VSIZE; i = i + 1) begin
            $display("i=%0d Va=%h Vb=%h Vout=%h",i, Va[i], Vb[i], Vout[i]);
        end

        #1 $finish;
    end
endmodule
