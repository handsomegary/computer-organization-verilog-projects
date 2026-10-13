module ID_EX(REGWRITE_out, MEMTOREG_out, BRANCH_out, MEMREAD_out, MEMWRITE_out,ALUSRC_out, REGDST_out, ALUOP_out, 
	PC_4_out, ReadData_1_out, ReadData_2_out, Signextend_Reg, RD_out, RT_out, RS_out,
	REGWRITE, MEMTOREG, BRANCH, MEMREAD, MEMWRITE, REGDST, ALUSRC, ALUOP, 
	PC_4, READ_DATA_1, READ_DATA_2, SE_REG, RD, RT, RS, CLK, RST);

output reg REGWRITE_out, MEMTOREG_out; 
output reg BRANCH_out, MEMREAD_out, MEMWRITE_out; 
output reg ALUSRC_out, REGDST_out;
output reg [1:0] ALUOP_out; 
output reg [31:0] PC_4_out, ReadData_1_out, ReadData_2_out, Signextend_Reg;
output reg [4:0] RD_out, RT_out, RS_out;

input CLK, RST;
input REGWRITE, MEMTOREG; 
input BRANCH, MEMREAD, MEMWRITE; 
input REGDST, ALUSRC ;
input [1:0] ALUOP; 
input [31:0] PC_4, READ_DATA_1, READ_DATA_2, SE_REG;
input [4:0] RD, RT, RS;




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
		ReadData_1_out<=32'b0; 
		ReadData_2_out<=32'b0;
		Signextend_Reg<=32'b0;
		RD_out<=5'b0; 
		RT_out<=5'b0;
		RS_out<=5'b0;
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
		ReadData_1_out<=READ_DATA_1; 
		ReadData_2_out<=READ_DATA_2;
		Signextend_Reg<=SE_REG;
		RD_out<=RD; 
		RT_out<=RT;
		RS_out<=RS;
	end
endmodule
