`timescale 1ns/1ps
// Independent integration stress tests. Instruction/data addresses are bytes.
`ifndef STRESS_PIPELINE
`define STRESS_CPU CPU_NoHazard
`else
`define STRESS_CPU CPU_Pipeline
`endif
module repaired_stress_dual_forwarding_tb;
  reg CLK=0, RST=0;
  integer i;
  `STRESS_CPU uut(.CLK(CLK),.RST(RST));
  always #5 CLK=~CLK;
  function [31:0] r;
    input [4:0] rs,rt,rd; input [5:0] fn;
    begin r={6'b0,rs,rt,rd,5'b0,fn}; end
  endfunction
  function [31:0] imm;
    input [5:0] op; input [4:0] rs,rt; input [15:0] value;
    begin imm={op,rs,rt,value}; end
  endfunction
  task check_reg;
    input integer n; input [31:0] expected;
    begin if(uut.RF.Regfile[n] !== expected)
      $fatal(1,"r%0d = %h expected %h",n,uut.RF.Regfile[n],expected);
    end
  endtask
  task check_mem;
    input integer n; input [31:0] expected;
    begin if(uut.DM.memory[n] !== expected)
      $fatal(1,"byte address %0d = %h expected %h",n*4,uut.DM.memory[n],expected);
    end
  endtask
  task start;
    begin
      #1 RST=1; #1 RST=0; #1;
      for(i=0;i<1024;i=i+1) uut.IM.memory[i]=0;
    end
  endtask
  reg seen_mixed=0,seen_newest=0;
  always @(negedge CLK) begin
    #1;
    if(!RST && uut.RS_ID_EX==1 && uut.RT_ID_EX==2 &&
       uut.FORWARDA==2'b01 && uut.FORWARDB==2'b10) seen_mixed=1;
    if(!RST && uut.RS_ID_EX==5 && uut.RT_ID_EX==5 &&
       uut.FORWARDA==2'b10 && uut.FORWARDB==2'b10) seen_newest=1;
  end

  initial begin
    start;
    uut.RF.Regfile[8]=1; uut.RF.Regfile[9]=2;
    uut.RF.Regfile[10]=20; uut.RF.Regfile[11]=5;
    uut.IM.memory[0]=r(8,9,1,6'h20); // r1=3
    uut.IM.memory[1]=r(10,11,2,6'h22); // r2=15
    uut.IM.memory[2]=r(1,2,3,6'h25); // MEM/WB A and EX/MEM B together
    uut.IM.memory[3]=r(2,1,4,6'h20); // r4=18
    uut.IM.memory[4]=imm(6'h08,0,5,1);
    uut.IM.memory[5]=imm(6'h08,0,5,2); // newest producer wins
    uut.IM.memory[6]=r(5,5,6,6'h20); // both use newest EX/MEM r5=2
    uut.IM.memory[7]=r(6,5,7,6'h20); // different stages on both operands
    uut.IM.memory[8]=imm(6'h2b,0,3,64);
    uut.IM.memory[9]=imm(6'h2b,0,4,68);
    uut.IM.memory[10]=imm(6'h2b,0,6,72);
    uut.IM.memory[11]=imm(6'h2b,0,7,76);
    uut.IM.memory[12]={6'h02,26'd12};
    repeat(50) @(negedge CLK); #1;
    check_reg(1,3); check_reg(2,15); check_reg(3,15); check_reg(4,18);
    check_reg(5,2); check_reg(6,4); check_reg(7,6);
    check_mem(16,15); check_mem(17,18); check_mem(18,4); check_mem(19,6);
    if(!seen_mixed || !seen_newest) $fatal(1,"forwarding stage coverage missing mixed=%b newest=%b",seen_mixed,seen_newest);

    $display("PASS repaired_stress_dual_forwarding"); $finish;
  end
  initial begin #2000; $fatal(1,"timeout"); end
endmodule
