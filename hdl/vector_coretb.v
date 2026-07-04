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
    // AI-GENERATED: d_rs1_pre/d_rs2_pre were never connected to the DUT (left at their
    // default 0), so Vec_Main's SR1/SR2 vector-regfile addresses for arithmetic ops were
    // always 0 regardless of d_rs1/d_rs2. In hazard3_core.v these just carry the same
    // register-address value one pipeline stage earlier (d_rs1_predecoded_nxt), so for
    // this standalone testbench they should track d_rs1/d_rs2 directly.
    reg  [W_REGADDR-1:0] d_rs1_pre;
    reg  [W_REGADDR-1:0] d_rs2_pre;
    reg  [W_REGADDR-1:0] d_rd;
    reg  [2:0]         d_funct3_32b;
    reg  [6:0]         d_funct7_32b;
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
        .d_rs1_pre(d_rs1_pre), // AI-GENERATED: was unconnected, see declaration comment above
        .d_rs2_pre(d_rs2_pre), // AI-GENERATED: was unconnected, see declaration comment above
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
        .test_vector_reg2(test_vector_reg2),
        .todo(),
        .no_todo()
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
        d_rs1_pre = 0; // AI-GENERATED
        d_rs2_pre = 0; // AI-GENERATED
        d_rd = 0;
        d_funct3_32b = 0;
        d_funct7_32b = 0;
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

        d_rd = 5'd1; // Destination register
        d_rs1 = 5'd1;// Source register 1
        d_rs2 = 5'b00000;// Source register 2
        scalar_reg1 = 32'd100;
        scalar_reg2 = 32'd50;

        //d_funct3_32b = 3'b000; // width = 8 bits
        d_funct3_32b = 3'b101; // width = 16 bits
        //d_funct3_32b = 3'b110; // width = 32 bits
        d_funct7_32b = 7'b000_0_00_1; // [31:29] nf , [28] mew, [27:26] mop , [25]vm
        d_vecop = 4'h2; // Vector Load
        vstart = 32'h0000_0000;
        vxrm = 2'b10; // Round down (truncate)
        vl = 32'd8; // Vector length
        vtype = 32'b0_0000000_00000000_00000000_0_0_000_001; // [31]vill , [7]vma,[6]vta,[5:3]vsew,[2:0]vlmul
        vlenb = 32'd16; // 16 8 bit elements


