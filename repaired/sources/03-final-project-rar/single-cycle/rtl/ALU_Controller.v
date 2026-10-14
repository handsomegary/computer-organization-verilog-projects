`timescale 1ns / 1ps

module ALU_Controller( ALU_CONTROL, ALU_OP, FUNCTION_FIELD ) ;

	output reg [3:0]ALU_CONTROL ;
	input [1:0] ALU_OP ;
	input [5:0] FUNCTION_FIELD ;

	always @* begin
		if ( ALU_OP == 2'b00 )       // add++
			ALU_CONTROL = 4'b0010 ;
		else if ( ALU_OP == 2'b01 )  // subtract --
			ALU_CONTROL = 4'b0110 ;
		else if ( ALU_OP == 2'b10 && FUNCTION_FIELD == 6'b100000 ) // add
			ALU_CONTROL = 4'b0010 ;
		else if ( ALU_OP == 2'b10 && FUNCTION_FIELD == 6'b100010 ) // subtract
			ALU_CONTROL = 4'b0110 ;
		else if ( ALU_OP == 2'b10 && FUNCTION_FIELD == 6'b100100 ) // AND
			ALU_CONTROL = 4'b0000 ;
		else if ( ALU_OP == 2'b10 && FUNCTION_FIELD == 6'b100101 ) // OR
			ALU_CONTROL = 4'b0001 ;
		else if ( ALU_OP == 2'b10 && FUNCTION_FIELD == 6'b101010 ) // set on less than
			ALU_CONTROL = 4'b0111 ;
		else  // Error !!!
			ALU_CONTROL = 4'b1111 ;
	end

endmodule
