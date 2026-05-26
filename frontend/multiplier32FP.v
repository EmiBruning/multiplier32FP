// =============================================================================
// multiplier32FP.v
// IEEE 754 Single-Precision Floating-Point Multiplier (32-bit)
// Pipelined - 2 stages
// Handles: NaN, Infinity, Denormals (dirty zero), Overflow, Underflow
// Rounding: Round toward zero (truncation)
// =============================================================================
`timescale 1ns/1ps

module multiplier32FP #(
    parameter DATA_W = 32,
    parameter EXP_W  = 8,
    parameter MAN_W  = 23
)(
    input  wire                clk,
    input  wire                rst_n,
    input  wire [DATA_W-1:0]   a_i,
    input  wire [DATA_W-1:0]   b_i,
    input  wire                start_i,
    output reg  [DATA_W-1:0]   product_o,
    output reg                 done_o,
    output reg                 nan_o,
    output reg                 infinit_o,
    output reg                 overflow_o,
    output reg                 underflow_o
);

    // -------------------------------------------------------------------------
    // Unpack fields
    // -------------------------------------------------------------------------
    wire        sign_a  = a_i[31];
    wire        sign_b  = b_i[31];
    wire [7:0]  exp_a   = a_i[30:23];
    wire [7:0]  exp_b   = b_i[30:23];
    wire [22:0] man_a   = a_i[22:0];
    wire [22:0] man_b   = b_i[22:0];

    // -------------------------------------------------------------------------
    // Classify inputs (combinational)
    // -------------------------------------------------------------------------
    wire is_nan_a     = (exp_a == 8'hFF) && (man_a != 23'd0);
    wire is_nan_b     = (exp_b == 8'hFF) && (man_b != 23'd0);
    wire is_inf_a     = (exp_a == 8'hFF) && (man_a == 23'd0);
    wire is_inf_b     = (exp_b == 8'hFF) && (man_b == 23'd0);
    wire is_denorm_a  = (exp_a == 8'h00);   // zero or dirty-zero
    wire is_denorm_b  = (exp_b == 8'h00);

    // -------------------------------------------------------------------------
    // Significands with implicit leading bit
    // denormals: implicit bit = 0; normals: implicit bit = 1
    // -------------------------------------------------------------------------
    wire [23:0] sig_a = is_denorm_a ? {1'b0, man_a} : {1'b1, man_a};
    wire [23:0] sig_b = is_denorm_b ? {1'b0, man_b} : {1'b1, man_b};

    // -------------------------------------------------------------------------
    // 24x24 -> 48-bit mantissa multiplication (single-cycle)
    // The critical path; synthesized to a multiplier primitive (DSP/array)
    // -------------------------------------------------------------------------
    wire [47:0] man_product = sig_a * sig_b;

    // -------------------------------------------------------------------------
    // Exponent addition with bias removal
    // Biased exp = (exp_a - 127) + (exp_b - 127) + 127 = exp_a + exp_b - 127
    // Use 10-bit to detect overflow/underflow
    // For denormals exponent is treated as 1 (they have exp=0 but represent
    // values with exponent -126, same as biased 1)
    // -------------------------------------------------------------------------
    wire [9:0] exp_a_ext = is_denorm_a ? 10'd1 : {2'b00, exp_a};
    wire [9:0] exp_b_ext = is_denorm_b ? 10'd1 : {2'b00, exp_b};
    wire [9:0] exp_sum   = exp_a_ext + exp_b_ext - 10'd127;

    // -------------------------------------------------------------------------
    // Sign of result
    // -------------------------------------------------------------------------
    wire sign_res = sign_a ^ sign_b;

    // -------------------------------------------------------------------------
    // STAGE 1 PIPELINE REGISTERS (combinational -> registered)
    // -------------------------------------------------------------------------
    reg         s1_valid;
    reg         s1_nan;
    reg         s1_inf;
    reg         s1_zero;          // at least one operand is zero/denorm and product flushes
    reg         s1_sign;
    reg [9:0]   s1_exp_sum;
    reg [47:0]  s1_man_product;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_valid       <= 1'b0;
            s1_nan         <= 1'b0;
            s1_inf         <= 1'b0;
            s1_zero        <= 1'b0;
            s1_sign        <= 1'b0;
            s1_exp_sum     <= 10'd0;
            s1_man_product <= 48'd0;
        end else begin
            s1_valid       <= start_i;
            s1_nan         <= is_nan_a | is_nan_b;
            s1_inf         <= (is_inf_a | is_inf_b) & ~(is_nan_a | is_nan_b);
            // Zero: either operand is +/- 0 (denorm with zero mantissa)
            // or underflow will flush (handled in stage 2)
            s1_zero        <= (is_denorm_a & (man_a == 23'd0)) |
                              (is_denorm_b & (man_b == 23'd0));
            s1_sign        <= sign_res;
            s1_exp_sum     <= exp_sum;
            s1_man_product <= man_product;
        end
    end

    // -------------------------------------------------------------------------
    // STAGE 2 - Normalize, round, detect special cases, output
    // -------------------------------------------------------------------------

    // man_product bit 47 = 1 if product overflows to 1x.xxx (needs right shift)
    // man_product bit 46 = 1 if product is   01.xxx (already normalized)
    wire        s1_ovf_bit  = s1_man_product[47];
    // normalized mantissa (top 24 bits after shifting)
    // if bit47=1 shift right 1, exponent +1; else use bits[46:23]
    wire [22:0] man_norm    = s1_ovf_bit ? s1_man_product[46:24]
                                         : s1_man_product[45:23];
    wire [9:0]  exp_norm    = s1_ovf_bit ? s1_exp_sum + 10'd1
                                         : s1_exp_sum;

    // exp_norm is a 10-bit value representing the raw biased exponent result.
    // Negative results wrap in 2's complement: bit[9]=1 means negative -> underflow.
    // Overflow: result is positive (bit9=0) AND >= 255 (0xFF)
    // Underflow: result is negative (bit9=1) OR equals zero (exp=0 -> denorm flush)
    // Priority: underflow takes precedence so we don't assert both flags.
    wire res_underflow = (exp_norm[9] == 1'b1) |    // negative exponent (wrap)
                         (exp_norm == 10'd0);        // exponent = 0 (flush to 0)
    wire res_overflow  = (exp_norm[9] == 1'b0) &    // positive exponent
                         (exp_norm >= 10'd255) &     // exceeds max
                         ~res_underflow;             // not underflow

    wire res_overflow_real  = res_overflow  & ~s1_zero & ~s1_nan & ~s1_inf;
    wire res_underflow_real = res_underflow & ~s1_zero & ~s1_nan & ~s1_inf;

    // Final product assembly
    wire [31:0] res_normal   = {s1_sign, exp_norm[7:0], man_norm};
    wire [31:0] res_overflow_val  = 32'h7FFF_FFFF;
    wire [31:0] res_underflow_val = 32'h0000_0000;
    wire [31:0] res_nan_val       = 32'h0000_0000;
    wire [31:0] res_inf_val       = {s1_sign, 8'hFF, 23'd0};
    wire [31:0] res_zero_val      = 32'h0000_0000;

    // Priority: NaN > Inf > Overflow > Underflow/Zero > Normal
    wire [31:0] result_mux =
          s1_nan              ? res_nan_val       :
          s1_inf              ? res_inf_val        :
          res_overflow_real   ? res_overflow_val   :
          (res_underflow_real | s1_zero) ? res_zero_val   :
          res_normal;

    // STAGE 2 OUTPUT REGISTERS
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product_o   <= 32'd0;
            done_o      <= 1'b0;
            nan_o       <= 1'b0;
            infinit_o   <= 1'b0;
            overflow_o  <= 1'b0;
            underflow_o <= 1'b0;
        end else begin
            done_o      <= s1_valid;
            nan_o       <= s1_valid & s1_nan;
            infinit_o   <= s1_valid & s1_inf;
            overflow_o  <= s1_valid & res_overflow_real;
            underflow_o <= s1_valid & res_underflow_real;
            product_o   <= s1_valid ? result_mux : 32'd0;
        end
    end

endmodule
