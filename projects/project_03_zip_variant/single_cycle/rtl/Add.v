`timescale 1ns / 1ps

module Add(OUT, IN0, IN1) ;

	output [31:0]OUT ;
	input [31:0]IN0, IN1 ; 

	assign OUT = IN0 + IN1 ;

endmodule