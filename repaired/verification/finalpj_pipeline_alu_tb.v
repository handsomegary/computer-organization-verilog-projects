`timescale 1ns/1ps
module finalpj_pipeline_alu_tb;
reg signed [31:0] IN0=0,IN1=0; reg [3:0] ALU_CONTROL=15;
wire signed [31:0] OUT; wire ZERO;
ALU dut(.OUT(OUT),.ZERO(ZERO),.IN0(IN0),.IN1(IN1),.ALU_CONTROL(ALU_CONTROL));

integer errors=0;
task check; input condition; input [511:0] label; begin
 if (condition !== 1'b1) begin errors=errors+1; $display("CHECK_FAIL %0s",label); end
end endtask
task finish_test; begin
 if (errors != 0) $fatal(1,"FAIL: %0d assertion(s)", errors);
 $display("PASS"); $finish;
end endtask

task vector; input [31:0] a,b; input [3:0] op; input [31:0] expected; input [511:0] label; begin
 IN0=a;IN1=b;ALU_CONTROL=op;#2;
 check(OUT===expected,label); check(ZERO===(expected==0),"ZERO flag");
end endtask
initial begin
 vector(32'h55aa00ff,32'h0ff0f00f,4'h0,32'h05a0000f,"AND");
 vector(32'h55aa00ff,32'h0ff0f00f,4'h1,32'h5ffaf0ff,"OR");
 vector(32'd11,32'd4,4'h2,32'd15,"ADD"); vector(32'd4,32'd11,4'h6,-32'd7,"SUB");
 vector(-32'd1,32'd0,4'h7,32'd1,"SLT -1 < 0");
 vector(32'h80000000,32'h7fffffff,4'h7,32'd1,"SLT min_signed < max_signed");
 vector(32'h7fffffff,32'h80000000,4'h7,32'd0,"SLT max_signed >= min_signed");
 vector(32'd2,32'd2,4'h6,32'd0,"SUB equality");
 finish_test;
end
endmodule
