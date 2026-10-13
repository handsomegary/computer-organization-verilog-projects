`timescale 1ns / 1ps
module MEM(Read_data_mem,ins_Alu,Alu_result,clk,Write_data_mem,rst,ins_Mem,memory10 );

input [31:0]ins_Alu;
input clk,rst;
input signed [31:0]Write_data_mem;
input signed[31:0]Alu_result;
output reg signed [31:0]Read_data_mem;
output reg [31:0]ins_Mem;
output reg [31:0]memory10;

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



always @(posedge clk or posedge rst)
begin
    if(rst)
	    begin
			Read_data_mem<=32'b0;
			ins_Mem<=32'b0;
			memory0<=32'd2;
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
	else
        begin
            ins_Mem<=ins_Alu;
        
            if(ins_Alu[31:26]==6'd43)
                begin
                    case(Alu_result)
                        32'd40:memory0<=Write_data_mem;
                        32'd36:memory1<=Write_data_mem;
                        32'd32:memory2<=Write_data_mem;
                        32'd28:memory3<=Write_data_mem;
                        32'd24:memory4<=Write_data_mem;
                        32'd20:memory5<=Write_data_mem;
                        32'd16:memory6<=Write_data_mem;
                        32'd12:memory7<=Write_data_mem;
                        32'd8:memory8<=Write_data_mem;
                        32'd4:memory9<=Write_data_mem;
                        32'd0:memory10<=Write_data_mem;
                    endcase
	           end
	       else if(ins_Alu[31:26]==6'd35)
	           begin
			       case(Alu_result)
                       32'd40:Read_data_mem<=memory0;
                       32'd36:Read_data_mem<=memory1;
                       32'd32:Read_data_mem<=memory2;
                       32'd28:Read_data_mem<=memory3;
                       32'd24:Read_data_mem<=memory4;
                       32'd20:Read_data_mem<=memory5;
                       32'd16:Read_data_mem<=memory6;
                       32'd12:Read_data_mem<=memory7;
                       32'd8:Read_data_mem<=memory8; 
                       32'd4:Read_data_mem<=memory9;
                       32'd0:Read_data_mem<=memory10;
			       endcase
	           end
	       else 
	           Read_data_mem<=Alu_result;
     end
end


endmodule