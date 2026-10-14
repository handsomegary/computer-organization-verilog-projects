`timescale 1ns / 1ps
// Self-checking demo. Compile this project independently: module names overlap.
module CPU_NoHazard_tb;
  reg CLK=0, RST=0;
  always #5 CLK=~CLK;
  CPU_NoHazard uut(.CLK(CLK), .RST(RST));
  task check_reg;
    input integer addr;
    input [31:0] expected;
    begin
      if (uut.RF.Regfile[addr] !== expected)
        $fatal(1, "register %0d: got %h expected %h", addr, uut.RF.Regfile[addr], expected);
    end
  endtask
  initial begin
    #1 RST=1; #11 RST=0;
    repeat (180) @(negedge CLK);
    check_reg(0,0); check_reg(1,400); check_reg(2,7); check_reg(3,7);
    check_reg(4,14); check_reg(5,32'hffffffff); check_reg(6,32'hfffffff8);
    check_reg(7,6); check_reg(8,7); check_reg(9,1); check_reg(10,0);
    check_reg(11,0); check_reg(12,396);
    if (uut.DM.memory[100] !== 7 || uut.DM.memory[101] !== 0 || uut.DM.memory[102] !== 396)
      $fatal(1, "demo memory/store/flush mismatch");
    $display("PASS 02-final-pj/hazard all ten instructions and demo state");
    $finish;
  end
endmodule
