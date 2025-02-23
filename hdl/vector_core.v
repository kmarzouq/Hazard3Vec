module Vec_Main (
    input clk,
    input rst,

    //instruction stuff
    input [W_ALUOP-1:0]aluop,
    input [W_VECOP-1:0]vecop,
    input  [W_DATA-1:0]    d_imm,
	input  [W_REGADDR-1:0] d_rs1,
	input  [W_REGADDR-1:0] d_rs2,
	input  [W_REGADDR-1:0] d_rd,
	input  [2:0]           d_funct3_32b,
	input  [6:0]           d_funct7_32b,
    input  [10:0]   	   d_zimm,
	input  [W_VECOP-1:0]   d_vecop,
    
    //vector CSR inputs
    input [XLEN-1:0] 		vstart,
	input 		 		    vxsat,
	input [1:0] 			vxrm,
	input [XLEN-1:0] 		vcsr,
	input [XLEN-1:0] 		vl,
	input [XLEN-1:0] 		vtype, // vill, vma, vta,vsew[2:0],vlmul[2:0]
	input [XLEN-1:0] 		vlenb,

    input [3:0]LMUL, // used for grouping vector registers together. LMUL max is 8

    output [31:0] d_Reg_str_out, // for memory interface
    output store128
    
);

    reg todo; // if there is a task to do | used to stall scalar pipeline
    reg bad_instr;//in the event of bad memory address translation

    //vector csr decoding
    wire vill = vtype[XLEN-1]; // Illegal Value if set
    wire vma = vtype[7]; // vector mask agnostic
    wire vta = vtype[6]; // vector tail agnostic
    wire [2:0]sew = vtype[5:3] // Selected element width (SEW)
    wire [2:0]lmul = vtype[2:0] // Vector register grouping multiplier (LMUL) | can be at max 8

// loading/storing inputs
    assign wire vm = d_funct7_32b[0]; // whether or not vector mask is active
    assign wire [1:0] mop = d_funct7_32b[2:1]; // determines if load/store is unit-stride, strided, or indexed
    assign wire mew = d_funct7_32b[3]; //shouldn't matter. Simply indicates whether or not 
    assign wire [2:0] nf = d_funct7_32b[6:4];

    assign wire [2:0]width = d_funct3_32b; //element width. Elements = VLEN/EEW

    assign wire [4:0] lumop = d_rs2;
    assign wire [4:0] sumop = d_rs2;

    assign wire mask_en = ~vm;

//for loading and storing ----------------------------------------------------------------------

always @(*) begin
    if (d_vecop == VECOP_LOAD & mop == UNIT_STRIDE) begin
        case (lumop)
            : 
            default: 
        endcase
    end
end


// for loading ops ---------------------------------------------------------------------------------



// for storing ops ---------------------------------------------------------------------------------



    //wire RegW;
    wire RegW;
    wire [4:0] DR, SR1, SR2;
    wire [127:0] Reg_In;
    wire [127:0] ReadReg1, ReadReg2;

    Vec_RF VRF(clk, rst, RegW, DR, SR1, SR2, Reg_In, ReadReg1, ReadReg2);

always @(posedge clk or posedge rst) begin
    if(rst) begin
        todo <=0;
    end
end



    
endmodule