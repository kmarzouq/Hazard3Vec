`timescale 1ns/1ps

module testbench #(
    `include "hazard3_width_const.vh",
    parameter W_ADDR = 32, // these from provided tb
	parameter W_DATA = 32,
	parameter XLEN = 32,
    parameter MAX_VECWIDTH = 4  
);
    
    // Clock and reset
    reg clk;
    reg rst;


    reg[31:0] instruction;

    // Instruction inputs
    reg  [W_ALUOP-1:0] d_aluop;
    reg  [W_DATA-1:0]  d_imm;
    reg  [W_REGADDR-1:0] d_rs1;
    reg  [W_REGADDR-1:0] d_rs2;
    reg  [W_REGADDR-1:0] d_rd;
    reg  [2:0]         d_funct3_32b;
    reg  [6:0]         d_funct7_32b;
    reg  [2:0]           d_funct3_32b_arith;
	reg  [6:0]           d_funct7_32b_arith;
    reg  [10:0]        d_zimm;
    reg  [W_VECOP-1:0] d_vecop;
    reg  [31:0]          scalar_reg1; // inputs from scalar reg file
    reg  [31:0]          scalar_reg2;
    reg  [127:0]         test_vector_reg2;

    // Load/store port
    wire                bus_aph_req_d;
    wire               bus_aph_excl_d;
    reg               bus_aph_ready_d;
    reg               bus_dph_ready_d;
    reg               bus_dph_err_d;
    reg               bus_dph_exokay_d;

    wire  [W_ADDR-1:0]  bus_haddr_d;
    wire  [2:0]         bus_hsize_d;
    wire                bus_priv_d;
    wire                bus_hwrite_d;
    wire  [W_DATA-1:0]  bus_wdata_d;
    reg [W_DATA-1:0]  bus_rdata_d;

    // Vector CSR inputs
    reg [XLEN-1:0] vstart;
    reg            vxsat;
    reg [1:0]      vxrm;
    reg [XLEN-1:0] vcsr;
    reg [XLEN-1:0] vl;
    reg [XLEN-1:0] vtype;
    reg [XLEN-1:0] vlenb;

    // Instantiate vector core
    Vec_Main dut (
        .clk(clk),
        .rst_n(rst),
        .d_aluop(d_aluop),
        .d_imm(d_imm),
        .d_rs1(d_rs1),
        .d_rs2(d_rs2),
        .d_rd(d_rd),
        .d_funct3_32b(d_funct3_32b),
        .d_funct7_32b(d_funct7_32b),
        .d_funct3_32b_arith(d_funct3_32b_arith),
        .d_funct7_32b_arith(d_funct7_32b_arith),
        .d_zimm(d_zimm),
        .d_vecop(d_vecop),
        .bus_aph_req_d(bus_aph_req_d),
        .bus_aph_excl_d(bus_aph_excl_d),
        .bus_aph_ready_d(bus_aph_ready_d),
        .bus_dph_ready_d(bus_dph_ready_d),
        .bus_dph_err_d(bus_dph_err_d),
        .bus_dph_exokay_d(bus_dph_exokay_d),
        .bus_haddr_d(bus_haddr_d),
        .bus_hsize_d(bus_hsize_d),
        .bus_priv_d(bus_priv_d),
        .bus_hwrite_d(bus_hwrite_d),
        .bus_wdata_d(bus_wdata_d),
        .bus_rdata_d(bus_rdata_d),
        .vstart(vstart),
        .vxsat(vxsat),
        .vxrm(vxrm),
        .vcsr(vcsr),
        .vl(vl),
        .vtype(vtype),
        .vlenb(vlenb),
        .scalar_reg1(scalar_reg1), // inputs from scalar reg file
        .scalar_reg2(scalar_reg2),
        .test_vector_reg2(test_vector_reg2)
    );

    // Clock generation
    always #5 clk = ~clk; // 10ns period

    // Testbench process
    initial begin
        $dumpfile("waves.vcd");
		$dumpvars(0, testbench);
        // Initialize signals
        clk = 0;
        rst = 1;
        d_aluop = 0;
        d_imm = 0;
        d_rs1 = 0;
        d_rs2 = 0;
        d_rd = 0;
        d_funct3_32b = 0;
        d_funct7_32b = 0;
        d_funct3_32b_arith = 0;
        d_funct7_32b_arith = 0;
        d_zimm = 0;
        d_vecop = 0;
        vstart = 0;
        vxsat = 0;
        vxrm = 2'b00;
        vcsr = 0;
        vl = 0;
        vtype = 0;
        vlenb = 0;
        scalar_reg1=0; // inputs from scalar reg file
        scalar_reg2=0;
        test_vector_reg2=0;

        // Reset sequence
        #5;
        rst = 0;
        #10
        rst = 1;
        d_aluop = MEMOP_NONE; // Example ALU operation
        d_vecop = VECOP_NONE; // Vector load

        #20

        // Test case 1: Set up vector operation
        d_aluop = ALUOP_VEC; // Example ALU operation
        d_vecop = VECOP_LOAD; // Vector load

        d_rd = 5'd0; // Destination register
        d_rs1 = 5'd1;// Source register 1
        d_rs2 = 5'b00000;// Source register 2
        scalar_reg1 = 32'd100;
        scalar_reg2 = 32'd50;

        //d_funct3_32b = 3'b000; // width = 8 bits
        //d_funct3_32b = 3'b101; // width = 16 bits
        d_funct3_32b = 3'b110; // width = 32 bits
        d_funct7_32b = 7'b001_0_00_1; // [31:29] nf , [28] mew, [27:26] mop , [25]vm
        d_vecop = 4'h2; // Vector Load
        vstart = 32'h0000_0000;
        vxrm = 2'b10; // Round down (truncate)
        vl = 32'd4; // Vector length
        vtype = 32'b0_0000000_00000000_00000000_0_0_000_000; // [31]vill , [7]vma,[6]vta,[5:3]vsew,[2:0]vlmul
        vlenb = 32'd16; // 16 8 bit elements












