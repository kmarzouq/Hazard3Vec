`timescale 10ns/1ns

`include "hazard3_ops.vh"


// verilator lint_off WIDTH
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
	output reg                 bus_aph_excl_d,
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

    output reg todo, // if there is a task to do | used to stall scalar pipeline
    output reg no_todo
    
);
    
    
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



reg [31:0] EEW; //Effective Element Width

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
reg [9:0] EMUL_pre_process;

reg [7:0] LMUL; // LMUL = 2^(vlmul[2:0])
always @(posedge clk) begin //finding LMUL
        case (vlmul)
        3'b001: LMUL <= 2;  // lmul = 2
        3'b010: LMUL <= 4;  // lmul = 4
        3'b011: LMUL <= 8;  // lmul = 8
        default: LMUL <= 1;   
    endcase
end

reg [7:0]VLMAX;//max number of elements that can possibly be worked on in a vector register grouping
reg bad_vl; // if VLMAX > vl
always @(posedge clk) begin //finding VLMAX  or the maximum amount of elements that can be worked on in a vector register
    case (vlmul) 
        3'b101: VLMAX <= (8'd128 / EEW) >> 3;
        3'b110: VLMAX <= (8'd128 / EEW) >> 2;
        3'b111: VLMAX <= (8'd128 / EEW) >> 1;
        3'b000: VLMAX <= (8'd128 / EEW);
        3'b001: VLMAX <= (8'd128 / EEW) << 1;
        3'b010: VLMAX <= (8'd128 / EEW) << 2;
        3'b011: VLMAX <= (8'd128 / EEW) << 3;
        default: VLMAX <= (8'd128 / EEW); // Default case to handle unexpected values
    endcase
    if (VLMAX>vl) begin
        bad_vl<=0;
    end
    else begin
        bad_vl<=1;
    end
end

always @(*) begin //EMUL preprocess
    case (vsew)
        3'b000: EMUL_pre_process = (EEW / 8);  // SEW = 8
        3'b001: EMUL_pre_process = (EEW / 16); // SEW = 16
        3'b010: EMUL_pre_process = (EEW / 32); // SEW = 32
        default: EMUL_pre_process = 1;         // Default case to handle unexpected values
    endcase
end

always @(posedge clk) begin// finding EMUL = LMUL * (EEW/SEW) | for indexed loads/stores
    case (vlmul)

        3'b001: EMUL <= EMUL_pre_process * 2;  // lmul = 2
        3'b010: EMUL <= EMUL_pre_process * 4;  // lmul = 4
        3'b011: EMUL <= EMUL_pre_process * 8;  // lmul = 8

        3'b101: EMUL <= EMUL_pre_process / 8;  // lmul = 1/8
        3'b110: EMUL <= EMUL_pre_process / 4;  // lmul = 1/4
        3'b111: EMUL <= EMUL_pre_process / 2;  // lmul = 1/2

        default: EMUL <= EMUL_pre_process;     // lmul = 1
    endcase
end

reg [4:0] num_elements_LS; // how many elements are being loaded/stored per reg
reg fault_first; //for fault-only-first unit stride load

wire [9:0] NF;
assign NF = nf+4'd1;

reg [7:0]nfxlmul; //nf x lmul
reg bad_nf_LMUL;
always @(posedge clk) begin
    nfxlmul = NF*LMUL; 
    if (nfxlmul > 32) begin// raise vill if nfxlmul > 32
        bad_nf_LMUL <= 1;
    end
    else begin
        bad_nf_LMUL <= 0;
    end
end

reg [9:0] lmuldiv; //lmuldiv/8 = lmul
always @(posedge clk) begin
    case (vlmul)

        3'b001: lmuldiv <= 16;  // lmul = 2
        3'b010: lmuldiv <= 32;  // lmul = 4
        3'b011: lmuldiv <= 64;  // lmul = 8

        3'b101: lmuldiv <= 1;  // lmul = 1/8
        3'b110: lmuldiv <= 2;  // lmul = 1/4
        3'b111: lmuldiv <= 4;  // lmul = 1/2

        default: lmuldiv <= 8;     // lmul = 1
    endcase
end

always @(posedge clk) begin //determining how many elements are being loaded/stored
    if (d_vecop == VECOP_LOAD & mop == UNIT_STRIDE) begin  // vl should cover how many elements are working on in each vector register grouping
        case (d_rs2)//lumop
 
            US_WLD: begin
            //num_elements_LS = VLMAX*LMUL;
            case (vsew)
                3'b000: begin num_elements_LS <= 16*NF/8*lmuldiv; fault_first<=0;end // 16 elements of 8-bit
                3'b001: begin num_elements_LS <= 8*NF/8*lmuldiv; fault_first<=0;end // 8 elements of 16-bit
                3'b010: begin num_elements_LS <= 4*NF*lmuldiv/8; fault_first<=0;end // 4 elements of 32-bit
                default: begin num_elements_LS <= vl*NF; fault_first<=0;end
            endcase
            fault_first<=0;
            end
            US_LD8: begin num_elements_LS <= vl*NF; fault_first <= 0; end
            US_fault: begin num_elements_LS <= vl*NF;  fault_first <= 1; end
            default: begin num_elements_LS <= vl*NF; fault_first <= 0; end //standard unit stride load
        endcase
    end
    if (d_vecop == VECOP_LOAD & mop == STRIDED) begin
        num_elements_LS <= vl*NF; fault_first<=0;
    end
    if (d_vecop == VECOP_LOAD & (mop == IND_UNORDER | mop == IND_ORDER)) begin // indexed unordered and ordered function the same for our purposes
        case (vsew)
                3'b000: begin num_elements_LS <= vl*NF; fault_first<=0; end // 16 elements of 8-bit
                3'b001: begin num_elements_LS <= vl*NF; fault_first<=0; end // 8 elements of 16-bit
                3'b010: begin num_elements_LS <= vl*NF; fault_first<=0; end// 4 elements of 32-bit
                default:begin num_elements_LS <= vl*NF; fault_first<=0; end
        endcase
    end
end


wire ld_st_mask_use;
assign ld_st_mask_use = mask_en;


integer i;

reg [31:0] ld_str_addrs [511:0]; // generating address for load/store ops 
//worst case: strided LMUL=8 NF=4 or LMUL=4 NF=8 and EEW=8 | 8*4*(128/8) = 512 addresses

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

always @(*) begin // address generation per register to iterate through
    if(rst | (todo==1 & no_todo==1)) begin // rst at start of new vector instruction
            for (i = 0; i < 512; i=i+1) begin 
                ld_str_addrs[i] = 0;
            end
    end
    else if (d_vecop == VECOP_LOAD | d_vecop==VECOP_STORE) begin
        case (mop)
            UNIT_STRIDE: begin //loading 32-bits at a time. no point for striding
                        
                    for (i = 0; i < 512; i=i+1) begin // 32x16 worst case
                        ld_str_addrs[i] = scalar_reg1 + i;
                    end
                
            end
            STRIDED: begin
                    for (i = 0; i < 512; i=i+1) begin // 32x16 worst case
                        ld_str_addrs[i] = scalar_reg1 + scalar_reg2*i; // base address + stride
                    end

            end
            IND_UNORDER: begin
                case (EEW) // will iterate through each register when lmul>1
                    7'd8: begin 
                        for (i = 0; i < 16; i=i+1) begin
                            ld_str_addrs[i] = scalar_reg1 + test_vector_reg2[ 7+i*8 -: 7 ];
                        end
                    end
                    7'd16: begin
                        for (i = 0; i < 8; i=i+1) begin
                            ld_str_addrs[i] = scalar_reg1 + test_vector_reg2[ 15+i*16 -: 15 ];
                        end
                    end
                    7'd32: begin
                        for (i = 0; i < 4; i=i+1) begin
                            ld_str_addrs[i] = scalar_reg1 + test_vector_reg2[ 31+i*32 -: 31 ];
                        end
                    end 
                    default: begin
                        for (i = 0; i < 4; i=i+1) begin // 4 elements of 32-bit
                            ld_str_addrs[i] = -1;
                        end
                    end
                endcase
            end
            IND_ORDER: begin
                case (EEW)
                    7'd8: begin
                        for (i = 0; i < 16; i=i+1) begin // 16 elements of 8-bit
                            ld_str_addrs[i] = scalar_reg1 + test_vector_reg2[ 7+i*8 -: 7 ]; // swap test_vector_reg2 w/ ReadReg2 when done testing
                        end
                    end
                    7'd16: begin
                        for (i = 0; i < 8; i=i+1) begin // 8 elements of 16-bit
                            ld_str_addrs[i] = scalar_reg1 + test_vector_reg2[ 15+i*16 -: 15 ];
                        end
                    end
                    7'd32: begin
                        for (i = 0; i < 4; i=i+1) begin // 4 elements of 32-bit
                            ld_str_addrs[i] = scalar_reg1 + test_vector_reg2[ 31+i*32 -: 31 ];
                        end
                    end 
                    default: begin
                        for (i = 0; i < 4; i=i+1) begin // 4 elements of 32-bit
                            ld_str_addrs[i] = -1;
                        end
                    end
                endcase
            end
        endcase
    end

end

//both dependent on LMUL and NF
reg [4:0] reg_to_load[511:0]; // register to load to 
reg[3:0] pos_to_load[511:0]; // position in register to load to


always @(*) begin // target register generation
    if(rst | (todo==1 & no_todo==1)) begin // rst at start of new vector instruction
            for (i = 0; i < 512; i=i+1) begin 
                reg_to_load[i] = 0;
            end
    end
    else if (d_vecop == VECOP_LOAD | d_vecop==VECOP_STORE) begin
        for (i = 0; i < 512; i=i+1) begin //assuming vl = VLMAX

            case (vlmul) // finding register to load to 
            //                 
            3'b001: reg_to_load[i] = (d_rd + ((i%NF)*2) + (i/(8'd128/EEW*2*NF))*2*NF)%32; //LMUL=2
            3'b010: reg_to_load[i] = (d_rd + ((i%NF)*4) + (i/(8'd128/EEW*4*NF))*4*NF)%32; //LMUL=4
            3'b011: reg_to_load[i] = (d_rd + ((i%NF)*8) + (i/(8'd128/EEW*8*NF))*8*NF)%32; //LMUL=8

            3'b101: reg_to_load[i] = (d_rd + (i%NF) + (i/(8'd128/8/EEW*NF))*NF)%32; //LMUL=1/8
            3'b110: reg_to_load[i] = (d_rd + (i%NF) + (i/(8'd128/4/EEW*NF))*NF)%32; //LMUL=1/4
            3'b111: reg_to_load[i] = (d_rd + (i%NF) + (i/(8'd128/2/EEW*NF))*NF)%32; //LMUL=1/2

            default: reg_to_load[i] = (d_rd + (i%NF) + (i/(8'd128/EEW*NF))*NF)%32; // LMUL=1
            endcase
            end
    end
    
end

always @(posedge clk or posedge rst) begin // target pos in register generation
    if(rst | (todo==1 & no_todo==1)) begin // rst at start of new vector instruction
            for (i = 0; i < 512; i=i+1) begin 
                pos_to_load[i] = 0;
            end
    end 
    else if (d_vecop == VECOP_LOAD | d_vecop==VECOP_STORE) begin
        for (i = 0; i < 512; i=i+1) begin 

            case (vlmul) // finding register to load to

            3'b101: pos_to_load[i] = i%(8'd128/8/EEW*NF); //LMUL=1/8
            3'b110: pos_to_load[i] = i%(8'd128/4/EEW*NF); //LMUL=1/4
            3'b111: pos_to_load[i] = i%(8'd128/2/EEW*NF); //LMUL=1/2

            default: pos_to_load[i] = i%(8'd128/EEW*NF); // LMUL=1,2,4,8
            endcase
            end
    end
    
end

wire [4:0] ld_st_reg_wire_rd;//used for selecting registers to read
wire [4:0] ld_st_reg_wire_st;//used for selecting registers to store to

// for loading ops ---------------------------------------------------------------------------------

reg [31:0] curr_ld_addr; // current address to load from
reg [4:0] curr_ld_reg; // current reg to store to
reg [3:0] curr_ld_pos; //current position in reg to store to

reg [31:0] next_ld_addr; // next address to load from 
reg [4:0] next_ld_reg; // next reg to store to
reg [3:0] next_ld_pos; //next position in reg to store to
reg [3:0] ld_state; // state of load operation

reg [127:0] to_store; // data to store

reg [4:0] ld_reg_wire_rd;//used for selecting registers to read
reg [4:0] ld_reg_wire_st;//used for selecting registers to store to

wire[31:0] ld_use_bus; // will be used as a reference for loading from AHB interface


reg [31:0] passed_len; // how many elements have been loaded/stored. Also will be used for vstart
reg [7:0] skip_cntr; //for NF when vl < VLEN/EEW*NF

reg [31:0] to_mask; // data mask
always @(posedge clk) begin
    case (EEW)
        8 :to_mask<= 32'b00000000000000000000000011111111;
        16:to_mask<= 32'b00000000000000001111111111111111;
        32:to_mask<= 32'b11111111111111111111111111111111; 
        default: to_mask<= 32'b00000000000000000000000011111111;
    endcase
end

reg ld_done;
always @(posedge clk or posedge rst) begin
    if (rst | ld_done) begin //waiting for instruction
        next_ld_addr<=0;
        next_ld_reg<=0;
        next_ld_pos<=0; 
        curr_ld_addr<=0;
        curr_ld_reg<=0;
        curr_ld_pos<=0;
        to_store<=0;
        ld_state<=0;
        passed_len<=0;
        bus_aph_req_d<=0;
        ld_done<=0;
        skip_cntr<=0;
    end
    else if (ld_state==0 & d_vecop == VECOP_LOAD) begin // modify to take into account AHB bus
        ld_state<=1;//instruction received "send load request state" / "start state"
        
    end
    else if (ld_state==1) begin //unit stride
        case (mop)
            2'b00: begin ld_state<=2; //unit stride
                    curr_ld_addr<=ld_str_addrs[passed_len];
                    curr_ld_reg<=d_rd;
                    curr_ld_pos<=0;
                    end
            2'b01:ld_state<=3; //strided
            2'b10:ld_state<=4; //indexed
            2'b11:ld_state<=4; //indexed 
            default:ld_state<=2; //unit stride
        endcase
    end
    else if (ld_state==2) begin
        RegW<=0;
            case (d_rs2)
                5'b00000:begin
                    if ((vl*NF)==passed_len ) begin
                            ld_done<=1;
                        end
                    else begin
                    // insert AHB signals for load
                    bus_aph_req_d<=1;//requesting data
                    bus_haddr_d<=curr_ld_addr; // address to read from
                    case (EEW)
                        8:bus_hsize_d<=3'd000; // 8-bit | setting size of data load 
                        16:bus_hsize_d<=3'd001; // 16-bit | setting size of data load
                        32:bus_hsize_d<=3'd010; // 32-bit | setting size of data load
                        default:bus_hsize_d<=3'd000; // 8-bit | setting size of data load  
                    endcase
                    bus_priv_d<=1; // user mode
                    bus_hwrite_d<=0; // read transaction
                    bus_aph_excl_d<=0; // not exclusive
                    bus_wdata_d<=0; // not storing data

                    //find next reg to load/store to
                    next_ld_addr<=ld_str_addrs[passed_len+1];

                    case (vlmul) 
                        3'b101: begin
                        next_ld_reg <= reg_to_load[passed_len + 1 + skip_cntr*(8'd128/8/EEW - vl)];
                        next_ld_pos <= pos_to_load[passed_len + 1 + skip_cntr*(8'd128/8/EEW - vl)];
                        end 
                        3'b110: begin
                        next_ld_reg <= reg_to_load[passed_len + 1 + skip_cntr*(8'd128/4/EEW - vl)];
                        next_ld_pos <= pos_to_load[passed_len + 1 + skip_cntr*(8'd128/4/EEW - vl)];
                        end 
                        3'b111: begin
                        next_ld_reg <= reg_to_load[passed_len + 1 + skip_cntr*(8'd128/2/EEW - vl)];
                        next_ld_pos <= pos_to_load[passed_len + 1 + skip_cntr*(8'd128/2/EEW - vl)];
                        end 
                        3'b001: begin
                        next_ld_reg <= reg_to_load[passed_len + 1 + skip_cntr*(8'd128/EEW*2 - vl)];
                        next_ld_pos <= pos_to_load[passed_len + 1 + skip_cntr*(8'd128/EEW*2 - vl)];
                        end 
                        3'b010: begin
                        next_ld_reg <= reg_to_load[passed_len + 1 + skip_cntr*(8'd128/EEW*4 - vl)];
                        next_ld_pos <= pos_to_load[passed_len + 1 + skip_cntr*(8'd128/EEW*4 - vl)];
                        end 
                        3'b011: begin
                        next_ld_reg <= reg_to_load[passed_len + 1 + skip_cntr*(8'd128/EEW*8 - vl)];
                        next_ld_pos <= pos_to_load[passed_len + 1 + skip_cntr*(8'd128/EEW*8 - vl)];
                        end 
                        default: begin
                        next_ld_reg <= reg_to_load[passed_len + 1 + skip_cntr*(8'd128/EEW - vl)];// Default case to handle unexpected values
                        next_ld_pos <= pos_to_load[passed_len + 1 + skip_cntr*(8'd128/EEW - vl)];// also LMUL = 1
                        end 
                    endcase

                    //next_ld_reg <= reg_to_load[passed_len + 1 + skip_cntr*(8'd128/EEW*NF - vl)];
                    
                    //next_ld_pos<= (passed_len + 1 + skip_cntr*(8'd128/EEW*NF - vl))%(8'd128/EEW); 
                    ld_state<=5;
                     

                    end
                end
                // 5'b01000:
                // 5'b01011:
                // 5'b10000:  
                // default: 
            endcase

    end

    else if (ld_state==5) begin
        if (bus_aph_ready_d==1) begin // acknowledgement of request from memory
            ld_state<=6;
            bus_aph_req_d<=0;
            ld_reg_wire_st<=curr_ld_reg;
            ld_reg_wire_rd<=curr_ld_reg;
        end
    end

    else if (ld_state==6) begin //load state for unit-stride
        if (bus_dph_ready_d==1) begin
            RegW<=1;
            case (d_rs2)
                5'b00000: begin
                    if (~mask_en | (mask_en && (mask[curr_ld_pos*EEW]))) begin
                        to_store <= (ReadReg2 & ~( (128'd0 | (to_mask)) << (curr_ld_pos*(EEW)))) | ( ( (128'd0 | (bus_rdata_d & to_mask)) << (curr_ld_pos*(EEW))) ) ; // storing data
                        //to_store <= (ReadReg2 & ~( (128'd0 | (to_mask)) << (curr_ld_pos*(EEW)))) | 
                    end
                    else begin
                        to_store <= to_store; // no change
                    end
                    
                end
                //default: 
            endcase
            ld_state<=2;
            passed_len<=passed_len+1;
            if (NF!=1 & ((passed_len+1)%(vl*NF))==0) begin
                skip_cntr<= skip_cntr+1;
            end
            curr_ld_addr<=next_ld_addr;
            curr_ld_reg<=next_ld_reg;
            curr_ld_pos<=next_ld_pos;
        end
    end
end


// for storing ops ---------------------------------------------------------------------------------


// Register file stuff ---------------------------------------------------------------------------------

assign ld_st_reg_wire_rd = (d_vecop==VECOP_LOAD ) ? ld_reg_wire_rd : 0; //swap 0 for st_reg_wire_rd
assign ld_st_reg_wire_st = (d_vecop==VECOP_LOAD ) ? ld_reg_wire_st : 0; //swap 0 for st_reg_wire_st
    reg  RegW;
    wire [4:0] DR, SR1, SR2;
    wire [127:0] Reg_In;
    wire [127:0] ReadReg1, ReadReg2;
    wire [127:0]mask;

    vec_regfile VRF(clk, rst, RegW, DR, SR1, SR2, Reg_In, ReadReg1, ReadReg2, mask);

    assign DR = ((d_vecop==VECOP_LOAD | d_vecop==VECOP_STORE) ) ? ld_st_reg_wire_st : d_rd;
    assign SR1 = d_rs1; 
    assign SR2 = ((d_vecop==VECOP_LOAD | d_vecop==VECOP_STORE) ) ? ld_st_reg_wire_rd : d_rs2; 

    assign Reg_In = to_store; // data to store

wire done; // set when done with arith operation

assign done = ld_done; // set when done with ld,str,or arith operation

always @(posedge clk or posedge rst) begin //when recieving a new instruction set todo to 1, and wait for 1 cycle before setting no_todo to 1 to 0
    if(rst) begin
        todo <=0;
        no_todo <=1;
        //done<=0;
    end
    else if (d_vecop!=VECOP_NONE) begin
        todo <=1;
        //done <=0;
    end
    if (todo==1 & no_todo==1) begin
        no_todo<=0;
    end
    if (done) begin
        todo<=0;
        no_todo<=1;
        //done<=0;
    end
end



    
endmodule
// verilator lint_on WIDTH
