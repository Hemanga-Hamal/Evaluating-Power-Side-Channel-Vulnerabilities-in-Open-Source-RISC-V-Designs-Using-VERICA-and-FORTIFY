// ============================================================================
// MODULE 7: PINI (Probe-Isolating Non-Interference) Violation
// ============================================================================
// This module violates PINI security, which requires that probed wires
// can be simulated using shares from only the "necessary" inputs,
// with stronger isolation between input and output dependencies.

module pini_violation #(
    parameter WIDTH = 4,
    parameter SHARES = 2
)(
    input  wire clk,
    input  wire rst_n,
    // Input X shares
    input  wire [WIDTH-1:0] x0,
    input  wire [WIDTH-1:0] x1,
    // Input Y shares  
    input  wire [WIDTH-1:0] y0,
    input  wire [WIDTH-1:0] y1,
    // Random values
    input  wire [WIDTH-1:0] r0,
    input  wire [WIDTH-1:0] r1,
    input  wire [WIDTH-1:0] r2,
    // Output shares
    output reg  [WIDTH-1:0] z0,
    output reg  [WIDTH-1:0] z1
);

    // Attempting to compute Z = X AND Y with masking
    // This implementation violates PINI
    
    // Cycle 1: Compute partial products
    reg [WIDTH-1:0] pp00, pp01, pp10, pp11;
    reg [WIDTH-1:0] refresh_out0, refresh_out1;
    
    // Cycle 2: Intermediate aggregation
    reg [WIDTH-1:0] intermediate_sum;  // PINI VIOLATION HERE!
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pp00 <= 0; pp01 <= 0; pp10 <= 0; pp11 <= 0;
            refresh_out0 <= 0;
            refresh_out1 <= 0;
            intermediate_sum <= 0;
            z0 <= 0;
            z1 <= 0;
        end else begin
            // Cycle 1: Partial products
            pp00 <= x0 & y0;
            pp01 <= x0 & y1;
            pp10 <= x1 & y0;
            pp11 <= x1 & y1;
            
            // Refresh one path
            refresh_out0 <= pp00 ^ r0;
            refresh_out1 <= pp11 ^ r1;
            
            // Cycle 2: VULNERABILITY - Non-isolated aggregation
            // This intermediate wire depends on shares from BOTH inputs
            // and affects multiple output shares
            intermediate_sum <= pp01 ^ pp10 ^ r2;
            
            // Output computation
            z0 <= refresh_out0 ^ (intermediate_sum & r0);  // FLAW: intermediate_sum affects z0
            z1 <= refresh_out1 ^ intermediate_sum;          // FLAW: intermediate_sum affects z1
        end
    end

    // EXPLANATION:
    // PINI (PROBE-ISOLATING NON-INTERFERENCE) VIOLATION:
    //
    // PINI Definition: A gadget satisfies t-PINI if:
    // 1. Probed internal wires can be simulated using shares from only ONE input
    //    (either all from X or all from Y, but not mixed)
    // 2. Output shares can be simulated independently
    // 3. This provides strong composability and isolation properties
    //
    // VULNERABILITY IN THIS MODULE:
    // 1. The 'intermediate_sum' wire is critical:
    //    intermediate_sum = pp01 ^ pp10 ^ r2
    //                     = (x0 & y1) ^ (x1 & y0) ^ r2
    // 2. This wire depends on shares from BOTH X and Y inputs
    // 3. It then influences BOTH z0 and z1 outputs
    // 4. If an attacker probes 'intermediate_sum':
    //    - Cannot simulate using only X shares (needs y1, y0)
    //    - Cannot simulate using only Y shares (needs x0, x1)
    //    - Violates the isolation property
    //
    // WHY PINI MATTERS:
    // - PINI ensures that each internal computation is "isolated" to one input
    // - This prevents information flow between multiple inputs through
    //   intermediate wires
    // - Enables modular security proofs and safe composition
    // - Particularly important for complex circuits with multiple masked operations
    //
    // PROPER PINI GADGET:
    // - Each internal wire should depend on shares from at most ONE input
    // - Use separate processing pipelines for different input dependencies
    // - Example: PINI AND gate separates x-dependent and y-dependent computations
    //   into different cycles with proper re-masking between stages
    // - Refreshing gadgets should be carefully placed to maintain isolation

endmodule
