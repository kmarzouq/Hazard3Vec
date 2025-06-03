module redsum(
	input [64*16-1:0] vector,
	input [63:0] scalar,
	input [31:0] sew,
	input [6:0] vl,
	output reg [63:0] out
);

integer i;
always @* begin
	out = scalar;

	case(sew)
		8  : for (i=0; i<vl; i = i+8 )	out = out + {56'b0, vector[i +: 8 ]};
		16 : for (i=0; i<vl; i = i+32)	out = out + {48'b0, vector[i +: 16]};
		32 : for (i=0; i<vl; i = i+32)	out = out + {32'b0, vector[i +: 32]};
		64 : for (i=0; i<vl; i = i+64)	out = out +         vector[i +: 64] ;
	endcase
end

endmodule