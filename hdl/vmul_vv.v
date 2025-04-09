module vmul_vv #( parameter MAX_VECWIDTH=8 //Maximum LMUL-supported vector width
)(
  input clk,
  input reset,
  input [32-1:0] vtype, //XLEN = 32
  input [32-1:0] vstart,
  input [1:0] vxrm,
  input [32-1:0] vl,
  input [2:0] vsew, //VSEW
  input [32-1:0] vlenb, // VLEN/8
  input [2:0] vlmul, // LMUL
  input [MAX_VECWIDTH*32-1:0] DataA,
  input [MAX_VECWIDTH*32-1:0] DataB,
  output reg [MAX_VECWIDTH*64-1:0] Pout,
  output [MAX_VECWIDTH-1:0] Ovflw,
  output reg vxsat
);

//compute vecwidth dynamically
reg [2:0] vecwidth;
integer i;

always@(*) begin
    case(vlmul)
        3'b000 : vecwidth = (vlenb / vsew); //LMUL = 1
        3'b001 : vecwidth = (vlenb / vsew) * 2; //LMUL = 2
        3'b010 : vecwidth = (vlenb / vsew) * 4; //LMUL = 4
        3'b011 : vecwidth = (vlenb / vsew) * 8; //LMUL = 8
        3'b101 : vecwidth = (vlenb / vsew) / 8; //LMUL = 1/8
        3'b110 : vecwidth = (vlenb / vsew) / 4; //LMUL = 1/4
        3'b111 : vecwidth = (vlenb / vsew) / 2; //LMUL = 1/2
        default : vecwidth = 1; //Fallback case
    endcase

    if(vecwidth > MAX_VECWIDTH)
        vecwidth =  MAX_VECWIDTH;
end


wire vma = vtype[7];
wire vta = vtype[6];

wire [MAX_VECWIDTH*64-1:0] mul_res_raw;
wire [MAX_VECWIDTH*64-1:0] overflow_flags;

// Parallel instantiation of the 32-bit adders
genvar idx;
generate
    for (idx = 0; idx < MAX_VECWIDTH; idx=idx+1) begin : VMUL_LOOP
        wire [31:0] A_lane = DataA[32*idx +: 32];
        wire [31:0] B_lane = DataB[32*idx +: 32];
        wire [63:0] P_lane;
        wire Ovflw_lane;

        multiply32bitparallel mul_lane (
            .DataA(A_lane),
            .DataB(B_lane),
            .Pout(P_lane),
            .Overflow(Ovflw_lane)
        );

        assign mul_res_raw[64*idx +: 64] = P_lane;
        assign Ovflw[idx] = Ovflw_lane;
    end
endgenerate

wire [MAX_VECWIDTH*32-1:0] rounded;
reg [MAX_VECWIDTH*32-1:0] final_result;

//Rounding logic
generate
    for(idx = 0; idx < MAX_VECWIDTH; idx=idx+1) begin : GEN_ROUND
        wire [63:0] full_product = mul_res_raw[64*idx +: 64];
        wire [31:0] lower = full_product[31:0];
        wire round_bit = full_product[32];
        wire lsb = full_product[0];
    
        assign rounded[32*idx +: 32] = 
            (vxrm == 2'b00) ? lower + round_bit : 
            (vxrm == 2'b01) ? lower + (round_bit & (lsb | round_bit)) :
            (vxrm == 2'b10) ? lower :
            (vxrm == 2'b11) ? lower | (~round_bit & lsb) :
                              lower;
    end
endgenerate



// Rounding and saturation logic
always @(posedge clk or posedge reset) begin
    if (reset) begin
      Pout <= 0;
      vxsat <= 0;
    end else begin
      vxsat <= 0;
      for (i = 0; i < MAX_VECWIDTH; i = i + 1) begin
        if (i < vecwidth) begin
          if (i < vl) begin
            if (overflow_flags[i]) begin
              vxsat <= 1;
              // Saturate based on sign of 64-bit result
              Pout[32*i +: 32] <= mul_res_raw[64*i + 63] ? 32'h80000000 : 32'h7FFFFFFF;
            end else begin
              Pout[32*i +: 32] <= rounded[32*i +: 32];
            end
          end else begin
            // Tail elements
            if (vta)
              Pout[32*i +: 32] <= 32'hFFFFFFFF;
            // Else: retain old value (no update)
          end
        end else begin
          // Elements beyond vecwidth (masked out)
          if (vma)
            Pout[32*i +: 32] <= 32'hFFFFFFFF;
        end
      end
    end
  end

endmodule
