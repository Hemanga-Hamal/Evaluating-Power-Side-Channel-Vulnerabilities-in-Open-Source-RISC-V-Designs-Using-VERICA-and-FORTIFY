// Deliberately vulnerable circuit with obvious side-channel leak
// This combines two shares in pure combinational logic without any register staging
// This RTL version will be synthesized by Yosys

module obvious_leak(
    input clk,
    input [7:0] share0,
    input [7:0] share1,
    output reg [7:0] leaked_output
);

    // VULNERABLE: Direct combinational XOR of both shares
    // This creates a path where both shares influence the same wire
    // in the same clock cycle - classic first-order leakage
    wire [7:0] temp;
    
    // Combinational logic combining both shares
    assign temp = share0 ^ share1;
    
    // Register the output (but damage is already done in combinational logic above)
    always @(posedge clk) begin
        leaked_output <= temp;
    end

endmodule