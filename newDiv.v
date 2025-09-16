// /*******************************************************************************
//  * Pipelined 40-bit / 32-bit Signed Integer Divider
//  *
//  * Implements division using the Newton-Raphson method for reciprocal approximation.
//  * - Algorithm: Quotient Q = Dividend * (1 / Divisor)
//  * - Method:
//  * 1. Normalize divisor D to the range [0.5, 1.0).
//  * 2. Get an initial guess for 1/D from a Look-Up Table (LUT).
//  * 3. Refine the guess using two Newton-Raphson iterations.
//  * 4. Multiply the final reciprocal by the dividend to get the quotient.
//  * - Latency: 8 clock cycles.
//  * - Throughput: 1 division per clock cycle after initial latency.
//  ******************************************************************************/
// module division(
//     input  wire          clk,
//     input  wire          reset,         // Active LOW reset
//     input  wire          input_valid,
//     input  wire signed [31:0]  divisor_data,
//     input  wire signed [39:0]  dividend_data,
//     output wire          quo_valid,
//     output wire signed [39:0]  quo_data
// );

// //------------------------------------------------------------------------------
// // Pipeline Validity & Control
// //------------------------------------------------------------------------------
// reg v0, v1, v2, v3, v4, v5, v6, v7, v8;

// always @(posedge clk) begin
//     if (!reset) begin
//         {v8, v7, v6, v5, v4, v3, v2, v1, v0} <= 9'b0;
//     end else begin
//         v0 <= input_valid;
//         v1 <= v0;
//         v2 <= v1;
//         v3 <= v2;
//         v4 <= v3;
//         v5 <= v4;
//         v6 <= v5;
//         v7 <= v6;
//         v8 <= v7;
//     end
// end

// assign quo_valid = v8;


// //------------------------------------------------------------------------------
// // Pipeline Stage 0: Input Latching, Absolute Value, and Sign
// //------------------------------------------------------------------------------
// reg signed [39:0] p1_dividend;
// reg [31:0]        p1_divisor_abs;
// reg               p1_sign;
// reg               p1_div_zero;

// always @(posedge clk) begin
//     if (!reset) begin
//         p1_dividend    <= 40'sd0;
//         p1_divisor_abs <= 32'd0;
//         p1_sign        <= 1'b0;
//         p1_div_zero    <= 1'b0;
//     end else if (input_valid) begin
//         p1_dividend    <= dividend_data;
//         p1_divisor_abs <= (divisor_data[31]) ? -divisor_data : divisor_data;
//         p1_sign        <= dividend_data[39] ^ divisor_data[31];
//         p1_div_zero    <= (divisor_data == 32'd0);
//     end
// end


// //------------------------------------------------------------------------------
// // Pipeline Stage 1: Normalization
// // Goal: Scale divisor to [0.5, 1.0) and apply the same scaling to the dividend.
// //------------------------------------------------------------------------------
// reg signed [39:0] p2_dividend;
// reg        [31:0] p2_divisor; // Normalized divisor, format Q1.31
// reg               p2_sign;
// reg               p2_div_zero;

// wire [4:0] lz;
// lzc32 lzc_inst (.x(p1_divisor_abs), .lzc(lz));

// always @(posedge clk) begin
//     if (!reset) begin
//         p2_dividend <= 40'sd0;
//         p2_divisor  <= 32'd0;
//         p2_sign     <= 1'b0;
//         p2_div_zero <= 1'b0;
//     end else begin
//         // Shift left by the number of leading zeros to normalize.
//         // The arithmetic shift (<<<) preserves the sign of the dividend.
//         p2_dividend <= p1_dividend <<< lz;
//         p2_divisor  <= p1_divisor_abs << lz;
//         p2_sign     <= p1_sign;
//         p2_div_zero <= p1_div_zero;
//     end
// end


// //------------------------------------------------------------------------------
// // Pipeline Stage 2: Initial Guess (from LUT)
// //------------------------------------------------------------------------------
// reg signed [39:0] p3_dividend;
// reg        [31:0] p3_divisor; // Q1.31
// reg signed [31:0] p3_X0;      // Initial reciprocal guess, format Q2.30
// reg               p3_sign;
// reg               p3_div_zero;

