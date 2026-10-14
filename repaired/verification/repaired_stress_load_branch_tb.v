`timescale 1ns/1ps
// Independent integration stress tests. Instruction/data addresses are bytes.
`ifndef STRESS_PIPELINE
`define STRESS_CPU CPU_NoHazard
`else
`define STRESS_CPU CPU_Pipeline
`endif
module repaired_stress_load_branch_tb;
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
    uut.DM.memory[0]=32'h1234; uut.DM.memory[2]=9;
    uut.RF.Regfile[20]=32'h1234; uut.RF.Regfile[21]=32'hdead; uut.RF.Regfile[22]=8;
    uut.DM.memory[16]=32'h11111111; uut.DM.memory[18]=32'h22222222;
    uut.IM.memory[0]=imm(6'h23,0,1,0);
    uut.IM.memory[1]=imm(6'h04,1,20,3); // loaded operand, taken to5
    uut.IM.memory[2]=imm(6'h2b,0,21,64);
    uut.IM.memory[3]=imm(6'h08,0,30,777);
    uut.IM.memory[4]={6'h02,26'd15};
    uut.IM.memory[5]=imm(6'h23,0,2,8);
    uut.IM.memory[6]=imm(6'h04,2,22,2); // loaded operand, not taken
    uut.IM.memory[7]=imm(6'h2b,0,2,68);
    uut.IM.memory[8]={6'h02,26'd11};
    uut.IM.memory[9]=imm(6'h2b,0,21,72);
    uut.IM.memory[10]=imm(6'h08,0,31,888);
    uut.IM.memory[11]=imm(6'h2b,0,1,76);
    uut.IM.memory[12]={6'h02,26'd12};
    repeat(65) @(negedge CLK); #1;
    check_reg(1,32'h1234); check_reg(2,9); check_reg(30,0); check_reg(31,0);
    check_mem(16,32'h11111111); check_mem(17,9); check_mem(18,32'h22222222); check_mem(19,32'h1234);
    if(stall_count!==2) $fatal(1,"load->beq expected two stalls, observed %0d",stall_count);

    $display("PASS repaired_stress_load_branch"); $finish;
  end
  initial begin #2000; $fatal(1,"timeout"); end
endmodule
