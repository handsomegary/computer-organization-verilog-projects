`timescale 1ns / 1ps
module ID(clk,ins,ins_reg,
          Read_data_mem,Read_data1,Read_data2,sign_extend,
          reg0,reg1,reg2,reg3,reg4,reg5,reg6,
          reg7,reg8,reg9,reg10,reg11,reg12,reg13,rst,zero
          );
 
input clk,rst;
input [31:0]ins;
input signed[31:0]Read_data_mem;
input signed[31:0]reg0,reg1,reg2,reg3,reg4,
                  reg5,reg6,reg7,reg8,reg9,reg10,
                  reg11,reg12,reg13,zero;

output reg [31:0]ins_reg;
output reg [31:0]sign_extend;
output reg signed[31:0]Read_data1;
output reg signed[31:0]Read_data2;


always @(posedge clk or posedge rst)
    begin
        if(rst) begin 
	       ins_reg<=32'd0;
		   Read_data1<=32'd0;
		   Read_data2<=32'd0;
		   sign_extend<=32'd0;
		end
	else
	   begin
	       ins_reg<=ins;
	       if(ins==32'd0)
               begin
                   Read_data1<=Read_data1;
                   Read_data2<=Read_data2;			
               end
	       else if(ins[31:26]==6'd0)
		       begin 
			       case(ins[25:21])
                       5'b01100:begin Read_data1<=reg0;end
                       5'b00001:begin Read_data1<=reg1;end
                       5'b00010:begin Read_data1<=reg2;end
                       5'b00011:begin Read_data1<=reg3;end
                       5'b00100:begin Read_data1<=reg4;end
                       5'b00101:begin Read_data1<=reg5;end
                       5'b00110:begin Read_data1<=reg6;end
                       5'b00111:begin Read_data1<=reg7;end
                       5'b01000:begin Read_data1<=reg8;end
                       5'b01001:begin Read_data1<=reg9;end
                       5'b01010:begin Read_data1<=reg10;end
                       5'b01011:begin Read_data1<=reg11;end
                       5'b11100:begin Read_data1<=reg12;end
                       5'b11110:begin Read_data1<=reg13;end
                       5'b11111:begin Read_data1<=zero;end
			       endcase
			       case(ins[20:16])
                       5'b01100:begin Read_data2<=reg0;end
                       5'b00001:begin Read_data2<=reg1;end
                       5'b00010:begin Read_data2<=reg2;end
                       5'b00011:begin Read_data2<=reg3;end
                       5'b00100:begin Read_data2<=reg4;end
                       5'b00101:begin Read_data2<=reg5;end
                       5'b00110:begin Read_data2<=reg6;end
                       5'b00111:begin Read_data2<=reg7;end
                       5'b01000:begin Read_data2<=reg8;end
                       5'b01001:begin Read_data2<=reg9;end
                       5'b01010:begin Read_data2<=reg10;end
                       5'b01011:begin Read_data2<=reg11;end
                       5'b11100:begin Read_data2<=reg12;end
                       5'b11110:begin Read_data2<=reg13;end
                       5'b11111:begin Read_data2<=zero;end
			     endcase
		end
	else if(ins[31:26]==6'd35    
		    ||ins[31:26]==6'd43 
			||ins[31:26]==6'd4  
			||ins[31:26]==6'd8 ) 
			begin				
				if(ins[31:26]==6'd4)
					begin
                        sign_extend[31:18]<={14{ins[15]}};
                        sign_extend[17:2]<=ins[15:0]; 
                        sign_extend[1:0]<=2'b00;
					end
				else 
					begin
                        sign_extend[31:16]<={16{ins[15]}};
                        sign_extend[15:0]<=ins[15:0];
					end 
				case(ins[25:21])
                    5'b01100:begin Read_data1<=reg0;end
                    5'b00001:begin Read_data1<=reg1;end
                    5'b00010:begin Read_data1<=reg2;end
                    5'b00011:begin Read_data1<=reg3;end
                    5'b00100:begin Read_data1<=reg4;end
                    5'b00101:begin Read_data1<=reg5;end
                    5'b00110:begin Read_data1<=reg6;end
                    5'b00111:begin Read_data1<=reg7;end
                    5'b01000:begin Read_data1<=reg8;end
                    5'b01001:begin Read_data1<=reg9;end
                    5'b01010:begin Read_data1<=reg10;end
                    5'b01011:begin Read_data1<=reg11;end
                    5'b11100:begin Read_data1<=reg12;end
                    5'b11110:begin Read_data1<=reg13;end
                    5'b11111:begin Read_data1<=zero;end
               endcase
               case(ins[20:16])
                   5'b01100:begin Read_data2<=reg0;end
                   5'b00001:begin Read_data2<=reg1;end
                   5'b00010:begin Read_data2<=reg2;end
                   5'b00011:begin Read_data2<=reg3;end
                   5'b00100:begin Read_data2<=reg4;end
                   5'b00101:begin Read_data2<=reg5;end
                   5'b00110:begin Read_data2<=reg6;end
                   5'b00111:begin Read_data2<=reg7;end
                   5'b01000:begin Read_data2<=reg8;end
                   5'b01001:begin Read_data2<=reg9;end
                   5'b01010:begin Read_data2<=reg10;end
                   5'b01011:begin Read_data2<=reg11;end
                   5'b11100:begin Read_data2<=reg12;end
                   5'b11110:begin Read_data2<=reg13;end
                   5'b11111:begin Read_data2<=zero;end
               endcase
			end
	else if(ins[31:26]==6'd35)    
	      sign_extend<={4'b0000,ins[25:0],2'b00};
    end
end

endmodule