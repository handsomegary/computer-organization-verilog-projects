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
	
		for (k=12; k<64; k=k+1) 
		begin  
			memory[k] <= 32'b0;
		end

		memory[0]  <= 32'b001000_00000_01111_0000000000110001; 
		memory[1]  <= 32'b001000_00000_10000_0000000000100101; 
		memory[2]  <= 32'b001000_00000_00111_0000000000011000; 
		memory[3]  <= 32'b001000_00000_01000_0000000000011001; 
		memory[4]  <= 32'b000000_01111_10000_10001_00000_100010;
		memory[5]  <= 32'b000000_01111_10000_10010_00000_100000;
		memory[6]  <= 32'b101011_01111_10000_0000000000000100;
		memory[7]  <= 32'b000000_01000_00111_01001_00000_100100;
		memory[8]  <= 32'b000100_01111_10000_0000000000000011; 
		memory[9]  <= 32'b000000_00111_01000_01011_00000_100101;
		memory[10] <= 32'b000000_00111_10000_10100_00000_101010;
		memory[11] <= 32'b100011_01111_01100_0000000000000100;

	end

endmodule
