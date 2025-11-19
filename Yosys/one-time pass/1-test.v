module static_key_leak (
    input wire clk,
    input wire reset,
    input wire [7:0] plaintext,
    output reg [7:0] ciphertext
);
// Secret key stored in flip-flops
reg [7:0] key_reg;
    // On reset load the private key; otherwise encrypt via XOR
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            key_reg <= 8'h5A; // (Example private key)
        end else begin
            ciphertext <= plaintext ^ key_reg;
        end
    end
endmodule