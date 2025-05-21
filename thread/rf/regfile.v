module registerFile
(
    input wire clk,
    input wire rst,
    input wire [3:0] rs0,
    input wire [3:0] rs1,
    input wire [55:0] data_in,
    input wire [3:0] dest_sel,
    input wire isrdSIMD,
    input wire iswrSIMD,
    input wire wen,
    output wire [55:0] dout0,
    output wire [55:0] dout1
);

    (* dont_touch = "yes" *) reg [27:0] rf [0:15]; 
    integer i;

    assign dout0 = isrdSIMD ? {rf[rs0], rf[rs0 + 1]} : {rf[rs0], 28'b0};
    assign dout1 = isrdSIMD ? {rf[rs1], rf[rs1 + 1]} : {rf[rs1], 28'b0};

    always @(negedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 16; i = i + 1) begin
                rf[i] <= 28'b0;
            end
        end else if (wen and iswrSIMD) begin
            {rf[dest_sel], rf[dest_sel + 1]} <= data_in;
        end else if (wen) begin
            rf[dest_sel] <= data_in[55:28];
        end
    end
endmodule