`timescale 1ns / 1ps
module WB(ins_Mem,Read_data_mem,
          reg0,reg1,reg2,reg3,reg4,reg5,reg6,
          reg7,reg8,reg9,reg10,reg11,reg12,reg13,
          clk,rst,zero,memory10);

input [31:0]memory10;
input [31:0] ins_Mem,Read_data_mem;
input clk,rst;
output reg signed[31:0]reg0,reg1,reg2,reg3,reg4,
                       reg5,reg6,reg7,reg8,reg9,
                       reg10,reg11,zero,reg12,reg13;

always @(posedge clk or posedge rst)
    begin
        if (rst)
	        begin
                reg0<=32'd0;
                reg1<=32'd3;
                reg2<=32'd2;
                reg3<=32'd3;
                reg4<=32'd4;
                reg5<=32'd5;
                reg6<=32'd5;
                reg7<=32'd4;
                reg8<=32'd3;
                reg9<=32'd2;
                reg10<=32'd1;
                reg11<=32'd0;
                reg12<=32'd0;
                reg13<=32'd0;
                zero<=32'd0;
	        end
        else 
        begin
 
            if((ins_Mem[31:26]==6'd35)
                ||(ins_Mem[31:26]==6'd8))
	           begin
	               case(ins_Mem[20:16])
                       5'b01100:begin reg0<=Read_data_mem; end
                       5'b00001:begin reg1<=Read_data_mem; end
                       5'b00010:begin reg2<=Read_data_mem; end
                       5'b00011:begin reg3<=Read_data_mem; end
                       5'b00100:begin reg4<=Read_data_mem; end
                       5'b00101:begin reg5<=Read_data_mem; end
                       5'b00110:begin reg6<=Read_data_mem; end
                       5'b00111:begin reg7<=Read_data_mem; end
                       5'b01000:begin reg8<=Read_data_mem; end
                       5'b01001:begin reg9<=Read_data_mem; end
                       5'b01010:begin reg10<=Read_data_mem; end
                       5'b01011:begin reg11<=Read_data_mem; end
                       5'b11100:begin reg12<=Read_data_mem; end
                       5'b11110:begin reg13<=Read_data_mem; end
		           endcase
	           end
	       else if(ins_Mem[31:26]==6'd0)
	           begin
	               case(ins_Mem[15:11])
                       5'b01100:begin reg0<=Read_data_mem; end
                       5'b00001:begin reg1<=Read_data_mem; end
                       5'b00010:begin reg2<=Read_data_mem; end
                       5'b00011:begin reg3<=Read_data_mem; end
                       5'b00100:begin reg4<=Read_data_mem; end
                       5'b00101:begin reg5<=Read_data_mem; end
                       5'b00110:begin reg6<=Read_data_mem; end
                       5'b00111:begin reg7<=Read_data_mem; end
                       5'b01000:begin reg8<=Read_data_mem; end
                       5'b01001:begin reg9<=Read_data_mem; end
                       5'b01010:begin reg10<=Read_data_mem; end
                       5'b01011:begin reg11<=Read_data_mem; end
                       5'b11100:begin reg12<=Read_data_mem; end
                       5'b11110:begin reg13<=Read_data_mem; end
		           endcase
	           end
        end
    end

endmodule