`timescale 1ns / 1ps

module ForwardingUnit(FORWARDA, FORWARDB, RS_in , RT_in, RD_EX_MEM, RD_MEM_WB, REGWRITE_EX_MEM, REGWRITE_MEM_WB);

	output reg [1:0] FORWARDA, FORWARDB;

	input [4:0] RS_in , RT_in, RD_EX_MEM, RD_MEM_WB; 
	input REGWRITE_EX_MEM, REGWRITE_MEM_WB;


	always@(*)
	begin

		FORWARDA=2'b00;
		FORWARDB=2'b00;

		
		if(REGWRITE_EX_MEM && (RD_EX_MEM!=0) && (RD_EX_MEM==RS_in))
			FORWARDA=2'b10;
		if(REGWRITE_EX_MEM && (RD_EX_MEM!=0) && (RD_EX_MEM==RT_in))
			FORWARDB=2'b10;

		
		if ( REGWRITE_MEM_WB && (RD_MEM_WB!=0) && (RD_MEM_WB==RS_in) && ( ~(  (REGWRITE_EX_MEM) && (RD_EX_MEM!=0) && (RD_EX_MEM == RS_in) ) ) )
			FORWARDA=2'b01;
		if ( REGWRITE_MEM_WB && (RD_MEM_WB!=0) && (RD_MEM_WB==RT_in) && ( ~(  (REGWRITE_EX_MEM) && (RD_EX_MEM!=0) && (RD_EX_MEM == RT_in) ) ) )
			FORWARDB=2'b01;

	end

endmodule
