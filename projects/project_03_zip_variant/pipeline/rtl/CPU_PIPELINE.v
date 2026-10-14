`timescale 1ns / 1ps

module CPU_Pipeline (PC_NEXT, CLK, RST,PC_4_IDEX_out, READ_DATA_1_ID_EX, READ_DATA_2_ID_EX, Signextend_Reg,PC_4, PC_4_IFID_out,Signextend_out,ALU_result,WRITE_DATA,Write_Addr_Mem_WB) ;
	input CLK, RST ;
	output [31:0]PC_NEXT ;
	output [31:0] PC_4, PC_4_IFID_out,Signextend_out,ALU_result,WRITE_DATA;
	output [31:0]PC_4_IDEX_out, READ_DATA_1_ID_EX, READ_DATA_2_ID_EX, Signextend_Reg;
	output [4:0]Write_Addr_Mem_WB ;
	wire [31:0]PC_IN, INSTRUCTION, ReadData_1_out, ReadData_2_out,  ALU_IN1, ALU_RESULT_EX_MEM, DataMemory_Output, 
		 SFL32_Output, PC_Branch, branch_result ;  // 32bits
	wire [27:0]SFL28_Output ;
	wire [4:0]WRITE_ADDR ; // 5bits
	wire [3:0]ALU_CONTROL ; // 4bits
	wire [1:0]ALUOP ; // 2bits 
	wire REGDST, ALUSRC, MEMTOREG, REGWRITE, MEMREAD, MEMWRITE, BRANCH, ZERO, branch_select ;  // 1bits

//////////////////////////////////////////////////////////////////////////////////////////////////////

	wire [31:0]INSTRUCTION_IF_ID ;

	wire REGWRITE_ID_EX, MEMTOREG_ID_EX, BRANCH_ID_EX, MEMREAD_ID_EX, MEMWRITE_ID_EX, ALUSRC_ID_EX, REGDST_ID_EX ; 
	wire [1:0]ALUOP_ID_EX ;

	wire [4:0]RD_ID_EX, RT_ID_EX ;


	wire REGWRITE_EX_MEM, MEMTOREG_EX_MEM, BRANCH_EX_MEM, MEMREAD_EX_MEM, MEMWRITE_EX_MEM, ZERO_EX_MEM ;
	wire [31:0] ADD_RESULT_EX_MEM,  READ_DATA_2_EX_MEM ;
	wire [4:0] WRITE_ADDR_EX_MEM ;

	wire REGWRITE_MEM_WB, MemToReg_MEM_WB ;
	wire [31:0]DataMemory_Output_MEM_WB, ALU_result_MEM_WB ;


	PC Program_Counter(.PC_OUT(PC_NEXT), .PC_IN(PC_IN), .CLK(CLK), .RST(RST));
	InstructionMemory IM(.INSTRUCTION(INSTRUCTION), .ADDR(PC_NEXT), .RST(RST)) ;

	wire [31:0]constant  ;
	assign constant = 32'd4 ;

	Add Add_1(.OUT(PC_4), .IN0(PC_NEXT), .IN1(constant) ) ;

	
	IF_ID IF_ID_Reg(.PC_4_out(PC_4_IFID_out), .IM_out(INSTRUCTION_IF_ID), .PC_4(PC_4), .IM(INSTRUCTION), .CLK(CLK), .RST(RST));

	Controller CTLER( .REGDST(REGDST), .ALUSRC(ALUSRC), .MEMTOREG(MEMTOREG), .REGWRITE(REGWRITE), 
					.MEMREAD(MEMREAD), .MEMWRITE(MEMWRITE), .BRANCH(BRANCH), .ALUOP(ALUOP), .OPCODE(INSTRUCTION_IF_ID[31:26]) ) ;

	Register_file RF(.READ_DATA_1(ReadData_1_out), .READ_DATA_2(ReadData_2_out), .READ_ADDR_1(INSTRUCTION_IF_ID[25:21]), .READ_ADDR_2(INSTRUCTION_IF_ID[20:16]), 
	.WRITE_ADDR(Write_Addr_Mem_WB), .WRITE_DATA(WRITE_DATA), .REGWRITE(REGWRITE_MEM_WB), .CLK(CLK),.RST(RST) );   

	Sign_Extend  SE(.OUT_32BITS(Signextend_out) , .IN_16BITS(INSTRUCTION_IF_ID[15:0] ) ) ;

	

	ID_EX ID_EX_Reg(.REGWRITE_out(REGWRITE_ID_EX), .MEMTOREG_out(MEMTOREG_ID_EX), .BRANCH_out(BRANCH_ID_EX), .MEMREAD_out(MEMREAD_ID_EX),
	 .MEMWRITE_out(MEMWRITE_ID_EX), .ALUSRC_out(ALUSRC_ID_EX), .REGDST_out(REGDST_ID_EX), .ALUOP_out(ALUOP_ID_EX), 
	 .PC_4_out(PC_4_IDEX_out), .READ_DATA_1_out(READ_DATA_1_ID_EX), .READ_DATA_2_out(READ_DATA_2_ID_EX), .SE_REG_out(Signextend_Reg), .RD_out(RD_ID_EX), .RT_out(RT_ID_EX),
	.REGWRITE(REGWRITE), .MEMTOREG(MEMTOREG), .BRANCH(BRANCH), .MEMREAD(MEMREAD), .MEMWRITE(MEMWRITE), .REGDST(REGDST), .ALUSRC(ALUSRC), .ALUOP(ALUOP), 
	.PC_4(PC_4_IFID_out), .READ_DATA_1(ReadData_1_out), .READ_DATA_2(ReadData_2_out), .SE_REG(Signextend_out), 
	.RD(INSTRUCTION_IF_ID[15:11]), .RT(INSTRUCTION_IF_ID[20:16]), .CLK(CLK), .RST(RST));

	
	Mux_5Bits Mux5_1(.OUT(WRITE_ADDR), .IN0(RT_ID_EX), .IN1(RD_ID_EX), .SEL(REGDST_ID_EX)) ; 
	Mux_32Bits Mux32_1(.OUT(ALU_IN1), .IN0(READ_DATA_2_ID_EX), .IN1(Signextend_Reg), .SEL(ALUSRC_ID_EX) ) ;
	
	ALU_Controller ALUCTLER( .ALU_CONTROL(ALU_CONTROL), .ALU_OP(ALUOP_ID_EX), .FUNCTION_FIELD(Signextend_Reg[5:0]) ) ; 

	ALU ALU_1(.OUT(ALU_RESULT_EX_MEM), .ZERO(ZERO), .IN0(READ_DATA_1_ID_EX), .IN1(ALU_IN1), .ALU_CONTROL(ALU_CONTROL) ) ; 

	Shift_Left_2_32BitsTo32Bits SFL32_1( .Out(SFL32_Output), .In(Signextend_Reg) ) ;

	Add Add_2(.OUT(PC_Branch), .IN0(PC_4_IDEX_out), .IN1(SFL32_Output) ) ;

	
	EX_MEM EX_MEM_Reg(.REGWRITE_out(REGWRITE_EX_MEM), .MEMTOREG_out(MEMTOREG_EX_MEM), .BRANCH_out(BRANCH_EX_MEM), .MEMREAD_out(MEMREAD_EX_MEM), .MEMWRITE_out(MEMWRITE_EX_MEM),
	.ADD_RESULT_out(ADD_RESULT_EX_MEM), .ALU_RESULT_out(ALU_result), .READ_DATA_2_out(READ_DATA_2_EX_MEM), .WRITE_ADDR_out(WRITE_ADDR_EX_MEM), .ZERO_out(ZERO_EX_MEM),
	.CLK(CLK), .RST(RST), .REGWRITE(REGWRITE_ID_EX), .MEMTOREG(MEMTOREG_ID_EX), .BRANCH(BRANCH_ID_EX), .MEMREAD(MEMREAD_ID_EX), .MEMWRITE(MEMWRITE_ID_EX),
	.ADD_RESULT(PC_Branch), .ALU_RESULT(ALU_RESULT_EX_MEM), .READ_DATA_2(READ_DATA_2_ID_EX), .WRITE_ADDR(WRITE_ADDR), .ZERO(ZERO));


	and and1(branch_select, BRANCH_EX_MEM, ZERO_EX_MEM) ;

	DataMemory DM( .READ_DATA(DataMemory_Output), .ADDR(ALU_result), .WRITE_DATA(READ_DATA_2_EX_MEM), 
					.MEM_WRITE(MEMWRITE_EX_MEM), .MEM_READ(MEMREAD_EX_MEM), .RST(RST), .CLK(CLK) );

	MEM_WB MEM_WB_Reg(.WRITE_ADDR_out(Write_Addr_Mem_WB), .ALU_result_out(ALU_result_MEM_WB), .READ_DATA_out(DataMemory_Output_MEM_WB), .WB_RegWrite_out(REGWRITE_MEM_WB), .WB_MemToReg_out(MemToReg_MEM_WB), 
	.WRITE_ADDR(WRITE_ADDR_EX_MEM), .ALU_result(ALU_result), .READ_DATA(DataMemory_Output), .WB_RegWrite(REGWRITE_EX_MEM), .WB_MemToReg(MEMTOREG_EX_MEM), .CLK(CLK), .RST(RST));

	Mux_32Bits Mux32_2(.OUT(WRITE_DATA), .IN0(DataMemory_Output_MEM_WB), .IN1(ALU_result_MEM_WB), .SEL(MemToReg_MEM_WB) ) ; 

	Mux_32Bits Mux32_3(.OUT(PC_IN), .IN0(PC_4), .IN1(ADD_RESULT_EX_MEM), .SEL(branch_select) ) ;

endmodule 
