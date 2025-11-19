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
    input  wire rst,           // Changed to synchronous reset
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
    
    // Changed to synchronous reset
    always @(posedge clk) begin
        if (rst) begin
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
    
    // Changed to synchronous reset
    always @(posedge clk) begin
        if (rst) begin
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
    //
    // NOTE: THE VULNERABILITY IS STILL PRESENT!
    // Changing from async to sync reset does not fix the security flaw.
    // This change only makes the code synthesizable in Yosys.

endmodule