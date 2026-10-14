`timescale 1ns/1ps
// Independent integration stress tests. Instruction/data addresses are bytes.
`ifndef STRESS_PIPELINE
`define STRESS_CPU CPU_NoHazard
`else
`define STRESS_CPU CPU_Pipeline
`endif
module repaired_stress_zero_hazards_tb;
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
  integer stall_count=0;
  always @(posedge CLK) if(!RST && uut.PCWrite===1'b0) stall_count=stall_count+1;

  initial begin
    start;
    uut.DM.memory[0]=32'hdeadbeef; uut.DM.memory[1]=123;
    uut.IM.memory[0]=imm(6'h23,0,0,0); // load into $zero
    uut.IM.memory[1]=r(0,0,1,6'h20); // must neither stall nor forward lw address/data
    uut.IM.memory[2]=imm(6'h08,0,2,7);
    uut.IM.memory[3]=imm(6'h08,0,0,100); // suppressed write into $zero
    uut.IM.memory[4]=r(0,2,3,6'h20);
    uut.IM.memory[5]=imm(6'h23,0,4,4);
    uut.IM.memory[6]=imm(6'h08,0,4,9); // rt is destination, no false load-use stall
    uut.IM.memory[7]=imm(6'h2b,0,4,80);
    uut.IM.memory[8]={6'h02,26'd8};
    repeat(45) @(negedge CLK); #1;
    check_reg(0,0); check_reg(1,0); check_reg(2,7); check_reg(3,7); check_reg(4,9);
    check_mem(20,9);
    if(stall_count!==0) $fatal(1,"zero/destination generated false stall count=%0d",stall_count);

    $display("PASS repaired_stress_zero_hazards"); $finish;
  end
  initial begin #2000; $fatal(1,"timeout"); end
endmodule
