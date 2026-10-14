`timescale 1ns / 1ps

module Shift_Left_2_32BitsTo32Bits ( Out,In ) ;
	
	output [31:0]Out ;
	input [31:0]In ;

	assign Out = { In[29:0], 2'b00 } ;

endmodule