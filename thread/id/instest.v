`timescale 1ns / 1ps

module instructionDecode_tb;
    // Inputs
    reg [31:0] ins;

    // Outputs
    wire [1:0] alusel0;
    wire [1:0] alusel1;
    wire [2:0] flags;
    wire inc;
    wire sh1dir;
    wire sh2dir;
    wire [3:0] sh1;
    wire [3:0] sh2;
    wire isSIMD;
    wire isJump;
    wire pop;
    wire zcmpw;
    wire setTOS;
    wire isHalted;
    wire idf;
    wire [9:0] jumpAddr;
    wire [3:0] rs0;
    wire [3:0] rs1;
    wire [3:0] rd;

    instructionDecode uut (
        .ins(ins),
        .alusel0(alusel0),
        .alusel1(alusel1),
        .flags(flags),
        .inc(inc),
        .sh1dir(sh1dir),
        .sh2dir(sh2dir),
        .sh1(sh1),
        .sh2(sh2),
        .isSIMD(isSIMD),
        .isJump(isJump),
        .pop(pop),
        .zcmpw(zcmpw),
        .setTOS(setTOS),
        .isHalted(isHalted),
        .idf(idf),
        .jumpAddr(jumpAddr),
        .rs0(rs0),
        .rs1(rs1),
        .rd(rd)
    );

    // Helper: assemble 32-bit instruction
    function automatic [31:0] make_ins(
        input [3:0] dest,
        input [3:0] s1,
        input [3:0] s0,
        input [9:0] imm_sh,
        input        inc_bit,
        input [2:0] flags_in,
        input [3:0] opcode1,
        input [1:0] opcode2
    );
        begin
            make_ins = {dest, s1, s0, imm_sh, inc_bit, flags_in, opcode1, opcode2};
        end
    endfunction

    initial begin
        ins = make_ins(4'h0, 4'h0, 4'h0, 10'h000, 1'b0, 3'b000, 4'h0, 2'b00);
        #5;
        $display("Test 0: zeros => alusel0=%b alusel1=%b flags=%b inc=%b isSIMD=%b isJump=%b pop=%b zcmpw=%b setTOS=%b isHalted=%b idf=%b rd=%h rs1=%h rs0=%h jumpAddr=%h", 
                 alusel0, alusel1, flags, inc, isSIMD, isJump, pop, zcmpw, setTOS, isHalted, idf, rd, rs1, rs0, jumpAddr);

        // Test 1: SIMD (opcode1=0, opcode2=0)
        ins = make_ins(4'hA, 4'h1, 4'h2, 10'h123, 1'b0, 3'b010, 4'h0, 2'b00);
        #5;
        $display("Test 1: SIMD => isSIMD=%b (should=1), rd=%h, rs1=%h, rs0=%h, imm_sh=%h, flags=%b", 
                 isSIMD, rd, rs1, rs0, jumpAddr, flags);
        $finish;
    end
endmodule
