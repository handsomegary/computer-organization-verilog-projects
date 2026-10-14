`timescale 1ns/1ps
module repaired_stress_single_memory_tb;
reg CLK=0, RST=0, MEM_WRITE=0, MEM_READ=0;
reg [31:0] ADDR=0, WRITE_DATA=0;
wire [31:0] READ_DATA;
DataMemory dut(READ_DATA, ADDR, WRITE_DATA, MEM_WRITE, MEM_READ, RST, CLK);
always #5 CLK=~CLK;
task store; input [31:0] a,d; begin
 @(negedge CLK); ADDR=a; WRITE_DATA=d; MEM_WRITE=1; MEM_READ=0;
 @(posedge CLK); #1; MEM_WRITE=0;
end endtask
task load; input [31:0] a,d; begin
 ADDR=a; MEM_READ=1; #1;
 if (READ_DATA !== d) $fatal(1,"load byte address %h = %h, expected %h",a,READ_DATA,d);
end endtask
initial begin
 dut.memory[63]=32'hffffffff; dut.memory[255]=32'hffffffff;
 #1 RST=1; #1 RST=0; #1;
 if(dut.memory[63]!==0 || dut.memory[255]!==0) $fatal(1,"last memory reset slot");
 store(400,32'h12345678); store(404,32'habcdef01);
 load(400,32'h12345678); load(404,32'habcdef01);
 if (dut.memory[100]!==32'h12345678) $fatal(1,"byte-address mapping");
 store(1020,32'h76543210); load(1020,32'h76543210);
 store(401,32'hffffffff); load(400,32'h12345678); load(401,0);
 store(1024,32'hffffffff); load(0,0); load(1024,0);
 store(32'hfffffffc,32'hffffffff); load(1020,32'h76543210); load(32'hfffffffc,0);
 MEM_READ=0; #1; if(READ_DATA!==0) $fatal(1,"MEM_READ gating");
 $display("PASS byte addressing, address400, reset boundary, range/alignment, consecutive accesses"); $finish;
end
initial begin #1000; $fatal(1,"timeout");end
endmodule
