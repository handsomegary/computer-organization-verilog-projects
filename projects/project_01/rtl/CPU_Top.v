`timescale 1ns / 1ps



















module CPU_Top(pc,clk,rst,t0,t1,t2,t3,t4,t5,s5,s4,s3,s2,s1,s0,NEWPC,PC_CLK,
instruction_ALU,instruction_REG,instruction_MEM,Instruction);

input [31:0]pc;
input clk,rst;
output reg PC_CLK;
reg [2:0]CLKcounter;
wire [4:0]Read_Reg1,Read_Reg2;
wire jump;
wire [31:0]newpc;
wire [31:0]instruction;
wire [31:0]instruction_Alu;
wire [31:0]instruction_Reg;
wire [31:0] instruction_Mem;
wire [4:0] Write_Reg_Rtype;
wire [4:0] Write_Reg_lw;
wire [4:0]Writeregister1;
wire [31:0]Write_data_mem;
wire [31:0]Writedata;
wire [31:0]Read_data_mem;
wire [31:0]sign_extend;
wire [31:0]Read_data1,Read_data2;
wire [31:0]register0,register1,register2,register3,
				register4,register5,register6,register7,register8,
				register9,register10,register11;
wire [5:0]Alu_control;
wire [31:0]Alu_result;
wire branch;
output reg [31:0]t0,t1,t2,t3,t4,t5,s5,s4,s3,s2,s1,s0,NEWPC,instruction_ALU,instruction_REG,instruction_MEM,Instruction;

always@(posedge clk or posedge rst)
begin
		if(rst)
		      begin
				CLKcounter<=0;

				end
		else
				begin
					if(CLKcounter<=3'd3)		
						begin				
						CLKcounter<=CLKcounter+3'd1;
						end
					else 
						begin
						CLKcounter<=0;
						end
				end
end

always@(clk)
begin
     if(clk)
		begin
			 if(CLKcounter==3'd1)
			 PC_CLK=1;
			 else
			 PC_CLK=0;
		end
	  else
	  PC_CLK=0;
end

always @(*)
	begin
	t0=register0;
	t1=register1;
	t2=register2;
	t3=register3;
	t4=register4;
	t5=register5;
	s5=register6;
	s4=register7;
	s3=register8;
	s2=register9;
	s1=register10;
	s0=register11;
	NEWPC=newpc;
	instruction_MEM=instruction_Mem;
	instruction_ALU=instruction_Alu;
	instruction_REG=instruction_Reg;
	Instruction=instruction;
	end


IF uu1(
		.pc(pc),
		.newpc(newpc),
		.clk(clk),
		.PC_CLK(PC_CLK),
		.rst(rst),
		.instruction(instruction),
		.Read_Reg1(Read_Reg1),
		.Read_Reg2(Read_Reg2),
		.Alu_control(Alu_control),
		.branch(branch),
		.jump(jump)
      );
ID uu2(
		.clk(clk),
		.Read_Reg1(Read_Reg1),
		.Read_Reg2(Read_Reg2),
		.Writeregister1(Writeregister1),
		.Writedata(Writedata),
		.instruction(instruction),
		.instruction_Reg(instruction_Reg),
		.Read_data_mem(Read_data_mem),
		.Read_data1(Read_data1),
		.Read_data2(Read_data2),
		.sign_extend(sign_extend),
		.register0(register0),
		.register1(register1),
		.register2(register2),
		.register3(register3),
		.register4(register4),
		.register5(register5),
		.register6(register6),
		.register7(register7),
		.register8(register8),
		.register9(register9),
		.register10(register10),
		.register11(register11),
		.Write_Reg_Rtype(Write_Reg_Rtype),
		.Write_Reg_lw(Write_Reg_lw)
      );
EX uu3(
		.Read_data1(Read_data1),
		.Read_data2(Read_data2),
		.instruction_Reg(instruction_Reg),
		.Alu_result(Alu_result),
		.instruction_Alu(instruction_Alu),
		.Write_data_mem(Write_data_mem),
		.clk(clk),
		.sign_extend(sign_extend),
		.rst(rst),
		.newpc(newpc),
		.branch(branch),
		.jump(jump)
      );
MEM uu4(
		.Read_data_mem(Read_data_mem),
		.instruction_Alu(instruction_Alu),
		.instruction_Mem(instruction_Mem),
		.Alu_result(Alu_result),
		.clk(clk),
		.Write_data_mem(Write_data_mem),
		.rst(rst)
      );
WB uu5(
		.instruction_Mem(instruction_Mem),
		.Read_data_mem(Read_data_mem),
		.Alu_result(Alu_result),
		.clk(clk),
		.register0(register0),
		.register1(register1),
		.register2(register2),
		.register3(register3),
		.register4(register4),
		.register5(register5),
		.register6(register6),
		.register7(register7),
		.register8(register8),
		.register9(register9),
		.register10(register10),
		.register11(register11)
      );
endmodule
