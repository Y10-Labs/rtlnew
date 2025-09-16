`timescale 1ns/1ps

module tb_lambdagen;
    parameter VEC_COUNT = 5;
    logic clk, rst, valid, stall;
    logic [127:0] input_bus;
    wire [31:0] l1, l2, z;
    wire [15:0] tID;
    wire dovalid;
    
    logic [127:0] vectors [0:VEC_COUNT-1];
    logic [31:0] exp_l1 [0:VEC_COUNT-1];
    logic [31:0] exp_l2 [0:VEC_COUNT-1];
    logic [31:0] exp_l3 [0:VEC_COUNT-1];
    logic [31:0] exp_z  [0:VEC_COUNT-1];

    lambdagen dut(.clk(clk), .rst(rst), .valid(valid), .stall(stall), .input_bus(input_bus), .l1(l1), .l2(l2), .tID(tID), .z_(z), .dovalid(dovalid));

    initial clk = 0;
    always #5 clk = ~clk;

    integer test_num = 0, pass_count = 0, fail_count = 0;
    
    always @(posedge clk) begin
        if (dovalid && test_num < VEC_COUNT) begin
            $display("Test %0d: Expected: l1=%h l2=%h z=%h | Got: l1=%h l2=%h z=%h", 
                     test_num, exp_l1[test_num], exp_l2[test_num], exp_z[test_num], l1, l2, z);
        if (tID === test_num &&
            l1[31:8] === exp_l1[test_num][31:8] &&   // compare upper 24 bits
            l2[31:8] === exp_l2[test_num][31:8] &&   // compare upper 24 bits
            z[31:16] === exp_z[test_num][31:16])     // compare upper 16 bits
                pass_count++;
            else 
                fail_count++;
            test_num++;
        end
    end

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_lambdagen);

        $readmemh("vectors.mem", vectors);
        $readmemh("expected_l1.mem", exp_l1);
        $readmemh("expected_l2.mem", exp_l3);
        $readmemh("expected_l3.mem", exp_l2);
        $readmemh("expected_z.mem", exp_z);
        
        rst = 1; valid = 0; stall = 0; input_bus = 0;
        repeat(3) @(posedge clk);
        rst = 0;
        @(posedge clk);

        for (int i = 0; i < VEC_COUNT; i++) begin
            #1 input_bus = vectors[i]; 
            valid = 1;
            @(posedge clk);
        end
        valid = 0; input_bus = 0;
        repeat(20) @(posedge clk);
        
        $display("PASSED: %0d/%0d, FAILED: %0d/%0d", pass_count, VEC_COUNT, fail_count, VEC_COUNT);
        $finish;
    end

    initial begin
        #10000;
        $display("TIMEOUT");
        $finish;
    end
endmodule
