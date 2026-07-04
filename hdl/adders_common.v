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


module adder8bit(Cout, S, A, Bin, Cin, Ovflw);
  input [7:0] A;
  input [7:0] Bin;
  input Cin;
  wire [7:0] P;
  wire [7:0] G;
  output [7:0] S;
  output Cout, Ovflw;
  wire C[7:1];

  wire [7:0] B;

  xor xor8 [7:0] (B, Bin, Cin);

  CLA cla1 ({C[3], C[2], C[1], Cin}, A[3:0], B[3:0], S[3:0], P[3:0], G[3:0]);
  carryGenerationUnit cgu1 ({C[4], C[3], C[2], C[1]}, P[3:0], G[3:0], Cin);

  CLA cla2 ({C[7], C[6], C[5], C[4]}, A[7:4], B[7:4], S[7:4], P[7:4], G[7:4]);
  carryGenerationUnit cgu2({Cout, C[7], C[6], C[5]}, P[7:4], G[7:4], C[4]);

  assign Ovflw = Cout ^ C[7];
endmodule


module adder16bit(Cout, S, A, Bin, Cin, Ovflw);
  input [15:0] A;
  input [15:0] Bin;
  input Cin;
  wire [15:0] P;
  wire [15:0] G;
  output [15:0] S;
  output Cout, Ovflw;
  wire C[15:1];

  wire [15:0] B;

  xor xor16 [15:0] (B, Bin, Cin);

  CLA cla1 ({C[3], C[2], C[1], Cin}, A[3:0], B[3:0], S[3:0], P[3:0], G[3:0]);
  carryGenerationUnit cgu1 ({C[4], C[3], C[2], C[1]}, P[3:0], G[3:0], Cin);

  CLA cla2 ({C[7], C[6], C[5], C[4]}, A[7:4], B[7:4], S[7:4], P[7:4], G[7:4]);at
  carryGenerationUnit cgu2 ({C[8], C[7], C[6], C[5]}, P[7:4], G[7:4], C[4]);

  CLA cla3 ({C[11], C[10], C[9], C[8]}, A[11:8], B[11:8], S[11:8], P[11:8], G[11:8]);
  carryGenerationUnit cgu3 ({C[12], C[11], C[10], C[9]}, P[11:8], G[11:8], C[8]);

  CLA cla4 ({C[15], C[14], C[13], C[12]}, A[15:12], B[15:12], S[15:12], P[15:12], G[15:12]);
  carryGenerationUnit cgu4 ({Cout, C[15], C[14], C[13]}, P[15:12], G[15:12], C[12]);

  assign Ovflw = Cout ^ C[15];
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


module adder64bit(Cout, S, A, Bin, Cin, Ovflw);
  input [63:0] A;
  input [63:0] Bin;
  input Cin;
  output [63:0] S;
  output Cout, Ovflw;

  wire [63:0] P;
  wire [63:0] G;
  wire [63:1] C;
  wire [63:0] B;

  xor xor64 [63:0] (B, Bin, {64{Cin}});

  // First block
  CLA cla1 ({C[3], C[2], C[1], Cin}, A[3:0], B[3:0], S[3:0], P[3:0], G[3:0]);
  carryGenerationUnit cgu1 ({C[4], C[3], C[2], C[1]}, P[3:0], G[3:0], Cin);
  CLA cla2 ({C[7], C[6], C[5], C[4]}, A[7:4], B[7:4], S[7:4], P[7:4], G[7:4]);
  carryGenerationUnit cgu2 ({C[8], C[7], C[6], C[5]}, P[7:4], G[7:4], C[4]);

  CLA cla3 ({C[11], C[10], C[9], C[8]}, A[11:8], B[11:8], S[11:8], P[11:8], G[11:8]);
  carryGenerationUnit cgu3 ({C[12], C[11], C[10], C[9]}, P[11:8], G[11:8], C[8]);
  CLA cla4 ({C[15], C[14], C[13], C[12]}, A[15:12], B[15:12], S[15:12], P[15:12], G[15:12]);
  carryGenerationUnit cgu4 ({C[16], C[15], C[14], C[13]}, P[15:12], G[15:12], C[12]);

  CLA cla5 ({C[19], C[18], C[17], C[16]}, A[19:16], B[19:16], S[19:16], P[19:16], G[19:16]);
  carryGenerationUnit cgu5 ({C[20], C[19], C[18], C[17]}, P[19:16], G[19:16], C[16]);
  CLA cla6 ({C[23], C[22], C[21], C[20]}, A[23:20], B[23:20], S[23:20], P[23:20], G[23:20]);
  carryGenerationUnit cgu6 ({C[24], C[23], C[22], C[21]}, P[23:20], G[23:20], C[20]);

  CLA cla7 ({C[27], C[26], C[25], C[24]}, A[27:24], B[27:24], S[27:24], P[27:24], G[27:24]);
  carryGenerationUnit cgu7 ({C[28], C[27], C[26], C[25]}, P[27:24], G[27:24], C[24]);
  CLA cla8 ({C[31], C[30], C[29], C[28]}, A[31:28], B[31:28], S[31:28], P[31:28], G[31:28]);
  carryGenerationUnit cgu8 ({C[32], C[31], C[30], C[29]}, P[31:28], G[31:28], C[28]);

  CLA cla9 ({C[35], C[34], C[33], C[32]}, A[35:32], B[35:32], S[35:32], P[35:32], G[35:32]);
  carryGenerationUnit cgu9 ({C[36], C[35], C[34], C[33]}, P[35:32], G[35:32], C[32]);
  CLA cla10 ({C[39], C[38], C[37], C[36]}, A[39:36], B[39:36], S[39:36], P[39:36], G[39:36]);
  carryGenerationUnit cgu10 ({C[40], C[39], C[38], C[37]}, P[39:36], G[39:36], C[36]);

  CLA cla11 ({C[43], C[42], C[41], C[40]}, A[43:40], B[43:40], S[43:40], P[43:40], G[43:40]);
  carryGenerationUnit cgu11 ({C[44], C[43], C[42], C[41]}, P[43:40], G[43:40], C[40]);
  CLA cla12 ({C[47], C[46], C[45], C[44]}, A[47:44], B[47:44], S[47:44], P[47:44], G[47:44]);
  carryGenerationUnit cgu12 ({C[48], C[47], C[46], C[45]}, P[47:44], G[47:44], C[44]);

  CLA cla13 ({C[51], C[50], C[49], C[48]}, A[51:48], B[51:48], S[51:48], P[51:48], G[51:48]);
  carryGenerationUnit cgu13 ({C[52], C[51], C[50], C[49]}, P[51:48], G[51:48], C[48]);
  CLA cla14 ({C[55], C[54], C[53], C[52]}, A[55:52], B[55:52], S[55:52], P[55:52], G[55:52]);
  carryGenerationUnit cgu14 ({C[56], C[55], C[54], C[53]}, P[55:52], G[55:52], C[52]);

  CLA cla15 ({C[59], C[58], C[57], C[56]}, A[59:56], B[59:56], S[59:56], P[59:56], G[59:56]);
  carryGenerationUnit cgu15 ({C[60], C[59], C[58], C[57]}, P[59:56], G[59:56], C[56]);
  CLA cla16 ({C[63], C[62], C[61], C[60]}, A[63:60], B[63:60], S[63:60], P[63:60], G[63:60]);
  carryGenerationUnit cgu16 ({Cout, C[63], C[62], C[61]}, P[63:60], G[63:60], C[60]);

  assign Ovflw = Cout ^ C[63];

endmodule