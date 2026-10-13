module EX_MEM(REGWRITE_out, MEMTOREG_out, BRANCH_out, MEMREAD_out, MEMWRITE_out,
	ADD_RESULT_out, ALU_RESULT_out, READ_DATA_2_out, WRITE_ADDR_out, ZERO_out,
	CLK, RST, REGWRITE, MEMTOREG, BRANCH, MEMREAD, MEMWRITE,
	ADD_RESULT, ALU_RESULT, READ_DATA_2, WRITE_ADDR, ZERO);

output reg REGWRITE_out, MEMTOREG_out; 
output reg BRANCH_out, MEMREAD_out, MEMWRITE_out; 
output reg [31:0] ADD_RESULT_out, ALU_RESULT_out, READ_DATA_2_out;
output reg [4:0] WRITE_ADDR_out ;
output reg ZERO_out ;

input CLK, RST;
input REGWRITE, MEMTOREG; 
input BRANCH, MEMREAD, MEMWRITE; 

input [31:0] ADD_RESULT, ALU_RESULT, READ_DATA_2;
input [4:0] WRITE_ADDR ;
input ZERO ;



always@(posedge CLK or posedge RST)
	if(RST)begin
		REGWRITE_out<=1'b0;
		MEMTOREG_out<=1'b0;
		BRANCH_out<=1'b0;
		MEMREAD_out<=1'b0;
		MEMWRITE_out<=1'b0;

		ADD_RESULT_out <= 32'b0 ;
		ALU_RESULT_out <= 32'b0 ;
		READ_DATA_2_out <= 32'b0 ;
		WRITE_ADDR_out <= 5'b0 ;
		ZERO_out <= 1'b0 ;

	end
	else begin
		REGWRITE_out<=REGWRITE;
		MEMTOREG_out<=MEMTOREG;
		BRANCH_out<=BRANCH;
		MEMREAD_out<=MEMREAD;
		MEMWRITE_out<=MEMWRITE;

		ADD_RESULT_out <= ADD_RESULT ;
		ALU_RESULT_out <= ALU_RESULT ;
		READ_DATA_2_out <= READ_DATA_2 ;
		WRITE_ADDR_out <= WRITE_ADDR ;
		ZERO_out <= ZERO ;
	end
endmodule