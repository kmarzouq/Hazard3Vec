`include "adders_common.v"

module multiply32bitparallel (DataA, DataB, Pout, Overflow);
    parameter n = 32;
    input [n-1:0] DataA, DataB;
    output [2*n-1:0] Pout;
    output Overflow;
    wire [n-1:0] A, B;

    wire Ovflw1,  Ovflw2,  Ovflw3,  Ovflw4,  Ovflw5,  Ovflw6,  Ovflw7,  Ovflw8,
     Ovflw9,  Ovflw10, Ovflw11, Ovflw12, Ovflw13, Ovflw14, Ovflw15, Ovflw16,
     Ovflw17, Ovflw18, Ovflw19, Ovflw20, Ovflw21, Ovflw22, Ovflw23, Ovflw24,
     Ovflw25, Ovflw26, Ovflw27, Ovflw28, Ovflw29, Ovflw30, Ovflw31, Ovflw32;

    wire Cout1, Cout2, Cout3, Cout4, Cout5, Cout6, Cout7, Cout8,
     Cout9, Cout10, Cout11, Cout12, Cout13, Cout14, Cout15, Cout16,
     Cout17, Cout18, Cout19, Cout20, Cout21, Cout22, Cout23, Cout24,
     Cout25, Cout26, Cout27, Cout28, Cout29, Cout30, Cout31, Cout32;

    wire [31:0] S1,  S2,  S3,  S4,  S5,  S6,  S7,  S8,
            S9,  S10, S11, S12, S13, S14, S15, S16,
            S17, S18, S19, S20, S21, S22, S23, S24,
            S25, S26, S27, S28, S29, S30, S31, S32;

    wire [31:0] Out1,  Out2,  Out3,  Out4,  Out5,  Out6,  Out7,  Out8,
            Out9,  Out10, Out11, Out12, Out13, Out14, Out15, Out16,
            Out17, Out18, Out19, Out20, Out21, Out22, Out23, Out24,
            Out25, Out26, Out27, Out28, Out29, Out30, Out31, Out32;


    wire [2*n-1:0] P;
    wire SignA, SignB;
    wire Signout;

    assign SignA = DataA[n-1];
    assign SignB = DataB[n-1];
    assign Signout = SignA ^ SignB;

    assign A = SignA ? ~DataA + 1 : DataA;
    assign B = SignB ? ~DataB + 1 : DataB;

    and andsig1 [n-1:0] (Out1, A, B[0]);
    adder32bit add1 (Cout1, S1, {32{1'b0}}, Out1, 1'b0, Ovflw1);

    and andsig2 [n-1:0] (Out2, A, B[1]);
    adder32bit add2 (Cout2, S2, {Cout1, S1[n-1:1]}, Out2, 1'b0, Ovflw2);

    and andsig3 [n-1:0] (Out3, A, B[2]);
    adder32bit add3 (Cout3, S3, {Cout2, S2[n-1:1]}, Out3, 1'b0, Ovflw3);

    and andsig4  [n-1:0] (Out4,  A, B[3]);
    adder32bit add4  (Cout4,  S4,  {Cout3,  S3[n-1:1]},     Out4,  1'b0, Ovflw4);

    and andsig5  [n-1:0] (Out5,  A, B[4]);
    adder32bit add5  (Cout5,  S5,  {Cout4,  S4[n-1:1]},     Out5,  1'b0, Ovflw5);

    and andsig6  [n-1:0] (Out6,  A, B[5]);
    adder32bit add6  (Cout6,  S6,  {Cout5,  S5[n-1:1]},     Out6,  1'b0, Ovflw6);

    and andsig7  [n-1:0] (Out7,  A, B[6]);
    adder32bit add7  (Cout7,  S7,  {Cout6,  S6[n-1:1]},     Out7,  1'b0, Ovflw7);

    and andsig8  [n-1:0] (Out8,  A, B[7]);
    adder32bit add8  (Cout8,  S8,  {Cout7,  S7[n-1:1]},     Out8,  1'b0, Ovflw8);

    and andsig9  [n-1:0] (Out9,  A, B[8]);
    adder32bit add9  (Cout9,  S9,  {Cout8,  S8[n-1:1]},     Out9,  1'b0, Ovflw9);

    and andsig10 [n-1:0] (Out10, A, B[9]);
    adder32bit add10 (Cout10, S10, {Cout9,  S9[n-1:1]},     Out10, 1'b0, Ovflw10);

    and andsig11 [n-1:0] (Out11, A, B[10]);
    adder32bit add11 (Cout11, S11, {Cout10, S10[n-1:1]},    Out11, 1'b0, Ovflw11);

    and andsig12 [n-1:0] (Out12, A, B[11]);
    adder32bit add12 (Cout12, S12, {Cout11, S11[n-1:1]},    Out12, 1'b0, Ovflw12);

    and andsig13 [n-1:0] (Out13, A, B[12]);
    adder32bit add13 (Cout13, S13, {Cout12, S12[n-1:1]},    Out13, 1'b0, Ovflw13);

    and andsig14 [n-1:0] (Out14, A, B[13]);
    adder32bit add14 (Cout14, S14, {Cout13, S13[n-1:1]},    Out14, 1'b0, Ovflw14);

    and andsig15 [n-1:0] (Out15, A, B[14]);
    adder32bit add15 (Cout15, S15, {Cout14, S14[n-1:1]},    Out15, 1'b0, Ovflw15);

    and andsig16 [n-1:0] (Out16, A, B[15]);
    adder32bit add16 (Cout16, S16, {Cout15, S15[n-1:1]},    Out16, 1'b0, Ovflw16);

    and andsig17 [n-1:0] (Out17, A, B[16]);
    adder32bit add17 (Cout17, S17, {Cout16, S16[n-1:1]},    Out17, 1'b0, Ovflw17);

    and andsig18 [n-1:0] (Out18, A, B[17]);
    adder32bit add18 (Cout18, S18, {Cout17, S17[n-1:1]},    Out18, 1'b0, Ovflw18);

    and andsig19 [n-1:0] (Out19, A, B[18]);
    adder32bit add19 (Cout19, S19, {Cout18, S18[n-1:1]},    Out19, 1'b0, Ovflw19);

    and andsig20 [n-1:0] (Out20, A, B[19]);
    adder32bit add20 (Cout20, S20, {Cout19, S19[n-1:1]},    Out20, 1'b0, Ovflw20);

    and andsig21 [n-1:0] (Out21, A, B[20]);
    adder32bit add21 (Cout21, S21, {Cout20, S20[n-1:1]},    Out21, 1'b0, Ovflw21);

    and andsig22 [n-1:0] (Out22, A, B[21]);
    adder32bit add22 (Cout22, S22, {Cout21, S21[n-1:1]},    Out22, 1'b0, Ovflw22);

    and andsig23 [n-1:0] (Out23, A, B[22]);
    adder32bit add23 (Cout23, S23, {Cout22, S22[n-1:1]},    Out23, 1'b0, Ovflw23);

    and andsig24 [n-1:0] (Out24, A, B[23]);
    adder32bit add24 (Cout24, S24, {Cout23, S23[n-1:1]},    Out24, 1'b0, Ovflw24);

    and andsig25 [n-1:0] (Out25, A, B[24]);
    adder32bit add25 (Cout25, S25, {Cout24, S24[n-1:1]},    Out25, 1'b0, Ovflw25);

    and andsig26 [n-1:0] (Out26, A, B[25]);
    adder32bit add26 (Cout26, S26, {Cout25, S25[n-1:1]},    Out26, 1'b0, Ovflw26);

    and andsig27 [n-1:0] (Out27, A, B[26]);
    adder32bit add27 (Cout27, S27, {Cout26, S26[n-1:1]},    Out27, 1'b0, Ovflw27);

    and andsig28 [n-1:0] (Out28, A, B[27]);
    adder32bit add28 (Cout28, S28, {Cout27, S27[n-1:1]},    Out28, 1'b0, Ovflw28);

    and andsig29 [n-1:0] (Out29, A, B[28]);
    adder32bit add29 (Cout29, S29, {Cout28, S28[n-1:1]},    Out29, 1'b0, Ovflw29);

    and andsig30 [n-1:0] (Out30, A, B[29]);
    adder32bit add30 (Cout30, S30, {Cout29, S29[n-1:1]},    Out30, 1'b0, Ovflw30);

    and andsig31 [n-1:0] (Out31, A, B[30]);
    adder32bit add31 (Cout31, S31, {Cout30, S30[n-1:1]},    Out31, 1'b0, Ovflw31);

    and andsig32 [n-1:0] (Out32, A, B[31]);
    adder32bit add32 (Cout32, S32, {Cout31, S31[n-1:1]},    Out32, 1'b0, Ovflw32);

    assign P = {Cout32, S32, S31[0], S30[0], S29[0], S28[0], S27[0], S26[0],
            S25[0], S24[0], S23[0], S22[0], S21[0], S20[0], S19[0], S18[0],
            S17[0], S16[0], S15[0], S14[0], S13[0], S12[0], S11[0], S10[0],
            S9[0], S8[0], S7[0], S6[0], S5[0], S4[0], S3[0], S2[0], S1[0]};

    assign Overflow = Ovflw1 | Ovflw2 | Ovflw3 | Ovflw4 | Ovflw5 | Ovflw6 |
                  Ovflw7 | Ovflw8 | Ovflw9 | Ovflw10 | Ovflw11 | Ovflw12 |
                  Ovflw13 | Ovflw14 | Ovflw15 | Ovflw16 | Ovflw17 | Ovflw18 |
                  Ovflw19 | Ovflw20 | Ovflw21 | Ovflw22 | Ovflw23 | Ovflw24 |
                  Ovflw25 | Ovflw26 | Ovflw27 | Ovflw28 | Ovflw29 | Ovflw30 |
                  Ovflw31 | Ovflw32;

    assign Pout = Signout ? ~P + 1 : P;


endmodule
