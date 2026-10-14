`timescale 1ns / 1ps
module ID_EX(REGWRITE_out, MEMTOREG_out, BRANCH_out, MEMREAD_out, MEMWRITE_out,ALUSRC_out, REGDST_out, ALUOP_out, 
	PC_4_out, READ_DATA_1_out, READ_DATA_2_out, SE_REG_out, RD_out, RT_out,
	REGWRITE, MEMTOREG, BRANCH, MEMREAD, MEMWRITE, REGDST, ALUSRC, ALUOP, 
	PC_4, READ_DATA_1, READ_DATA_2, SE_REG, RD, RT, CLK, RST);

output reg REGWRITE_out, MEMTOREG_out; //WB
output reg BRANCH_out, MEMREAD_out, MEMWRITE_out; //M
output reg ALUSRC_out, REGDST_out; //EX
output reg [1:0] ALUOP_out; //EX
output reg [31:0] PC_4_out, READ_DATA_1_out, READ_DATA_2_out, SE_REG_out;
output reg [4:0] RD_out, RT_out;

input CLK, RST;
input REGWRITE, MEMTOREG; //WB
input BRANCH, MEMREAD, MEMWRITE; //M
input REGDST, ALUSRC ;//EX
input [1:0] ALUOP; //EX
input [31:0] PC_4, READ_DATA_1, READ_DATA_2, SE_REG;
input [4:0] RD, RT;




always@(posedge CLK or posedge RST)
	if(RST)begin
		REGWRITE_out<=1'b0;
		MEMTOREG_out<=1'b0;
		BRANCH_out<=1'b0;
		MEMREAD_out<=1'b0;
		MEMWRITE_out<=1'b0;
		REGDST_out<=1'b0;
		ALUSRC_out<=1'b0;
		ALUOP_out<=2'b00;
		PC_4_out<=32'b0;
		READ_DATA_1_out<=32'b0; 
		READ_DATA_2_out<=32'b0;
		SE_REG_out<=32'b0;
		RD_out<=5'b0; 
		RT_out<=5'b0;
	end
	else begin
		REGWRITE_out<=REGWRITE;
		MEMTOREG_out<=MEMTOREG;
		BRANCH_out<=BRANCH;
		MEMREAD_out<=MEMREAD;
		MEMWRITE_out<=MEMWRITE;
		REGDST_out<=REGDST;
		ALUSRC_out<=ALUSRC;
		ALUOP_out<=ALUOP;
		PC_4_out<=PC_4;
		READ_DATA_1_out<=READ_DATA_1; 
		READ_DATA_2_out<=READ_DATA_2;
		SE_REG_out<=SE_REG;
		RD_out<=RD; 
		RT_out<=RT;
	end
endmodule