// wire [4:0]        lut_index = p2_divisor[29:25];
// wire signed [31:0] X0_from_lut;
// recip_lut lut_inst (.index(lut_index), .value(X0_from_lut));

// always @(posedge clk) begin
//     if (!reset) begin
//         p3_dividend <= 40'sd0;
//         p3_divisor  <= 32'd0;
//         p3_X0       <= 32'sd0;
//         p3_sign     <= 1'b0;
//         p3_div_zero <= 1'b0;
//     end else begin
//         p3_dividend <= p2_dividend;
//         p3_divisor  <= p2_divisor;
//         p3_X0       <= X0_from_lut;
//         p3_sign     <= p2_sign;
//         p3_div_zero <= p2_div_zero;
//     end
// end


// //------------------------------------------------------------------------------
// // Pipeline Stage 3: NR Iteration 1, Part 1 (D * X0)
// //------------------------------------------------------------------------------
// reg signed [39:0] p4_dividend;
// reg        [31:0] p4_divisor; // Q1.31
// reg signed [31:0] p4_X0;      // Q2.30
// reg signed [63:0] p4_DX0;     // D * X0, format Q3.61
// reg               p4_sign;
// reg               p4_div_zero;

// always @(posedge clk) begin
//     if (!reset) begin
//         p4_dividend <= 40'sd0;
//         p4_divisor  <= 32'd0;
//         p4_X0       <= 32'sd0;
//         p4_DX0      <= 64'sd0;
//         p4_sign     <= 1'b0;
//         p4_div_zero <= 1'b0;
//     end else begin
//         p4_dividend <= p3_dividend;
//         p4_divisor  <= p3_divisor;
//         p4_X0       <= p3_X0;
//         p4_DX0      <= p3_divisor * p3_X0; // Q1.31 * Q2.30 -> Q3.61
//         p4_sign     <= p3_sign;
//         p4_div_zero <= p3_div_zero;
//     end
// end


// //------------------------------------------------------------------------------
// // Pipeline Stage 4: NR Iteration 1, Part 2 (X1 = X0 * (2 - D*X0))
// //------------------------------------------------------------------------------
// reg signed [39:0] p5_dividend;
// reg        [31:0] p5_divisor; // Q1.31
// reg signed [31:0] p5_X1;      // First refinement, format Q2.30
// reg               p5_sign;
// reg               p5_div_zero;

// wire signed [63:0] term_2_minus_DX0 = (64'd2 << 61) - p4_DX0; // 2.0 in Q3.61
// wire signed [95:0] new_X1_full      = p4_X0 * term_2_minus_DX0; // Q2.30 * Q3.61 -> Q5.91

// always @(posedge clk) begin
//     if (!reset) begin
//         p5_dividend <= 40'sd0;
//         p5_divisor  <= 32'd0;
//         p5_X1       <= 32'sd0;
//         p5_sign     <= 1'b0;
//         p5_div_zero <= 1'b0;
//     end else begin
//         p5_dividend <= p4_dividend;
//         p5_divisor  <= p4_divisor;
//         p5_X1       <= new_X1_full[91:61]; // Truncate Q5.91 back to Q2.30
//         p5_sign     <= p4_sign;
//         p5_div_zero <= p4_div_zero;
//     end
// end


// //------------------------------------------------------------------------------
// // Pipeline Stage 5: NR Iteration 2, Part 1 (D * X1)
// //------------------------------------------------------------------------------
// reg signed [39:0] p6_dividend;
// reg signed [31:0] p6_X1;      // Q2.30
// reg signed [63:0] p6_DX1;     // D * X1, format Q3.61
// reg               p6_sign;
// reg               p6_div_zero;

// always @(posedge clk) begin
//     if (!reset) begin
//         p6_dividend <= 40'sd0;
//         p6_X1       <= 32'sd0;
//         p6_DX1      <= 64'sd0;
//         p6_sign     <= 1'b0;
//         p6_div_zero <= 1'b0;
//     end else begin
//         p6_dividend <= p5_dividend;
//         p6_X1       <= p5_X1;
//         p6_DX1      <= p5_divisor * p5_X1; // Q1.31 * Q2.30 -> Q3.61
//         p6_sign     <= p5_sign;
//         p6_div_zero <= p5_div_zero;
//     end
// end


