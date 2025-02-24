module Vec_Main (
    input clk,
    input rst,

    //instruction stuff
    input [W_ALUOP-1:0] d_aluop,
    input  [W_DATA-1:0]    d_imm,
	input  [W_REGADDR-1:0] d_rs1,
	input  [W_REGADDR-1:0] d_rs2,
	input  [W_REGADDR-1:0] d_rd,
	input  [2:0]           d_funct3_32b,
	input  [6:0]           d_funct7_32b,
    input  [10:0]   	   d_zimm,
	input  [W_VECOP-1:0]   d_vecop,

    // Load/store port
	output reg                 bus_aph_req_d,
	output wire                bus_aph_excl_d,
	input  wire                bus_aph_ready_d,
	input  wire                bus_dph_ready_d,
	input  wire                bus_dph_err_d,
	input  wire                bus_dph_exokay_d,

	output reg  [W_ADDR-1:0]   bus_haddr_d,
	output reg  [2:0]          bus_hsize_d,
	output reg                 bus_priv_d,
	output reg                 bus_hwrite_d,
	output reg  [W_DATA-1:0]   bus_wdata_d,
	input  wire [W_DATA-1:0]   bus_rdata_d,
    
    //vector CSR inputs | NEED TO DEVELOP WAY TO UPDATE CSRs
    input [XLEN-1:0] 		vstart, // vector start position (basically if there is an error, where to do start back from after error handler runs)
	
    input 		 		    vxsat, // fixed-point saturate flag | FOR ARITHMETIC INSTRUCTIONS

	input [1:0] 			vxrm, // fixed-point rounding mode | FOR ARITHMETIC INSTRUCTIONS
    //vxrm[1:0]       abbr   rounding mode                               rounding increment, r
    //00               RNU   Round to Nearest up (add+0.5 LSB)           v[d-1]
    //01               RNE   Round to Nearest even                       v[d-1] & (v[d-2:0]!=0 | v[d])
    //10               RDN   Round down (truncate)                       0
    //11               ROD   Round to odd (OR bits into LSB, aka "jam")  !v[d] & v[d-1:0]!=0


	input [XLEN-1:0] 		vcsr, // vector control and status register | holds vxrm and vxsat
	input [XLEN-1:0] 		vl, //vector length (how many elements in the vector register are being processed, rest of elements are tail)
	input [XLEN-1:0] 		vtype, // vector data type register

	input [XLEN-1:0] 		vlenb, // VLEN/8
    
);

    reg todo,no_todo; // if there is a task to do | used to stall scalar pipeline
    reg bad_instr;//in the event of bad memory address translation
    integer i;

    //vector csr vtype reg decoding
    wire vill = vtype[XLEN-1]; // Illegal Value if set
    wire vma = vtype[7]; // vector mask agnostic | basically do you care if mask elements change
    wire vta = vtype[6]; // vector tail agnostic | basically do you care if tail elements change

    wire [2:0]sew = vtype[5:3] // Selected element width (SEW)
    // SEW                  Elements per vector register  vsew[2:0]
    // 64                   2                             011
    // 32                   4                             010
    // 16                   8                             001
    // 8                    16                            000

    reg [2:0]lmul = vtype[2:0] // Vector register grouping multiplier (LMUL) | can be at max 8
    // used for grouping vector registers together. LMUL max is 8, LMUL min is 1/8
    // lmul[2:0]       actual LMUL     #groups  VLMAX                 registers grouped w/ register n
    // 100               -----------------------------------------------------------------------------
    // 101               1/8            32      VLEN/SEW/8            single reg
    // 110               1/4            32      VLEN/SEW/4            single reg
    // 111               1/2            32      VLEN/SEW/2            single reg
    // 000               1              32      VLEN/SEW              single reg
    // 001               2              16      2*VLEN/SEW            v[n] & v[n+1]
    // 010               4              8       4*VLEN/SEW            v[n] & v[n+1] & v[n+2] & v[n+3]
    // 011               8              4       8*VLEN/SEW            v[n] & v[n+1] & v[n+2] & v[n+3] & v[n+4] & v[n+5] & v[n+6] & v[n+7]



// loading/storing inputs ----------------------------------------------------------------------
    assign wire vm = d_funct7_32b[0]; // whether or not vector mask is active
    assign wire [1:0] mop = d_funct7_32b[2:1]; // determines if load/store is unit-stride, strided, or indexed
    assign wire mew = d_funct7_32b[3]; //shouldn't matter. Simply indicates whether or not 

    assign wire [2:0] nf = d_funct7_32b[6:4]; // for segmented loading/storing | only 1,2,4, and 8 NFIELDS are supported, otherwise, vill is set
    // nf[2:0]       #fields
    // 000           1
    // 001           2
    // 011           4
    // 111           8

    assign wire [2:0]width = d_funct3_32b; //width per element

    assign wire mask_en = ~vm; 

//for loading and storing ----------------------------------------------------------------------

reg [7:0]VLMAX;//max number of elements that can possibly be be processed;

wire [6:0] EEW; //Effective Element Width

