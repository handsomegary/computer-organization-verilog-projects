`timescale 1ns / 1ps

module CPU_NoHazard_tb;

	
	reg CLK;
	reg RST;
	
	wire [31:0]PC_NEXT,READ_DATA_1,READ_DATA_2,READ_DATA_1_ID_EX, READ_DATA_2_ID_EX, ALU_Input0, ALU_Input1,ALU_RESULT_EX_MEM,ALU_result_MEM_WB, WRITE_DATA;
	wire [1:0] FORWARDA, FORWARDB;
	wire [4:0]WRITE_ADDR, WRITE_ADDR_EX_MEM,Write_Addr_Mem_WB ;


	
	CPU_NoHazard uut (
		.PC_NEXT(PC_NEXT), 
		.READ_DATA_1(READ_DATA_1),
		.READ_DATA_2(READ_DATA_2),
		.READ_DATA_1_ID_EX(READ_DATA_1_ID_EX),
		.READ_DATA_2_ID_EX(READ_DATA_2_ID_EX),
		.ALU_Input0(ALU_Input0),
		.ALU_Input1(ALU_Input1),
		.ALU_RESULT_EX_MEM(ALU_RESULT_EX_MEM),
		.ALU_result_MEM_WB(ALU_result_MEM_WB),
		.WRITE_DATA(WRITE_DATA),
		.FORWARDA(FORWARDA),
		.FORWARDB(FORWARDB),
		.WRITE_ADDR(WRITE_ADDR),
		.WRITE_ADDR_EX_MEM(WRITE_ADDR_EX_MEM),
		.Write_Addr_Mem_WB(Write_Addr_Mem_WB),
		.CLK(CLK), 
		.RST(RST)
	);

	initial begin
		CLK = 1'b0 ;
		forever #10 CLK = ~CLK ;
	end 

	initial begin
		
		RST = 1'b0;

		
		#100;
        
		
		RST = 1'b1;
		#15 RST = 1'b0 ;
		
	end
      
endmodule

