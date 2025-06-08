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


module regne (R, Clock, Resetn, E, Q);
    parameter n = 32;
    input [n-1:0] R;
    input Clock, Resetn, E;
    output reg [n-1:0] Q;

    always @(posedge Clock, negedge Resetn)
    begin
        if (Resetn == 0)
            Q <= 0;
        else if (E && R[n-1])
            Q <= ~R + 1;
        else if(E && !R[n-1])
            Q <= R;
            
    end
endmodule


module shiftlne (R, L, E, w, Clock, Q);
    parameter n = 32;
    input [n-1:0] R;
    input L, E, w, Clock;
    output reg [n-1:0] Q;
    integer k;

    always @(posedge Clock)
    begin
        if (L)
            Q <= R;
        else if (E)
        begin
            Q[0] <= w;
            for(k = 1; k < n; k=k+1)
                Q[k] <= Q[k-1];
        end
    end
endmodule

module shiftlne_2comp (R, L, E, w, Clock, Q);
    parameter n = 32;
    input [n-1:0] R;
    input L, E, w, Clock;
    output reg [n-1:0] Q;
    integer k;

    always @(posedge Clock)
    begin
        if (L && R[n-1])
            Q <= ~R+1;
        else if(L && !R[n-1])
            Q <= R;
        else if (E)
        begin
            Q[0] <= w;
            for(k = 1; k < n; k=k+1)
                Q[k] <= Q[k-1];
        end
    end
endmodule


module muxdff (D0, D1, Sel, Clock, Q);
    input D0, D1, Sel, Clock;
    output reg Q;
    wire D;

    assign #1 D = Sel ? D1 : D0;

    always @(posedge Clock)
        Q <= D;
    
endmodule


module downcount (Clock, EC, LC, Count);
    parameter n = 32, logn = 5;
    input Clock, LC, EC;
    output reg [logn-1:0] Count;

    always @(posedge Clock)
    begin
        if (LC)
            Count <= n-1;
        else if (EC)
            Count <= Count - 1;
    end
endmodule


module divider32 (Clock, Resetn, s, LA, EB, DataA, DataB, R, Q, Done, err);
    parameter n = 32, logn = 5;
    input Clock, Resetn, s, LA, EB;
    input [n-1:0] DataA, DataB;
    output [n-1:0] R, Q;
    output reg Done;
    output err;
    wire Cout, z, R0;
    wire [n-1:0] DataR;
    wire [n:0] Sum;
    reg [1:0] y, Y;
    wire [n-1:0] A, B;
    wire [logn-1:0] Count;
    reg EA, Rsel, LR, ER, ER0, LC, EC;

    reg SignA, SignB;
    wire Signout;

    wire Ovflw;
    reg Div0;

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
            default: begin
                LR = 0; ER = 0; ER0 = 0; LC = 0; EC = 0; EA = 0;
                Rsel = 0; Done = 0;
            end
        endcase
    end

    //Check DataA sign
    always@(posedge Clock, negedge Resetn)
    begin
        if(Resetn==0)
            SignA <= 0;
        else if(LA)
            SignA <= DataA[n-1];        
    end

    //Check DataB sign
    always@(posedge Clock, negedge Resetn)
    begin
        if(Resetn==0)
        begin
            SignB <= 0;
            Div0 <= 0;
        end
        else if(EB)
        begin
            SignB <= DataB[n-1];
            Div0 <= (DataB == 0);
        end        
    end

    regne RegB (.R(DataB), .Clock(Clock), .Resetn(Resetn), .E(EB), .Q(B));
        defparam RegB.n = n;

    shiftlne ShiftR (.R(DataR), .L(LR), .E(ER), .w(R0), .Clock(Clock), .Q(R));
        defparam ShiftR.n = n;

    muxdff FF_R0 (.D0(1'b0), .D1(A[n-1]), .Sel(ER0), .Clock(Clock), .Q(R0));

    shiftlne_2comp ShiftA (.R(DataA), .L(LA), .E(EA), .w(Cout), .Clock(Clock), .Q(A)); 
        defparam ShiftA.n = n;

    assign #1 Q = Signout ? ~A + 1 : A;

    downcount Counter (Clock, EC, LC, Count);
        defparam Counter.n = n;

    assign #1 z = (Count == 0);

    //assign #1 Sum = {1'b0, R[n-2:0], R0} + {1'b0, ~B} + 1;
    adder32bit subtractor (.Cout(Cout), .S(Sum), .A({1'b0, R[n-2:0], R0}), .Bin(B), .Cin(1'b1), .Ovflw(Ovflw));
    //assign #1 Cout = Sum[n];

    assign Signout = SignA ^ SignB;
    or Error (err, Div0, Ovflw);

    // define the n 2-to-1 multiplexers
    assign #1 DataR = Rsel ? Sum : 0;

endmodule


module divider32bitby32 #(parameter vecwidth = 32) (Clock, Resetn, s, LA, EB, DataA, DataB, R, Q, Done, err);
  input Clock;

  input [vecwidth-1:0] Resetn;
  input [vecwidth-1:0] s;
  input [vecwidth-1:0] LA;
  input [vecwidth-1:0] EB;

  input [31:0] DataA [vecwidth-1:0];
  input [31:0] DataB [vecwidth-1:0];
  output [31:0] R [vecwidth-1:0];
  output [31:0] Q [vecwidth-1:0];
  
  output reg [vecwidth-1:0] Done;
  output [vecwidth-1:0] err;

  divider32 d32bit32 [vecwidth-1:0] (Clock, Resetn, s, LA, EB, DataA, DataB, R, Q, Done, err);

endmodule
