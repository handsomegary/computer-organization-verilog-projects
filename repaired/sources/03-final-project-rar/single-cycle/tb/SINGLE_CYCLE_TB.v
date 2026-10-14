`timescale 1ns / 1ps
// Self-checking top-module testbench for the bundled instruction-memory program.
module CPU_SingleCycle_tb;
  reg CLK = 0;
  reg RST = 0;
  wire [31:0] PC_NEXT;
  CPU_SingleCycle uut(.CLK(CLK), .RST(RST), .PC_NEXT(PC_NEXT));
  always #5 CLK = ~CLK;
  initial begin
    #1 RST = 1;
    #1 RST = 0;
    repeat (30) @(negedge CLK);
    if (uut.RF.Regfile[16] !== 32'h00000015) $fatal(1, "ROM result r16");
    if (uut.RF.Regfile[17] !== 32'h00000017) $fatal(1, "ROM result r17");
    if (uut.RF.Regfile[18] !== 32'hfffffffe) $fatal(1, "ROM result r18");
    if (uut.RF.Regfile[20] !== 32'h00000000) $fatal(1, "ROM result r20");
    if (uut.RF.Regfile[8] !== 32'hffffffff) $fatal(1, "ROM result r8");
    if (uut.RF.Regfile[9] !== 32'hffffffff) $fatal(1, "ROM result r9");
    if (uut.DM.memory[6] !== 32'd21) $fatal(1, "ROM store/load result");
    if (uut.RF.Regfile[0] !== 0) $fatal(1, "$zero changed");
    $display("PASS single-cycle ROM: all ten instruction types, branch, jump, aligned sw/lw");
    $finish;
  end
  initial begin #1000; $fatal(1, "timeout"); end
endmodule