// //------------------------------------------------------------------------------
// // Pipeline Stage 6: NR Iteration 2, Part 2 (X2 = X1 * (2 - D*X1))
// //------------------------------------------------------------------------------
// reg signed [39:0] p7_dividend;
// reg signed [31:0] p7_X2;      // Final reciprocal, format Q2.30
// reg               p7_sign;
// reg               p7_div_zero;

// wire signed [63:0] term_2_minus_DX1 = (64'd2 << 61) - p6_DX1; // 2.0 in Q3.61
// wire signed [95:0] new_X2_full      = p6_X1 * term_2_minus_DX1; // Q2.30 * Q3.61 -> Q5.91

// always @(posedge clk) begin
//     if (!reset) begin
//         p7_dividend <= 40'sd0;
//         p7_X2       <= 32'sd0;
//         p7_sign     <= 1'b0;
//         p7_div_zero <= 1'b0;
//     end else begin
//         p7_dividend <= p6_dividend;
//         p7_X2       <= new_X2_full[91:61]; // Truncate Q5.91 back to Q2.30
//         p7_sign     <= p6_sign;
//         p7_div_zero <= p6_div_zero;
//     end
// end


// //------------------------------------------------------------------------------
// // Pipeline Stage 7: Final Multiplication (Quotient = Dividend * Reciprocal)
// //------------------------------------------------------------------------------
// reg signed [71:0] p8_quotient_full; // S40.0 * Q2.30 -> S41.30
// reg               p8_sign;
// reg               p8_div_zero;

// always @(posedge clk) begin
//     if (!reset) begin
//         p8_quotient_full <= 72'sd0;
//         p8_sign          <= 1'b0;
//         p8_div_zero      <= 1'b0;
//     end else begin
//         p8_quotient_full <= p7_dividend * p7_X2;
//         p8_sign          <= p7_sign;
//         p8_div_zero      <= p7_div_zero;
//     end
// end


// //------------------------------------------------------------------------------
// // Final Output Stage
// //------------------------------------------------------------------------------
// // To convert from S41.30 format to a standard integer, right-shift by 30 bits.
// // This is equivalent to taking the integer part of the fixed-point number.
// wire signed [41:0] quotient_signed = $signed(p8_quotient_full) >>> 30;

// // Handle sign and division by zero
// wire signed [39:0] final_quotient = p8_sign ? -quotient_signed[39:0] : quotient_signed[39:0];

// // On division by zero, output the largest positive signed number.
// assign quo_data = p8_div_zero ? 40'h7FFFFFFFFF : final_quotient;

// endmodule

// //==============================================================================
// // Sub-module: Leading Zero Counter (32-bit)
// //==============================================================================
// module lzc32 (
//     input [31:0] x,
//     output reg [4:0] lzc
// );
//     // Note: A 32-bit input can have from 0 to 32 leading zeros.
//     // However, for normalization, the input is non-zero, so the max is 31.
//     always @(*) begin
//         if      (x[31]) lzc = 5'd0;
//         else if (x[30]) lzc = 5'd1;
//         else if (x[29]) lzc = 5'd2;
//         else if (x[28]) lzc = 5'd3;
//         else if (x[27]) lzc = 5'd4;
//         else if (x[26]) lzc = 5'd5;
//         else if (x[25]) lzc = 5'd6;
//         else if (x[24]) lzc = 5'd7;
//         else if (x[23]) lzc = 5'd8;
//         else if (x[22]) lzc = 5'd9;
//         else if (x[21]) lzc = 5'd10;
//         else if (x[20]) lzc = 5'd11;
//         else if (x[19]) lzc = 5'd12;
//         else if (x[18]) lzc = 5'd13;
//         else if (x[17]) lzc = 5'd14;
//         else if (x[16]) lzc = 5'd15;
//         else if (x[15]) lzc = 5'd16;
//         else if (x[14]) lzc = 5'd17;
//         else if (x[13]) lzc = 5'd18;
//         else if (x[12]) lzc = 5'd19;
//         else if (x[11]) lzc = 5'd20;
//         else if (x[10]) lzc = 5'd21;
//         else if (x[9])  lzc = 5'd22;
//         else if (x[8])  lzc = 5'd23;
//         else if (x[7])  lzc = 5'd24;
//         else if (x[6])  lzc = 5'd25;
//         else if (x[5])  lzc = 5'd26;
//         else if (x[4])  lzc = 5'd27;
//         else if (x[3])  lzc = 5'd28;
//         else if (x[2])  lzc = 5'd29;
//         else if (x[1])  lzc = 5'd30;
//         else            lzc = 5'd31;
//     end
// endmodule

