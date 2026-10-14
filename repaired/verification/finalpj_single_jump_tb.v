`timescale 1ns/1ps
// Directed verification only: TB initializes memories/registers after reset.
// Regression test for repaired RTL; addresses use standard byte addressing.
module finalpj_single_jump_tb;
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
 uut.RF.Regfile[1]=5;uut.RF.Regfile[2]=6;
 uut.IM.memory[0]={6'h02,26'd4};
 uut.IM.memory[1]={6'h08,5'd0,5'd10,16'd1};
 uut.IM.memory[2]={6'h08,5'd0,5'd11,16'd2};
 uut.IM.memory[3]={6'h08,5'd0,5'd12,16'd3};
 uut.IM.memory[4]={6'h00,5'd1,5'd2,5'd13,5'd0,6'h20};
 repeat(20) @(negedge CLK); #1;
 $display("OBSERVED jump fall-through r10=%h r11=%h r12=%h",uut.RF.Regfile[10],uut.RF.Regfile[11],uut.RF.Regfile[12]); check(uut.RF.Regfile[10]===32'd0 && uut.RF.Regfile[11]===32'd0 && uut.RF.Regfile[12]===32'd0,"jump must skip fall-through writes"); check(uut.RF.Regfile[13]===32'd11,"jump target executed");
 finish_test;
end
initial begin #2000; $fatal(1,"timeout");end
endmodule
