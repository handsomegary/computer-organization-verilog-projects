`timescale 1ns / 1ps

module Mux_32Bits(OUT, IN0, IN1, SEL) ; 

	output [31:0]OUT ;
	input [31:0]IN0, IN1 ;
	input SEL;

	assign OUT = (SEL) ? IN1 : IN0 ;

endmodule
