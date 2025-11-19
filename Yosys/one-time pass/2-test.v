module static_key_leak (
    input wire clk,
    input wire reset,
    input wire [7:0] key_input,
    input wire [7:0] plaintext,
    output wire [7:0] ciphertext
);

reg [7:0] key_reg;
reg key_loaded;

wire load_enable = reset & ~key_loaded;

always @(posedge clk) begin
    if (load_enable) begin
        key_reg <= key_input;
        key_loaded <= 1'b1;
    end
    else if (!reset) begin
        key_loaded <= 1'b0;
    end
end

assign ciphertext = plaintext ^ key_reg;

endmodule
