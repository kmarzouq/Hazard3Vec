`timescale 10ns/1ns

`include "hazard3_ops.vh"



module Vec_Main #(
    `include "hazard3_width_const.vh",
    `include "vec_vars.vh",
    parameter W_DATA = 32,
    parameter W_ADDR = 32
)  (
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
    input  [31:0]          scalar_reg1, // inputs from scalar reg file
    input  [31:0]          scalar_reg2,
    input  [127:0]         test_vector_reg2, //for testing 

    // Load/store port
	output reg                 bus_aph_req_d, // figure out way to hijack existing load store interface
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

	input [XLEN-1:0] 		vlenb // VLEN/8
    
);

    reg todo,no_todo; // if there is a task to do | used to stall scalar pipeline
    reg bad_instr;//in the event of bad memory address translation

    //vector csr vtype reg decoding
    wire vill = vtype[XLEN-1]; // Illegal Value if set
    wire vma = vtype[7]; // vector mask agnostic | basically do you care if mask elements change
    wire vta = vtype[6]; // vector tail agnostic | basically do you care if tail elements change

    wire [2:0]vsew = vtype[5:3]; // Selected element width (SEW)
    // SEW                  Elements per vector register  vsew[2:0]
    // 8                    16                            000
    // 16                   8                             001
    // 32                   4                             010
    // 64                   2                             011
    
    
    

    reg [2:0]vlmul = vtype[2:0]; // Vector register grouping multiplier (LMUL) | can be at max 8
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
    wire vm;
    wire [1:0] mop;
    wire mew;
    assign  vm = d_funct7_32b[0]; // whether or not vector mask is active
    assign  mop = d_funct7_32b[2:1]; // determines if load/store is unit-stride, strided, or indexed
    assign  mew = d_funct7_32b[3]; //shouldn't matter. Simply indicates whether or not 

    wire [2:0] nf;
    assign  nf = d_funct7_32b[6:4]; // for segmented loading/storing | only 1,2,4, and 8 NFIELDS are supported, otherwise, vill is set
    // nf[2:0]       #fields
    // 000           1
    // 001           2
    // 011           4
    // 111           8
    
    wire [2:0]width;
    assign  width = d_funct3_32b; //width per element
    
    wire mask_en;
    assign  mask_en = ~vm; 

//for loading and storing ----------------------------------------------------------------------

reg [7:0]VLMAX;//max number of elements that can possibly be be processed;

wire [6:0] EEW; //Effective Element Width

