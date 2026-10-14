`timescale 1ns/1ps
// Conventional MIPS decode checks; preserved source is never changed.
module finalpj_single_decode_tb;
reg [5:0] OPCODE=6'b111111, FUNCTION_FIELD=0;
wire REGDST, ALUSRC, MEMTOREG, REGWRITE, MEMREAD, MEMWRITE, BRANCH;
wire [1:0] ALUOP; wire [3:0] ALU_CONTROL;
wire JUMP;
Controller dut(.REGDST(REGDST),.ALUSRC(ALUSRC),.MEMTOREG(MEMTOREG),.REGWRITE(REGWRITE),.MEMREAD(MEMREAD),.MEMWRITE(MEMWRITE),.BRANCH(BRANCH),.ALUOP(ALUOP),.OPCODE(OPCODE), .JUMP(JUMP));
ALU_Controller ac(.ALU_CONTROL(ALU_CONTROL),.ALU_OP(ALUOP),.FUNCTION_FIELD(FUNCTION_FIELD));

integer errors=0;
task check; input condition; input [511:0] label; begin
 if (condition !== 1'b1) begin errors=errors+1; $display("CHECK_FAIL %0s",label); end
end endtask
task finish_test; begin
 if (errors != 0) $fatal(1,"FAIL: %0d assertion(s)", errors);
 $display("PASS"); $finish;
end endtask

task rtype; input [5:0] funct; input [3:0] expected; input [511:0] label; begin
 OPCODE=0; FUNCTION_FIELD=funct; #2;
 check(REGWRITE===1'b1,label); check(REGDST===1'b1,"R dest rd");
 check(ALUSRC===1'b0,"R second operand register"); check(MEMTOREG===1'b0,"R writeback ALU");
 check(MEMREAD===1'b0 && MEMWRITE===1'b0,"R no memory access");
 check(BRANCH===1'b0,"R no branch"); check(ALU_CONTROL===expected,label);
end endtask
initial begin
 #1;
 rtype(6'h20,4'h2,"add"); rtype(6'h22,4'h6,"sub");
 rtype(6'h24,4'h0,"and"); rtype(6'h25,4'h1,"or"); rtype(6'h2a,4'h7,"slt");
 OPCODE=6'h08; #2;
 check(REGWRITE===1'b1 && REGDST===1'b0 && ALUSRC===1'b1,"addi datapath");
 check(MEMTOREG===1'b0 && ALU_CONTROL===4'h2,"addi add and ALU writeback");
 check(MEMREAD===1'b0 && MEMWRITE===1'b0,"addi must not read/write data memory");
 OPCODE=6'h23; #2;
 check(REGWRITE===1'b1 && REGDST===1'b0 && ALUSRC===1'b1,"lw datapath");
 check(MEMTOREG===1'b1 && MEMREAD===1'b1 && MEMWRITE===1'b0 && ALU_CONTROL===4'h2,"lw controls");
 OPCODE=6'h2b; #2;
 check(REGWRITE===1'b0 && ALUSRC===1'b1 && MEMREAD===1'b0 && MEMWRITE===1'b1 && ALU_CONTROL===4'h2,"sw controls");
 OPCODE=6'h04; #2;
 check(REGWRITE===1'b0 && ALUSRC===1'b0 && MEMREAD===1'b0 && MEMWRITE===1'b0 && BRANCH===1'b1 && ALU_CONTROL===4'h6,"beq controls");
 OPCODE=6'h02; #2;
 check(REGWRITE===1'b0 && MEMREAD===1'b0 && MEMWRITE===1'b0 && BRANCH===1'b0,"j has no register/memory write");
 check(JUMP === 1'b1,"jump control asserted");
 finish_test;
end
endmodule
