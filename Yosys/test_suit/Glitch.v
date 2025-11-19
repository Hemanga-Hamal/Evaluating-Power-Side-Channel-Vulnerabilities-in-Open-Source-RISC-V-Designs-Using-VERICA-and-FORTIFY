// Glitch Vulnerability - Yosys Compatible Version
// Changed to synchronous reset for synthesis compatibility
// THE VULNERABILITY IS STILL PRESENT!

module glitch_vulnerable #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] share0,
    input  wire [WIDTH-1:0] share1,
    input  wire [WIDTH-1:0] share2,
    output reg  [WIDTH-1:0] result
);

    // Intermediate combinational signals (GLITCH PRONE!)
    wire [WIDTH-1:0] partial_xor;
    wire [WIDTH-1:0] partial_and;
    wire [WIDTH-1:0] unregistered_result;
    
    // VULNERABILITY: Unregistered combinational logic on shared values
    assign partial_xor = share0 ^ share1;
    assign partial_and = partial_xor & share2;
    assign unregistered_result = partial_and ^ share2;
    
    // Changed to synchronous reset for Yosys compatibility
    always @(posedge clk) begin
        if (!rst_n) begin
            result <= 0;
        end else begin
            result <= unregistered_result;
        end
    end

    // THE GLITCH VULNERABILITY IS STILL HERE!
    // The combinational logic still creates glitches
    // This change just makes it synthesizable in Yosys

endmodule