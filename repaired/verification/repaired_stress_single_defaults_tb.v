`timescale 1ns/1ps
module repaired_stress_single_defaults_tb;
reg CLK=0,RST=0; integer i;
CPU_SingleCycle uut(.CLK(CLK),.RST(RST));
always #5 CLK=~CLK;
initial begin
 #1 RST=1; #1 RST=0; #1;
 for(i=0;i<64;i=i+1) uut.IM.memory[i]=0;
 uut.IM.memory[0]={6'h08,5'd0,5'd1,16'd20};
 uut.IM.memory[1]={6'h2b,5'd0,5'd1,16'd20};
 uut.IM.memory[2]={6'h3f,5'd1,5'd1,16'd20};
 uut.IM.memory[3]={6'h00,5'd1,5'd1,5'd1,5'd0,6'h3f};
 uut.IM.memory[4]={6'h08,5'd0,5'd0,16'd777};
 uut.IM.memory[5]={6'h08,5'd0,5'd3,16'd17};
 repeat(10) @(negedge CLK); #1;
 if(uut.RF.Regfile[1]!==32'd20 || uut.DM.memory[5]!==32'd20) $fatal(1,"unsupported instruction side effect");
 if(uut.RF.Regfile[0]!==0 || uut.RF.Regfile[3]!==32'd17) $fatal(1,"zero register");
 if(uut.IM.memory[63]!==0) $fatal(1,"ROM tail initialization");
 // Also check an out-of-range fetch never indexes beyond the ROM array.
 force uut.PC_NEXT=32'd256; #1;
 if(uut.INSTRUCTION!==0) $fatal(1,"out-of-range ROM fetch");
 release uut.PC_NEXT;
 $display("PASS unknown opcode/function defaults, hardwired zero, ROM tail/fetch bounds"); $finish;
end
initial begin #1000;$fatal(1,"timeout");end
endmodule
