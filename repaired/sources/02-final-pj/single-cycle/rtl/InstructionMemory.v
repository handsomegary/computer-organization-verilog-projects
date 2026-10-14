`timescale 1ns / 1ps

module InstructionMemory(INSTRUCTION, ADDR, RST) ;

	output [31:0]INSTRUCTION ;
	input [31:0]ADDR ;
	input RST ;

	reg [31:0]memory[63:0] ;

	//assign INSTRUCTION = memory[ADDR] ;

//////////////////////////////////////////////////////////////////////////////////////////////////

	wire [31:0] shifted_read_addr;
	assign shifted_read_addr = { 2'b00,ADDR[31:2] };
	// Out-of-range or unaligned instruction fetches produce NOP.
	assign INSTRUCTION = (ADDR[1:0] == 0 && ADDR < 32'd256) ? memory[shifted_read_addr] : 32'b0;


	integer k;

	always @(posedge RST)
	begin
		for (k=0; k<64; k=k+1) begin  // initialize every ROM word
			memory[k] <= 32'b0;
		end

memory[0] <= 32'b001000_00000_10001_0000000000010001; //addi $s1, $zero, 17
memory[1] <= 32'b001000_00000_10010_0000000000010011; //addi $s2, $zero, 19
memory[2] <= 32'b101011_10010_10001_0000000000000001; //sw $s1, 1($s2): byte address 20, aligned
memory[3] <= 32'b000000_10001_10010_10011_00000_100010; //sub $s3, $s1, $s2
memory[4] <= 32'b001000_00000_10010_1111111111111110; //addi $s2, $zero, -2
memory[5] <= 32'b000100_10010_10011_0000000000000011; //beq $s2, $s3, LABEL1
memory[6] <= 32'b001000_00000_10010_0000000000010011; //addi $s2, $zero, 19
memory[7] <= 32'b100011_10010_10001_0000000000000001; //lw $s1, 1($s2): byte address 20, aligned
memory[8] <= 32'b000010_00000000000000000000001110; //j  EXIT
memory[9] <= 32'b000000_10010_10011_10101_00000_100100; //and $s5, $s2, $s3
memory[10] <= 32'b000000_10101_10001_01001_00000_100101; //or $t1, $s5, $s1
memory[11] <= 32'b000000_10010_10011_10101_00000_101010; //slt $s5, $s2, $s3
memory[12] <= 32'b000000_10101_01001_01010_00000_100000; //add $t2, $s5, $t1
memory[13] <= 32'b000010_00000000000000000000000110; //j  LABEL2


	end

endmodule
