// ============================================================================
// MODULE 3: Coupling Effects (Physical Coupling Leakage)
// ============================================================================
// This module demonstrates how physically adjacent signals can couple,
// causing information leakage when sensitive shares are processed together.

module coupling_leakage #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] secret_share0,
    input  wire [WIDTH-1:0] secret_share1,
    input  wire [WIDTH-1:0] mask,
    output reg  [WIDTH-1:0] protected_out
);

    // VULNERABILITY: All shares processed in same cycle without isolation
    reg [WIDTH-1:0] temp_share0;
    reg [WIDTH-1:0] temp_share1;
    reg [WIDTH-1:0] combined;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            temp_share0 <= 0;
            temp_share1 <= 0;
            combined <= 0;
            protected_out <= 0;
        end else begin
            // FLAW: All operations happen simultaneously in same cycle
            // Physical coupling between wires carrying different shares
            temp_share0 <= secret_share0 ^ mask;  // Share 0 processing
            temp_share1 <= secret_share1 ^ mask;  // Share 1 processing (adjacent logic)
            combined <= temp_share0 ^ temp_share1;  // Combining shares
            protected_out <= combined;
        end
    end

    // EXPLANATION:
    // COUPLING VULNERABILITY arises from:
    // 1. Physical Proximity: When temp_share0 and temp_share1 are computed
    //    in adjacent logic/wires, capacitive/inductive coupling occurs
    // 2. Simultaneous Transitions: Both shares transition in the same clock
    //    cycle, creating correlated switching activity
    // 3. Coupled Charge: A transition in temp_share0 induces a small current
    //    in temp_share1's wire (and vice versa), creating a measurable
    //    coupling effect proportional to (share0 & share1) or (share0 ^ share1)
    // 4. The coupling effect depends on BOTH shares, leaking information
    //    about their joint distribution, which relates to the secret
    //
    // ATTACK: Power/EM analysis can detect the coupling-induced current
    // which correlates with Hamming distance/weight of share combinations
    //
    // MITIGATION: 
    // - Process shares in different clock cycles (temporal isolation)
    // - Use register-based domain separation
    // - Apply physical placement constraints to separate share logic
    // - Use differential logic styles (e.g., WDDL, iMDPL)

endmodule
