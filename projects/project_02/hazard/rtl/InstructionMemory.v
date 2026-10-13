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
	
		for (k=12; k<64; k=k+1) begin  
			memory[k] <= 32'b0;
		end
		
		memory[0] <= 32'b001000_00000_00010_0000000000000010;
		memory[1] <= 32'b001000_00000_00100_0000000000000100;
		memory[2] <= 32'b001000_00000_00101_0000000000000101;
		memory[3] <= 32'b001000_00000_00110_0000000000000110;
		memory[4] <= 32'b000000_00010_00100_00011_00000_100010;
		memory[5] <= 32'b000000_00011_00101_01101_00000_100100;
		memory[6] <= 32'b000000_00110_00011_01110_00000_100101;
		memory[7] <= 32'b000000_00011_00011_01111_00000_100000;
		memory[8] <= 32'b101011_00011_00011_0000000000010000;
	end

endmodule
