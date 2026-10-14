`timescale 1ns/1ps
// Independent integration stress tests. Instruction/data addresses are bytes.
`ifndef STRESS_PIPELINE
`define STRESS_CPU CPU_NoHazard
`else
`define STRESS_CPU CPU_Pipeline
`endif
module repaired_stress_control_stores_tb;
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

  initial begin
    start;
    uut.RF.Regfile[1]=1; uut.RF.Regfile[2]=2;
    uut.RF.Regfile[3]=33; uut.RF.Regfile[4]=44; uut.RF.Regfile[5]=55;
    for(i=16;i<=22;i=i+1) uut.DM.memory[i]=32'h12345678;
    uut.IM.memory[0]=imm(6'h04,1,2,4); // not taken
    uut.IM.memory[1]=imm(6'h2b,0,3,64); // must commit after untaken branch
    uut.IM.memory[2]={6'h02,26'd5};
    uut.IM.memory[3]=imm(6'h2b,0,2,68); // jump wrong path
    uut.IM.memory[4]=imm(6'h2b,0,2,68); // jump wrong path
    uut.IM.memory[5]=imm(6'h2b,0,4,68); // jump target
    uut.IM.memory[6]=imm(6'h04,1,1,4); // taken: target11
    uut.IM.memory[7]=imm(6'h2b,0,2,72); // EX when branch resolves
    uut.IM.memory[8]=imm(6'h2b,0,2,76); // ID when branch resolves
    uut.IM.memory[9]=imm(6'h2b,0,2,80); // IF when branch resolves
    uut.IM.memory[10]=imm(6'h2b,0,2,84);
    uut.IM.memory[11]=imm(6'h2b,0,5,88); // taken target
    uut.IM.memory[12]={6'h02,26'd12};
    repeat(60) @(negedge CLK); #1;
    check_mem(16,33); check_mem(17,44); check_mem(22,55);
    for(i=18;i<=21;i=i+1) check_mem(i,32'h12345678);

    $display("PASS repaired_stress_control_stores"); $finish;
  end
  initial begin #2000; $fatal(1,"timeout"); end
endmodule
