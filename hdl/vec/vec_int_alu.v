// === AI-GENERATED FILE ===
// Generic single-width integer ALU covering the RVV 1.0 OPIVV/OPIVX/OPIVI
// logic, min/max, reverse-subtract and shift instructions (funct6 values
// per the official riscv-v-spec inst-table.adoc):
//   000001? no  -- 001001 vand, 001010 vor, 001011 vxor
//   000100 vminu, 000101 vmin, 000110 vmaxu, 000111 vmax
//   000011 vrsub   (OPIVX/OPIVI only, no .vv form)
//   100101 vsll, 101000 vsrl, 101001 vsra
// One module handles both vv and vx/vi forms (vx_mode selects whether A is
// read per-lane like a vector register, or as a single broadcast scalar/
// immediate) so the vector-vector and vector-scalar variants share one
// datapath instead of duplicating the SEW dispatch four times, matching the
// intent (not the letter) of the existing vadd32_vv.v/vadd32_vx.v split.
// verilator lint_off WIDTH
module vec_int_alu #(
    parameter MAX_VECWIDTH = 16,
    parameter XLEN = 32
)(
    input  [5:0] op,      // funct6
    input        vx_mode, // 0: A is vs1 (per-lane), 1: A is scalar/imm (broadcast)
    input  [XLEN-1:0] vtype,
    input  [1:0] vxrm,      // unused (no rounding in this op set), kept for port parity
    input  [XLEN-1:0] vl,
    input  [XLEN-1:0] vlenb,
    input        vm_bit,
    input  [MAX_VECWIDTH-1:0] v0_mask,
    input        vxsat,     // unused, kept for port parity
    input  [MAX_VECWIDTH*XLEN-1:0] S_old,
    input  [MAX_VECWIDTH*XLEN-1:0] A,
    input  [MAX_VECWIDTH*XLEN-1:0] B,
    output reg [MAX_VECWIDTH*XLEN-1:0] S
);

wire [MAX_VECWIDTH-1:0] mask_out;
mask #(.VLEN(MAX_VECWIDTH)) mask_inst (
    .vm(vm_bit),
    .v0_mask(v0_mask),
    .mask_out(mask_out)
);

