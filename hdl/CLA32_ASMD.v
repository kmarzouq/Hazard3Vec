// Verilog code for 32-bit adder created using eight 4-bit CLA adders

module CLA1bit(Cin, A, B, S, P, G);
  input Cin, A, B;
  output S, P, G;
  
  xor(S, Cin, P);
  xor(P, A, B);
  and(G, A, B);
endmodule

module CLA( C, A, B, S, P, G);
  input [3:0]C;
  input [3:0]A;
  input [3:0]B;
  output [3:0]S;
  output [3:0]P;
  output [3:0]G;
  CLA1bit c1(C[0], A[0], B[0], S[0], P[0], G[0]);
  CLA1bit c2(C[1], A[1], B[1], S[1], P[1], G[1]); 
  CLA1bit c3(C[2], A[2], B[2], S[2], P[2], G[2]); 
  CLA1bit c4(C[3], A[3], B[3], S[3], P[3], G[3]);
endmodule

module carryGenerationUnit(C, P, G, Cin);
  input [3:0]P;
  input [3:0]G;
  input Cin;
  output [3:0]C;

  assign C[0] = P[0]&Cin|G[0];
  assign C[1] = P[1]&P[0]&Cin|P[1]&G[0]|G[1];
  assign C[2] = P[2]&P[1]&P[0]&Cin|P[2]&P[1]&G[0]|P[2]&G[1]|G[2];
  assign C[3] = P[3]&P[2]&P[1]&P[0]&Cin|P[3]&P[2]&P[1]&G[0]|P[3]&P[2]&G[1]|P[3]&G[2]|G[3];
endmodule

module adder32bit(Cout, S, A, Bin, Cin, Ovflw);
  input [31:0] A;
  input [31:0] Bin;
  input Cin;
  wire [31:0] P;
  wire [31:0] G;
  output [31:0] S;
  output Cout, Ovflw;
  wire C[31:1];
  
  wire [31:0] B;

  xor xor32 [31:0] (B, Bin, Cin);

  CLA cla1 ({C[3], C[2], C[1], Cin}, A[3:0], B[3:0], S[3:0], P[3:0], G[3:0]);
  carryGenerationUnit cgu1 ({C[4], C[3], C[2], C[1]}, P[3:0], G[3:0], Cin);
  CLA cla2 ({C[7], C[6], C[5], C[4]}, A[7:4], B[7:4], S[7:4], P[7:4], G[7:4]);
  carryGenerationUnit cgu2({C[8], C[7], C[6],C[5]}, P[7:4], G[7:4], C[4]);

  CLA cla3 ({C[11], C[10], C[9], C[8]}, A[11:8], B[11:8], S[11:8], P[11:8], G[11:8]);
  carryGenerationUnit cgu3 ({C[12], C[11], C[10], C[9]}, P[11:8], G[11:8], C[8]);
  CLA cla4 ({C[15], C[14], C[13], C[12]}, A[15:12], B[15:12], S[15:12], P[15:12], G[15:12]);
  carryGenerationUnit cgu4({C[16], C[15], C[14], C[13]}, P[15:12], G[15:12], C[12]);

  CLA cla5 ({C[19], C[18], C[17], C[16]}, A[19:16], B[19:16], S[19:16], P[19:16], G[19:16]);
  carryGenerationUnit cgu5 ({C[20], C[19], C[18], C[17]}, P[19:16], G[19:16], C[16]);
  CLA cla6 ({C[23], C[22], C[21], C[20]}, A[23:20], B[23:20], S[23:20], P[23:20], G[23:20]);
  carryGenerationUnit cgu6({C[24], C[23], C[22], C[21]}, P[23:20], G[23:20], C[20]);

  CLA cla7 ({C[27], C[26], C[25], C[24]}, A[27:24], B[27:24], S[27:24], P[27:24], G[27:24]);
  carryGenerationUnit cgu7 ({C[28], C[27], C[26], C[25]}, P[27:24], G[27:24], C[24]);
  CLA cla8 ({C[31], C[30], C[29], C[28]}, A[31:28], B[31:28], S[31:28], P[31:28], G[31:28]);
  carryGenerationUnit cgu8({Cout, C[31], C[30],C[29]}, P[31:28], G[31:28], C[28]);

  assign Ovflw = Cout ^ C[31];

endmodule


module adder32bitby32 (Cout, S, A, B, Cin, Ovflw);
  parameter vecwidth = 32;
  input [31:0] A [vecwidth-1:0];
  input [31:0] B [vecwidth-1:0];
  input Cin [vecwidth-1:0];
  output [31:0] S [vecwidth-1:0];
  output Cout [vecwidth-1:0];
  output Ovflw [vecwidth-1:0];

  adder32bit a32bit32 [vecwidth-1:0] (Cout, S, A, B, Cin, Ovflw);

endmodule

