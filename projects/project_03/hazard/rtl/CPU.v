`timescale 1ns / 1ps

module CPU(CLK);
           
input CLK;


wire RegWrite;
reg  [31:0]Writedata;
wire [4:0]WriteReg; 
wire [31:0]PC;
wire [31:0]Instruction;
wire RegDst,Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite_out; 
wire [31:0]Read_Data1;
wire [31:0]Read_Data2;
wire [4:0]Instruction16_20;
wire [4:0]Instruction11_15;
wire [31:0]Instruction15to32bit; 
wire [31:0]PCO;
wire [1:0]ALUOp_out;
wire [4:0]ID_EX_Rt;
wire [4:0]ID_EX_Rs;

wire [31:0]npc1; 
wire pcsel;

wire regwrite;
wire [31:0] ALUresult, EX_branch_PC;
wire MEM_zero;
wire [4:0]MEM_writereg;
wire mem_to_reg,write_back,memtoreg; 
wire[4:0] write_reg;
wire memwrite,memread,branch,zero,Zero;
wire [4:0]Rt,Rd;
wire [31:0] addr,write_data;
wire [31:0] EX_PC;

wire mem_to_reg1;
wire [31:0]read_data1;
wire [31:0]addr1;

reg [1:0]Forward1;
reg [1:0]Forward2;

reg IF_ID_Write = 1'b1;
reg PC_Write = 1'b1;
reg Control_Slt = 1'b1;

PC  block1(.clk(CLK),.insout(Instruction),.pcout(PC),.pcsel(pcsel),.npc1(npc1),
       .IF_ID_Write(IF_ID_Write),.PC_Write(PC_Write));

Reg block2(.CLK(CLK),.RegWrite(RegWrite),.WriteReg(WriteReg),.RegDst_out(RegDst),.Writedata(Writedata),.PC(PC),
       .Read_Data1_out(Read_Data1),.Read_Data2_out(Read_Data2),.PC_out(PCO),.Instruction(Instruction),.MemtoReg_out(MemtoReg),.ALUOp_out(ALUOp_out),
       .Instruction16_20_out(Instruction16_20),.Instruction11_15_out(Instruction11_15),.Instruction0_15_to_32_out(Instruction15to32bit),
       .Branch_out(Branch),.MemRead_out(MemRead),
       .MemWrite_out(MemWrite),
       .ALUSrc_out(ALUSrc),.RegWrite_out(RegWrite_out),
       .ID_EX_Rt(ID_EX_Rt),.ID_EX_Rs(ID_EX_Rs),
       .Control_Slt(Control_Slt));        

ALU block3(.ALUresult(ALUresult),.ALUop(ALUOp_out),.readdata1(Read_Data1),.readdata2(Read_Data2),.Zero(Zero),.ALUsrc(ALUSrc),.branch_PC(EX_branch_PC),.PC(PCO),.Rt(Instruction16_20),.Rd(Instruction11_15),.writereg(MEM_writereg),
       .Forward1(Forward1),.Forward2(Forward2),.regdst(RegDst),.address(Instruction15to32bit),.MEM_WB_DATA(Writedata),.EX_MEM_DATA(addr));

EXandMEM block4(.clk(CLK),.MEM_memtoreg(mem_to_reg),.MEM_regwrite(write_back),.MEM_memread(memread),.MEM_memwrite(memwrite),.MEM_branch(branch),.MEM_zero(zero),.MEM_aluresult(addr),.MEM_readda2(write_data),.MEM_writereg(write_reg),.MEM_branch_PC(npc1),
          .EX_memtoreg(MemtoReg),.EX_regwrite(RegWrite_out),.EX_memread(MemRead),.EX_memwrite(MemWrite),.EX_branch(Branch),.EX_branch_PC(EX_branch_PC),.EX_zero(Zero),.EX_aluresult(ALUresult),.EX_readda2(Read_Data2),.EX_writereg(MEM_writereg));

Dmemory   block5(.addr(addr),.write_reg1(WriteReg),.write_back1(RegWrite),.mem_to_reg1(mem_to_reg1),.write_data(write_data),.memwrite(memwrite),.memread(memread),.clk(CLK),.write_back(write_back),.read_data1(read_data1),.addr1(addr1),.PCsrc(pcsel),.mem_to_reg(mem_to_reg),.write_reg(write_reg),.m(branch),.zero(zero)
         );

always@(*) begin
    if(mem_to_reg1 == 1'b1)
        Writedata <= addr1;
    else if(mem_to_reg1 == 1'b0)
        Writedata <= read_data1;
end

always@(MemRead or Instruction or ID_EX_Rt) begin 
    if(MemRead == 1) begin
        if((Instruction[25:21] == ID_EX_Rt) || (Instruction[20:16] == ID_EX_Rt)) begin
            IF_ID_Write = 0;
            PC_Write = 0;
            Control_Slt = 0;
        end
        else begin
            IF_ID_Write = 1;
            PC_Write = 1;
            Control_Slt = 1;
        end
    end
    else begin
        IF_ID_Write = 1;
        PC_Write = 1;
        Control_Slt = 1;
    end
end

always@(write_reg or WriteReg or write_back or RegWrite or ID_EX_Rt or ID_EX_Rs) begin 
    if((write_back == 1) && (write_reg != 0) && ((write_reg == ID_EX_Rt) || (write_reg == ID_EX_Rs))) begin
        if((write_reg == ID_EX_Rs) && (write_reg == ID_EX_Rt)) begin
            Forward1 = 2'b10;
            Forward2 = 2'b10;
        end
        else if((write_reg == ID_EX_Rs) && (write_reg != ID_EX_Rt)) begin
            Forward1 = 2'b10;
            Forward2 = 2'b00;
        end
        else if((write_reg != ID_EX_Rs) && (write_reg == ID_EX_Rt)) begin
            Forward1 = 2'b00;
            Forward2 = 2'b10;
        end
        else begin
            Forward1 = 2'b00;
            Forward2 = 2'b00;
        end
    end  
    else if((RegWrite == 1) && (WriteReg != 0) && ((WriteReg == ID_EX_Rt) || (WriteReg == ID_EX_Rs))) begin
        if((WriteReg == ID_EX_Rs) && (WriteReg == ID_EX_Rt)) begin
            Forward1 = 2'b01;
            Forward2 = 2'b01;
        end
        else if((WriteReg == ID_EX_Rs) && (WriteReg != ID_EX_Rt)) begin
            Forward1 = 2'b01;
            Forward2 = 2'b00;
        end
        else if((WriteReg != ID_EX_Rs) && (WriteReg == ID_EX_Rt)) begin
            Forward1 = 2'b00;
            Forward2 = 2'b01;
        end
        else begin
            Forward1 = 2'b00;
            Forward2 = 2'b00;
        end
    end      
    else begin
        Forward1 = 2'b00;
        Forward2 = 2'b00;
    end
end
endmodule



