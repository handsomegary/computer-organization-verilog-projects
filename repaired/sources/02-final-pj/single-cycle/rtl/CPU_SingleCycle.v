`timescale 1ns / 1ps

module CPU_SingleCycle (PC_NEXT, CLK, RST, READ_DATA_2, Signextend_out, ALU_Input0, ALU_Input1, ALU_result, DataMem_out, WRITE_DATA) ;
	output [31:0]PC_NEXT, READ_DATA_2, Signextend_out, ALU_Input0, ALU_Input1, ALU_result, DataMem_out, WRITE_DATA ;
	input CLK, RST ;
	wire [31:0]PC_OUT, PC_IN, INSTRUCTION,PC_4, SFL32_Output, PC_Branch, branch_result ;  // 32bits
	wire [27:0]SFL28_Output ;
	wire [4:0]WRITE_ADDR ; // 5bits
	wire [3:0]ALU_Ctrl ; // 4bits
	wire [1:0]ALUOP ; // 2bits
	wire REGDST, ALUSRC, MEMTOREG, REGWRITE, MEMREAD, MEMWRITE, BRANCH, JUMP, ZERO, branch_select ;  // 1bits


	// Unsupported R-type function codes have no register side effects.
    wire VALID_REGWRITE;
    assign VALID_REGWRITE = REGWRITE && ((ALUOP != 2'b10) || (ALU_Ctrl != 4'b1111));

    PC Program_Counter(.PC_OUT(PC_NEXT), .PC_IN(PC_IN), .CLK(CLK), .RST(RST));

	InstructionMemory IM(.INSTRUCTION(INSTRUCTION), .ADDR(PC_NEXT), .RST(RST)) ;
	Controller CTLER( .REGDST(REGDST), .ALUSRC(ALUSRC), .MEMTOREG(MEMTOREG), .REGWRITE(REGWRITE),
					.MEMREAD(MEMREAD), .MEMWRITE(MEMWRITE), .BRANCH(BRANCH), .JUMP(JUMP), .ALUOP(ALUOP), .OPCODE(INSTRUCTION[31:26]) ) ;
	Mux_5Bits Mux5_1(.OUT(WRITE_ADDR), .IN0(INSTRUCTION[20:16]), .IN1(INSTRUCTION[15:11]), .SEL(REGDST)) ;

	Register_file RF(.READ_DATA_1(ALU_Input0), .READ_DATA_2(READ_DATA_2), .READ_ADDR_1(INSTRUCTION[25:21]), .READ_ADDR_2(INSTRUCTION[20:16]),
		.WRITE_ADDR(WRITE_ADDR), .WRITE_DATA(WRITE_DATA), .REGWRITE(VALID_REGWRITE), .CLK(CLK),.RST(RST) );   //   1

	Sign_Extend  SE(.OUT_32BITS(Signextend_out) , .IN_16BITS(INSTRUCTION[15:0] ) ) ;

	Mux_32Bits Mux32_1(.OUT(ALU_Input1), .IN0(READ_DATA_2), .IN1(Signextend_out), .SEL(ALUSRC) ) ;
	ALU_Controller ALUCTLER( .ALU_CONTROL(ALU_Ctrl), .ALU_OP(ALUOP), .FUNCTION_FIELD(INSTRUCTION[5:0]) ) ;
	ALU ALU_1(.OUT(ALU_result), .ZERO(ZERO), .IN0(ALU_Input0), .IN1(ALU_Input1), .ALU_CONTROL(ALU_Ctrl) ) ;

	DataMemory DM( .READ_DATA(DataMem_out), .ADDR(ALU_result), .WRITE_DATA(READ_DATA_2),
					.MEM_WRITE(MEMWRITE), .MEM_READ(MEMREAD), .RST(RST), .CLK(CLK) );

	Mux_32Bits Mux32_2(.OUT(WRITE_DATA), .IN0(ALU_result), .IN1(DataMem_out), .SEL(MEMTOREG) ) ;

	wire [31:0]constant  ;
	assign constant = 32'd4 ;

	Add Add_1(.OUT(PC_4), .IN0(PC_NEXT), .IN1(constant) ) ;
	Shift_Left_2_32BitsTo32Bits SFL32_1( .Out(SFL32_Output), .In(Signextend_out) ) ;
	Add Add_2(.OUT(PC_Branch), .IN0(PC_4), .IN1(SFL32_Output) ) ;

	and and1(branch_select, BRANCH, ZERO) ;
	Mux_32Bits Mux32_3(.OUT(branch_result), .IN0(PC_4), .IN1(PC_Branch), .SEL(branch_select) ) ;


	Shift_Left_2_26BitsTo28Bits SFL28_1( .Out(SFL28_Output), .In(INSTRUCTION[25:0] ) ) ;
	Mux_32Bits Mux32_4(.OUT(PC_IN), .IN0(branch_result), .IN1( {PC_4[31:28], SFL28_Output} ), .SEL(JUMP) ) ;

endmodule
