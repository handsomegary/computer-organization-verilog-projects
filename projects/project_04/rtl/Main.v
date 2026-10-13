`timescale 1ns / 1ps
module ha(pc,clk,rst,t0,t1,t2,t3,t4,t5,s5,s4,s3,s2,s1,s0,NEWPC,PC_CLK,
          ins_ALU,ins_REG,ins_MEM,Ins,Write_Data_Mem,Read_Data_Mem,Alu_Result,
          Sign_extend,Read_Data1,Read_Data2,Memory10,nop1,nop2,Branch,Jump);

input [31:0]pc;
input clk,rst;

output reg Branch,Jump;
output reg PC_CLK;
output reg [31:0]t0,t1,t2,t3,t4,t5,s5,s4,s3,s2,s1,s0,NEWPC,ins_ALU,ins_REG,ins_MEM,Ins,
                 Write_Data_Mem,Read_Data_Mem,Alu_Result,Sign_extend,Read_Data1,Read_Data2, Memory10,nop1,nop2;

reg clk1,clk2,clk3,clk4,clk5;
reg [2:0]CLKcounter;

wire jump;
wire [31:0]PC;
wire [31:0]ins;
wire [31:0]ins_Alu;
wire [31:0]ins_reg;
wire [31:0]ins_Mem;
wire [31:0]Write_data_mem;
wire [31:0]Writedata;
wire [31:0]Read_data_mem;
wire [31:0]sign_extend;
wire [31:0]Read_data1,Read_data2;
wire [31:0]reg0,reg1,reg2,reg3,
		   reg4,reg5,reg6,reg7,reg8,
	       reg9,reg10,reg11,reg12,reg13,memory10,zero;
wire [31:0]result;
wire branch;


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
			    if(CLKcounter==3'd0)
			    PC_CLK=1;
			else
			    PC_CLK=0;
		end
	    else
	        PC_CLK=0;
    end

always @(*)
	begin
        t0=reg0;
        t1=reg1;
        t2=reg2;
        t3=reg3;
        t4=reg4;
        t5=reg5;
        s5=reg6;
        s4=reg7;
        s3=reg8;
        s2=reg9;
        s1=reg10;
        s0=reg11;
        nop1=reg12;
        nop2=reg13;
        NEWPC=PC;
        ins_MEM=ins_Mem;
        ins_ALU=ins_Alu;
        ins_REG=ins_reg;
        Ins=ins;
        Write_Data_Mem=Write_data_mem;
        Read_Data_Mem=Read_data_mem;
        Alu_Result=Alu_result;
        Sign_extend=sign_extend;
        Read_Data1=Read_data1;
        Read_Data2=Read_data2;
        Memory10=memory10;
        Branch=branch;
        Jump=jump;
	end

IF uu1(
		.pc(pc),
		.PC(PC),
		.clk(clk),
		.PC_CLK(PC_CLK),
		.rst(rst),
		.ins(ins),
		.branch(branch),
		.jump(jump)
      );
ID uu2(
		.clk(clk),
		.ins(ins),
		.ins_reg(ins_reg),
		
		.Read_data1(Read_data1),
		.Read_data2(Read_data2),
		.sign_extend(sign_extend),
		.reg0(reg0),
		.reg1(reg1),
		.reg2(reg2),
		.reg3(reg3),
		.reg4(reg4),
		.reg5(reg5),
		.reg6(reg6),
		.reg7(reg7),
		.reg8(reg8),
		.reg9(reg9),
		.reg10(reg10),
		.reg11(reg11),
		.reg12(reg12),
		.reg13(reg13),
		.zero(zero),
		.rst(rst)
      );
EX uu3(
		.Read_data1(Read_data1),
		.Read_data2(Read_data2),
		.ins_reg(ins_reg),
		.Alu_result(Alu_result),
		.ins_Alu(ins_Alu),
		.Write_data_mem(Write_data_mem),
		.clk(clk),
		.sign_extend(sign_extend),
		.rst(rst),
		.PC(PC),
		.branch(branch),
		.jump(jump)
      );
MEM uu4(
		.Read_data_mem(Read_data_mem),
		.ins_Alu(ins_Alu),
		.ins_Mem(ins_Mem),
		.result(result),
		.clk(clk),
		.Write_data_mem(Write_data_mem),
		.rst(rst),
		.memory10(memory10)
      );
WB uu5(
		.ins_Mem(ins_Mem),
		.Read_data_mem(Read_data_mem),
		.clk(clk),
		.reg0(reg0),
		.reg1(reg1),
		.reg2(reg2),
		.reg3(reg3),
		.reg4(reg4),
		.reg5(reg5),
		.reg6(reg6),
		.reg7(reg7),
		.reg8(reg8),
		.reg9(reg9),
		.reg10(reg10),
		.reg11(reg11),
		.reg12(reg12),
		.reg13(reg13),
		.zero(zero),
		.rst(rst),
		.memory10(memory10)
      );
endmodule