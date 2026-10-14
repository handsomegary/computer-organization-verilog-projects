`timescale 1ns / 1ps

module CPU_Pipeline_tb;

	// Inputs
	reg CLK;
	reg RST;

	// Outputs
	wire [31:0] PC_NEXT,PC_4, PC_4_IFID_out,PC_4_IDEX_out,ReadData_1_out, ReadData_2_out,Signextend_out,SE_Reg_Out,ALU_result,WRITE_DATA;
    wire [4:0]Write_Addr_Mem_WB;
	// Instantiate the Unit Under Test (UUT)
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
		// Initialize Inputs
		RST = 1'b0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		RST = 1'b1;
		#15 RST = 1'b0 ;

		#300 $finish ;
		
	end
      
endmodule

