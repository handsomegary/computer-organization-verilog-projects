`timescale 1ns / 1ps

module CPU_Pipeline_tb;

	
	reg CLK;
	reg RST;

	
	wire [31:0] PC_NEXT,PC_4, PC_4_IFID_out,PC_4_IDEX_out,ReadData_1_out, ReadData_2_out,Signextend_out,SE_Reg_Out,ALU_result,WRITE_DATA;
    wire [4:0]Write_Addr_Mem_WB;
	
	CPU_Pipeline uut (
		.PC_NEXT(PC_NEXT), 
		.PC_4(PC_4),
		.PC_4_IFID_out(PC_4_IFID_out),
		.Signextend_out(Signextend_out),
		.ALU_result(ALU_result),
		.WRITE_DATA(WRITE_DATA),
		.CLK(CLK), 
		.RST(RST),
		.PC_4_IDEX_out(PC_4_IDEX_out),
		.READ_DATA_1_ID_EX(ReadData_1_out),
		.READ_DATA_2_ID_EX(ReadData_2_out),
		.Signextend_Reg(SE_Reg_Out),
		.Write_Addr_Mem_WB(Write_Addr_Mem_WB)
	);

	initial begin
		CLK = 1'b0 ;
		forever #2 CLK = ~CLK ;
	end 

	initial begin
		
		RST = 1'b0;

		
		#100;
        
		
		RST = 1'b1;
		#15 RST = 1'b0 ;

		#300 $finish ;
		
	end
      
endmodule

