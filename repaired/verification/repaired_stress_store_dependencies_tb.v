`timescale 1ns/1ps
// Independent integration stress tests. Instruction/data addresses are bytes.
`ifndef STRESS_PIPELINE
`define STRESS_CPU CPU_NoHazard
`else
`define STRESS_CPU CPU_Pipeline
`endif
module repaired_stress_store_dependencies_tb;
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
    uut.DM.memory[0]=80; uut.DM.memory[1]=32'hcafef00d;
    uut.RF.Regfile[3]=32'hdeadbeef;
    uut.IM.memory[0]=imm(6'h23,0,1,0);
    uut.IM.memory[1]=imm(6'h2b,1,3,0); // loaded store base
    uut.IM.memory[2]=imm(6'h23,0,2,4);
    uut.IM.memory[3]=imm(6'h2b,0,2,84); // loaded store data
    uut.IM.memory[4]=imm(6'h23,0,5,0);
    uut.IM.memory[5]=imm(6'h2b,5,5,8); // loaded base and data together
    uut.IM.memory[6]=imm(6'h08,0,6,96);
    uut.IM.memory[7]=imm(6'h2b,6,3,0); // ALU result store base
    uut.IM.memory[8]=r(3,0,7,6'h20);
    uut.IM.memory[9]=imm(6'h2b,0,7,100); // ALU result store data
    uut.IM.memory[10]=imm(6'h23,0,8,0);
    uut.IM.memory[11]=imm(6'h23,8,9,0); // loaded load base
    uut.IM.memory[12]=imm(6'h2b,0,9,104); // that loaded word is store data
    uut.IM.memory[13]={6'h02,26'd13};
    repeat(65) @(negedge CLK); #1;
    check_mem(20,32'hdeadbeef); check_mem(21,32'hcafef00d); check_mem(22,80);
    check_mem(24,32'hdeadbeef); check_mem(25,32'hdeadbeef); check_mem(26,32'hdeadbeef);
    check_reg(9,32'hdeadbeef);
    if(stall_count!==5) $fatal(1,"load/store expected five stalls, observed %0d",stall_count);

    $display("PASS repaired_stress_store_dependencies"); $finish;
  end
  initial begin #2000; $fatal(1,"timeout"); end
endmodule
