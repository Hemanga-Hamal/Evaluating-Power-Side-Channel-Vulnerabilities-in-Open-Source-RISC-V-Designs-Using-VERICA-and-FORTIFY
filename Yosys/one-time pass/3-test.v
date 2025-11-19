module static_key_leak (
    input  wire        clk,
    input  wire        reset,
    input  wire [7:0]  key_input,
    input  wire [7:0]  plaintext,
    output wire [7:0]  ciphertext
);

    // Explicit registers
    reg [7:0] key_reg;
    reg       key_loaded;

    // Combinational next-state logic for registers
    wire [7:0] key_next;
    wire       loaded_next;

    assign key_next    = (~key_loaded & reset) ? key_input : key_reg;
    assign loaded_next = (~key_loaded & reset) ? 1'b1 : (~reset ? 1'b0 : key_loaded);

    // Synchronous DFFs
    always @(posedge clk) begin
        key_reg    <= key_next;
        key_loaded <= loaded_next;
    end

    // Output
    assign ciphertext = plaintext ^ key_reg;

endmodule
