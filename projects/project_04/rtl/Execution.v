`timescale 1ns / 1ps
module EX(Read_data1,Read_data2,ins_reg,result,ins_Alu,Write_data_mem,
		  clk,sign_extend,rst,PC,branch,jump);

input [31:0]PC;
input signed [31:0]Read_data1,Read_data2;
input [31:0]ins_reg;
input clk,rst;
input [31:0]sign_extend;

output reg signed [31:0]result;
output reg [31:0]ins_Alu;
output reg signed [31:0]Write_data_mem;
output reg branch,jump;

reg [31:0] RESULT;


always@(ins_reg)
    begin
        if((ins_reg[15:11]==5'b00010))
            RESULT=result;
        else 
            RESULT=RESULT;
    end

always @(posedge clk or posedge rst)
    begin
        if(rst) 
            begin
                Write_data_mem<=32'd0;
                ins_Alu<=32'd0;
                result<=32'b0;
                branch<=0;
                jump<=0;
            end
        else 
            begin
                Write_data_mem<=Read_data2;
                ins_Alu<=ins_reg;
                if (ins_reg==32'd0)
                    begin
                        result<=result;
                        branch<=0;
                        jump<=0;
                    end                
                
                else if((ins_reg[31:26]==6'd0)&&
                        (ins_reg[5:0]==6'b100000))
                        begin
                            if((Read_data1==5'b00010)||(Read_data2==5'b00010))
                                begin
                                    if((Read_data1==5'b00010)&&(Read_data2!=5'b00010))
                                        begin
                                            result<=RESULT+Read_data2;
                                            branch<=0;
                                            jump<=0;
                                        end
                            else if((Read_data1!=5'b00010)&&(Read_data2==5'b00010))
                                    begin
                                        result<=RESULT+Read_data1;
                                        branch<=0;
                                        jump<=0;
                                    end
                            else
                                    begin
                                        result<=RESULT+RESULT;
                                        branch<=0;
                                        jump<=0;
                                    end
                            end
                        else
                            begin
                                result<=Read_data1+Read_data2;
                                branch<=0;
                                jump<=0;
                            end
                        end
                else if((ins_reg[31:26]==6'd0)&&
                        (ins_reg[5:0]==6'b100010))
                        begin
                            if((Read_data1==5'b00010)||(Read_data2==5'b00010))
                                begin
                                    if((Read_data1==5'b00010)&&(Read_data2!=5'b00010))
                                        begin
                                            result<=RESULT-Read_data2;
                                            branch<=0;
                                            jump<=0;
                                        end
                                    else if((Read_data1!=5'b00010)&&(Read_data2==5'b00010))
                                        begin
                                            result<=Read_data1-RESULT;
                                            branch<=0;
                                            jump<=0;
                                        end
                                    else
                                        begin
                                            result<=RESULT-RESULT;
                                            branch<=0;
                                            jump<=0;
                                        end
                                end
                        else
                            begin
                                result<=Read_data1-Read_data2;
                                branch<=0;
                                jump<=0;
                            end
                        end
                else if((ins_reg[31:26]==6'd0)&&
                        (ins_reg[5:0]==6'b100100))
                        begin
                            if((Read_data1==5'b00010)||(Read_data2==5'b00010))
                                begin
                                    if((Read_data1==5'b00010)&&(Read_data2!=5'b00010))
                                        begin
                                            result<=RESULT&Read_data2;
                                            branch<=0;
                                            jump<=0;
                                        end
                                    else if((Read_data1!=5'b00010)&&(Read_data2==5'b00010))
                                        begin
                                            result<=Read_data1&RESULT;
                                            branch<=0;
                                            jump<=0;
                                        end
                                    else
                                        begin
                                            result<=RESULT&RESULT;
                                            branch<=0;
                                            jump<=0;
                                        end
                                end
                        else
                            begin
                                result<=Read_data1&Read_data2;
                                branch<=0;
                                jump<=0;
                            end
                        end
                else if((ins_reg[31:26]==6'd0)&&
                        (ins_reg[5:0]==6'b100101))
                        begin
                            if((Read_data1==5'b00010)||(Read_data2==5'b00010))
                                begin
                                    if((Read_data1==5'b00010)&&(Read_data2!=5'b00010))
                                        begin
                                            result<=RESULT|Read_data2;
                                            branch<=0;
                                            jump<=0;
                                        end
                                    else if((Read_data1!=5'b00010)&&(Read_data2==5'b00010))
                                        begin
                                            result<=Read_data1|RESULT;
                                            branch<=0;
                                            jump<=0;
                                        end
                                    else
                                        begin
                                            result<=RESULT|RESULT;
                                            branch<=0;
                                            jump<=0;
                                        end
                                end
                        else
                            begin
                                result<=Read_data1|Read_data2;
                                branch<=0;
                                jump<=0;
                            end
                        end
                else if((ins_reg[31:26]==6'd0)&&
                        (ins_reg[5:0]==6'b101010))
                        begin
                            branch<=0;
                            jump<=0;
                            
                            if(Read_data1<Read_data2)
                                result<=32'd1;
                            else
                                result<=32'd0; 
                        end
                
                
                else if((ins_reg[31:26]==6'd43)||
                        (ins_reg[31:26]==6'd35)||
                        (ins_reg[31:26]==6'd8))
                        begin
                            if(Read_data1==5'b00010)
                                begin
                                    result<=RESULT+sign_extend;
                                    branch<=0;
                                    jump<=0;
                                end
                        else
                            begin
                                result<=Read_data1+sign_extend;
                                branch<=0;
                                jump<=0;
                            end
                        end
                
              else if(ins_reg[31:26]==6'd4)
                     begin
                        if (Read_data1==Read_data2)
                            begin branch<=1;jump<=0; end
                        else
                            begin branch<=0;jump<=0; end
                     end
                else if(ins_reg[31:26]==6'd2)
                       begin
                           jump<=1;
                           branch<=0;
                       end
             end	 
    end

endmodule