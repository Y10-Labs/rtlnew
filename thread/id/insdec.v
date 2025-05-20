module instructionDecode
(
    input wire [31:0] ins,
    output wire [1:0] alusel0,
    output wire [1:0] alusel1,
    output wire [2:0] flags,
    output wire inc,
    output wire sh1dir,
    output wire sh2dir,
    output wire [3:0] shamt1,
    output wire [3:0] shamt2,
    output wire isSIMD,
    output wire isJump,
    output wire pop,
    output wire zcmpw,
    output wire setTOS,
    output wire isHalted,
    output wire idf,
    output wire [9:0] jumpAddr,
    output wire [9:0] addrTOS,
    output wire [3:0] rs0,
    output wire [3:0] rs1,
    output wire [3:0] rd
);
    assign alusel0 = ins[1:0];
    assign alusel1 = ins[3:2];
    assign flags = ins[8:6];
    assign inc = ins[9];
    assign sh1dir = ins[14];
    assign sh2dir = ins[19];
    assign sh1 = ins[13:10];
    assign sh2 = ins[18:15];
    assign isSIMD = (~ins[5]) & (~ins[4]);
    assign isJump = ins[5] & (~ins[3]);
    assign pop = ins[5] & ins[3];
    assign zcmpw = ins[4] & (~ins[3]) & (~ins[2]);
    assign setTOS = (~ins[5]) & ins[3] & ins[2];
    assign isHalted = ins[5] & ins[4] & ins[3];
    assign idf = ins[4] & ins[3] & (~ins[2]);
    assign jumpAddr = ins[19:10];
    assign addrTOS = ins[19:10];
    assign rd = ins[31:28];
    assign rs1 = ins[27:24];
    assign rs0 = ins[23:20];
endmodule