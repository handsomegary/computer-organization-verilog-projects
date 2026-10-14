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
	assign INSTRUCTION = memory[shifted_read_addr];


	integer k;
	// I-MEM in this case is addressed by word, not by byte
	

	always @(posedge RST)
	begin
	
		for (k=12; k<64; k=k+1) 
		begin  // here Ou changes k=0 to k=16
			memory[k] <= 32'b0;
		end

		memory[0]  <= 32'b001000_00000_10000_0000000000110000;
		memory[1]  <= 32'b001000_00000_10001_0000000000100100;
		memory[2]  <= 32'b001000_00000_01000_0000000000010111;
		memory[3]  <= 32'b001000_00000_01001_0000000000011000;
		memory[4]  <= 32'b000000_10000_10001_10010_00000_100010;
		memory[5]  <= 32'b000000_10000_10001_10011_00000_100000;
		memory[6]  <= 32'b101011_10000_10001_0000000000000100;
		memory[7]  <= 32'b000000_01001_01000_01010_00000_100100;
		memory[8]  <= 32'b000100_10000_10001_0000000000000011;
		memory[9]  <= 32'b000000_01000_01001_01100_00000_100101;
		memory[10] <= 32'b000000_01000_10001_10101_00000_101010;
		memory[11] <= 32'b100011_10000_01101_0000000000000100;

	end

endmodule
