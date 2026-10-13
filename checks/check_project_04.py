"""Reproduce compilation and functional findings in project_04 without repairing it."""
import re
from hdl import ROOT, compile_and_run

BASE='projects/project_04/'


def unit(filename,bench):
    result=compile_and_run([BASE+'rtl/'+filename],'probe',bench)
    assert result['compiled'],result['diagnostics']
    assert result.get('returncode')==0,result
    return [line.split() for line in result['stdout'].splitlines()]


def main():
    sources=[p.relative_to(ROOT).as_posix() for p in sorted((ROOT/BASE/'rtl').glob('*.v'))]
    result=compile_and_run(sources,'ha',run=False)
    assert not result['compiled'],'Archived top unexpectedly compiles: audit must be updated'
    assert re.search(r'\bAlu_result\b.*not a port.*\buu3\b',result['diagnostics']),result
    assert re.search(r'\bresult\b.*not a port.*\buu4\b',result['diagnostics']),result
    original_tb=compile_and_run(sources+[BASE+'tb/final_tb.v'],'ha_tb',run=False)
    assert not original_tb['compiled'],original_tb

    # Defined numeric inputs exercise ordinary ALU cases and the incorrect value=2 forwarding trigger.
    alu=unit('Execution.v',r'''`timescale 1ns/1ps
module probe;
reg clk=0,rst=0; reg [31:0] a=0,b=0,ins=0,imm=0,pc=0;
wire [31:0] result,out_ins,store; wire branch,jump;
EX dut(a,b,ins,result,out_ins,store,clk,imm,rst,pc,branch,jump);
task tick; begin #3;clk=1;#1;clk=0;#1;end endtask
task rtype; input [5:0] fn; input [31:0] av,bv;
begin a=av;b=bv;ins={6'd0,5'd1,5'd3,5'd4,5'd0,fn};tick;
$display("ALU %0d %08x",fn,result);end endtask
initial begin
rst=1;#1;tick;rst=0;
rtype(32,7,5);rtype(34,7,5);rtype(36,7,5);rtype(37,7,5);
rtype(42,32'hffffffff,1);
a=7;imm=32'hfffffffc;ins={6'd8,5'd1,5'd4,16'hfffc};tick;$display("ADDI %08x",result);
a=7;b=7;ins={6'd4,5'd1,5'd3,16'd3};tick;$display("BEQ %0d",branch);
ins={6'd2,26'd5};tick;$display("J %0d",jump);
// A real value of 2 should still participate in ordinary addition.
rtype(32,2,5);
$finish(0);end
endmodule''')
    assert alu[:5]==[['ALU','32','0000000c'],['ALU','34','00000002'],['ALU','36','00000005'],['ALU','37','00000007'],['ALU','42','00000001']],alu
    assert alu[5:8]==[['ADDI','00000003'],['BEQ','1'],['J','1']],alu
    assert alu[-1][0:2]==['ALU','32'] and alu[-1][2].lower()!='00000007',alu

    fetch=unit('Instruction_Fetching.v',r'''`timescale 1ns/1ps
module probe;
reg clk=0,rst=0,branch=0,jump=0;reg [31:0] start=80;wire [31:0] pc,ins;
IF dut(start,pc,clk,rst,ins,branch,jump,1'b1);
task tick;begin #2;clk=1;#1;clk=0;#1;end endtask
initial begin rst=1;#1;rst=0;tick;$display("NEXT %0d",pc);
branch=1;tick;$display("BRANCH %0d",pc);
branch=0;jump=1;tick;$display("JUMP %0d",pc);$finish(0);end
endmodule''')
    assert fetch==[['NEXT','84'],['BRANCH','16'],['JUMP','104']],fetch

    memory=unit('Memory_Access.v',r'''`timescale 1ns/1ps
module probe;
reg clk=0,rst=0;reg [31:0] ins=0,addr=0,data=0;
wire [31:0] readback,out_ins,memory10;
MEM dut(readback,ins,addr,clk,data,rst,out_ins,memory10);
task tick;begin #2;clk=1;#1;clk=0;#1;end endtask
initial begin rst=1;#1;rst=0;
ins={6'd43,26'd0};addr=0;data=17;tick;
ins={6'd35,26'd0};tick;$display("IN_RANGE %0d",readback);
ins={6'd43,26'd0};addr=100;data=99;tick;
ins={6'd35,26'd0};tick;$display("ADDRESS100 %0d",readback);
$finish(0);end endmodule''')
    assert memory==[['IN_RANGE','17'],['ADDRESS100','17']],memory

    # rs=0 does not select the declared reg0; the previous read value is retained.
    decode=unit('Instruction_Decoding.v',r'''`timescale 1ns/1ps
module probe;
reg clk=0,rst=0;reg [31:0] ins=0;wire [31:0] out_ins,a,b,imm;
ID dut(.clk(clk),.rst(rst),.ins(ins),.ins_reg(out_ins),.Read_data_mem(32'd0),
.Read_data1(a),.Read_data2(b),.sign_extend(imm),.reg0(32'd55),.reg1(32'd11),
.reg2(32'd12),.reg3(32'd13),.reg4(32'd14),.reg5(32'd15),.reg6(32'd16),.reg7(32'd17),
.reg8(32'd18),.reg9(32'd19),.reg10(32'd20),.reg11(32'd21),.reg12(32'd22),.reg13(32'd23),.zero(32'd0));
task tick;begin #2;clk=1;#1;clk=0;#1;end endtask
initial begin rst=1;#1;rst=0;ins={6'd0,5'd1,5'd3,5'd4,5'd0,6'd32};tick;
$display("RS1 %0d",a);ins={6'd0,5'd0,5'd3,5'd4,5'd0,6'd32};tick;$display("RS0 %0d",a);
ins={6'd8,5'd1,5'd4,16'hfffc};tick;$display("IMM %08x",imm);$finish(0);end endmodule''')
    assert decode==[['RS1','11'],['RS0','11'],['IMM','fffffffc']],decode
    print('AUDIT REPRODUCED project_04: top/TB fail elaboration; ALU value=2 defect, fixed branch/jump, limited memory and register decode; ordinary unit cases verified.')


if __name__=='__main__':main()
