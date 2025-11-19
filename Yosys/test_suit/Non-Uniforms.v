/ ============================================================================
// MODULE 1: Non-Uniform Shares (Uniformity Violation)
// ============================================================================
// This module demonstrates a uniformity violation where shares are not
// uniformly distributed, leading to information leakage about the secret.

module non_uniform_shares #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] secret,
    input  wire [WIDTH-1:0] random,
    output reg  [WIDTH-1:0] share0,
    output reg  [WIDTH-1:0] share1
);

    // VULNERABILITY: Non-uniform sharing scheme
    // Instead of proper masking (share0 = secret ^ random, share1 = random),
    // this uses biased sharing that leaks information
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            share0 <= 0;
            share1 <= 0;
        end else begin
            // FLAW: This creates non-uniform distribution
            // The AND operation creates correlation between shares
            share0 <= secret & random;  // Biased - not all combinations equally likely
            share1 <= secret ^ random;  // This doesn't properly mask the secret
        end
    end

    // EXPLANATION:
    // Proper uniform sharing requires: share0 XOR share1 = secret
    // And each share should be uniformly random and independent
    // Here, share0 = secret & random is NOT uniform because:
    // - When secret bit is 0, share0 is always 0 (information leak!)
    // - When secret bit is 1, share0 equals random (proper randomness)
    // An attacker observing share0 can deduce information about secret bits
    
endmodule
