`timescale 1ns/1ps
// Program/state initialization is test stimulus, not an RTL repair.
module probe;
reg clk=0,rst=0;
wire [31:0] pc;
`ifdef PIPE_CPU
CPU_Pipeline dut(.CLK(clk),.RST(rst),.PC_NEXT(pc));
localparam STEPS=7;
`else
CPU_SingleCycle dut(.CLK(clk),.RST(rst),.PC_NEXT(pc));
localparam STEPS=1;
`endif
integer i,k;
task tick;begin #2;clk=1;#1;clk=0;#1;end endtask
task reset_case;
begin
rst=0;#1;rst=1;#1;rst=0;#1;
for(i=0;i<64;i=i+1)begin
    // Identity OR uses the required ISA subset; no implicit sll-zero NOP.
    dut.IM.memory[i]={6'd0,5'd31,5'd31,5'd31,5'd0,6'd37};
    dut.DM.memory[i]=0;
end
for(i=0;i<32;i=i+1)dut.RF.Regfile[i]=0;
dut.RF.Regfile[1]=7;dut.RF.Regfile[3]=5;dut.RF.Regfile[4]=32'hdeadc0de;
end endtask
task run;
input integer count;
begin for(k=0;k<count;k=k+1)tick;end endtask
task rtype;
input [5:0] fn;input [31:0] av,bv;
begin reset_case;dut.RF.Regfile[1]=av;dut.RF.Regfile[3]=bv;
dut.IM.memory[0]={6'd0,5'd1,5'd3,5'd4,5'd0,fn};#1;run(STEPS);
$display("OBS CPU_ALU_%0d_%08x_%08x %08x",fn,av,bv,dut.RF.Regfile[4]);
if(fn==32 && av==7 && bv==5)$display("OBS SEQUENTIAL_PC %08x",pc);
end endtask
initial begin
rtype(32,7,5);rtype(34,7,5);rtype(36,7,5);rtype(37,7,5);
rtype(42,32'hffffffff,1);rtype(42,1,32'hffffffff);
reset_case;dut.DM.memory[3]=77;
dut.IM.memory[0]={6'd8,5'd1,5'd4,16'hfffc};#1;run(STEPS);
$display("OBS CPU_ADDI_NEGATIVE %08x",dut.RF.Regfile[4]);
$display("OBS CPU_ADDI_MEMORY_UNCHANGED %08x",dut.DM.memory[3]);
reset_case;dut.RF.Regfile[1]=16;dut.DM.memory[20]=123;
dut.IM.memory[0]={6'd35,5'd1,5'd4,16'd4};#1;run(STEPS);
$display("OBS CPU_LW_BYTE20 %08x",dut.RF.Regfile[4]);
reset_case;dut.RF.Regfile[1]=16;dut.RF.Regfile[3]=123;
dut.IM.memory[0]={6'd43,5'd1,5'd3,16'd4};#1;run(STEPS);
$display("OBS CPU_SW_BYTE20 %08x",dut.DM.memory[20]);
// A branch skips three independent writes in the no-delay-slot textbook ISA.
reset_case;dut.RF.Regfile[5]=77;dut.RF.Regfile[6]=77;dut.RF.Regfile[7]=77;
dut.IM.memory[0]={6'd4,5'd1,5'd1,16'd3};
dut.IM.memory[1]={6'd0,5'd1,5'd3,5'd5,5'd0,6'd32};
dut.IM.memory[2]={6'd0,5'd1,5'd3,5'd6,5'd0,6'd37};
dut.IM.memory[3]={6'd0,5'd1,5'd3,5'd7,5'd0,6'd36};
dut.IM.memory[4]={6'd0,5'd1,5'd3,5'd8,5'd0,6'd34};#1;run(12);
$display("OBS BRANCH_SKIPPED_R5 %08x",dut.RF.Regfile[5]);
$display("OBS BRANCH_SKIPPED_R6 %08x",dut.RF.Regfile[6]);
$display("OBS BRANCH_SKIPPED_R7 %08x",dut.RF.Regfile[7]);
$display("OBS BRANCH_TARGET_R8 %08x",dut.RF.Regfile[8]);
reset_case;dut.RF.Regfile[5]=77;
dut.IM.memory[0]={6'd4,5'd1,5'd3,16'd3};
dut.IM.memory[1]={6'd0,5'd1,5'd3,5'd5,5'd0,6'd32};#1;run(12);
$display("OBS BRANCH_NOT_TAKEN_R5 %08x",dut.RF.Regfile[5]);
// Negative branch offset: from PC=16, PC+4-4*4 is 4.
reset_case;dut.Program_Counter.PC_OUT=16;dut.RF.Regfile[3]=7;
dut.IM.memory[4]={6'd4,5'd1,5'd3,16'hfffc};#1;
`ifdef PIPE_CPU
run(3);$display("OBS NEGATIVE_BRANCH_TARGET %08x",dut.PC_IN);
`else
run(1);$display("OBS NEGATIVE_BRANCH_TARGET %08x",pc);
`endif
reset_case;dut.RF.Regfile[5]=77;
dut.IM.memory[0]={6'd2,26'd4};
dut.IM.memory[1]={6'd0,5'd1,5'd3,5'd5,5'd0,6'd32};
dut.IM.memory[4]={6'd0,5'd1,5'd3,5'd8,5'd0,6'd34};#1;run(12);
$display("OBS JUMP_SKIPPED_R5 %08x",dut.RF.Regfile[5]);
$display("OBS JUMP_TARGET_R8 %08x",dut.RF.Regfile[8]);
`ifndef PIPE_CPU
reset_case;dut.Program_Counter.PC_OUT=32'h0ffffffc;
force dut.INSTRUCTION=32'h08000005;#1;
$display("OBS JUMP_UPPER_PC4 %08x",dut.PC_IN);
release dut.INSTRUCTION;
`endif
$finish(0);
end
endmodule
