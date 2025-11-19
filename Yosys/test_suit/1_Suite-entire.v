// ============================================================================
// VERICA Framework Test Suite - All Vulnerable Modules
// ============================================================================
// This file contains all 8 vulnerable Verilog modules for testing VERICA
// Each module demonstrates a specific side-channel vulnerability
// Save each module to a separate .v file for individual testing
// ============================================================================

// ============================================================================
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


// ============================================================================
// MODULE 2: Glitch Vulnerability (Transition Leakage)
// ============================================================================
// This module shows how combinational logic creates glitches that
// leak sensitive information during signal transitions.

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
    // These operations happen in combinational logic and can create glitches
    assign partial_xor = share0 ^ share1;  // First combination
    assign partial_and = partial_xor & share2;  // Second combination
    assign unregistered_result = partial_and ^ share2;  // Final unmasking
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 0;
        end else begin
            result <= unregistered_result;
        end
    end

    // EXPLANATION:
    // GLITCH VULNERABILITY occurs because:
    // 1. When share0, share1, or share2 change, the combinational logic
    //    creates intermediate transitions (glitches) before stabilizing
    // 2. During these glitches, partial_xor might temporarily contain
    //    unmasked sensitive data (share0 ^ share1 reveals info)
    // 3. If share0 transitions before share1, partial_xor briefly holds
    //    the XOR of old share1 with new share0, leaking information
    // 4. Power/EM side channels can observe these transient states
    // 
    // PROPER FIX: Register all intermediate results to prevent glitches:
    // - Register partial_xor before using it
    // - Register partial_and before final XOR
    // - Ensure all shares update synchronously

endmodule


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
    input  wire rst_n,
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
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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

endmodule


// ============================================================================
// MODULE 6: Probe-and-SNI (p-sni) Violation
// ============================================================================
// This module violates probe-and-strong-non-interference, which is a
// stronger security notion than p-ni. It fails when composition of
// gadgets is considered.

module psni_violation #(
    parameter WIDTH = 4
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] a_share0,
    input  wire [WIDTH-1:0] a_share1,
    input  wire [WIDTH-1:0] b_share0,
    input  wire [WIDTH-1:0] b_share1,
    input  wire [WIDTH-1:0] rand0,
    input  wire [WIDTH-1:0] rand1,
    output reg  [WIDTH-1:0] out_share0,
    output reg  [WIDTH-1:0] out_share1
);

    // Computing (A AND B) in two stages to show composition issue
    
    // Stage 1 registers
    reg [WIDTH-1:0] stage1_s0, stage1_s1;
    reg [WIDTH-1:0] stage1_cross;  // VULNERABILITY: Reused across stages!
    
    // Stage 2 intermediate
    wire [WIDTH-1:0] stage2_temp;  // VULNERABLE TO COMPOSITION!
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_s0 <= 0;
            stage1_s1 <= 0;
            stage1_cross <= 0;
        end else begin
            // Stage 1: Initial AND computation
            stage1_s0 <= (a_share0 & b_share0) ^ rand0;
            stage1_s1 <= (a_share1 & b_share1) ^ rand1;
            
            // FLAW: This cross term is visible to stage 2
            stage1_cross <= (a_share0 & b_share1) ^ (a_share1 & b_share0);
        end
    end
    
    // Stage 2: Combinational completion (COMPOSITION ISSUE!)
    assign stage2_temp = stage1_cross ^ rand0 ^ rand1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_share0 <= 0;
            out_share1 <= 0;
        end else begin
            out_share0 <= stage1_s0;
            out_share1 <= stage1_s1 ^ stage2_temp;
        end
    end

    // EXPLANATION:
    // PROBE-AND-SNI (p-sni) VIOLATION:
    //
    // Definition: t-p-sni (probe-and-strong-non-interference) requires that:
    // 1. For any set of t1 probed intermediate values
    // 2. And any set of t2 output shares (t1 + t2 ≤ t)
    // 3. The simulation can be done with at most t1 input shares
    // 4. This ensures secure composition of gadgets
    //
    // VULNERABILITY IN THIS MODULE:
    // 1. Consider 1 probe on 'stage1_cross' (t1=1)
    // 2. And observation of out_share0 (t2=1), so t1+t2=2
    // 3. The stage1_cross depends on ALL shares of both inputs:
    //    - Uses a_share0, a_share1, b_share0, b_share1
    // 4. To simulate this probe + output, we need MORE than t1=1 input shares
    // 5. We actually need at least 2 shares from each input (4 total)
    //
    // WHY THIS MATTERS FOR COMPOSITION:
    // - When this gadget feeds into another gadget, the security doesn't compose
    // - An attacker probing the next gadget + this gadget's outputs can
    //   effectively "use up" more probes than allowed
    // - The property fails because internal wires depend on too many input shares
    //
    // PROPER p-SNI GADGET:
    // - Each internal wire should depend on at most (d-1) shares per input
    //   where d is the number of shares
    // - Use sufficient fresh randomness
    // - Carefully register and isolate intermediate stages
    // - Example: DOM (Domain-Oriented Masking) AND gate

