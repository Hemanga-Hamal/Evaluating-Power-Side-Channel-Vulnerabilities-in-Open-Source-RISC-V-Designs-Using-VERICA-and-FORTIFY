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
