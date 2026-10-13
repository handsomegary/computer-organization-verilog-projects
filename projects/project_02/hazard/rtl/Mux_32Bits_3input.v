`timescale 1ns / 1ps

module Mux_32Bits_3input(OUT, IN0, IN1, IN2, SEL) ; 

	output reg [31:0]OUT ;
	input [31:0]IN0, IN1 ,IN2;
	input [1:0]SEL;

	always@(*)begin
		if (SEL == 2'b00)
			OUT = IN0;
		else if (SEL == 2'b01)
			OUT = IN1;
		else if (SEL == 2'b10)
			OUT = IN2;
		else   
			OUT = IN0;
	end
endmodule
