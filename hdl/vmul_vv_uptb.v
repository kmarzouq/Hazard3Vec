module testbench();
  `timescale 1ns/1ps
  parameter MAX_VECWIDTH = 32;
  parameter XLEN = 32;

  // DUT inputs
  reg [XLEN-1:0] vtype;
  reg [1:0] vxrm;
  reg [XLEN-1:0] vl;
  reg [XLEN-1:0] vlenb;
  reg [MAX_VECWIDTH*XLEN-1:0] A;
  reg [MAX_VECWIDTH*XLEN-1:0] B;
  reg [MAX_VECWIDTH-1:0] vmask;

  // DUT outputs
  wire [MAX_VECWIDTH*XLEN-1:0] P;
  wire [MAX_VECWIDTH-1:0] Ovflw;
  wire vxsat_comb;

  // Instantiate DUT
  vmul32_vv #(
    .MAX_VECWIDTH(MAX_VECWIDTH),
    .XLEN(XLEN)
  ) dut (
    .vtype(vtype),
    .vxrm(vxrm),
    .vl(vl),
    .vlenb(vlenb),
    .A(A),
    .B(B),
    .vmask(vmask),
    .P(P),
    .Ovflw(Ovflw),
    .vxsat_comb(vxsat_comb)
  );

  // Helper task to print results
  task print_results;
    integer i;
    begin
      $display("--- Result P and Ovflw ---");
      for (i = 0; i < vl; i = i + 1) begin
        $display("Lane %0d: P = %0d, Overflow = %b", i, P[XLEN*i +: XLEN], Ovflw[i]);
      end
      $display("vxsat_comb = %b", vxsat_comb);
      $display("---------------------------\n");
    end
  endtask

  initial begin
    // Initialize
    vtype = 32'b0000_0000; // vsew=0 (8-bit elements), vlmul=0 (1x)
    vxrm = 2'b00;           // RNU (round to nearest up)
    vl = 4;                 // Process 4 elements
    vlenb = 4;              // 4 bytes (32 bits) total vector length for test

    // Prepare two small arrays for A and B (4 lanes)
    A = { 4{32'd5} }; // All elements = 5
    B = { 4{32'd3} }; // All elements = 3
    vmask = 4'b1111;  // Mask all enabled

    #10;
    $display("Test 1: Simple Multiplication");
    print_results();

    // Test overflow case
    A = {32'h7FFF_FFFF, 32'd2, 32'd1000, 32'd50}; // Huge value to cause overflow in lane 3
    B = {32'd2, 32'd3, 32'd1000, 32'd4};
    vmask = 4'b1111;

    #10;
    $display("Test 2: Overflow Check");
    print_results();

    // Test masking (disable lane 2)
    vmask = 4'b1011; // Disable lane 2

    #10;
    $display("Test 3: With Masking");
    print_results();

    // Test tail undisturbed (vta=1)
    vtype[6] = 1'b1; // Set vta = 1
    vl = 2; // Only first 2 lanes active

    #10;
    $display("Test 4: Tail Agnostic");
    print_results();

    $finish;
  end

endmodule