module shiftlne (DataA, LA, EA, clk, A);
  parameter bitsize = 32;
  input [bitsize-1:0] DataA;
  input LA, EA, clk;
  output reg [bitsize-1:0] A;

  always@(posedge clk) begin
    if(LA) begin
      A <= DataA;
    end  
    else if(EA) begin
      A <= A <<< 1;
    end  
  end  
endmodule

module shiftrne (DataB, LB, EB, clk, B);
  parameter bitsize = 32;
  input [bitsize-1:0] DataB;
  input LB, EB, clk;
  output reg [bitsize-1:0] B;

  always@(posedge clk) begin
    if(LB) begin
      B <= DataB;
    end  
    else if(EB) begin
      B <= B >>> 1;
    end  
  end  
endmodule

module regne (DataP, EP, Resetn, clk, P);
  parameter bitsize = 32;
  input EP, Resetn, clk;
  input [bitsize-1:0] DataP;
  output reg [bitsize-1:0] P;

  always@(posedge clk, negedge Resetn) begin
    if(Resetn == 0) 
      P <= 0;
    else if(EP)
      P <= DataP;
  end
endmodule

module MSB (A, B, clk, LA, LB, Resetn, MSB_A, MSB_B);
  parameter bitsize = 32;
  input [bitsize-1:0] A, B;
  input LA, LB, clk, Resetn;
  output reg MSB_A, MSB_B;

  always@(posedge clk or negedge Resetn) begin
    if(Resetn == 0) begin
      MSB_A <= 0;
      MSB_B <= 0;
    end
    else if((LA && LB) == 1) begin
      MSB_A <= A[bitsize-1];
      MSB_B <= B[bitsize-1];
    end  
    else if(LA) begin
      MSB_A <= A[bitsize-1];
    end
    else if(LB) begin
      MSB_B <= B[bitsize-1];
    end
    else begin
      MSB_A <= MSB_A;
      MSB_B <= MSB_B; 
    end
  end  
endmodule


