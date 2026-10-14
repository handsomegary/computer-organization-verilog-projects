`timescale 1ns/1ps
module finalpj_hazard_units_tb;
reg [4:0] rs,rt,exrd,wbrd;
reg exwrite,wbwrite; wire [1:0] fa,fb;
reg [4:0] idrs,idrt,loadrt;reg memread;
wire pcwrite,ifwrite,ctrl;
ForwardingUnit fw(.FORWARDA(fa),.FORWARDB(fb),.RS_in(rs),.RT_in(rt),.RD_EX_MEM(exrd),.RD_MEM_WB(wbrd),.REGWRITE_EX_MEM(exwrite),.REGWRITE_MEM_WB(wbwrite));
Hazard_detection_unit hd(.PCWRITE(pcwrite),.IF_ID_WRITE(ifwrite),.CTRL_SEL(ctrl),.RS_IF_ID(idrs),.RT_IF_ID(idrt),.RT_ID_EX(loadrt),.MEMREAD_ID_EX(memread));

integer errors=0;
task check; input condition; input [511:0] label; begin
 if (condition !== 1'b1) begin errors=errors+1; $display("CHECK_FAIL %0s",label); end
end endtask
task finish_test; begin
 if (errors != 0) $fatal(1,"FAIL: %0d assertion(s)", errors);
 $display("PASS"); $finish;
end endtask

initial begin
 #1; rs=1;rt=2;exrd=0;wbrd=0;exwrite=0;wbwrite=0;
 idrs=1;idrt=2;loadrt=3;memread=0;
 #2; check(fa===0 && fb===0,"no forwarding"); check(pcwrite===1 && ifwrite===1 && ctrl===1,"no load hazard");
 exwrite=1;exrd=1;#2;check(fa===2 && fb===0,"EX forwards operand A");
 exrd=2;#2;check(fa===0 && fb===2,"EX forwards operand B");
 exwrite=0;wbwrite=1;wbrd=1;#2;check(fa===1,"WB forwards operand A");
 wbrd=2;#2;check(fb===1,"WB forwards operand B");
 exwrite=1;exrd=2;wbrd=2;#2;check(fb===2,"EX priority over WB");
 rs=0;rt=0;exrd=0;wbrd=0;#2;check(fa===0 && fb===0,"never forward register zero");
 memread=1;loadrt=1;#2;check(pcwrite===0 && ifwrite===0 && ctrl===0,"load-use rs stalls and inserts bubble");
 loadrt=2;#2;check(pcwrite===0 && ifwrite===0 && ctrl===0,"load-use rt stalls and inserts bubble");
 loadrt=3;#2;check(pcwrite===1 && ifwrite===1 && ctrl===1,"unrelated load continues");
 memread=0;loadrt=1;#2;check(pcwrite===1 && ifwrite===1 && ctrl===1,"ALU producer does not load-stall");
 finish_test;
end
endmodule
