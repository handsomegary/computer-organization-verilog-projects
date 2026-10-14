`timescale 1ns / 1ps

module Shift_Left_2_26BitsTo28Bits ( Out,In ) ;
	
	output [27:0]Out ;
	input [25:0]In ;

	assign Out =  { In[25:0], 2'b00 } ;

endmodule
