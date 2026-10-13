`timescale 1ns / 1ps



















module WB(instruction_Mem,Read_data_mem,Alu_result,
register0,register1,register2,register3,register4,register5,register6,
register7,register8,register9,register10,register11,clk);

input [31:0] instruction_Mem,Read_data_mem,Alu_result;
input clk;
output reg [31:0]register0,register1,register2,register3,register4,register5,register6,register7,register8,register9,register10,register11;

always @(posedge clk)
begin
    if((instruction_Mem[31:26]==6'd35)
			||(instruction_Mem[31:26]==6'd8))
	begin
	   case(instruction_Mem[20:16])
		5'b00000:begin register0<=Read_data_mem; end
		5'b00001:begin register1<=Read_data_mem; end
		5'b00010:begin register2<=Read_data_mem; end
		5'b00011:begin register3<=Read_data_mem; end
		5'b00100:begin register4<=Read_data_mem; end
		5'b00101:begin register5<=Read_data_mem; end
		5'b00110:begin register6<=Read_data_mem; end
		5'b00111:begin register7<=Read_data_mem; end
		5'b01000:begin register8<=Read_data_mem; end
		5'b01001:begin register9<=Read_data_mem; end
		5'b01010:begin register10<=Read_data_mem; end
		5'b01011:begin register11<=Read_data_mem; end
		endcase
	end
	else if(instruction_Mem[31:26]==6'd0)
	begin
	   case(instruction_Mem[15:11])
		5'b00000:begin register0<=Alu_result; end
		5'b00001:begin register1<=Alu_result; end
		5'b00010:begin register2<=Alu_result; end
		5'b00011:begin register3<=Alu_result; end
		5'b00100:begin register4<=Alu_result; end
		5'b00101:begin register5<=Alu_result; end
		5'b00110:begin register6<=Alu_result; end
		5'b00111:begin register7<=Alu_result; end
		5'b01000:begin register8<=Alu_result; end
		5'b01001:begin register9<=Alu_result; end
		5'b01010:begin register10<=Alu_result; end
		5'b01011:begin register11<=Alu_result; end
		endcase
	end
end


endmodule
