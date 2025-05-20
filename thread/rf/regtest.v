`timescale 1ns / 1ps

module registerFile_tb;
    // Inputs
    reg clk;
    reg rst;
    reg [3:0] rs0;
    reg [3:0] rs1;
    reg [27:0] data_in;
    reg [3:0] dest_sel;
    reg wen;

    // Outputs
    wire [27:0] dout0;
    wire [27:0] dout1;

    // Instantiate the Unit Under Test (UUT)
    registerFile uut (
        .clk(clk),
        .rst(rst),
        .rs0(rs0),
        .rs1(rs1),
        .data_in(data_in),
        .dest_sel(dest_sel),
        .wen(wen),
        .dout0(dout0),
        .dout1(dout1)
    );

    // Clock generation: 10ns period
    initial begin
        clk = 0;
        forever #1.5 clk = ~clk;
    end

    initial begin
        $dumpfile("registerFile.vcd");
        $dumpvars(0, registerFile_tb);

        // Test 1: Reset clears all registers to zero
        rst = 1;
        wen = 0;
        rs0 = 4'd0; rs1 = 4'd1;
        #3;
        rst = 0;
        #4.5;
        if (dout0 !== 28'd0 || dout1 !== 28'd0) begin
            $display("[FAIL] Reset did not clear registers: dout0=%h dout1=%h", dout0, dout1);
        end else begin
            $display("[PASS] Reset cleared registers");
        end

        // Test 2: Write to R0 (dest_sel=0) should write zero regardless of data_in
        data_in = 28'hABCDE;
        dest_sel = 4'd0;
        wen = 1;
        #3;
        wen = 0;
        rs0 = 4'd0; rs1 = 4'd0;
        #3;
        if (dout0 !== 28'd0) begin
            $display("[FAIL] Write to R0 should remain zero: dout0=%h", dout0);
        end else begin
            $display("[PASS] R0 write-protected");
        end

        // Test 3: Write and read from multiple registers
        // Write 0x1234567 to R5
        data_in = 28'h1234567;
        dest_sel = 4'd5;
        wen = 1;
        #3;
        wen = 0;
        rs0 = 4'd5; rs1 = 4'd0;
        #3;
        if (dout0 !== 28'h1234567 || dout1 !== 28'd0) begin
            $display("[FAIL] Write/Read mismatch: dout0=%h dout1=%h", dout0, dout1);
        end else begin
            $display("[PASS] Write/read R5 and R0");
        end

        // Test 4: Overwrite a register
        data_in = 28'h0FEDCBA;
        dest_sel = 4'd5;
        wen = 1;
        #3;
        wen = 0;
        rs0 = 4'd5; rs1 = 4'd5;
        #3;
        if (dout0 !== 28'h0FEDCBA || dout1 !== 28'h0FEDCBA) begin
            $display("[FAIL] Overwrite failed: dout0=%h dout1=%h", dout0, dout1);
        end else begin
            $display("[PASS] Overwrite register");
        end
        $display("All tests completed.");
        $finish;
    end
endmodule
