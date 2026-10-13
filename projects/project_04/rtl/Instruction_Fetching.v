`timescale 1ns / 1ps
module IF(pc,PC,clk,rst,ins,branch,jump,PC_CLK);

input branch;
input [31:0]pc;
input jump;
input rst,clk;
input PC_CLK;

output reg [31:0]ins;
output reg [31:0]PC;

always@(posedge clk or posedge rst)
    begin
	    if(rst) 
	        begin
		        PC[31:0]<=pc[31:0];
		    end
	    else
			begin 
			    if(jump)
					PC[31:0]<=32'd104;
			    else if(branch)
					PC[31:0]<=32'd16;
				else
					PC[31:0]<=PC[31:0]+32'd4;		
		    end
	end
	
always @(PC)
    begin
		case(PC)
            32'd0:ins<=32'd0;
            32'd4:ins=32'b00000000001000110001000000100010;
            32'd8:ins=32'b00000000010001010100100000100100;
            32'd12:ins=32'b00000000100000100100000000100101;
            32'd16:ins=32'b00000000010000100011100000100000;
            32'd20:ins=32'b10101100010001100000000000000000;
            default ins=ins;
		endcase
    end
	
endmodule