endmodule


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


// ============================================================================
// MODULE 8: Transition-Based Leakage (Hamming Distance)
// ============================================================================
// This module demonstrates how unprotected state transitions leak
// information through power consumption proportional to Hamming distance.

module transition_leakage #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire load_key,
    input  wire [WIDTH-1:0] secret_key,
    input  wire [WIDTH-1:0] plaintext,
    output reg  [WIDTH-1:0] ciphertext
);

    // Key register - holds sensitive value across operations
    reg [WIDTH-1:0] key_reg;
    
    // VULNERABILITY: Direct state transitions without masking
    reg [WIDTH-1:0] state;  // Intermediate state register
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_reg <= 0;
            state <= 0;
            ciphertext <= 0;
        end else begin
            // Load secret key
            if (load_key) begin
                key_reg <= secret_key;
            end
            
            // FLAW: Direct transition from one secret-dependent value to another
            // The Hamming distance between consecutive states leaks information
            state <= plaintext ^ key_reg;  // First operation
            
            // More operations that depend on state
            ciphertext <= state ^ {state[6:0], state[7]};  // Simple mixing
        end
    end

    // EXPLANATION:
    // TRANSITION-BASED (HAMMING DISTANCE) LEAKAGE:
    //
    // Power consumption in CMOS circuits is dominated by:
    // P ∝ HammingDistance(state_old, state_new)
    //
    // VULNERABILITY:
    // 1. When 'state' transitions from one value to another, the power
    //    consumption is proportional to the number of bits that flip
    // 2. Hamming Distance = popcount(state_old XOR state_new)
    // 3. In this module:
    //    - state_old might be from previous plaintext processing
    //    - state_new = current_plaintext ^ key_reg
    //    - Power ∝ HD(prev_state, plaintext ^ key_reg)
    // 4. By processing multiple plaintexts and measuring power, an attacker
    //    can perform Correlation Power Analysis (CPA) to recover key_reg
    //
    // ATTACK SCENARIO:
    // 1. Attacker controls plaintext input
    // 2. Measures power consumption during state transition
    // 3. For each key hypothesis K':
    //    - Predicts HD based on state transitions: HD(prev, plaintext ^ K')
    //    - Computes correlation with measured power traces
    // 4. Correct key K' will show highest correlation
    //
    // WHY IT WORKS:
    // - Without masking, state directly depends on secret key
    // - Each bit flip in state register draws charge from Vdd
    // - Power analysis can distinguish HD through noise
    // - More bit flips = more power consumption = measurable difference
    //
    // MITIGATIONS:
    // - Boolean masking: state = (plaintext ^ key) ^ random_mask
    // - Dual-rail precharge logic (constant HD)
    // - Shuffling to decorrelate operations
    // - Hiding: add noise or randomize timing

endmodule

// ============================================================================
// END OF VERICA TEST SUITE
// ============================================================================