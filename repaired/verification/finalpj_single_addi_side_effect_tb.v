`timescale 1ns/1ps
// Directed verification only: TB initializes memories/registers after reset.
// Regression test for repaired RTL; addresses use standard byte addressing.
module finalpj_single_addi_side_effect_tb;
reg CLK=0,RST=0; integer i;
CPU_SingleCycle uut(.CLK(CLK),.RST(RST));
always #5 CLK=~CLK;


integer errors=0;
task check; input condition; input [511:0] label; begin
 if (condition !== 1'b1) begin errors=errors+1; $display("CHECK_FAIL %0s",label); end
end endtask
task finish_test; begin
 if (errors != 0) $fatal(1,"FAIL: %0d assertion(s)", errors);
 $display("PASS"); $finish;
end endtask

initial begin
 #1 RST=1; #1 RST=0; #1;
 for(i=0;i<64;i=i+1) begin uut.IM.memory[i]=0;uut.DM.memory[i]=0;end
 uut.DM.memory[5]=32'h12345678;
 uut.IM.memory[0]={6'h08,5'd0,5'd1,16'd20};
 repeat(20) @(negedge CLK); #1;
 check(uut.RF.Regfile[1]===32'd20,"addi register result"); $display("OBSERVED memory[5]=%h expected=12345678",uut.DM.memory[5]); check(uut.DM.memory[5]===32'h12345678,"addi must preserve data memory sentinel");
 finish_test;
end
initial begin #2000; $fatal(1,"timeout");end
endmodule
