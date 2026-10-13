`timescale 1ns / 1ps























module CPU_Alternate();

	
	reg [31:0] pc;
	reg clk=0;

	reg rst=0;

	
	wire [31:0] t0;
	wire [31:0] t1;
	wire [31:0] t2;
	wire [31:0] t3;
	wire [31:0] t4;
	wire [31:0] t5;
	wire [31:0] s5;
	wire [31:0] s4;
	wire [31:0] s3;
	wire [31:0] s2;
	wire [31:0] s1;
	wire [31:0] s0;
   wire [31:0] NEWPC,instruction_MEM,instruction_ALU,instruction_REG,Instruction;
	wire PC_CLK;
	
	
	CPU_Top uut (
		.pc(pc), 
		.clk(clk), 
		.PC_CLK(PC_CLK),
		.rst(rst), 
		.t0(t0), 
		.t1(t1), 
		.t2(t2), 
		.t3(t3), 
		.t4(t4), 
		.t5(t5), 
		.s5(s5), 
		.s4(s4), 
		.s3(s3), 
		.s2(s2), 
		.s1(s1), 
		.s0(s0),
		.NEWPC(NEWPC),
		.instruction_MEM(instruction_MEM),
		.instruction_ALU(instruction_ALU),
		.instruction_REG(instruction_REG),
		.Instruction(Instruction)
		);
	

		
	initial begin
		
		pc = 0;
		clk = 0;
		rst = 1;

		
		#130 rst=0;

        
		

	end
always
#50 clk=~clk;	

endmodule

