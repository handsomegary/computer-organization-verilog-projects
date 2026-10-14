`timescale 1ns / 1ps

module Hazard_detection_unit(PCWRITE, IF_ID_WRITE, CTRL_SEL, RS_IF_ID, RT_IF_ID, RT_ID_EX, MEMREAD_ID_EX);

	output reg PCWRITE, IF_ID_WRITE, CTRL_SEL;

	input [4:0] RS_IF_ID, RT_IF_ID, RT_ID_EX;
	input MEMREAD_ID_EX;

	always@(*)begin

		if( MEMREAD_ID_EX && (RT_ID_EX != 5'd0) && ((RT_ID_EX==RS_IF_ID) || (RT_ID_EX==RT_IF_ID)) )
		begin
			PCWRITE=1'b0;
			IF_ID_WRITE=1'b0;
			CTRL_SEL=1'b0;	
		end
		
		else begin
			PCWRITE=1'b1;
			IF_ID_WRITE=1'b1;
			CTRL_SEL=1'b1;
		end

	end

endmodule
