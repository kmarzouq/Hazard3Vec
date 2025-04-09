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
