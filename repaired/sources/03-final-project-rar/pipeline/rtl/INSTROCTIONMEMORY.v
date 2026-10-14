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
  // Level B: three NOPs separate instructions to schedule RAW dependencies.
  always @(posedge RST) begin
    for (k=0; k<1024; k=k+1) memory[k] <= 32'b0;
      memory[0] <= 32'h20010190; // addi $1,$0,400
      memory[1] <= 32'h00000000; // scheduled NOP
      memory[2] <= 32'h00000000; // scheduled NOP
      memory[3] <= 32'h00000000; // scheduled NOP
      memory[4] <= 32'h20020007; // addi $2,$0,7
      memory[5] <= 32'h00000000; // scheduled NOP
      memory[6] <= 32'h00000000; // scheduled NOP
      memory[7] <= 32'h00000000; // scheduled NOP
      memory[8] <= 32'hac220000; // sw $2,0($1)
      memory[9] <= 32'h00000000; // scheduled NOP
      memory[10] <= 32'h00000000; // scheduled NOP
      memory[11] <= 32'h00000000; // scheduled NOP
      memory[12] <= 32'h8c230000; // lw $3,0($1)
      memory[13] <= 32'h00000000; // scheduled NOP
      memory[14] <= 32'h00000000; // scheduled NOP
      memory[15] <= 32'h00000000; // scheduled NOP
      memory[16] <= 32'h00622020; // add $4,$3,$2
      memory[17] <= 32'h00000000; // scheduled NOP
      memory[18] <= 32'h00000000; // scheduled NOP
      memory[19] <= 32'h00000000; // scheduled NOP
      memory[20] <= 32'h2005ffff; // addi $5,$0,-1
      memory[21] <= 32'h00000000; // scheduled NOP
      memory[22] <= 32'h00000000; // scheduled NOP
      memory[23] <= 32'h00000000; // scheduled NOP
      memory[24] <= 32'h00a23022; // sub $6,$5,$2
      memory[25] <= 32'h00000000; // scheduled NOP
      memory[26] <= 32'h00000000; // scheduled NOP
      memory[27] <= 32'h00000000; // scheduled NOP
      memory[28] <= 32'h00823824; // and $7,$4,$2
      memory[29] <= 32'h00000000; // scheduled NOP
      memory[30] <= 32'h00000000; // scheduled NOP
      memory[31] <= 32'h00000000; // scheduled NOP
      memory[32] <= 32'h00e24025; // or $8,$7,$2
      memory[33] <= 32'h00000000; // scheduled NOP
      memory[34] <= 32'h00000000; // scheduled NOP
      memory[35] <= 32'h00000000; // scheduled NOP
      memory[36] <= 32'h00a2482a; // slt $9,$5,$2
      memory[37] <= 32'h00000000; // scheduled NOP
      memory[38] <= 32'h00000000; // scheduled NOP
      memory[39] <= 32'h00000000; // scheduled NOP
      memory[40] <= 32'h11200007; // beq $9,$0,wrong (not taken)
      memory[41] <= 32'h00000000; // scheduled NOP
      memory[42] <= 32'h00000000; // scheduled NOP
      memory[43] <= 32'h00000000; // scheduled NOP
      memory[44] <= 32'h1129000b; // beq $9,$9,taken
      memory[45] <= 32'h00000000; // scheduled NOP
      memory[46] <= 32'h00000000; // scheduled NOP
      memory[47] <= 32'h00000000; // scheduled NOP
      memory[48] <= 32'h200a0063; // wrong path: addi $10,$0,99
      memory[49] <= 32'h00000000; // scheduled NOP
      memory[50] <= 32'h00000000; // scheduled NOP
      memory[51] <= 32'h00000000; // scheduled NOP
      memory[52] <= 32'hac220004; // wrong path: sw $2,4($1)
      memory[53] <= 32'h00000000; // scheduled NOP
      memory[54] <= 32'h00000000; // scheduled NOP
      memory[55] <= 32'h00000000; // scheduled NOP
      memory[56] <= 32'h08000040; // j done
      memory[57] <= 32'h00000000; // scheduled NOP
      memory[58] <= 32'h00000000; // scheduled NOP
      memory[59] <= 32'h00000000; // scheduled NOP
      memory[60] <= 32'h200b0063; // wrong path: addi $11,$0,99
      memory[61] <= 32'h00000000; // scheduled NOP
      memory[62] <= 32'h00000000; // scheduled NOP
      memory[63] <= 32'h00000000; // scheduled NOP
      memory[64] <= 32'h202cfffc; // addi $12,$1,-4
      memory[65] <= 32'h00000000; // scheduled NOP
      memory[66] <= 32'h00000000; // scheduled NOP
      memory[67] <= 32'h00000000; // scheduled NOP
      memory[68] <= 32'hac2c0008; // sw $12,8($1)
      memory[69] <= 32'h00000000; // scheduled NOP
      memory[70] <= 32'h00000000; // scheduled NOP
      memory[71] <= 32'h00000000; // scheduled NOP
      memory[72] <= 32'h08000048; // j stop
      memory[73] <= 32'h00000000; // scheduled NOP
      memory[74] <= 32'h00000000; // scheduled NOP
      memory[75] <= 32'h00000000; // scheduled NOP
  end
endmodule
