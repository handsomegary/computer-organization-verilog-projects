`timescale 1ns / 1ps

module Mux_5Bits(OUT, IN0, IN1, SEL) ; 

	output [4:0]OUT ;
	input [4:0]IN0, IN1 ;
	input SEL ;

	assign OUT = (SEL) ? IN1 : IN0 ;

endmodule
