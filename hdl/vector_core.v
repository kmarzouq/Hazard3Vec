// `timescale 10ns/1ns

`include "hazard3_ops.vh"


// verilator lint_off WIDTH
module Vec_Main #(
    `include "hazard3_width_const.vh",
    `include "vec_vars.vh",
    parameter W_DATA = 32,
    parameter W_ADDR = 32,
    parameter MAX_VECWIDTH = 4
)  (
    input clk,
    input rst_n,

    //instruction stuff
    input [W_ALUOP-1:0] d_aluop,
    input  [W_DATA-1:0]    d_imm,
	input  [W_REGADDR-1:0] d_rs1,
	input  [W_REGADDR-1:0] d_rs2,
	input  [W_REGADDR-1:0] d_rd,
	input  [2:0]           d_funct3_32b,
	input  [6:0]           d_funct7_32b,
    input  [2:0]           d_funct3_32b_arith,
	input  [6:0]           d_funct7_32b_arith,
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
    assign  nf = d_funct7_32b[6:4]; // for segmented loading/storing | basically and integer. NF = nf+1
    
    wire [2:0]width;
    assign  width = d_funct3_32b; //width per element
    
    wire mask_en;
    assign  mask_en = ~vm | ((mop == UNIT_STRIDE) & (d_vecop == VECOP_LOAD | d_vecop == VECOP_STORE) & (US_LD8==d_rs2)); // if mask is enabled | if unit stride load/store and mask is enabled, then mask is enabled


//for loading and storing ----------------------------------------------------------------------



reg [31:0] EEW; //Effective Element Width

always @(*) begin //determining EEW
    if ((d_vecop == VECOP_LOAD | d_vecop == VECOP_STORE) & mop == UNIT_STRIDE & d_rs2==US_LD8) begin // if unit stride mask load EEW=8
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

//reg [7:0]VLMAX;// the maximum amount of elements is 128
reg bad_vl; // if VLMAX > vl
always @(posedge clk) begin //finding VLMAX  or the maximum amount of elements that can be worked on in a vector register
    // case (vlmul) 
    //     3'b101: VLMAX <= (8'd128 / EEW) >> 3;
    //     3'b110: VLMAX <= (8'd128 / EEW) >> 2;
    //     3'b111: VLMAX <= (8'd128 / EEW) >> 1;
    //     3'b000: VLMAX <= (8'd128 / EEW);
    //     3'b001: VLMAX <= (8'd128 / EEW) << 1;
    //     3'b010: VLMAX <= (8'd128 / EEW) << 2;
    //     3'b011: VLMAX <= (8'd128 / EEW) << 3;
    //     default: VLMAX <= (8'd128 / EEW); // Default case to handle unexpected values
    // endcase
    if (8'd128>(vl*NF)) begin
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
            case (EEW)
                8: begin num_elements_LS <= 16*NF/8*lmuldiv; fault_first<=0;end // 16 elements of 8-bit
                16: begin num_elements_LS <= 8*NF/8*lmuldiv; fault_first<=0;end // 8 elements of 16-bit
                32: begin num_elements_LS <= 4*NF*lmuldiv/8; fault_first<=0;end // 4 elements of 32-bit
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



reg [31:0] ld_str_addrs [511:0]; // generating address for load/store ops 
//worst case: strided LMUL=8 NF=4 or LMUL=4 NF=8 and EEW=8 | 8*4*(128/8) = 128 addresses

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
integer i;
always @(*) begin // address generation per register to iterate through
    if(!rst_n) begin // rst at start of new vector instruction
            for (i = 0; i < 128; i=i+1) begin 
                ld_str_addrs[i] = 0;
            end
    end
    else if (d_vecop == VECOP_LOAD | d_vecop == VECOP_STORE) begin
        case (mop)
            UNIT_STRIDE: begin //loading 32-bits at a time. no point for striding
                        
                    for (i = 0; i < 128; i=i+1) begin // 128 bit worst case
                        ld_str_addrs[i] = scalar_reg1 + i;
                    end
                
            end
            STRIDED: begin
                    for (i = 0; i < 128; i=i+1) begin // 128 bit worst case
                        ld_str_addrs[i] = scalar_reg1 + scalar_reg2*i; // base address + stride
                    end

            end
            IND_UNORDER: begin
                case (EEW) // will iterate through each register when lmul>1
                    7'd8: begin 
                        for (i = 0; i < 16; i=i+1) begin
                            ld_str_addrs[i] = scalar_reg1 + ReadReg2[ 7+i*8 -: 7 ];
                        end
                    end
                    7'd16: begin
                        for (i = 0; i < 8; i=i+1) begin
                            ld_str_addrs[i] = scalar_reg1 + ReadReg2[ 15+i*16 -: 15 ];
                        end
                    end
                    7'd32: begin
                        for (i = 0; i < 4; i=i+1) begin
                            ld_str_addrs[i] = scalar_reg1 + ReadReg2[ 31+i*32 -: 31 ];
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
                            ld_str_addrs[i] = scalar_reg1 + ReadReg2[ 7+i*8 -: 7 ]; // swap test_vector_reg2 w/ ReadReg2 when done testing
                        end
                    end
                    7'd16: begin
                        for (i = 0; i < 8; i=i+1) begin // 8 elements of 16-bit
                            ld_str_addrs[i] = scalar_reg1 + ReadReg2[ 15+i*16 -: 15 ];
                        end
                    end
                    7'd32: begin
                        for (i = 0; i < 4; i=i+1) begin // 4 elements of 32-bit
                            ld_str_addrs[i] = scalar_reg1 + ReadReg2[ 31+i*32 -: 31 ];
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
reg [3:0] pos_to_load [511:0]; // position in register to load to

integer i2;
always @(*) begin // target register generation
/*     if(!rst_n | (todo==1 & no_todo==1)) begin // rst at start of new vector instruction
            for (i2 = 0; i2 < 128; i2 = i2+1) begin 
                reg_to_load[i2] = 0;
            end
    end
    else */ if (d_vecop == VECOP_LOAD | d_vecop==VECOP_STORE) begin
        for (i2 = 0; i2 < 128; i2 = i2+1) begin //assuming vl = VLMAX = 128

            case (vlmul) // finding register to load to 
            //                 
            3'b001: reg_to_load[i2] = ((d_rd)*2 + ((i2%NF)*2) + (i2/(8'd128/EEW*NF)))%32; //LMUL=2
            3'b010: reg_to_load[i2] = ((d_rd)*4 + ((i2%NF)*4) + (i2/(8'd128/EEW*NF)))%32; //LMUL=4
            3'b011: reg_to_load[i2] = ((d_rd)*8 + ((i2%NF)*8) + (i2/(8'd128/EEW*NF)))%32; //LMUL=8

            3'b101: reg_to_load[i2] = ((d_rd + (i2%NF))/8)%32; //LMUL=1/8
            3'b110: reg_to_load[i2] = ((d_rd + (i2%NF))/4)%32; //LMUL=1/4
            3'b111: reg_to_load[i2] = ((d_rd + (i2%NF))/2)%32; //LMUL=1/2

            default: reg_to_load[i2] = (d_rd + (i2%NF))%32; // LMUL=1
            endcase
            end
    end
    
end

integer i3;
always @(posedge clk or negedge rst_n) begin // target pos in register generation
    if(!rst_n)  for (i3 = 0; i3 < 128; i3 = i3+1) pos_to_load[i3] = 0;

    else if (d_vecop == VECOP_LOAD | d_vecop==VECOP_STORE) begin
        for (i3 = 0; i3 < 128; i3=i3+1) begin 

            case (vlmul) // finding register to load to

                3'b101: pos_to_load[i3] = (i3/NF)%(8'd128/EEW/8) + (8'd128/EEW/8)*((d_rd + i3%NF)%8); //LMUL=1/8
                3'b110: pos_to_load[i3] = (i3/NF)%(8'd128/EEW/4) + (8'd128/EEW/4)*((d_rd + i3%NF)%4); //LMUL=1/4
                3'b111: pos_to_load[i3] = (i3/NF)%(8'd128/EEW/2) + (8'd128/EEW/2)*((d_rd + i3%NF)%2); //LMUL=1/2

                default: pos_to_load[i3] = (i3/NF)%(8'd128/EEW); // LMUL=1

                
            endcase
        end
    end
end

wire [4:0] ld_st_reg_wire_rd;//used for selecting registers to read
wire [4:0] ld_st_reg_wire_st;//used for selecting registers to store to

reg [31:0] to_mask; // data mask
always @(posedge clk) begin
    case (EEW)
        8 :to_mask<= 32'b00000000000000000000000011111111;
        16:to_mask<= 32'b00000000000000001111111111111111;
        32:to_mask<= 32'b11111111111111111111111111111111; 
        default: to_mask<= 32'b00000000000000000000000011111111;
    endcase
end

// for loading ops ---------------------------------------------------------------------------------

reg [31:0] curr_ld_addr; // current address to load from
reg [4:0] curr_ld_reg; // current reg to store to
reg [3:0] curr_ld_pos; //current position in reg to store to

reg [31:0] next_ld_addr; // next address to load from 
reg [4:0] next_ld_reg; // next reg to store to
reg [3:0] next_ld_pos; //next position in reg to store to
reg [5:0] ld_state; // state of load operation


reg [4:0] ld_reg_wire_rd;//used for selecting registers to read
reg [4:0] ld_reg_wire_st;//used for selecting registers to store to

wire[31:0] ld_use_bus; // will be used as a reference for loading from AHB interface


reg [31:0] passed_len_ld; // how many elements have been loaded/stored. Also will be used for vstart
reg [7:0] skip_cntr_ld; //for NF when vl < VLEN/EEW*NF


reg [31:0] bus_data; // avoid reading in garbage
always_latch @* if (d_vecop == VECOP_LOAD) bus_data = bus_rdata_d;

wire [VLEN-1:0] ld_gap_maker,ld_gap;//holds register data w/ gap for data to be put in
wire [VLEN-1:0] ld_fill;//holds data loaded and ready to be put into gaps
wire [127:0] prev_bypass = ld_st_reg_delayed == ld_reg_wire_rd ? result_vector : 0; // todo will this cause issues with consecutive instr
assign ld_fill = ( (128'd0 | (bus_data & to_mask)) << (curr_ld_pos*(EEW))); 
assign ld_gap_maker = ~( (128'd0 | (to_mask) ) << (curr_ld_pos*(EEW)) );
assign ld_gap = (prev_bypass & ld_gap_maker); // bypass for 1 cycle pipelined loads

always @* begin
    case (EEW)
        8:       bus_hsize_d = 3'd000; // 8-bit | setting size of data load 
        16:      bus_hsize_d = 3'd001; // 16-bit | setting size of data load
        32:      bus_hsize_d = 3'd010; // 32-bit | setting size of data load
        default: bus_hsize_d = 3'd000; // 8-bit | setting size of data load  
    endcase
end

reg ld_done;
reg [8:0] index;

reg [4:0] ld_st_reg_delayed;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n | ld_done) begin
        curr_ld_addr <= 0;
        curr_ld_reg <= 0;
        curr_ld_pos <= 0;
        passed_len_ld = 0;
        bus_aph_req_d <= 0;
        ld_done <= 0;
        skip_cntr_ld <= 0;
        index <= 0;
        RegW_a <= 0;
    end
    else if (d_vecop == VECOP_LOAD) begin
        case (mop)
            2'b00, 2'b01: begin
                // Setup memory request
                ld_reg_wire_st <= reg_to_load[passed_len_ld];
                ld_reg_wire_rd <= reg_to_load[passed_len_ld];
                curr_ld_pos <= pos_to_load[passed_len_ld];
                
                bus_priv_d <= 1;
                bus_hwrite_d <= 0;
                bus_aph_excl_d <= 0;
                bus_wdata_d <= 0;
                bus_aph_req_d <= 1;
                bus_haddr_d <= ld_str_addrs[passed_len_ld];

                // Handle data if ready
                if (bus_dph_ready_d) begin                    
                    if (~mask_en | (mask_en && mask[passed_len_ld])) begin
                        RegW_a <= 1;
                        result_vector <= (ld_gap | ld_fill);
                        ld_st_reg_delayed <= ld_reg_wire_st; // delayed since regfile saves next cycle
                    end
                    else begin
                        RegW_a <= 0;
                        result_vector <= ReadReg2;
                    end
                    if (num_elements_LS == passed_len_ld) begin
                        ld_done <= 1;
                    end
                    passed_len_ld = passed_len_ld + 1;
                    index <= passed_len_ld + 1 + skip_cntr_ld;

                    bus_haddr_d <= ld_str_addrs[passed_len_ld]; // immediately give next address
                end
                else begin
                    RegW_a <= 0;
                end
            end
            // 2'b10, 2'b11: // ... indexed handling ...
            default: begin end// ... default handling ...
        endcase
    end
end


// for storing ops ---------------------------------------------------------------------------------


// Register file stuff ---------------------------------------------------------------------------------

//add case for VECOP_ARITH
assign ld_st_reg_wire_rd = (d_vecop==VECOP_LOAD ) ? ld_reg_wire_rd : 0; //swap 0 for st_reg_wire_rd
assign ld_st_reg_wire_st = (d_vecop==VECOP_LOAD ) ? ld_st_reg_delayed : 0; //swap 0 for st_reg_wire_st

wire [4:0] DR, SR1, SR2;
wire [127:0] Reg_In;
wire [127:0] ReadReg1, ReadReg2;
wire [127:0] mask;
reg [127:0] result_vector;
reg RegW_a;

wire [127:0] test_mask;
assign test_mask = 128'b10111101;//test 32 bit mask

vec_regfile VRF(clk, rst_n, RegW, DR, SR1, SR2, Reg_In, ReadReg1, ReadReg2, mask);

assign DR = ((d_vecop==VECOP_LOAD | d_vecop==VECOP_STORE) ) ? ld_st_reg_wire_st : DR_a;
assign SR1 = d_rs1; //modify this for arith instructions
assign SR2 = ((d_vecop==VECOP_LOAD | d_vecop==VECOP_STORE) ) ? ld_st_reg_wire_rd : d_rs2;
wire RegW = RegW_a;

assign Reg_In = result_vector; // data to store

wire done = (d_vecop == VECOP_ARITH) ? done_arith : ld_done; // set when done with ld,str,or arith operation

always @*/*(posedge clk or negedge rst_n)*/ begin //when recieving a new instruction set todo to 1, and wait for 1 cycle before setting no_todo to 1 to 0
    if(!rst_n | done) begin
        todo = 0;
        no_todo = 1;
        //done<=0;
    end
    else if (d_vecop != VECOP_NONE && d_vecop != VECOP_CONFIG && todo == 0) begin
        todo = 1;
        //done <=0;
    end
    // else if (todo == 1 & no_todo == 1) begin
    //     no_todo = 0;
    // end
    // else if (done) begin
    //     todo = 0;
    //     no_todo = 1;
    //     //done<=0;
    // end
end

//Adder Stuff ---------------------------------------------------------------------------------

reg DR_a;

reg [MAX_VECWIDTH*XLEN-1:0] A_in;
reg [MAX_VECWIDTH*XLEN-1:0] B_in;
reg [MAX_VECWIDTH*XLEN-1:0] S_old;
wire [MAX_VECWIDTH*XLEN-1:0] add_out, sub_out, mul_out, mulh_out, mulhu_out, div_out, divu_out;

reg done_arith;
reg [2:0] arith_state;

wire vm_a;
wire [5:0] funct6;

assign vm_a = d_funct7_32b_arith[0];
assign funct6 = d_funct7_32b_arith[6:1];

reg [MAX_VECWIDTH-1:0] V0;

vadd32_vv #(.MAX_VECWIDTH(MAX_VECWIDTH), .XLEN(XLEN)) vadd_vv_inst (
    .vtype(vtype), .vxrm(vxrm),
    .vl(vl), .vlenb(vlenb), .vm_bit(vm_a), .v0_mask(V0), .vxsat(vxsat), .S_old(S_old), .A(A_in), .B(B_in),
    .S(add_out)
);

vsub32_vv #(.MAX_VECWIDTH(MAX_VECWIDTH), .XLEN(XLEN)) vsub_vv_inst (
    .vtype(vtype), .vxrm(vxrm),
    .vl(vl), .vlenb(vlenb), .vm_bit(vm_a), .v0_mask(V0), .vxsat(vxsat), .S_old(S_old), .A(A_in), .B(B_in),
    .S(sub_out)
);

vmul32_vv #(.MAX_VECWIDTH(MAX_VECWIDTH), .XLEN(XLEN)) vmul_vv_inst (
    .vtype(vtype), .vxrm(vxrm),
    .vl(vl), .vlenb(vlenb), .vm_bit(vm_a), .v0_mask(V0), .vxsat(vxsat), .S_old(S_old), .A(A_in), .B(B_in),
    .S(mul_out)
);

vmul32h_vv #(.MAX_VECWIDTH(MAX_VECWIDTH), .XLEN(XLEN)) vmulh_vv_inst (
    .vtype(vtype), .vxrm(vxrm),
    .vl(vl), .vlenb(vlenb), .vm_bit(vm_a), .v0_mask(V0), .vxsat(vxsat), .S_old(S_old), .A(A_in), .B(B_in),
    .S(mulh_out)
);

vmul32hu_vv #(.MAX_VECWIDTH(MAX_VECWIDTH), .XLEN(XLEN)) vmulhu_vv_inst (
    .vtype(vtype), .vxrm(vxrm),
    .vl(vl), .vlenb(vlenb), .vm_bit(vm_a), .v0_mask(V0), .vxsat(vxsat), .S_old(S_old), .A(A_in), .B(B_in),
    .S(mulhu_out)
);

vdiv32_vv #(.MAX_VECWIDTH(MAX_VECWIDTH), .XLEN(XLEN)) vdiv_vv_inst (
    .vtype(vtype), .vxrm(vxrm),
    .vl(vl), .vlenb(vlenb), .vm_bit(vm_a), .v0_mask(V0), .vxsat(vxsat), .S_old(S_old), .A(A_in), .B(B_in),
    .S(div_out)
);

vdiv32u_vv #(.MAX_VECWIDTH(MAX_VECWIDTH), .XLEN(XLEN)) vdivu_vv_inst (
    .vtype(vtype), .vxrm(vxrm),
    .vl(vl), .vlenb(vlenb), .vm_bit(vm_a), .v0_mask(V0), .vxsat(vxsat), .S_old(S_old), .A(A_in), .B(B_in),
    .S(divu_out)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        A_in <= 0;
        B_in <= 0;
        result_vector <= 0;
        done_arith <= 0;
        RegW_a <= 0;
        arith_state <= 0;
    end
    else begin
        case (arith_state)
            0: begin
                if (d_vecop == VECOP_ARITH) begin
                    arith_state <= 1;
                    done_arith <= 0;
                end
                else begin
                    arith_state <= 0;
                    done_arith <= 0;
                end
            end
            1: begin
                // Take data from readreg1 and readreg2
                A_in <= ReadReg2;
                B_in <= ReadReg1;
                arith_state <= 2;
            end
            2: begin
                // Use arith module results
                RegW_a <= 1;
                DR_a <= d_rd;

                case(d_funct3_32b_arith)
                    3'b000: begin // OPIVV
                        case(funct6)
                            6'b000000: result_vector <= add_out; 
                            6'b000010: result_vector <= sub_out;
                            default: result_vector <= 0;
                        endcase
                    end
                    3'b010: begin //OPMVV
                        case(funct6)
                            6'b100000: result_vector <= divu_out; 
                            6'b100001: result_vector <= div_out; 
                            6'b100100: result_vector <= mulhu_out; 
                            6'b100101: result_vector <= mul_out; 
                            6'b100111: result_vector <= mulh_out; 
                            default: result_vector <= 0;
                        endcase
                    end
                    default: result_vector <= 0;
                endcase

                done_arith <= 1'b1;
                arith_state <= 0;
            end
        endcase
    end
end


endmodule
// verilator lint_on WIDTH