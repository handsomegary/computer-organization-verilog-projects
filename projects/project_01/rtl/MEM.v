`timescale 1ns / 1ps



















module MEM(Read_data_mem,instruction_Alu,Alu_result,clk,Write_data_mem,rst,instruction_Mem );

output reg signed [31:0]Read_data_mem;
input [31:0]instruction_Alu;
input clk,rst;
input signed [31:0]Write_data_mem;
output reg [31:0]instruction_Mem;
reg [31:0]memory0;
reg [31:0]memory1;
reg [31:0]memory2;
reg [31:0]memory3;
reg [31:0]memory4;
reg [31:0]memory5;
reg [31:0]memory6;
reg [31:0]memory7;
reg [31:0]memory8;
reg [31:0]memory9;
reg [31:0]memory10;
output reg signed [31:0]Alu_result;





always @(posedge clk)
begin
    instruction_Mem<=instruction_Alu;
    if(rst)
				begin
					Read_data_mem<=32'b0;
					memory0<=32'd0;
					memory1<=32'd2;
					memory2<=32'd2;
					memory3<=32'd2;
					memory4<=32'd2;
					memory5<=32'd2;
					memory6<=32'd2;
					memory7<=32'd2;
					memory8<=32'd2;
					memory9<=32'd2;
					memory10<=32'd2;
				end
	else if(instruction_Alu[31:26]==6'd43)
	begin
				case(Alu_result)
				32'd0:memory0<=Write_data_mem;
				32'd1:memory1<=Write_data_mem;
				32'd2:memory2<=Write_data_mem;
				32'd3:memory3<=Write_data_mem;
				32'd4:memory4<=Write_data_mem;
				32'd5:memory5<=Write_data_mem;
				32'd6:memory6<=Write_data_mem;
				32'd7:memory7<=Write_data_mem;
				32'd8:memory8<=Write_data_mem;
				32'd9:memory9<=Write_data_mem;
				32'd10:memory10<=Write_data_mem;
				endcase
	end
	else if(instruction_Alu[31:26]==6'd35)
	begin
				case(Alu_result)
				32'd0:Read_data_mem<=memory0;
				32'd1:Read_data_mem<=memory1;
				32'd2:Read_data_mem<=memory2;
				32'd3:Read_data_mem<=memory3;
				32'd4:Read_data_mem<=memory4;
				32'd5:Read_data_mem<=memory5;
				32'd6:Read_data_mem<=memory6;
				32'd7:Read_data_mem<=memory7;
				32'd8:Read_data_mem<=memory8;
				32'd9:Read_data_mem<=memory9;
				32'd10:Read_data_mem<=memory10;
				endcase
	end
	 else 
	    Read_data_mem<=Alu_result;
end


endmodule
