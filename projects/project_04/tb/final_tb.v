`timescale 1ns / 1ps
module ha_tb();

	
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
	wire [31:0] nop1;
	wire [31:0] nop2;
    wire [31:0] NEWPC,ins_MEM,ins_ALU,ins_REG,Ins,Write_Data_Mem,Read_Data_Mem,
	            Alu_Result,Sign_extend,Read_Data1,Read_Data2,Memory10;
	wire PC_CLK,Branch,Jump;
	
	
	ha uut(
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
		.nop1(nop1),
		.nop2(nop2),
		.NEWPC(NEWPC),
		.ins_MEM(ins_MEM),
		.ins_ALU(ins_ALU),
		.ins_REG(ins_REG),
		.Ins(Ins),
		.Write_Data_Mem(Write_Data_Mem),
	    .Read_Data_Mem(Read_Data_Mem),
	    .Alu_Result(Alu_Result),
	    .Sign_extend(Sign_extend),
		.Read_Data1(Read_Data1),
		.Read_Data2(Read_Data2),
		.Memory10(Memory10),
		.Branch(Branch),
		.Jump(Jump)
	    );
	    
    always
        #50 clk=~clk;	
        
	initial begin
		
		pc = 0;
		clk = 0;
		rst = 0;

		
		#20 rst=1;
		#10 rst=0;
        
		

	end
endmodule