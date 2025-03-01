`timescale 1ns/1ps

module testbench #(
    `include "hazard3_width_const.vh",
    parameter W_ADDR = 32, // these from provided tb
	parameter W_DATA = 32,
	parameter XLEN = 32  
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
    reg  [10:0]        d_zimm;
    reg  [W_VECOP-1:0] d_vecop;
    reg  [31:0]          scalar_reg1; // inputs from scalar reg file
    reg  [31:0]          scalar_reg2;
    reg  [127:0]         test_vector_reg2;

    // Load/store port
    reg                bus_aph_req_d;
    wire               bus_aph_excl_d;
    wire               bus_aph_ready_d;
    wire               bus_dph_ready_d;
    wire               bus_dph_err_d;
    wire               bus_dph_exokay_d;

    reg  [W_ADDR-1:0]  bus_haddr_d;
    reg  [2:0]         bus_hsize_d;
    reg                bus_priv_d;
    reg                bus_hwrite_d;
    reg  [W_DATA-1:0]  bus_wdata_d;
    wire [W_DATA-1:0]  bus_rdata_d;

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
        .rst(rst),
        .d_aluop(d_aluop),
        .d_imm(d_imm),
        .d_rs1(d_rs1),
        .d_rs2(d_rs2),
        .d_rd(d_rd),
        .d_funct3_32b(d_funct3_32b),
        .d_funct7_32b(d_funct7_32b),
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
		$dumpvars(0, tb);
        // Initialize signals
        clk = 0;
        rst = 0;
        d_aluop = 0;
        d_imm = 0;
        d_rs1 = 0;
        d_rs2 = 0;
        d_rd = 0;
        d_funct3_32b = 0;
        d_funct7_32b = 0;
        d_zimm = 0;
        d_vecop = 0;
        bus_aph_req_d = 0;
        bus_haddr_d = 0;
        bus_hsize_d = 0;
        bus_priv_d = 0;
        bus_hwrite_d = 0;
        bus_wdata_d = 0;
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
        rst = 1;
        #10
        rst = 0;

        // Test case 1: Set up vector operation
        #10;
        d_aluop = 6'h3f; // Example ALU operation
        //d_rs1 = 5'd1;
        d_rs2 = 5'b01000;
        //d_rd = 5'd3;
        d_funct3_32b = 3'b000;
        d_funct7_32b = 7'b0000001;
        d_vecop = 4'h2; // Vector Load
        vstart = 32'h0000_0008;
        vxrm = 2'b10; // Round down (truncate)
        vl = 32'd32; // Vector length
        vtype = 32'b00000000_00000000_00000000_00000000; // Example vector type
        vlenb = 32'd16; // 16 8 bit elements













        // Simulate a memory request
        #10;
        bus_aph_req_d = 1;
        bus_haddr_d = 32'h2000_0000; // Example memory address
        bus_hsize_d = 3'b010; // Word-sized transaction
        bus_priv_d = 1;
        bus_hwrite_d = 1;
        bus_wdata_d = 32'hDEADBEEF;

        #10;
        bus_aph_req_d = 0; // Deassert request

        // Wait for response
        wait (bus_dph_ready_d);

        // Display results
        $display("Test Case 1: Vector Operation");
        $display("Instruction: %h", {d_funct7_32b, d_rs2, d_rs1, d_funct3_32b, d_rd, d_aluop});
        $display("Vector Start: %h", vstart);
        $display("VLEN: %h", vlenb);
        $display("Memory Addr: %h, Data Written: %h", bus_haddr_d, bus_wdata_d);

        // Add additional test cases here

        // Finish test
        #50;
        $finish;
    end

endmodule
