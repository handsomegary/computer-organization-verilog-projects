`timescale 1ns/1ps
module repaired_stress_single_deck_tb;
reg CLK=0,RST=0; integer i;
CPU_SingleCycle uut(.CLK(CLK),.RST(RST));
always #5 CLK=~CLK;
initial begin
 #1 RST=1; #1 RST=0; #1;
 for(i=0;i<64;i=i+1) uut.IM.memory[i]=0;
 for(i=0;i<=100;i=i+1) uut.DM.memory[i]=i+1;
 uut.IM.memory[0]={6'h08,5'd0,5'd9,16'd400};
 uut.IM.memory[1]={6'h23,5'd9,5'd17,16'd0};
 uut.IM.memory[2]={6'h00,5'd18,5'd17,5'd18,5'd0,6'h20};
 uut.IM.memory[3]={6'h08,5'd9,5'd9,16'hfffc};
 uut.IM.memory[4]={6'h00,5'd9,5'd0,5'd10,5'd0,6'h2a};
 uut.IM.memory[5]={6'h04,5'd10,5'd0,16'hfffb};
 uut.IM.memory[6]={6'h02,26'd8};
 uut.IM.memory[7]={6'h08,5'd0,5'd20,16'd666};
 uut.IM.memory[8]={6'h00,5'd18,5'd0,5'd20,5'd0,6'h25};
 uut.IM.memory[9]={6'h00,5'd20,5'd17,5'd12,5'd0,6'h22};
 uut.IM.memory[10]={6'h00,5'd20,5'd12,5'd13,5'd0,6'h24};
 uut.IM.memory[11]={6'h2b,5'd0,5'd13,16'd0};
 uut.IM.memory[12]={6'h02,26'd12};
 repeat(520) @(negedge CLK); #1;
 if(uut.RF.Regfile[18]!==32'd5151) $fatal(1,"deck accumulation %d",uut.RF.Regfile[18]);
 if(uut.RF.Regfile[9]!==32'hfffffffc || uut.RF.Regfile[10]!==32'd1) $fatal(1,"signed loop termination");
 if(uut.RF.Regfile[20]!==32'd5151 || uut.RF.Regfile[12]!==32'd5150 || uut.RF.Regfile[13]!==32'd5150) $fatal(1,"loop2 arithmetic");
 if(uut.DM.memory[0]!==32'd5150) $fatal(1,"loop2 store");
 $display("PASS deck-style address400 loop: 101 loads, addi -4, signed slt, backward beq, jump, logical/sub/store");
 $finish;
end
initial begin #7000;$fatal(1,"timeout");end
endmodule