// //==============================================================================
// // Sub-module: Reciprocal Look-Up Table
// // Provides an initial guess for 1/D where D is a normalized Q1.31 number.
// // Index is the 5 most significant fractional bits of D.
// // Values are in Q2.30 format, calculated as round((1/D_midpoint) * 2^30).
// //==============================================================================
// module recip_lut (
//     input  wire [4:0] index,
//     output reg signed [31:0] value
// );
//     always @(*) begin
//         case (index)
//             5'd0:  value = 32'sd2114061312; // D ~ 0.5078, 1/D ~ 1.969
//             5'd1:  value = 32'sd2051021824; // D ~ 0.5234, 1/D ~ 1.910
//             5'd2:  value = 32'sd1991138304; // D ~ 0.5391, 1/D ~ 1.855
//             5'd3:  value = 32'sd1934209024; // D ~ 0.5547, 1/D ~ 1.803
//             5'd4:  value = 32'sd1880027136; // D ~ 0.5703, 1/D ~ 1.753
//             5'd5:  value = 32'sd1828403200; // D ~ 0.5859, 1/D ~ 1.707
//             5'd6:  value = 32'sd1779159040; // D ~ 0.6016, 1/D ~ 1.662
//             5'd7:  value = 32'sd1732132864; // D ~ 0.6172, 1/D ~ 1.620
//             5'd8:  value = 32'sd1687175168; // D ~ 0.6328, 1/D ~ 1.580
//             5'd9:  value = 32'sd1644146688; // D ~ 0.6484, 1/D ~ 1.542
//             5'd10: value = 32'sd1602920448; // D ~ 0.6641, 1/D ~ 1.506
//             5'd11: value = 32'sd1563381760; // D ~ 0.6797, 1/D ~ 1.471
//             5'd12: value = 32'sd1525422080; // D ~ 0.6953, 1/D ~ 1.438
//             5'd13: value = 32'sd1488941056; // D ~ 0.7109, 1/D ~ 1.407
//             5'd14: value = 32'sd1453848576; // D ~ 0.7266, 1/D ~ 1.376
//             5'd15: value = 32'sd1420060672; // D ~ 0.7422, 1/D ~ 1.347
//             5'd16: value = 32'sd1387501568; // D ~ 0.7578, 1/D ~ 1.320
//             5'd17: value = 32'sd1356095488; // D ~ 0.7734, 1/D ~ 1.293
//             5'd18: value = 32'sd1325772800; // D ~ 0.7891, 1/D ~ 1.267
//             5'd19: value = 32'sd1296469248; // D ~ 0.8047, 1/D ~ 1.243
//             5'd20: value = 32'sd1268121600; // D ~ 0.8203, 1/D ~ 1.219
//             5'd21: value = 32'sd1240674304; // D ~ 0.8359, 1/D ~ 1.196
//             5'd22: value = 32'sd1214072832; // D ~ 0.8516, 1/D ~ 1.174
//             5'd23: value = 32'sd1188268032; // D ~ 0.8672, 1/D ~ 1.153
//             5'd24: value = 32'sd1163214848; // D ~ 0.8828, 1/D ~ 1.133
//             5'd25: value = 32'sd1138866176; // D ~ 0.8984, 1/D ~ 1.113
//             5'd26: value = 32'sd1115181056; // D ~ 0.9141, 1/D ~ 1.094
//             5'd27: value = 32'sd1092120576; // D ~ 0.9297, 1/D ~ 1.076
//             5'd28: value = 32'sd1069645824; // D ~ 0.9453, 1/D ~ 1.058
//             5'd29: value = 32'sd1047719936; // D ~ 0.9609, 1/D ~ 1.041
//             5'd30: value = 32'sd1026306048; // D ~ 0.9766, 1/D ~ 1.024
//             5'd31: value = 32'sd1005371392; // D ~ 0.9922, 1/D ~ 1.008
//             default: value = 32'sd1073741824; // Should not be reached
//         endcase
//     end
// endmodule