wire [2:0] vsew = vtype[5:3];
wire [2:0] vlmul = vtype[2:0];
wire [31:0] sew = 1 << ({1'b0, vsew} + 3);
wire [31:0] vlen = vlenb * 8;

wire [31:0] raw_vecwidth = (vlmul == 3'b000) ? vlen / sew :
                           (vlmul == 3'b001) ? (2 * vlen) / sew :
                           (vlmul == 3'b010) ? (4 * vlen) / sew :
                           (vlmul == 3'b011) ? (8 * vlen) / sew :
                           (vlmul == 3'b101) ? vlen / (8 * sew) :
                           (vlmul == 3'b110) ? vlen / (4 * sew) :
                           (vlmul == 3'b111) ? vlen / (2 * sew) :
                           vlen / sew;
wire [31:0] vecwidth = (raw_vecwidth > MAX_VECWIDTH) ? MAX_VECWIDTH : raw_vecwidth;

wire vma = vtype[7];
wire vta = vtype[6];

reg [7:0]  A8   [MAX_VECWIDTH-1:0]; reg [7:0]  B8   [MAX_VECWIDTH-1:0]; reg [7:0]  S8   [MAX_VECWIDTH-1:0]; reg [7:0]  S8_old  [MAX_VECWIDTH-1:0];
reg [15:0] A16  [MAX_VECWIDTH-1:0]; reg [15:0] B16  [MAX_VECWIDTH-1:0]; reg [15:0] S16  [MAX_VECWIDTH-1:0]; reg [15:0] S16_old [MAX_VECWIDTH-1:0];
reg [31:0] A32  [MAX_VECWIDTH-1:0]; reg [31:0] B32  [MAX_VECWIDTH-1:0]; reg [31:0] S32  [MAX_VECWIDTH-1:0]; reg [31:0] S32_old [MAX_VECWIDTH-1:0];
reg [63:0] A64  [MAX_VECWIDTH-1:0]; reg [63:0] B64  [MAX_VECWIDTH-1:0]; reg [63:0] S64  [MAX_VECWIDTH-1:0]; reg [63:0] S64_old [MAX_VECWIDTH-1:0];

integer j;
reg [63:0] alu_tmp;

function [63:0] alu_op;
    input [5:0]  f6;
    input [63:0] a;
    input [63:0] b;
    input [5:0]  shamt_mask; // sew-1, used to mask the shift amount
    begin
        case (f6)
            6'b001001: alu_op = a & b;                       // vand
            6'b001010: alu_op = a | b;                        // vor
            6'b001011: alu_op = a ^ b;                        // vxor
            6'b000011: alu_op = a - b;                        // vrsub: rs1 - vs2 (a=scalar, b=vs2)
            6'b100101: alu_op = b << (a & shamt_mask);        // vsll
            6'b101000: alu_op = b >> (a & shamt_mask);        // vsrl (logical)
            default:   alu_op = b;
        endcase
    end
endfunction

always @(*) begin
    S = 0;
    for (j = 0; j < vecwidth; j = j + 1) begin
        A8[j]=0; B8[j]=0; S8[j]=0; S8_old[j]=0;
        A16[j]=0; B16[j]=0; S16[j]=0; S16_old[j]=0;
        A32[j]=0; B32[j]=0; S32[j]=0; S32_old[j]=0;
        A64[j]=0; B64[j]=0; S64[j]=0; S64_old[j]=0;
    end

    case (sew)
        8: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                A8[j] = vx_mode ? A[7:0] : A[8*j +: 8];
                B8[j] = B[8*j +: 8];
                S8_old[j] = S_old[8*j +: 8];

                if (j < vl) begin
                    if (mask_out[j]) begin
                        case (op)
                            6'b000100: S8[j] = (A8[j] < B8[j]) ? A8[j] : B8[j];                                     // vminu
                            6'b000101: S8[j] = ($signed(A8[j]) < $signed(B8[j])) ? A8[j] : B8[j];                   // vmin
                            6'b000110: S8[j] = (A8[j] > B8[j]) ? A8[j] : B8[j];                                     // vmaxu
                            6'b000111: S8[j] = ($signed(A8[j]) > $signed(B8[j])) ? A8[j] : B8[j];                   // vmax
                            6'b101001: S8[j] = $signed(B8[j]) >>> (A8[j] & 3'd7);                                    // vsra
                            default: begin alu_tmp = alu_op(op, {56'b0,A8[j]}, {56'b0,B8[j]}, 6'd7); S8[j] = alu_tmp[7:0]; end
                        endcase
                    end else if (!vma) S8[j] = S8_old[j];
                    else S8[j] = 8'hFF;
                end else if (vta) S8[j] = 8'hFF;
            end
            for (j = 0; j < vecwidth; j = j + 1) S[8*j +: 8] = S8[j];
        end

        16: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                A16[j] = vx_mode ? A[15:0] : A[16*j +: 16];
                B16[j] = B[16*j +: 16];
                S16_old[j] = S_old[16*j +: 16];

                if (j < vl) begin
                    if (mask_out[j]) begin
                        case (op)
                            6'b000100: S16[j] = (A16[j] < B16[j]) ? A16[j] : B16[j];
                            6'b000101: S16[j] = ($signed(A16[j]) < $signed(B16[j])) ? A16[j] : B16[j];
                            6'b000110: S16[j] = (A16[j] > B16[j]) ? A16[j] : B16[j];
                            6'b000111: S16[j] = ($signed(A16[j]) > $signed(B16[j])) ? A16[j] : B16[j];
                            6'b101001: S16[j] = $signed(B16[j]) >>> (A16[j] & 4'd15);
                            default: begin alu_tmp = alu_op(op, {48'b0,A16[j]}, {48'b0,B16[j]}, 6'd15); S16[j] = alu_tmp[15:0]; end
                        endcase
                    end else if (!vma) S16[j] = S16_old[j];
                    else S16[j] = 16'hFFFF;
                end else if (vta) S16[j] = 16'hFFFF;
            end
            for (j = 0; j < vecwidth; j = j + 1) S[16*j +: 16] = S16[j];
        end

        32: begin
            for (j = 0; j < vecwidth; j = j + 1) begin
                A32[j] = vx_mode ? A[31:0] : A[32*j +: 32];
                B32[j] = B[32*j +: 32];
                S32_old[j] = S_old[32*j +: 32];

                if (j < vl) begin
                    if (mask_out[j]) begin
                        case (op)
                            6'b000100: S32[j] = (A32[j] < B32[j]) ? A32[j] : B32[j];
                            6'b000101: S32[j] = ($signed(A32[j]) < $signed(B32[j])) ? A32[j] : B32[j];
                            6'b000110: S32[j] = (A32[j] > B32[j]) ? A32[j] : B32[j];
                            6'b000111: S32[j] = ($signed(A32[j]) > $signed(B32[j])) ? A32[j] : B32[j];
                            6'b101001: S32[j] = $signed(B32[j]) >>> (A32[j] & 5'd31);
                            default: begin alu_tmp = alu_op(op, {32'b0,A32[j]}, {32'b0,B32[j]}, 6'd31); S32[j] = alu_tmp[31:0]; end
                        endcase
                    end else if (!vma) S32[j] = S32_old[j];
                    else S32[j] = 32'hFFFFFFFF;
                end else if (vta) S32[j] = 32'hFFFFFFFF;
            end
            for (j = 0; j < vecwidth; j = j + 1) S[32*j +: 32] = S32[j];
        end

        default: begin // 64
            for (j = 0; j < vecwidth; j = j + 1) begin
                A64[j] = vx_mode ? A[63:0] : A[64*j +: 64];
                B64[j] = B[64*j +: 64];
                S64_old[j] = S_old[64*j +: 64];

                if (j < vl) begin
                    if (mask_out[j]) begin
                        case (op)
                            6'b000100: S64[j] = (A64[j] < B64[j]) ? A64[j] : B64[j];
                            6'b000101: S64[j] = ($signed(A64[j]) < $signed(B64[j])) ? A64[j] : B64[j];
                            6'b000110: S64[j] = (A64[j] > B64[j]) ? A64[j] : B64[j];
                            6'b000111: S64[j] = ($signed(A64[j]) > $signed(B64[j])) ? A64[j] : B64[j];
                            6'b101001: S64[j] = $signed(B64[j]) >>> (A64[j] & 6'd63);
                            default:   S64[j] = alu_op(op, A64[j], B64[j], 6'd63);
                        endcase
                    end else if (!vma) S64[j] = S64_old[j];
                    else S64[j] = 64'hFFFFFFFFFFFFFFFF;
                end else if (vta) S64[j] = 64'hFFFFFFFFFFFFFFFF;
            end
            for (j = 0; j < vecwidth; j = j + 1) S[64*j +: 64] = S64[j];
        end
    endcase
end

endmodule
// verilator lint_on WIDTH
// === END AI-GENERATED FILE ===
