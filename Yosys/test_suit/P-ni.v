// ============================================================================
// MODULE 5: Probe-and-NI (p-ni) Violation
// ============================================================================
// This module violates probe-and-non-interference security by allowing
// an attacker who probes intermediate values AND observes output shares
// to learn secret information.

module pni_violation #(
    parameter WIDTH = 4  // Using 4-bit for clarity
)(
    input  wire clk,
    input  wire rst,           // Changed to synchronous reset
    input  wire [WIDTH-1:0] x_share0,  // Input X, share 0
    input  wire [WIDTH-1:0] x_share1,  // Input X, share 1
    input  wire [WIDTH-1:0] y_share0,  // Input Y, share 0
    input  wire [WIDTH-1:0] y_share1,  // Input Y, share 1
    input  wire [WIDTH-1:0] random,    // Random mask
    output reg  [WIDTH-1:0] z_share0,  // Output Z, share 0
    output reg  [WIDTH-1:0] z_share1   // Output Z, share 1
);

    // Computing Z = X AND Y in masked domain
    // Using 2-share Boolean masking
    
    // Intermediate cross-products
    reg [WIDTH-1:0] cross_term;  // VULNERABLE INTERMEDIATE!
    reg [WIDTH-1:0] partial0, partial1;
    
    // Changed to synchronous reset
    always @(posedge clk) begin
        if (rst) begin
            cross_term <= 0;
            partial0 <= 0;
            partial1 <= 0;
            z_share0 <= 0;
            z_share1 <= 0;
        end else begin
            // Stage 1: Compute partial products
            partial0 <= x_share0 & y_share0;  // a0 * b0
            partial1 <= x_share1 & y_share1;  // a1 * b1
            
            // VULNERABILITY: Cross term computation
            // This depends on one share from each input
            cross_term <= (x_share0 & y_share1) ^ (x_share1 & y_share0);
            
            // Stage 2: Combine with refresh
            z_share0 <= partial0 ^ random;
            z_share1 <= partial1 ^ cross_term ^ random;
        end
    end

    // EXPLANATION:
    // PROBE-AND-NI (p-ni) VIOLATION:
    // 
    // Definition: A gadget is t-p-ni if an attacker who:
    // 1. Probes up to t intermediate wires, AND
    // 2. Observes any subset of output shares
    // Cannot learn anything about the secret inputs
    //
    // VULNERABILITY HERE:
    // 1. If attacker probes 'cross_term' (1 probe)
    // 2. AND observes z_share0 (output share)
    // 3. They can compute:
    //    cross_term = (x_share0 & y_share1) ^ (x_share1 & y_share0)
    //    z_share0 = (x_share0 & y_share0) ^ random
    // 4. With knowledge of the output z_share0 and the probed cross_term,
    //    plus observing z_share1 in the output, the attacker can derive
    //    information about the secret X AND Y
    //
    // WHY IT FAILS:
    // - The cross_term depends on shares from BOTH inputs (x and y)
    // - Combined with output observation, this creates information flow
    // - The random refresh doesn't properly isolate the intermediate
    //   computation from the output shares
    //
    // PROPER p-ni GADGET WOULD:
    // - Ensure that any t probes + output shares remain independent of inputs
    // - Use proper register stages between dependent operations
    // - Apply sufficient fresh randomness at each stage
    //
    // NOTE: THE VULNERABILITY IS STILL PRESENT!
    // Changing from async to sync reset does not fix the security flaw.
    // This change only makes the code synthesizable in Yosys.

endmodule