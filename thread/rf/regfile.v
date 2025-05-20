module registerFile
(
    input wire clk,
    input wire rst,
    input wire [3:0] rs0,
    input wire [3:0] rs1,
    input wire [27:0] data_in,
    input wire [3:0] dest_sel,
    input wire wen,
    output wire [27:0] dout0,
    output wire [27:0] dout1
);
    reg [27:0] rf [0:15];
    integer i;

    assign dout0 = rf[rs0];
    assign dout1 = rf[rs1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 16; i = i + 1) begin
                rf[i] <= 28'b0;
            end
        end else if (wen) begin
            rf[dest_sel] <= (|dest_sel)? data_in : 28'b0;
        end
    end
endmodule