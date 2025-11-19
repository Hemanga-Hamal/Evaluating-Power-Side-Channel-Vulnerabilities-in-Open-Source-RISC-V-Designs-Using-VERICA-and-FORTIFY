// File: dff_map.v
// Maps all internal Yosys DFF cells to Nangate45 gates

// Simple DFF
module $dff (D, Q, C);
    input D, C;
    output Q;
    DFF_X1 inst (.CK(C), .D(D), .Q(Q));
endmodule

// DFF with enable
module $dffe (D, Q, C, E);
    input D, C, E;
    output Q;
    SDFF_X1 inst (.CK(C), .D(D), .Q(Q), .E(E));
endmodule

// DFF with set/reset
module $dffsr (D, Q, C, S, R);
    input D, C, S, R;
    output Q;
    DFFRS_X1 inst (.CK(C), .D(D), .Q(Q), .RN(R), .SN(S));
endmodule

// DFF with enable + set/reset
module $sdffe (D, Q, C, E);
    input D, C, E;
    output Q;
    SDFF_X1 inst (.CK(C), .D(D), .Q(Q), .E(E));
endmodule
