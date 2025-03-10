
module bitwise_tb();
	parameter VSIZE = 32;

	reg  [31:0][VSIZE-1:0] Va;
	reg  [31:0][VSIZE-1:0] Vb;
	wire [31:0][VSIZE-1:0] Vo_and;  
	wire [31:0][VSIZE-1:0] Vo_or;  
	wire [31:0][VSIZE-1:0] Vo_xor;  


	vand #(.VSIZE(VSIZE)) tand (
		Va, Vb, Vo_and
	);
	vor #(.VSIZE(VSIZE)) tor (	
		Va, Vb, Vo_or
	);
	vxor #(.VSIZE(VSIZE)) txor (
		Va, Vb, Vo_xor
	);

	integer i;
	initial begin
		$dumpfile("waves.vcd");
		$dumpvars(0, bitwise_tb);

		for (i = 0; i < VSIZE; i = i + 1) begin
			Va[i] = i;
			Vb[i] = i+1;
		end
		#10;
		
		for (i = 0; i < VSIZE; i = i + 1) begin
			$display("i=%0d Va=%b Vb=%b\n\tVand=%b, Vor=%b, Vxor=%b",i, Va[i], Vb[i], Vo_and[i], Vo_or[i], Vo_xor[i]);
		end
		

		for (i = 0; i < VSIZE; i = i + 1) begin
			Va[i] = i+3;
			Vb[i] = i+1;
		end
		
		#10;
		$display("\n\n");
		for (i = 0; i < VSIZE; i = i + 1) begin
			$display("i=%0d Va=%b Vb=%b\n\tVand=%b Vor=%b, Vxor=%b",i, Va[i], Vb[i], Vo_and[i], Vo_or[i], Vo_xor[i]);
		end
		#10 $finish;
	end
endmodule