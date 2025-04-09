module vsub_vv #( parameter MAX_VECWIDTH=8 //Maximum LMUL-supported vector width
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
  input [MAX_VECWIDTH*32-1:0] A,
  input [MAX_VECWIDTH*32-1:0] B,
  output [MAX_VECWIDTH*32-1:0] S,
  output [MAX_VECWIDTH-1:0] Cout,
  output [MAX_VECWIDTH-1:0] Ovflw,
  output reg vxsat
);

reg [MAX_VECWIDTH*32-1:0] S_internal;
assign S = S_internal;

//compute vecwidth dynamically
reg [2:0] vecwidth;
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

wire [MAX_VECWIDTH-1:0] Cin;
assign C_in = {MAX_VECWIDTH{1'b1}};

wire [MAX_VECWIDTH*32-1:0] temp;
reg [MAX_VECWIDTH*32-1:0] rounded;
integer i;

genvar j;
generate
    for (j = 0; j < MAX_VECWIDTH; j = j + 1) begin : ADDER_LOOP
        adder32bit adder_inst (
            .A(A[32*j +: 32]), 
            .Bin(B[32*j +: 32]), 
            .Cin(Cin[j]), 
            .S(temp[32*j +: 32]), 
            .Cout(Cout[j]), 
            .Ovflw(Ovflw[j])
        );
    end
endgenerate


// Rounding and saturation logic
always @(posedge clk or posedge reset) begin
  if (reset) begin
    S_internal<= {MAX_VECWIDTH*32{1'b0}};
    vxsat <= 1'b0;
  end else begin
    for (i = 0; i < MAX_VECWIDTH; i = i + 1) begin
      if(i < vecwidth) begin //masks out extra adders
        if (i < vl) begin
            // Rounding Mode Implementation
            case (vxrm)
                2'b00: rounded[32*i +: 32] = temp[32*i +: 32] + ((temp[32*i +: 32] >> 1) & 1); // rnu (Round to Nearest Up)
                2'b01: rounded[32*i +: 32] = temp[32*i +: 32] + (((temp[32*i +: 32] >> 1) & 1) & (((temp[32*i +: 32] & 1) != 0) | ((temp[32*i +: 32] >> 1) & 1))); // rne (Round to Nearest Even)
                2'b10: rounded[32*i +: 32] = temp[32*i +: 32]; // rdn (Truncate)
                2'b11: rounded[32*i +: 32] = temp[32*i +: 32] | (!((temp[32*i +: 32] >> 1) & 1) & ((temp[32*i +: 32] & 1) != 0)); // rod (Round to Odd)
                default: rounded[32*i +: 32] = temp[32*i +: 32];
            endcase
            
            // Overflow and Saturation Handling
            if (Ovflw[i]) begin
                vxsat <= 1'b1;
                S_internal[32*i +: 32] = (temp[32*i + 31]) ? 32'h80000000 : 32'h7FFFFFFF; //Checks for signed and unsigned overflow
            end else if (!vma) begin
                S_internal[32*i +: 32] = rounded[32*i +: 32];
            end else begin
                S_internal[32*i +: 32] = 32'hFFFFFFFF; //Marks inactive elements as agnostic
            end
        end else if (i >= vl) begin
            S_internal[32*i +: 32] = vta ? 32'hFFFFFFFF : S_internal[32*i +: 32]; //Tail elements processing
        end
        end
    end
  end
end

endmodule
