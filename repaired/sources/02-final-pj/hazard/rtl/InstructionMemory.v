`timescale 1ns / 1ps
module InstructionMemory(INSTRUCTION, ADDR, RST);
  output [31:0] INSTRUCTION;
  input [31:0] ADDR;
  input RST;
  reg [31:0] memory[0:1023];
  wire valid_addr = (ADDR[31:12] == 0) && (ADDR[1:0] == 0);
  assign INSTRUCTION = valid_addr ? memory[ADDR[11:2]] : 32'b0;
  integer k;
  // Demo covers all ten required instructions, byte address 400,
  // negative immediate, signed SLT, taken/untaken branches and jump.
  // Level C: dependencies execute without scheduled NOPs.
  always @(posedge RST) begin
    for (k=0; k<1024; k=k+1) memory[k] <= 32'b0;
      memory[0] <= 32'h20010190; // addi $1,$0,400
      memory[1] <= 32'h20020007; // addi $2,$0,7
      memory[2] <= 32'hac220000; // sw $2,0($1)
      memory[3] <= 32'h8c230000; // lw $3,0($1)
      memory[4] <= 32'h00622020; // add $4,$3,$2
      memory[5] <= 32'h2005ffff; // addi $5,$0,-1
      memory[6] <= 32'h00a23022; // sub $6,$5,$2
      memory[7] <= 32'h00823824; // and $7,$4,$2
      memory[8] <= 32'h00e24025; // or $8,$7,$2
      memory[9] <= 32'h00a2482a; // slt $9,$5,$2
      memory[10] <= 32'h11200001; // beq $9,$0,wrong (not taken)
      memory[11] <= 32'h11290002; // beq $9,$9,taken
      memory[12] <= 32'h200a0063; // wrong path: addi $10,$0,99
      memory[13] <= 32'hac220004; // wrong path: sw $2,4($1)
      memory[14] <= 32'h08000010; // j done
      memory[15] <= 32'h200b0063; // wrong path: addi $11,$0,99
      memory[16] <= 32'h202cfffc; // addi $12,$1,-4
      memory[17] <= 32'hac2c0008; // sw $12,8($1)
      memory[18] <= 32'h08000012; // j stop
  end
endmodule