#60;
        // Simulate memory access
        
        bus_aph_ready_d = 1;
        #10
        bus_aph_ready_d = 0;
        bus_dph_ready_d = 1;
        bus_rdata_d = 32'hBBBBAAAA;
        #10;
        bus_dph_ready_d = 0;
        #40

        //#10;
        bus_aph_ready_d = 1;
        #10
        bus_aph_ready_d = 0;
        bus_dph_ready_d = 1;
        bus_rdata_d = 32'hDDDDCCCC;
        #10;
        bus_dph_ready_d = 0;
        #40

        //#10;
        bus_aph_ready_d = 1;
        #10
        bus_aph_ready_d = 0;
        bus_dph_ready_d = 1;
        bus_rdata_d = 32'hFFFFEEEE;
        #10;
        bus_dph_ready_d = 0;
        #40

        //#10;
        bus_aph_ready_d = 1;
        #10
        bus_aph_ready_d = 0;
        bus_dph_ready_d = 1;
        bus_rdata_d = 32'h22221111;
        #10;
        bus_dph_ready_d = 0;
        #40

        // cutoff for lmul/nf testing

        bus_aph_ready_d = 1;
        #10
        bus_aph_ready_d = 0;
        bus_dph_ready_d = 1;
        bus_rdata_d = 32'hEEEEEEEE;
        #10;
        bus_dph_ready_d = 0;
        #40

        //#10;
        bus_aph_ready_d = 1;
        #10
        bus_aph_ready_d = 0;
        bus_dph_ready_d = 1;
        bus_rdata_d = 32'hFFFFFFFF;
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
        
        // #10;
        // bus_aph_ready_d = 1;
        // #10
        // bus_aph_ready_d = 0;
        // bus_dph_ready_d = 1;
        // bus_rdata_d = 32'h33333333;
        // #10;
        // bus_dph_ready_d = 0;
        // #40

        d_vecop = 4'h0;
        #10;


        // Display results
        $display("Test Case 1: Vector Unit Stride Vector load");
        $display("Instruction: %h", {d_funct7_32b, d_rs2, d_rs1, d_funct3_32b, d_rd, d_aluop});
        $display("Vector Start: %h", vstart);
        $display("VLEN: %h", vlenb);
        $display("Memory Addr: %h, Data Written: %h", bus_haddr_d, bus_wdata_d);

        // Add additional test cases here

        // Finish test
        #100;

        // Test case 1: Set up vector operation
        d_aluop = ALUOP_VEC; // Example ALU operation
        d_vecop = VECOP_ARITH; // Vector arith

        d_rd = 5'd0; // Destination register
        d_rs1 = 5'd1;// Source register 1
        d_rs2 = 5'b00010;// Source register 2
        scalar_reg1 = 32'd100;
        scalar_reg2 = 32'd50;

        //d_funct3_32b = 3'b000; // width = 8 bits
        //d_funct3_32b = 3'b101; // width = 16 bits
        d_funct3_32b = 3'b000; // OPMVV
        d_funct7_32b = 7'b000000_1; // vadd_vv, unmasked
        d_vecop = 4'h1; // Vector arith
        vstart = 32'h0000_0000;
        vxsat = 1'b0;
        vxrm = 2'b10; // Round down (truncate)
        vl = 32'd1; // Vector length
        vtype = 32'b0_0000000_00000000_00000000_0_0_010_001; // [31]vill , [7]vma,[6]vta,[5:3]vsew,[2:0]vlmul
        vlenb = 32'd16; // 16 8 bit elements

        // Now wait a few clock cycles for DUT to process

        #50;

        // === AI-GENERATED BEGIN: directed self-checked tests for OPIVX/OPMVX (.vx) dispatch ===
        // Covers the newly-wired scalar-operand path in vector_core.v (recovered from the
        // stable branch's unmerged niels-holzmann _vx modules) and regression-checks the
        // vs2-op-rs1 (not rs1-op-vs2) operand-order fix applied to vsub/vdiv/vdivu.
        begin : vx_tests
            integer errors;
            errors = 0;

            // Common config: SEW=32, LMUL=1, vl=4 (one full 128-bit register)
            vtype  = 32'h0000_0010; // vma=0,vta=0,vsew=3'b010,vlmul=3'b000
            vlenb  = 32'd16;
            vl     = 32'd4;
            vxsat  = 1'b0;
            vxrm   = 2'b00;

            // Preload v1 (vs2 operand) = [10, 20, 30, 40] (element 0 in low bits)
            dut.VRF.REG[1] = {32'd40, 32'd30, 32'd20, 32'd10};
            scalar_reg1 = 32'd5;

            d_aluop = ALUOP_VEC;
            d_vecop = VECOP_ARITH;
            d_rd  = 5'd3;
            d_rs2 = 5'd1; d_rs2_pre = 5'd1; // vs2 = v1
            #30; // let the (synchronously-read) vec regfile catch up to the new SR2 address

            // vadd.vx v3, v1, x5  =>  v1 + 5
            d_funct3_32b = 3'b100; // OPIVX
            d_funct7_32b = 7'b000000_1; // funct6=vadd, vm=1 (unmasked)
            #30;
            if (dut.VRF.REG[3] === {32'd45, 32'd35, 32'd25, 32'd15})
                $display("PASS: vadd.vx");
            else begin
                $display("FAIL: vadd.vx got %h", dut.VRF.REG[3]);
                errors = errors + 1;
            end

            // vsub.vx v3, v1, x5  =>  v1 - 5
            d_funct7_32b = 7'b000010_1; // funct6=vsub, vm=1
            #30;
            if (dut.VRF.REG[3] === {32'd35, 32'd25, 32'd15, 32'd5})
                $display("PASS: vsub.vx");
            else begin
                $display("FAIL: vsub.vx got %h", dut.VRF.REG[3]);
                errors = errors + 1;
            end

            // vmul.vx v3, v1, x5  =>  v1 * 5
            d_funct3_32b = 3'b110; // OPMVX
            d_funct7_32b = 7'b100101_1; // funct6=vmul, vm=1
            #30;
            if (dut.VRF.REG[3] === {32'd200, 32'd150, 32'd100, 32'd50})
                $display("PASS: vmul.vx");
            else begin
                $display("FAIL: vmul.vx got %h", dut.VRF.REG[3]);
                errors = errors + 1;
            end

            // vdivu.vx v3, v1, x5  =>  v1 / 5 (unsigned) -- regresses the vs2/rs1 operand-order fix
            d_funct7_32b = 7'b100000_1; // funct6=vdivu, vm=1
            #30;
            if (dut.VRF.REG[3] === {32'd8, 32'd6, 32'd4, 32'd2})
                $display("PASS: vdivu.vx");
            else begin
                $display("FAIL: vdivu.vx got %h", dut.VRF.REG[3]);
                errors = errors + 1;
            end

            // vdiv.vx v3, v1, x5  =>  v1 / 5 (signed) -- regresses the vs2/rs1 operand-order fix
            d_funct7_32b = 7'b100001_1; // funct6=vdiv, vm=1
            #30;
            if (dut.VRF.REG[3] === {32'd8, 32'd6, 32'd4, 32'd2})
                $display("PASS: vdiv.vx");
            else begin
                $display("FAIL: vdiv.vx got %h", dut.VRF.REG[3]);
                errors = errors + 1;
            end

            // vsub.vv v3, v1, v2 => v1 - v2 -- regresses the vs2-vs1 (not vs1-vs2) operand-order fix
            dut.VRF.REG[2] = {32'd1, 32'd1, 32'd1, 32'd1};
            d_funct3_32b = 3'b000; // OPIVV
            d_funct7_32b = 7'b000010_1; // funct6=vsub, vm=1
            d_rs1 = 5'd2; d_rs1_pre = 5'd2; // vs1 = v2
            d_rs2 = 5'd1; d_rs2_pre = 5'd1; // vs2 = v1
            #30;
            if (dut.VRF.REG[3] === {32'd39, 32'd29, 32'd19, 32'd9})
                $display("PASS: vsub.vv");
            else begin
                $display("FAIL: vsub.vv got %h", dut.VRF.REG[3]);
                errors = errors + 1;
            end

            d_vecop = VECOP_NONE;

            if (errors == 0)
                $display("=== ALL OPIVX/OPMVX DIRECTED TESTS PASSED ===");
            else
                $display("=== %0d OPIVX/OPMVX DIRECTED TEST(S) FAILED ===", errors);
        end
        // === AI-GENERATED END ===

        // === AI-GENERATED BEGIN: directed tests for the generic int ALU (vand/vmax/vsll/vrsub.vx) ===
        begin : int_alu_tests
            integer errors2;
            errors2 = 0;

            d_aluop = ALUOP_VEC;
            d_vecop = VECOP_ARITH;
            d_rd = 5'd3;
            d_rs2 = 5'd1; d_rs2_pre = 5'd1; // vs2 = v1 = [10,20,30,40] (still set from vx_tests)
            d_funct3_32b = 3'b100; // OPIVX

            // vand.vx v3, v1, x5 => v1 & 5
            scalar_reg1 = 32'd5;
            d_funct7_32b = 7'b001001_1; // funct6=vand, vm=1
            #30;
            if (dut.VRF.REG[3] === {32'd0, 32'd4, 32'd4, 32'd0})
                $display("PASS: vand.vx");
            else begin
                $display("FAIL: vand.vx got %h", dut.VRF.REG[3]);
                errors2 = errors2 + 1;
            end

            // vmax.vx v3, v1, x25 => max(v1, 25)
            scalar_reg1 = 32'd25;
            d_funct7_32b = 7'b000111_1; // funct6=vmax, vm=1
            #30;
            if (dut.VRF.REG[3] === {32'd40, 32'd30, 32'd25, 32'd25})
                $display("PASS: vmax.vx");
            else begin
                $display("FAIL: vmax.vx got %h", dut.VRF.REG[3]);
                errors2 = errors2 + 1;
            end

            // vsll.vx v3, v1, x2 => v1 << 2
            scalar_reg1 = 32'd2;
            d_funct7_32b = 7'b100101_1; // funct6=vsll, vm=1
            #30;
            if (dut.VRF.REG[3] === {32'd160, 32'd120, 32'd80, 32'd40})
                $display("PASS: vsll.vx");
            else begin
                $display("FAIL: vsll.vx got %h", dut.VRF.REG[3]);
                errors2 = errors2 + 1;
            end

            // vrsub.vx v3, v1, x100 => 100 - v1
            scalar_reg1 = 32'd100;
            d_funct7_32b = 7'b000011_1; // funct6=vrsub, vm=1
            #30;
            if (dut.VRF.REG[3] === {32'd60, 32'd70, 32'd80, 32'd90})
                $display("PASS: vrsub.vx");
            else begin
                $display("FAIL: vrsub.vx got %h", dut.VRF.REG[3]);
                errors2 = errors2 + 1;
            end

            d_vecop = VECOP_NONE;

            if (errors2 == 0)
                $display("=== ALL INT ALU DIRECTED TESTS PASSED ===");
            else
                $display("=== %0d INT ALU DIRECTED TEST(S) FAILED ===", errors2);
        end
        // === AI-GENERATED END ===

        // === AI-GENERATED BEGIN: directed test for masking (V0 fix) + undisturbed policy (S_old fix) ===
        // Regresses two latent bugs found while implementing compares: V0 (the mask module's
        // v0_mask input) was never driven by the real v0 register, and S_old (vd's prior value,
        // needed for the mask/tail-undisturbed default policy) was hardwired to 0.
        begin : mask_policy_tests
            integer errors3;
            errors3 = 0;

            d_vecop = VECOP_NONE; // keep arith disabled while we stage operands/opcode
            d_aluop = ALUOP_VEC;
            d_rd = 5'd3;
            d_rs2 = 5'd1; d_rs2_pre = 5'd1; // vs2 = v1 = [10,20,30,40]
            d_funct3_32b = 3'b100; // OPIVX
            dut.VRF.REG[0] = 128'b0101; // v0 mask, 1 bit/element: elements 0,2 active; 1,3 inactive

            // Stage v3 = v1 + 999 through a *real* instruction (not a hierarchical force) so
            // result_vector and REG[3] stay consistent -- this is the "sentinel" prior vd value.
            scalar_reg1 = 32'd999;
            d_funct7_32b = 7'b000000_1; // funct6=vadd, vm=1 (unmasked)
            d_vecop = VECOP_ARITH;
            #30;
            d_vecop = VECOP_NONE;

            // Now vadd.vx v3, v1, x5, vm=0 (masked); vma=0 (undisturbed, from the vtype set earlier)
            scalar_reg1 = 32'd5;
            d_funct7_32b = 7'b000000_0; // funct6=vadd, vm=0 -- set BEFORE re-enabling ARITH
            #30;
            d_vecop = VECOP_ARITH;
            #30;
            if (dut.VRF.REG[3] === {32'd1039, 32'd35, 32'd1019, 32'd15})
                $display("PASS: vadd.vx masked (v0 + undisturbed policy)");
            else begin
                $display("FAIL: vadd.vx masked got %h", dut.VRF.REG[3]);
                errors3 = errors3 + 1;
            end

            d_funct7_32b = 7'b000000_1; // restore vm=1 for any subsequent stimulus
            d_vecop = VECOP_NONE;

            if (errors3 == 0)
                $display("=== ALL MASK POLICY DIRECTED TESTS PASSED ===");
            else
                $display("=== %0d MASK POLICY DIRECTED TEST(S) FAILED ===", errors3);
        end
        // === AI-GENERATED END ===

        // === AI-GENERATED BEGIN: directed tests for compare instructions (mask-producing) ===
        begin : cmp_tests
            integer errors4;
            errors4 = 0;

            d_vecop = VECOP_NONE;
            d_aluop = ALUOP_VEC;
            d_rd = 5'd3;
            d_rs2 = 5'd1; d_rs2_pre = 5'd1; // vs2 = v1 = [10,20,30,40]
            d_funct3_32b = 3'b100; // OPIVX

            // vmslt.vx v3, v1, x25 (signed) => v1[i] < 25 => [1,1,0,0]
            scalar_reg1 = 32'd25;
            d_funct7_32b = 7'b011011_1; // funct6=vmslt, vm=1
            #30; d_vecop = VECOP_ARITH; #30;
            d_vecop = VECOP_NONE;
            if (dut.VRF.REG[3][3:0] === 4'b0011)
                $display("PASS: vmslt.vx");
            else begin
                $display("FAIL: vmslt.vx got %b", dut.VRF.REG[3][3:0]);
                errors4 = errors4 + 1;
            end

            // vmseq.vx v3, v1, x20 => v1[i] == 20 => [0,1,0,0]
            scalar_reg1 = 32'd20;
            d_funct7_32b = 7'b011000_1; // funct6=vmseq, vm=1
            #30; d_vecop = VECOP_ARITH; #30;
            d_vecop = VECOP_NONE;
            if (dut.VRF.REG[3][3:0] === 4'b0010)
                $display("PASS: vmseq.vx");
            else begin
                $display("FAIL: vmseq.vx got %b", dut.VRF.REG[3][3:0]);
                errors4 = errors4 + 1;
            end

            // vmsgt.vx v3, v1, x25 (signed) => v1[i] > 25 => [0,0,1,1]
            scalar_reg1 = 32'd25;
            d_funct7_32b = 7'b011111_1; // funct6=vmsgt, vm=1
            #30; d_vecop = VECOP_ARITH; #30;
            d_vecop = VECOP_NONE;
            if (dut.VRF.REG[3][3:0] === 4'b1100)
                $display("PASS: vmsgt.vx");
            else begin
                $display("FAIL: vmsgt.vx got %b", dut.VRF.REG[3][3:0]);
                errors4 = errors4 + 1;
            end

            if (errors4 == 0)
                $display("=== ALL COMPARE DIRECTED TESTS PASSED ===");
            else
                $display("=== %0d COMPARE DIRECTED TEST(S) FAILED ===", errors4);
        end
        // === AI-GENERATED END ===

        // === AI-GENERATED BEGIN: directed tests for vmv.v.x / vmerge.vxm ===
        begin : merge_tests
            integer errors5;
            errors5 = 0;

            d_vecop = VECOP_NONE;
            d_aluop = ALUOP_VEC;
            d_rd = 5'd3;
            d_rs2 = 5'd1; d_rs2_pre = 5'd1; // vs2 = v1 = [10,20,30,40]
            d_funct3_32b = 3'b100; // OPIVX

            // vmv.v.x v3, x777 (vm=1) => v3 = [777,777,777,777]
            scalar_reg1 = 32'd777;
            d_funct7_32b = 7'b010111_1; // funct6=vmerge/vmv, vm=1 -> vmv.v.x
            #30; d_vecop = VECOP_ARITH; #30;
            d_vecop = VECOP_NONE;
            if (dut.VRF.REG[3] === {32'd777, 32'd777, 32'd777, 32'd777})
                $display("PASS: vmv.v.x");
            else begin
                $display("FAIL: vmv.v.x got %h", dut.VRF.REG[3]);
                errors5 = errors5 + 1;
            end

            // vmerge.vxm v3, v1, x777, v0 (vm=0; v0=0101 from earlier -> elements 0,2 select x777)
            d_funct7_32b = 7'b010111_0; // funct6=vmerge/vmv, vm=0 -> vmerge.vxm
            #30; d_vecop = VECOP_ARITH; #30;
            d_vecop = VECOP_NONE;
            if (dut.VRF.REG[3] === {32'd40, 32'd777, 32'd20, 32'd777})
                $display("PASS: vmerge.vxm");
            else begin
                $display("FAIL: vmerge.vxm got %h", dut.VRF.REG[3]);
                errors5 = errors5 + 1;
            end

            if (errors5 == 0)
                $display("=== ALL MERGE DIRECTED TESTS PASSED ===");
            else
                $display("=== %0d MERGE DIRECTED TEST(S) FAILED ===", errors5);
        end
        // === AI-GENERATED END ===

        // === AI-GENERATED BEGIN: directed test for vmacc.vx ===
        begin : macc_tests
            integer errors6;
            errors6 = 0;

            d_vecop = VECOP_NONE;
            d_aluop = ALUOP_VEC;
            d_rd = 5'd3;
            d_rs2 = 5'd1; d_rs2_pre = 5'd1; // vs2 = v1 = [10,20,30,40]
            d_funct3_32b = 3'b100; // OPIVX

            // Stage v3 = 100 (all lanes) via vmv.v.x (real instruction, so result_vector stays consistent).
            // NOTE: the arith FSM has no single-shot/done gating -- it recomputes and rewrites vd on
            // *every* cycle d_vecop==ARITH is held. That's harmless for idempotent ops (add/sub/mul/...)
            // but vmacc accumulates, so it must only be asserted for exactly one clock, matching how the
            // real core's stall logic already treats VECOP_ARITH as single-cycle (see x_stall_vec in
            // hazard3_core.v, which explicitly excludes VECOP_ARITH from needing a multi-cycle stall).
            scalar_reg1 = 32'd100;
            d_funct7_32b = 7'b010111_1; // vmv.v.x
            #30; d_vecop = VECOP_ARITH; #10; d_vecop = VECOP_NONE; #20;

            // vmacc.vx v3, x3, v1 => v3 = (3 * v1) + v3_old = [130,160,190,220]
            scalar_reg1 = 32'd3;
            d_funct3_32b = 3'b110; // OPMVX
            d_funct7_32b = 7'b101101_1; // funct6=vmacc, vm=1
            #30; d_vecop = VECOP_ARITH; #10; d_vecop = VECOP_NONE; #20;
            if (dut.VRF.REG[3] === {32'd220, 32'd190, 32'd160, 32'd130})
                $display("PASS: vmacc.vx");
            else begin
                $display("FAIL: vmacc.vx got %h", dut.VRF.REG[3]);
                errors6 = errors6 + 1;
            end

            // vredsum.vs v3, v1, v2 => vd[0] = sum(v2[0], v1[*]) = 5 + (10+20+30+40) = 105
            // Regresses two fixes: rmask polarity (was inverted) and vector/scalar operand swap
            // (redsum was reducing vs1 seeded by vs2 instead of reducing vs2 seeded by vs1[0]).
            dut.VRF.REG[2] = {32'd0, 32'd0, 32'd0, 32'd5}; // vs1, only element 0 (seed) matters
            d_rs1 = 5'd2; d_rs1_pre = 5'd2;
            d_rs2 = 5'd1; d_rs2_pre = 5'd1; // vs2 = v1 = [10,20,30,40]
            d_funct3_32b = 3'b010; // OPMVV
            d_funct7_32b = 7'b000000_1; // funct6=vredsum, vm=1
            #30; d_vecop = VECOP_ARITH; #10; d_vecop = VECOP_NONE; #20;
            if (dut.VRF.REG[3][31:0] === 32'd105)
                $display("PASS: vredsum.vs");
            else begin
                $display("FAIL: vredsum.vs got %h", dut.VRF.REG[3]);
                errors6 = errors6 + 1;
            end

            // vredmax.vs v3, v1, v2 => vd[0] = max(v2[0]=5, v1[*]=[10,20,30,40]) = 40
            d_funct7_32b = 7'b000111_1; // funct6=vredmax, vm=1
            #30; d_vecop = VECOP_ARITH; #10; d_vecop = VECOP_NONE; #20;
            if (dut.VRF.REG[3][31:0] === 32'd40)
                $display("PASS: vredmax.vs");
            else begin
                $display("FAIL: vredmax.vs got %h", dut.VRF.REG[3]);
                errors6 = errors6 + 1;
            end

            // vmand.mm v3, v1, v2 => vd = v1(vs2) & v2(vs1) = 0b1010 & 0b1100 = 0b1000
            dut.VRF.REG[1] = 128'b1010;
            dut.VRF.REG[2] = 128'b1100;
            d_rs1 = 5'd2; d_rs1_pre = 5'd2; // vs1 = v2
            d_rs2 = 5'd1; d_rs2_pre = 5'd1; // vs2 = v1
            d_funct7_32b = 7'b011001_1; // funct6=vmand, vm=1 (unused by this op)
            #30; d_vecop = VECOP_ARITH; #10; d_vecop = VECOP_NONE; #20;
            if (dut.VRF.REG[3][3:0] === 4'b1000)
                $display("PASS: vmand.mm");
            else begin
                $display("FAIL: vmand.mm got %b", dut.VRF.REG[3][3:0]);
                errors6 = errors6 + 1;
            end

            if (errors6 == 0)
                $display("=== ALL MACC DIRECTED TESTS PASSED ===");
            else
                $display("=== %0d MACC DIRECTED TEST(S) FAILED ===", errors6);
        end
        // === AI-GENERATED END ===

        // === AI-GENERATED BEGIN: directed test for OPIVI (immediate) dispatch ===
        begin : imm_tests
            integer errors7;
            errors7 = 0;

            d_vecop = VECOP_NONE;
            d_aluop = ALUOP_VEC;
            d_rd = 5'd3;
            dut.VRF.REG[1] = {32'd40, 32'd30, 32'd20, 32'd10}; // restore v1 (clobbered by the vmand.mm test above)
            d_rs2 = 5'd1; d_rs2_pre = 5'd1; // vs2 = v1 = [10,20,30,40]
            d_funct3_32b = 3'b011; // OPIVI
            d_rs1 = 5'd7; // imm[4:0] = 7 (positive, reuses the rs1 field's raw bits)
            d_funct7_32b = 7'b000000_1; // funct6=vadd, vm=1

            #30; d_vecop = VECOP_ARITH; #10; d_vecop = VECOP_NONE; #20;
            if (dut.VRF.REG[3] === {32'd47, 32'd37, 32'd27, 32'd17})
                $display("PASS: vadd.vi");
            else begin
                $display("FAIL: vadd.vi got %h", dut.VRF.REG[3]);
                errors7 = errors7 + 1;
            end

            if (errors7 == 0)
                $display("=== ALL OPIVI DIRECTED TESTS PASSED ===");
            else
                $display("=== %0d OPIVI DIRECTED TEST(S) FAILED ===", errors7);
        end
        // === AI-GENERATED END ===

        // === AI-GENERATED BEGIN: regression test for the vmulh sign-restoration borrow bug ===
        // vmulh negated just the high half of the magnitude product in isolation instead of the
        // full 2*SEW product, which is wrong whenever the low half of the magnitude is nonzero
        // (the common case). -100000 * 100000 = -10,000,000,000, whose magnitude (10,000,000,000)
        // needs more than 32 bits, so the high word is genuinely exercised; the old buggy code
        // gave 0xFFFFFFFE here instead of the correct 0xFFFFFFFD.
        begin : vmulh_sign_test
            integer errors8;
            errors8 = 0;

            d_vecop = VECOP_NONE;
            d_aluop = ALUOP_VEC;
            d_rd = 5'd3;
            dut.VRF.REG[1] = {32'hFFFE7960, 32'hFFFE7960, 32'hFFFE7960, 32'hFFFE7960}; // -100000 x4
            d_rs2 = 5'd1; d_rs2_pre = 5'd1; // vs2 = v1
            d_funct3_32b = 3'b110; // OPMVX
            scalar_reg1 = 32'd100000;
            d_funct7_32b = 7'b100111_1; // funct6=vmulh, vm=1
            #30; d_vecop = VECOP_ARITH; #10; d_vecop = VECOP_NONE; #20;
            if (dut.VRF.REG[3] === {4{32'hFFFFFFFD}})
                $display("PASS: vmulh.vx sign restoration");
            else begin
                $display("FAIL: vmulh.vx sign restoration got %h", dut.VRF.REG[3]);
                errors8 = errors8 + 1;
            end

            if (errors8 == 0)
                $display("=== ALL VMULH SIGN DIRECTED TESTS PASSED ===");
            else
                $display("=== %0d VMULH SIGN DIRECTED TEST(S) FAILED ===", errors8);
        end
        // === AI-GENERATED END ===

        $finish;
    end

endmodule