`timescale 1ns / 1ps



















module IF(pc,newpc,clk,rst,instruction,Read_Reg1,Read_Reg2,Alu_control,branch,jump,PC_CLK);

input branch;
input [31:0]pc;
input jump;
output reg [31:0]newpc;
input rst,clk;
input PC_CLK;
output reg [31:0]instruction;
output reg [4:0]Read_Reg1,Read_Reg2;
output reg [5:0]Alu_control;

always@(posedge PC_CLK or posedge rst)
	begin 
		if(rst)
			begin
				newpc[31:0]<=pc[31:0];
				
			end
		else
		
			if(jump)
				
				newpc[31:0]<=32'b00001000000000000000000000011001;
			else if(branch)
				newpc[31:0]<=32'b10001100001000000000000000000000;
				
			else
				newpc[31:0]<=newpc[31:0]+32'd4;
	end

always@(posedge PC_CLK or posedge rst)
   begin
	  if(rst)
		  instruction<=32'd0;
	  else
		  case(newpc)
		  32'd4:instruction<=32'b00100001011000010000000000101000;
		  32'd8:instruction<=32'b10001100001000000000000000000000;
		  32'd12:instruction<=32'b00000001001010100100100000100000;
		  32'd16:instruction<=32'b00100000001111111111111111111100;
		  32'd20:instruction<=32'b00000000001010110000100000101010;
		  32'd24:instruction<=32'b00010000010111111111111111111011;
		  32'd28:instruction<=32'b00001000000000000000000000011001;
		  32'd104:instruction<=32'b10010101000010110100000000100101;
		  32'd108:instruction<=32'b00000000100000110010000000100010;
		  32'd112:instruction<=32'b00000000111001000011100000100100;
		  32'd116:instruction<=32'b10101100110000000000000000000000;
		  default instruction<=instruction;
		  endcase
	end
	
always@(posedge PC_CLK)
begin
			Read_Reg1<=instruction[25:21];
			Read_Reg2<=instruction[20:16];
end

endmodule
