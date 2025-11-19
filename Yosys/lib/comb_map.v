// File: comb_map.v
// Parameter-free mapping of internal Yosys gates to Nangate45 cells

module $and(A, B, Y);
    input A, B;
    output Y;
    AND2_X1 u0 (.A1(A), .A2(B), .ZN(Y));
endmodule

module $xor(A, B, Y);
    input A, B;
    output Y;
    XOR2_X1 u0 (.A(A), .B(B), .Z(Y));
endmodule

module $not(A, Y);
    input A;
    output Y;
    INV_X1 u0 (.A(A), .ZN(Y));
endmodule