#60;
        // Simulate memory access
        
        bus_aph_ready_d = 1;
        #10
        bus_aph_ready_d = 0;
        bus_dph_ready_d = 1;
        bus_rdata_d = 32'h00000008;
        #10;
        bus_dph_ready_d = 0;
        #40

        //#10;
        bus_aph_ready_d = 1;
        #10
        bus_aph_ready_d = 0;
        bus_dph_ready_d = 1;
        bus_rdata_d = 32'h00000002;
        #10;
        bus_dph_ready_d = 0;
        #40

        //#10;
        bus_aph_ready_d = 1;
        #10
        bus_aph_ready_d = 0;
        bus_dph_ready_d = 1;
        bus_rdata_d = 32'h00000144;
        #10;
        bus_dph_ready_d = 0;
        #40

        //#10;
        bus_aph_ready_d = 1;
        #10
        bus_aph_ready_d = 0;
        bus_dph_ready_d = 1;
        bus_rdata_d = 32'h00000066;
        #10;
        bus_dph_ready_d = 0;
        #40

        // cutoff for lmul/nf testing

        bus_aph_ready_d = 1;
        #10
        bus_aph_ready_d = 0;
        bus_dph_ready_d = 1;
        bus_rdata_d = 32'hFFFFFFFF;
        #10;
        bus_dph_ready_d = 0;
        #40

        //#10;
        bus_aph_ready_d = 1;
        #10
        bus_aph_ready_d = 0;
        bus_dph_ready_d = 1;
        bus_rdata_d = 32'hEEEEEEEE;
        #10;
        bus_dph_ready_d = 0;
        #40

        bus_aph_ready_d = 1;
        #10
        bus_aph_ready_d = 0;
        bus_dph_ready_d = 1;
        bus_rdata_d = 32'h11111111;
        #10;
        bus_dph_ready_d = 0;
        #40

        #10;
        bus_aph_ready_d = 1;
        #10
        bus_aph_ready_d = 0;
        bus_dph_ready_d = 1;
        bus_rdata_d = 32'h22222222;
        #10;
        bus_dph_ready_d = 0;
        #40

        d_vecop = 4'h0;
        #10;


        // Display results
        $display("Test Case 1: Vector Unit Stride Vector load");
        // $display("Instruction: %h", {d_funct7_32b, d_rs2, d_rs1, d_funct3_32b, d_rd, d_aluop});
        // $display("Vector Start: %h", vstart);
        // $display("VLEN: %h", vlenb);
        // $display("Memory Addr: %h, Data Written: %h", bus_haddr_d, bus_wdata_d);

        // Add additional test cases here

        // Finish test
        #100;

        // Test case 1: Set up vector operation
        d_aluop = ALUOP_VEC; // Example ALU operation
        d_vecop = VECOP_ARITH; // Vector arith

        d_rd = 5'd0; // Destination register
        d_rs1 = 5'd1;// Source register 1
        d_rs2 = 5'b00000;// Source register 2
        scalar_reg1 = 32'd100;
        scalar_reg2 = 32'd50;

        //d_funct3_32b = 3'b000; // width = 8 bits
        //d_funct3_32b = 3'b101; // width = 16 bits
        d_funct3_32b_arith = 3'b010; // OPMVV
        d_funct7_32b_arith = 7'b100000_1; // vmul_vv, unmasked
        d_vecop = 4'h1; // Vector arith
        vstart = 32'h0000_0000;
        vxsat = 1'b0;
        vxrm = 2'b10; // Round down (truncate)
        vl = 32'd4; // Vector length
        vtype = 32'b0_0000000_00000000_00000000_0_0_010_000; // [31]vill , [7]vma,[6]vta,[5:3]vsew,[2:0]vlmul
        vlenb = 32'd16; // 16 8 bit elements

        // Now wait a few clock cycles for DUT to process

        #50;


        //start adding 
        $finish;
    end

endmodule