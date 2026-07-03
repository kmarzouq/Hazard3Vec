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

	// === AI-GENERATED BEGIN: fix loop bound / mask index (was hardcoded for sew=8: vl*8 and
	// mask[i/8] only cover the right element count and mask bit for 8-bit elements; for wider
	// SEW the loop stopped after vl/2, vl/4, or vl/8 elements and read the wrong mask bits) ===
	case(sew) // assuming /8 optimizes into [:2]
		7'd8  : for (i=0; i<vl*8 ; i = i+8 )	if (mask[i/8 ]) out = out + {56'b0, vector[i +: 8 ]};
		7'd16 : for (i=0; i<vl*16; i = i+16)	if (mask[i/16]) out = out + {48'b0, vector[i +: 16]};
		7'd32 : for (i=0; i<vl*32; i = i+32)	if (mask[i/32]) out = out + {32'b0, vector[i +: 32]};
		default : for (i=0; i<vl*64; i = i+64)	if (mask[i/64]) out = out +      vector[i +: 64] ; // 64 bit
	endcase
	// === AI-GENERATED END ===
end

endmodule

// === AI-GENERATED FILE (module below) ===
// Remaining RVV 1.0 single-width integer reductions (funct6, OPMVV only):
//   000001 vredand, 000010 vredor, 000011 vredxor,
//   000100 vredminu, 000101 vredmin, 000110 vredmaxu, 000111 vredmax
// Same vd[0] = op(vs1[0], vs2[*]) shape and vd/vs2/vs1 <-> out/vector/scalar
// port convention as redsum above, generalized with an opcode select.
module vec_reduce_other (
	input [5:0] op, // funct6
	input [64*2-1:0] vector, // vs2 (elements being reduced)
	input [63:0] scalar,     // vs1[0] (seed)
	input [6:0] sew,
	input [6:0] vl,
	input [63:0] mask,
	output reg [63:0] out
);

integer i;
reg [63:0] elem, signbit;

function [63:0] reduce_op;
	input [5:0]  f6;
	input [63:0] acc;
	input [63:0] e;
	input [63:0] sb; // 1 << (sew-1), for signed compares
	reg signed [64:0] accs, es;
	begin
		accs = $signed({1'b0,acc} ^ {1'b0,sb}) - $signed({1'b0,sb});
		es   = $signed({1'b0,e}   ^ {1'b0,sb}) - $signed({1'b0,sb});
		case (f6)
			6'b000001: reduce_op = acc & e;                    // vredand
			6'b000010: reduce_op = acc | e;                    // vredor
			6'b000011: reduce_op = acc ^ e;                    // vredxor
			6'b000100: reduce_op = (e < acc) ? e : acc;         // vredminu
			6'b000101: reduce_op = (es < accs) ? e : acc;       // vredmin
			6'b000110: reduce_op = (e > acc) ? e : acc;         // vredmaxu
			6'b000111: reduce_op = (es > accs) ? e : acc;       // vredmax
			default:   reduce_op = acc;
		endcase
	end
endfunction

always @* begin
	out = scalar;
	case (sew)
		7'd8  : begin
			signbit = 64'h80;
			for (i=0; i<vl*8;  i=i+8 ) if (mask[i/8 ]) out = reduce_op(op, out, {56'b0,vector[i+:8 ]}, signbit);
		end
		7'd16 : begin
			signbit = 64'h8000;
			for (i=0; i<vl*16; i=i+16) if (mask[i/16]) out = reduce_op(op, out, {48'b0,vector[i+:16]}, signbit);
		end
		7'd32 : begin
			signbit = 64'h80000000;
			for (i=0; i<vl*32; i=i+32) if (mask[i/32]) out = reduce_op(op, out, {32'b0,vector[i+:32]}, signbit);
		end
		default : begin // 64
			signbit = 64'h8000000000000000;
			for (i=0; i<vl*64; i=i+64) if (mask[i/64]) out = reduce_op(op, out, vector[i+:64], signbit);
		end
	endcase
end

endmodule
// === END AI-GENERATED FILE ===