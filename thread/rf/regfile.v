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
    // Register file with 16 registers (28 bits each)
    reg [27:0] rf [1:15];  // Only registers 1-15 are stored
    integer i;

    // Register 0 is hardwired to zero
    assign dout0 = (rs0 == 4'b0) ? 28'b0 : rf[rs0];
    assign dout1 = (rs1 == 4'b0) ? 28'b0 : rf[rs1];

    always @(negedge clk or posedge rst) begin
        if (rst) begin
            for (i = 1; i < 16; i = i + 1) begin
                rf[i] <= 28'b0;
            end
        end else if (wen) begin
            rf[dest_sel] <= data_in;
        end
    end
endmodule