module multiply(Clock, Resetn, LA, LB, s, DataA, DataB, Pout, Done, Overflow);
    parameter n = 32;
    input Clock, Resetn, LA, LB, s;
    input [n-1:0] DataA, DataB;
    reg [n-1:0] P;
    output [n-1:0] Pout;
    output reg Done;
    output Overflow;
    reg Ovflw_Add;
    wire Ovflw_MUL;
    wire z;
    reg [n-1:0] DataP;
    wire [n-1:0] A, Sum;
    reg [1:0] y, Y;
    wire [n-1:0] B;
    reg EA, EB, EP, Psel;
    integer k;
    wire Ovflw, Cout;
    wire MSB_A, MSB_B, Psign;


    parameter S1=2'b00, S2=2'b01, S3=2'b10, S4=2'b11;

    always@(s, y, z)
    begin: State_table
        case (y)
            S1: if (s == 0) Y = S1;
                else Y = S2;
            S2: if (z == 0) Y = S2;
                else Y = S3;
            S3: if (s == 1) Y = S3;
                else Y = S1;
            S4: Y = S1;
            default: Y = 2'bxx;
        endcase
    end

    always @(posedge Clock, negedge Resetn)
    begin: State_flipflops
        if (Resetn == 0)
            y <= S1;
        else
            y <= Y;
    end
    
    always @(s, y, B[0])
    begin: FSM_outputs
        // defaults
        EA = 0; EB = 0; EP = 0; Done = 0; Psel = 0;
        case (y)
            S1: EP = 1;
            S2: begin
                EA = 1; EB = 1; Psel = 1;
                if (B[0]) EP = 1;
                else EP = 0;
            end
            S3: Done = 1;
            default: begin
              EA = 0; EB = 0; EP = 0; Done = 0; Psel = 0;
            end
        endcase
    end

    shiftrne ShiftB (DataB, LB, EB, Clock, B); 
    shiftlne ShiftA (DataA, LA, EA, Clock, A);

    MSB msb_ovflw (.A(DataA), .B(DataB), .clk(Clock), .LA(LA), .LB(LB), .Resetn(Resetn), .MSB_A(MSB_A), .MSB_B(MSB_B));
    
    assign z = (B == 0);
    adder32bit m32 (.Cout(Cout), .S(Sum), .A(A), .Bin(Pout), .Cin(1'b0), .Ovflw(Ovflw));

    always @(posedge Clock, negedge Resetn)
    begin: Overflow_Adder
        if (Resetn == 0)
            Ovflw_Add <= 1'b0;
        else if(Ovflw)
            Ovflw_Add <= 1'b1;
        else
            Ovflw_Add <= Ovflw_Add;
    end

    // define the 2n 2-to-1 multiplexers
    and and64 [31:0] (DataP, Sum, {32{Psel}});
    regne RegP (DataP, EP, Resetn, Clock, P);

    assign Pout = P[31:0];

    xor sign (Psign, MSB_A, MSB_B);
    //assign Ovflw_MUL = Done && (P[63:32] != {32{P[31]}});
    //assign Ovflw_MUL = 1'b0;
    assign Ovflw_MUL = (Psign != Pout[31]);
    //assign Ovflw_MUL = (MSB_B);

    or orOvflw (Overflow, Ovflw_MUL, 1'b0);

endmodule


module multiplier32bitby32 (Clock, Resetn, LA, LB, s, DataA, DataB, Pout, Done, Overflow);
  //issue with vectorizing, will resolve later
  
  parameter n = 32;
  input Clock;
  //input Resetn [n-1:0];
  //input LA [n-1:0];
  //input LB [n-1:0];
  //input s [n-1:0];

  input [n-1:0] Resetn;
  input [n-1:0] LA;
  input [n-1:0] LB;
  input [n-1:0] s;

  input [n-1:0] DataA [n-1:0];
  input [n-1:0] DataB [n-1:0];
  output [n-1:0] Pout [n-1:0];
  //output reg Done [n-1:0];
  //output Overflow [n-1:0];

  output reg [n-1:0] Done;
  output [n-1:0] Overflow;

  multiply m32bit32 [n-1:0] (Clock, Resetn, LA, LB, s, DataA, DataB, Pout, Done, Overflow);

endmodule

module muxdff (D0, D1, Sel, Clock, Q);
  input D0, D1, Sel, Clock;
  output reg Q;

  always @(posedge Clock) begin
    if (!Sel) begin
      Q <= D0;
    end
    else begin
      Q <= D1;
    end
  end
endmodule

module downcount (R, Clock, E, L, Q);
  parameter n = 8;
  input [n-1:0] R;
  input Clock, L, E;
  output reg [n-1:0] Q;

  always @(posedge Clock) begin
    if (L) begin
      Q <= R;
    end
    else if (E) begin
      Q <= Q - 1;
    end
  end
endmodule

module divider (Clock, Resetn, s, LA, EB, DataA, DataB, R, Q, Done);
  parameter n = 8, logn = 3;
  input Clock, Resetn, s, LA, EB;
  input [n-1:0] DataA, DataB;
  output [n-1:0] R, Q;
  output reg Done;
  wire Cout, z, R0;
  wire [n-1:0] DataR;
  wire [n:0] Sum;
  reg [1:0] y, Y;
  wire [n-1:0] A, B;
  wire [logn-1:0] Count;
  reg EA, Rsel, LR, ER, ER0, LC, EC;
  integer k;

  // control circuit
  parameter S1 = 2'b00, S2 = 2'b01, S3 = 2'b10;

  always @(s, y, z)
  begin: State_table
    case (y)
      S1: if (s == 0) Y = S1;
        else Y = S2;
      S2: if (z == 0) Y = S2;
        else Y = S3;
      S3: if (s == 1) Y = S3;
        else Y = S1;
      default: Y = 2'bxx;
    endcase
  end

  always @(posedge Clock, negedge Resetn)
  begin: State_flipflops
    if (Resetn == 0)
      y <= S1;
    else
      y <= Y;
  end

  always @(y, s, Cout, z)
  begin: FSM_outputs
    // defaults
    LR = 0; ER = 0; ER0 = 0; LC = 0; EC = 0; EA = 0;
    Rsel = 0; Done = 0;
    case (y)
      S1: begin
          LC = 1; ER = 1;
          if (s == 0)
          begin
            LR = 1; ER0 = 0;
          end
          else
          begin
            LR = 0; EA = 1; ER0 = 1;
          end
        end
      S2: begin
          Rsel = 1; ER = 1; ER0 = 1; EA = 1;
          if (Cout) LR = 1;
          else LR = 0;
          if (z == 0) EC = 1;
          else EC = 0;
        end
      S3: Done = 1;
    endcase
  end

  regne RegB (.DataP(DataB), .EP(EB), .Resetn(Resetn), .clk(Clock), .P(B));
  shiftlne ShiftR (.DataA(DataR), .LA(LR), .EA(ER), .clk(Clock), .A(R));
  muxdff FF_R0 (.D0(1'b0), .D1(A[n-1]), .Sel(ER0), .Clock(Clock), .Q(R0));
  shiftlne ShiftA (.DataA(DataA), .LA(LA), .EA(EA), .clk(Clock), .A(A));

  assign Q = A;
  downcount Counter (.Clock(Clock), .E(EC), .L(LC), .Q(Count));

  assign z = (Count == 0);
  assign Sum = {1'b0, R[n-2:0], R0} + {1'b0, B} + 1;
  assign Cout = Sum[n];
  // define the n 2-to-1 multiplexers
  assign DataR = Rsel ? Sum : 0;

endmodule