always @(*) begin
    if ((d_vecop == VECOP_LOAD | d_vecop == VECOP_STORE) & mop == UNIT_STRIDE & d_rs2==5'b01011) begin
        EEW=3'b000;
    end
    else if (d_vecop==IND_UNORDER | d_vecop==IND_ORDER)begin // if indexed, EEW = SEW
        case (sew)
            3'b000:EEW=8;
            3'b001:EEW=16;
            3'b010:EEW=32;
            3'b011:EEW=64; 
        endcase
    end
    else begin
        case (width)
            3'b000:EEW=8;
            3'b101:EEW=16;
            3'b110:EEW=32;
            3'b111:EEW=64; 
        endcase
    end
end

reg [6:0]EMUL;
always @(posedge clk) begin // finding max number of elements possible
    
    EMUL<= (EEW>>sew)<<lmul;

    case (lmul) // remember to +1 when referencing due to being able to only do a section of a reg
        3'b101:VLMAX<= (8'd128 >> (sew + 8'd3)) >> 3;
        3'b110:VLMAX<= (8'd128 >> (sew + 8'd3) ) >> 2;
        3'b111:VLMAX<= (8'd128 >> (sew + 8'd3)) >> 1;
        3'b000:VLMAX<= (8'd128 >> (sew + 8'd3));
        3'b001:VLMAX<= (8'd128 >> (sew + 8'd3)) <<1;
        3'b010:VLMAX<= (8'd128 >> (sew + 8'd3)) <<2;
        3'b011:VLMAX<= (8'd128 >> (sew + 8'd3)) <<3;
    endcase
end

reg [4:0] num_elements_LS; // how many elements are being loaded/stored
reg fault_first; //for fault-only-first unit stride load

always @(*) begin
    if (d_vecop == VECOP_LOAD & mop == UNIT_STRIDE) begin //can just load in 32 bit chunks
        case (d_rs2)//lumop
 
            US_WLD: case (sew)
                3'b000: num_elements_LS=16; fault_first=0; // 16 elements of 8-bit
                3'b001: num_elements_LS=8; fault_first=0; // 8 elements of 16-bit
                3'b010: num_elements_LS=4; fault_first=0; // 4 elements of 32-bit
                3'b011: num_elements_LS=2; fault_first=0; // 2 elements of 64-bit
                default: num_elements_LS=vl; fault_first=0;
            endcase
            US_LD8: num_elements_LS=16; fault_first=0;
            US_fault: num_elements_LS=vl;  fault_first=1;
            default: num_elements_LS=vl; fault_first=0; //standard unit stride load
        endcase
    end
    if (d_vecop == VECOP_LOAD & mop == STRIDED) begin
        num_elements_LS=vl; fault_first=0;
    end
    if (d_vecop == VECOP_LOAD & (mop == IND_UNORDER | mop == IND_ORDER)) begin // indexed unordered and ordered function the same for our purposes
        case (sew)
                3'b000: num_elements_LS=16; fault_first=0; // 16 elements of 8-bit
                3'b001: num_elements_LS=8; fault_first=0; // 8 elements of 16-bit
                3'b010: num_elements_LS=4; fault_first=0; // 4 elements of 32-bit
                3'b011: num_elements_LS=2; fault_first=0; // 2 elements of 64-bit
                default: num_elements_LS=vl; fault_first=0; 
        endcase
    end
end

reg [31:0] ld_str_queue [8:0]; // for storing all load addressess | LMUL=8, EEW=8, NF=4 8*4*(128/8) = 512 addresses

wire mask_use;
assign ld_st_mask_use = mask_en;
assign wire [3:0]NF = nf+4'd1;

always @(posedge clk or posedge rst) begin
    if(rst or (todo==1 & no_todo==1)) begin
            for (i = 0; i < 128; i=i+1) begin
                ld_str_queue[i] <= 0;
            end
    end
    else if (d_vecop == VECOP_LOAD) begin
        case (mop)
            UNIT_STRIDE: begin
                if (fault_first==1) begin // will get to later

                end
                else begin
                    for (i = 0; i < num_elements_LS; i=i+1) begin //loading 32-bits at a time. no point for striding
                        ld_str_queue[] <= ;
                    end
                end
            end
            default: 
        endcase
    end

end

// for loading ops ---------------------------------------------------------------------------------

reg [8:0] next_ld_addr; // next address to load from 
reg [4:0] next_ld_reg; // next reg to store to
reg [3:0] next_ld_pos; //next position in reg to store to



// for storing ops ---------------------------------------------------------------------------------


// Register file stuff ---------------------------------------------------------------------------------

    wire clk, RegW, reset;
    wire [4:0] DR, SR1, SR2;
    wire [127:0] Reg_In;
    wire [127:0] ReadReg1, ReadReg2;
    wire [127:0]mask;

    Register VRF(clk, reset, RegW, DR, SR1, SR2, Reg_In, ReadReg1, ReadReg2,mask);


    assign ReadReg2 = d_rs2; 

reg done; // set when done with arith operation

always @(posedge clk or posedge rst) begin //when recieving a new instruction set todo to 1, and wait for 1 cycle before setting no_todo to 1 to 0
    if(rst) begin
        todo <=0;
        no_todo <=1;
        done<=0;
    end
    else if (d_vecop!=VECOP_NONE) begin
        todo <=1;
    end
    if (todo==1 & no_todo==1) begin
        no_todo<=0;
    end
    if (done==1) begin
        todo<=0;
        no_todo<=1;
    end
end



    
endmodule