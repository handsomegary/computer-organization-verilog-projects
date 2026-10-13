`timescale 1ns / 1ps

module InstructionMemory(INSTRUCTION, ADDR, RST) ;

	output [31:0]INSTRUCTION ;
	input [31:0]ADDR ;
	input RST ;

	reg [31:0]memory[63:0] ;
	
	



	wire [31:0] shifted_read_addr;
	assign shifted_read_addr = { 2'b00,ADDR[31:2] };
	assign INSTRUCTION = memory[shifted_read_addr];


	integer k;

	always @(posedge RST)
	begin	
		for (k=14; k<64; k=k+1) begin  
			memory[k] <= 32'b0;
		end	

memory[0] <= 32'b001000_00000_10001_0000000000010001; 
memory[1] <= 32'b001000_00000_10010_0000000000010011; 
memory[2] <= 32'b101011_10010_10001_0000000000000100; 
memory[3] <= 32'b000000_10001_10010_10011_00000_100010; 
memory[4] <= 32'b001000_00000_10010_1111111111111110; 
memory[5] <= 32'b000100_10010_10011_0000000000000011; 
memory[6] <= 32'b001000_00000_10010_0000000000010011; 
memory[7] <= 32'b100011_10010_10001_0000000000000100; 
memory[8] <= 32'b000010_00000000000000000000001110; 
memory[9] <= 32'b000000_10010_10011_10101_00000_100100; 
memory[10] <= 32'b000000_10101_10001_01001_00000_100101; 
memory[11] <= 32'b000000_10010_10011_10101_00000_101010; 
memory[12] <= 32'b000000_10101_01001_01010_00000_100000; 
memory[13] <= 32'b000010_00000000000000000000000110; 


	end

endmodule
