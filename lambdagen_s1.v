module lambdagen_s1 #(
    parameter ZWIDTH = 16,
    parameter XWIDTH = 9,
    parameter YWIDTH = 8,
    parameter IDWIDTH = 16,
    parameter LWIDTH = 32
)
(
    input clk,
    input rst,
    input valid,
    input stall,
    input [IDWIDTH-1:0] tID_s0,
    input signed [XWIDTH-1:0] x1_s0, x2_s0, x3_s0,
    input signed [YWIDTH-1:0] y1_s0, y2_s0, y3_s0,
    input signed [ZWIDTH-1:0] z1_s0, z2_s0, z3_s0,
    output reg signed [XWIDTH:0] dl1x_s1, 
    output reg signed [XWIDTH:0] dl2x_s1, 
    output reg signed [YWIDTH:0] dl1y_s1,
    output reg signed [YWIDTH:0] dl2y_s1,
    output reg signed [XWIDTH-1:0] x1_s1,
    output reg signed [XWIDTH-1:0] x2_s1,
    output reg signed [YWIDTH-1:0] y1_s1,
    output reg signed [YWIDTH-1:0] y2_s1,
    output reg signed [ZWIDTH-1:0] z1_s1,
    output reg signed [ZWIDTH-1:0] z2_s1,
    output reg signed [ZWIDTH-1:0] z3_s1,
    output reg [IDWIDTH-1:0] tID_s1,
    output reg ovalid
);
    always @(posedge clk) begin
        if (rst) begin 
            dl1x_s1 <= 0;
            dl2x_s1 <= 0;
            dl1y_s1 <= 0;
            dl2y_s1 <= 0;
            tID_s1 <= 0;
            x1_s1 <= 0;
            x2_s1 <= 0;
            y1_s1 <= 0;
            y2_s1 <= 0;
            z1_s1 <= 0;
            z2_s1 <= 0;
            z3_s1 <= 0;
            ovalid <= 0;
        end
        else if (valid) begin
            dl1x_s1 <= y2_s0 - y1_s0;
            dl2x_s1 <= y3_s0 - y2_s0;
            dl1y_s1 <= x1_s0 - x2_s0;
            dl2y_s1 <= x2_s0 - x3_s0;
            tID_s1  <= tID_s0;
            x1_s1 <= x1_s0;
            x2_s1 <= x2_s0;
            y1_s1 <= y1_s0;
            y2_s1 <= y2_s0;
            z1_s1 <= z1_s0;
            z2_s1 <= z2_s0;
            z3_s1 <= z3_s0;
            ovalid <= 1;
        end
        else if (stall) begin
            dl1x_s1 <= dl1x_s1;
            dl2x_s1 <= dl2x_s1;
            dl1y_s1 <= dl1y_s1;
            dl2y_s1 <= dl2y_s1;
            tID_s1  <= tID_s1 ;
            x1_s1 <= x1_s1;
            x2_s1 <= x2_s1;
            y1_s1 <= y1_s1;
            y2_s1 <= y2_s1;
            z1_s1 <= z1_s1;
            z2_s1 <= z2_s1;
            z3_s1 <= z3_s1;
            ovalid <= 1;
        end
        else begin
            ovalid <= 0;
        end
    end
endmodule
