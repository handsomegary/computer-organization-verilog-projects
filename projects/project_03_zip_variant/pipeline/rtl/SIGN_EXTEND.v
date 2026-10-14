`timescale 1ns / 1ps

module Sign_Extend(OUT_32BITS, IN_16BITS) ;

	output reg [31:0]OUT_32BITS ;
	input [15:0]IN_16BITS ;

	always @(IN_16BITS) begin
		if ( IN_16BITS[15] == 1'b0 ) 
			OUT_32BITS = { { 16{1'b0} } ,IN_16BITS} ;
		else 
			OUT_32BITS = { { 16{1'b1} } ,IN_16BITS} ;
	end

endmodule