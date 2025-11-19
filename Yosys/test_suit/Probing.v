// ============================================================================
// MODULE 4: First-Order Probing Vulnerability
// ============================================================================
// This module fails 1st-order probing security by allowing a single
// probe to observe unmasked sensitive data.

module first_order_probing #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] secret_a,
    input  wire [WIDTH-1:0] secret_b,
    input  wire [WIDTH-1:0] mask_a,
    input  wire [WIDTH-1:0] mask_b,
    output reg  [WIDTH-1:0] result
);

    // Masked inputs
    wire [WIDTH-1:0] masked_a0 = secret_a ^ mask_a;
    wire [WIDTH-1:0] masked_a1 = mask_a;
    wire [WIDTH-1:0] masked_b0 = secret_b ^ mask_b;
    wire [WIDTH-1:0] masked_b1 = mask_b;
    
    // VULNERABILITY: Intermediate unmasked value
    wire [WIDTH-1:0] unmasked_product;  // PROBE HERE = LEAK!
    
    // Insecure AND operation on masked values
    // This creates an intermediate unmasked value
    assign unmasked_product = (masked_a0 ^ masked_a1) & (masked_b0 ^ masked_b1);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 0;
        end else begin
            // Trying to re-mask the result (too late!)
            result <= unmasked_product ^ mask_a;
        end
    end

    // EXPLANATION:
    // FIRST-ORDER PROBING VULNERABILITY:
    // 1. The signal 'unmasked_product' contains the actual secret value:
    //    secret_a AND secret_b (completely unmasked!)
    // 2. A single probe on this wire reveals the sensitive computation
    // 3. This violates 1st-order probing security which requires that
    //    ANY single wire/register should be independent of secrets
    //
    // WHY IT HAPPENS:
    // - (masked_a0 ^ masked_a1) = (secret_a ^ mask_a) ^ mask_a = secret_a
    // - (masked_b0 ^ masked_b1) = (secret_b ^ mask_b) ^ mask_b = secret_b
    // - unmasked_product = secret_a & secret_b (UNPROTECTED!)
    //
    // PROPER APPROACH (TI/DOM AND):
    // For masked AND of (a0,a1) and (b0,b1), need:
    // - p0 = (a0 & b0) ^ r
    // - p1 = (a0 & b1) ^ (a1 & b0) ^ r
    // - p2 = (a1 & b1)
    // Where r is fresh random, and no intermediate unmasks the secret

endmodule
