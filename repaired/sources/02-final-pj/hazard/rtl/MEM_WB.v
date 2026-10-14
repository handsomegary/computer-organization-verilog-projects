`timescale 1ns / 1ps
module MEM_WB (WRITE_ADDR_out, ALU_result_out, READ_DATA_out, WB_RegWrite_out, WB_MemToReg_out, 
	WRITE_ADDR, ALU_result, READ_DATA, WB_RegWrite, WB_MemToReg, CLK, RST);

output reg [31:0] ALU_result_out, READ_DATA_out;
output reg [4:0] WRITE_ADDR_out ;
output reg WB_RegWrite_out, WB_MemToReg_out;

input [31:0] ALU_result, READ_DATA;
input [4:0]  WRITE_ADDR ;
input WB_RegWrite, WB_MemToReg ;
input CLK,RST;

always@(posedge CLK or posedge RST) begin
	if(RST) begin
		WRITE_ADDR_out <= 32'b0;
		ALU_result_out <= 32'b0;
		READ_DATA_out <= 32'b0;
		WB_RegWrite_out <= 1'b0;
		WB_MemToReg_out <= 1'b0;
	end
	else begin
		WRITE_ADDR_out <= WRITE_ADDR;
		ALU_result_out <= ALU_result;
		READ_DATA_out <= READ_DATA;
		WB_RegWrite_out <= WB_RegWrite ;
		WB_MemToReg_out <= WB_MemToReg ;
	end

end

endmodule
