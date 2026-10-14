`timescale 1ns/1ps
// Directed verification only: TB initializes memories/registers after reset.
// Regression test for repaired RTL; addresses use standard byte addressing.
module finalpj_single_isa_data_tb;
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
 uut.RF.Regfile[1]=20;uut.RF.Regfile[2]=4;uut.RF.Regfile[4]=32'h80000000;uut.RF.Regfile[5]=32'h7fffffff;
 uut.IM.memory[0]={6'h2b,5'd0,5'd1,16'd8};
 uut.IM.memory[4]={6'h23,5'd0,5'd6,16'd8};
 uut.IM.memory[8]={6'h00,5'd1,5'd2,5'd7,5'd0,6'h20};
 uut.IM.memory[12]={6'h08,5'd2,5'd8,16'hffff};
 uut.IM.memory[16]={6'h00,5'd1,5'd2,5'd9,5'd0,6'h22};
 uut.IM.memory[20]={6'h00,5'd1,5'd2,5'd10,5'd0,6'h24};
 uut.IM.memory[24]={6'h00,5'd1,5'd2,5'd11,5'd0,6'h25};
 uut.IM.memory[28]={6'h00,5'd4,5'd5,5'd12,5'd0,6'h2a};
 repeat(38) @(negedge CLK); #1;
 check(uut.DM.memory[2]===32'd20,"sw byte8 / memory[2]"); check(uut.RF.Regfile[6]===32'd20,"lw"); check(uut.RF.Regfile[7]===32'd24,"add"); check(uut.RF.Regfile[8]===32'd3,"addi register result"); check(uut.RF.Regfile[9]===32'd16,"sub"); check(uut.RF.Regfile[10]===32'd4,"and"); check(uut.RF.Regfile[11]===32'd20,"or"); check(uut.RF.Regfile[12]===32'd1,"signed slt");
 finish_test;
end
initial begin #2000; $fatal(1,"timeout");end
endmodule
