`timescale 1ns/1ps
// Independent integration stress tests. Instruction/data addresses are bytes.
`ifndef STRESS_PIPELINE
`define STRESS_CPU CPU_NoHazard
`else
`define STRESS_CPU CPU_Pipeline
`endif
module repaired_stress_reset_inflight_tb;
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
    uut.RF.Regfile[2]=32'hcafef00d;
    uut.DM.memory[255]=32'hffffffff;
    uut.DM.memory[1023]=32'hffffffff;
    uut.IM.memory[0]=imm(6'h08,0,5,99);
    uut.IM.memory[1]=imm(6'h2b,0,2,64);
    uut.IM.memory[2]=imm(6'h08,0,6,123);
    // Reset while the store waits in MEM and the older ADDI waits for WB.
    wait(uut.MEMWRITE_EX_MEM===1'b1); #1;
    if(uut.REGWRITE_MEM_WB!==1'b1) $fatal(1,"test did not reach simultaneous pending WB/store");
    RST=1; #1;
    if(uut.PC_NEXT!==0 || uut.MEMWRITE_EX_MEM!==0 || uut.REGWRITE_MEM_WB!==0)
      $fatal(1,"asynchronous reset did not clear in-flight state");
    for(i=0;i<1024;i=i+1) uut.IM.memory[i]=0;
    #1 RST=0;
    repeat(15) @(negedge CLK); #1;
    check_reg(0,0); check_reg(2,0); check_reg(5,0); check_reg(6,0);
    check_mem(16,0); check_mem(255,0); check_mem(1023,0);

    $display("PASS repaired_stress_reset_inflight"); $finish;
  end
  initial begin #2000; $fatal(1,"timeout"); end
endmodule