always @(*) begin //determining EEW
    if ((d_vecop == VECOP_LOAD | d_vecop == VECOP_STORE) & mop == UNIT_STRIDE & d_rs2==5'b01011) begin // if unit stride mask load EEW=8
        EEW=8;
    end
    else if (mop==IND_UNORDER | mop==IND_ORDER)begin // if indexed, EEW = SEW
        case (vsew)
            3'b000: EEW=8;
            3'b001: EEW=16;
            3'b010: EEW=32;
            default: EEW = 8;
        endcase
    end
    else begin
        case (width)
            3'b000:EEW=8;
            3'b101:EEW=16;
            3'b110:EEW=32;
            default: EEW = 8;
        endcase
    end
end
reg [9:0] EMUL; // effective LMUL
wire [9:0] EMUL_pre_process;

reg [7:0] LMUL; // LMUL = 2^(vlmul[2:0])
always @(*) begin
        case (vlmul)
        3'b001: LMUL = 2;  // lmul = 2
        3'b010: LMUL = 4;  // lmul = 4
        3'b011: LMUL = 8;  // lmul = 8
        default: LMUL = 1;   
    endcase
end


always @(*) begin
    case (vsew)
        3'b000: EMUL_pre_process = (EEW / 8);  // SEW = 8
        3'b001: EMUL_pre_process = (EEW / 16); // SEW = 16
        3'b010: EMUL_pre_process = (EEW / 32); // SEW = 32
        default: EMUL_pre_process = 1;         // Default case to handle unexpected values
    endcase
end

always @(posedge clk) begin
    case (vlmul)
        3'b000: EMUL <= EMUL_pre_process * 1;  // lmul = 1
        3'b001: EMUL <= EMUL_pre_process * 2;  // lmul = 2
        3'b010: EMUL <= EMUL_pre_process * 4;  // lmul = 4
        3'b011: EMUL <= EMUL_pre_process * 8;  // lmul = 8
        3'b101: EMUL <= EMUL_pre_process / 8;  // lmul = 1/8
        3'b110: EMUL <= EMUL_pre_process / 4;  // lmul = 1/4
        3'b111: EMUL <= EMUL_pre_process / 2;  // lmul = 1/2
        default: EMUL <= EMUL_pre_process;     // Default case to handle unexpected values
    endcase
end

always @(posedge clk) begin
    case (vlmul) // remember to +1 when referencing due to being able to only do a section of a reg ie lmul = 1/8,1/4,1/2
        3'b101: VLMAX <= (8'd128 >> (vsew + 8'd3)) >> 3;
        3'b110: VLMAX <= (8'd128 >> (vsew + 8'd3)) >> 2;
        3'b111: VLMAX <= (8'd128 >> (vsew + 8'd3)) >> 1;
        3'b000: VLMAX <= (8'd128 >> (vsew + 8'd3));
        3'b001: VLMAX <= (8'd128 >> (vsew + 8'd3)) << 1;
        3'b010: VLMAX <= (8'd128 >> (vsew + 8'd3)) << 2;
        3'b011: VLMAX <= (8'd128 >> (vsew + 8'd3)) << 3;
        default: VLMAX <= (8'd128 >> (vsew + 8'd3)); // Default case to handle unexpected values
    endcase
end

reg [4:0] num_elements_LS; // how many elements are being loaded/stored per reg
reg fault_first; //for fault-only-first unit stride load

always @(*) begin //determining how many elements are being loaded/stored
    if (d_vecop == VECOP_LOAD & mop == UNIT_STRIDE) begin //can just load in 32 bit chunks
        case (d_rs2)//lumop
 
            US_WLD: case (vsew)
                3'b000: begin num_elements_LS=16*EMUL; fault_first=0;end // 16 elements of 8-bit
                3'b001: begin num_elements_LS=8*EMUL; fault_first=0;end // 8 elements of 16-bit
                3'b010: begin num_elements_LS=4*EMUL; fault_first=0;end // 4 elements of 32-bit
                default: begin num_elements_LS=vl; fault_first=0;end
            endcase
            US_LD8: begin num_elements_LS=16*EMUL; fault_first=0; end
            US_fault: begin num_elements_LS=vl;  fault_first=1; end
            default: begin num_elements_LS=vl; fault_first=0; end //standard unit stride load
        endcase
    end
    if (d_vecop == VECOP_LOAD & mop == STRIDED) begin
        num_elements_LS=vl; fault_first=0;
    end
    if (d_vecop == VECOP_LOAD & (mop == IND_UNORDER | mop == IND_ORDER)) begin // indexed unordered and ordered function the same for our purposes
        case (vsew)
                3'b000: begin num_elements_LS=16*EMUL; fault_first=0; end // 16 elements of 8-bit
                3'b001: begin num_elements_LS=8*EMUL; fault_first=0; end // 8 elements of 16-bit
                3'b010: begin num_elements_LS=4*EMUL; fault_first=0; end// 4 elements of 32-bit
        endcase
    end
end


wire ld_st_mask_use;
assign ld_st_mask_use = mask_en;
wire [3:0] NF;
assign NF = nf+4'd1;

integer i;

reg [31:0] ld_str_addrs [9:0]; // generating address for load/store ops 
//worst case: strided LMUL=8 NF=4 or LMUL=4 NF=8 and EEW=8 | 8*4*(128/8) = 512 addresses

reg [7:0]nfxlmul; //nf x lmul
always @(posedge clk) begin
    nfxlmul = NF*LMUL; // raise vill if nfxlmul > 32
end

//NOTICE: I don't think we have to account for memory misalignment to simplify implementation

reg mem_misalignment; // if memory is misaligned

always @(*) begin
    if (todo == 1 && (d_vecop == VECOP_LOAD || d_vecop == VECOP_STORE)) begin
        case (EEW)
            16: mem_misalignment = (scalar_reg1 % 2 != 0);
            32: mem_misalignment = (scalar_reg1 % 4 != 0);
            default: mem_misalignment = 0; 
        endcase
    end else begin
        mem_misalignment = 0;
    end
end

//we do not have to care about order for unit-stride and strided load/stores

always @(posedge clk or posedge rst) begin // address generation per register to iterate through
    if(rst | (todo==1 & no_todo==1)) begin // rst at start of new vector instruction
            for (i = 0; i < 512; i=i+1) begin 
                ld_str_addrs[i] <= 0;
            end
    end
    else if (d_vecop == VECOP_LOAD | d_vecop==VECOP_STORE) begin
        case (mop)
            UNIT_STRIDE: begin //loading 32-bits at a time. no point for striding
                        
                    for (i = 0; i < 129; i=i+1) begin //32x4 +1 in event of memory misalignment
                        ld_str_addrs[i] <= scalar_reg1 + 4*i;
                    end
                
            end
            STRIDED: begin
                
                if (scalar_reg2[31]==1)begin // if negative stride
                    for (i = 0; i < 512; i=i+1) begin // 32x16 worst case
                        ld_str_addrs[i] <= scalar_reg1 - scalar_reg2*i; // base address + stride
                    end
                end
                else begin
                    for (i = 0; i < 512; i=i+1) begin // 32x16 worst case
                        ld_str_addrs[i] <= scalar_reg1 + scalar_reg2*i; // base address + stride
                    end
                end
            end
            IND_UNORDER: begin
                case (EEW) // will iterate through each register when lmul>1
                    7'd8: begin 
                        for (i = 0; i < 16; i=i+1) begin
                            ld_str_addrs[i] <= scalar_reg1 + test_vector_reg2[ 7+i*8 : 0+i*8 ];
                        end
                    end
                    7'd16: begin
                        for (i = 0; i < 8; i=i+1) begin
                            ld_str_addrs[i] <= scalar_reg1 + test_vector_reg2[ 15+i*16 : 0+i*16 ];
                        end
                    end
                    7'd32: begin
                        for (i = 0; i < 4; i=i+1) begin
                            ld_str_addrs[i] <= scalar_reg1 + test_vector_reg2[ 31+i*32 : 0+i*32 ];
                        end
                    end 
                endcase
            end
            IND_ORDER: begin
                case (EEW)
                    7'd8: begin
                        for (i = 0; i < 16; i=i+1) begin // 16 elements of 8-bit
                            ld_str_addrs[i] <= scalar_reg1 + test_vector_reg2[ 7+i*8 : 0+i*8 ]; // swap test_vector_reg2 w/ ReadReg2 when done testing
                        end
                    end
                    7'd16: begin
                        for (i = 0; i < 8; i=i+1) begin // 8 elements of 16-bit
                            ld_str_addrs[i] <= scalar_reg1 + test_vector_reg2[ 15+i*16 : 0+i*16 ];
                        end
                    end
                    7'd32: begin
                        for (i = 0; i < 4; i=i+1) begin // 4 elements of 32-bit
                            ld_str_addrs[i] <= scalar_reg1 + test_vector_reg2[ 31+i*32 : 0+i*32 ];
                        end
                    end 
                endcase
            end
        endcase
    end

end

// for loading ops ---------------------------------------------------------------------------------

reg [8:0] next_ld_addr; // next address to load from 
reg [4:0] next_ld_reg; // next reg to store to
reg [3:0] next_ld_pos; //next position in reg to store to
reg [3:0] ld_state; // state of load operation

wire [4:0] ld_st_reg_wire_rd;//used for selecting registers to read
wire [4:0] ld_st_reg_wire_st;//used for selecting registers to store to

wire[31:0] ld_use_bus; // will be used as a reference for loading from AHB interface
wire data_rec;//used to signal that data has been received from AHB interface

always @(posedge clk or posedge rst) begin
    if (rst) begin
        next_ld_addr<=0;
        next_ld_reg<=0;
        next_ld_pos<=0; 
        ld_state<=0;//waiting for instruction
    end
    else if (ld_state==0 & d_vecop == VECOP_LOAD) begin // modify to take into account AHB bus
        ld_state<=1;//instruction received "send load request state"
    end
    else if (ld_state==1 & data_rec) begin 
        ld_state<=2; //data received, store in register

    end
end


// for storing ops ---------------------------------------------------------------------------------


// Register file stuff ---------------------------------------------------------------------------------

    wire  RegW;
    wire [4:0] DR, SR1, SR2;
    wire [127:0] Reg_In;
    wire [127:0] ReadReg1, ReadReg2;
    wire [127:0]mask;

    Register VRF(clk, rst, RegW, DR, SR1, SR2, Reg_In, ReadReg1, ReadReg2, mask);

    assign DR = ((d_vecop==VECOP_LOAD | d_vecop==VECOP_STORE) ) ? ld_st_reg_wire_st : d_rd;
    assign SR1 = d_rs1; 
    assign SR2 = ((d_vecop==VECOP_LOAD | d_vecop==VECOP_STORE) ) ? ld_st_reg_wire : d_rs2; 

reg done; // set when done with arith operation

always @(posedge clk or posedge rst) begin //when recieving a new instruction set todo to 1, and wait for 1 cycle before setting no_todo to 1 to 0
    if(rst) begin
        todo <=0;
        no_todo <=1;
        done<=0;
    end
    else if (d_vecop!=VECOP_NONE) begin
        todo <=1;
        done <=0;
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