module redsum(
	input [64*2-1:0] vector,
	input [63:0] scalar,
	input [6:0] sew,
	input [6:0] vl,
	input [63:0] mask,
	output reg [63:0] out
);

integer i;
always @* begin
	out = scalar;

	case(sew) // assuming /8 optimizes into [:2]
		7'd8  : for (i=0; i<vl*8; i = i+8 )	if (mask[i/8]) out = out + {56'b0, vector[i +: 8 ]};
		7'd16 : for (i=0; i<vl*8; i = i+16)	if (mask[i/8]) out = out + {48'b0, vector[i +: 16]};
		7'd32 : for (i=0; i<vl*8; i = i+32)	if (mask[i/8]) out = out + {32'b0, vector[i +: 32]};
		default : for (i=0; i<vl*8; i = i+64)	if (mask[i/8]) out = out +      vector[i +: 64] ; // 64 bit
	endcase
end

endmodule