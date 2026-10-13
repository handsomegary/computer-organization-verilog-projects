`timescale 1ns/1ps
// Same probes, compiled separately against each unmodified RTL directory.
module probe;
reg [5:0] opcode=0, fn=0;
reg [31:0] a=0,b=0;
wire rd,src,mtr,rw,mr,mw,branch;
wire [1:0] aluop;
wire [3:0] control;
wire [31:0] result;
wire zero;
`ifdef PIPE_CONTROLLER
Controller c(rd,src,mtr,rw,mr,mw,branch,aluop,opcode);
`else
wire jump;
Controller c(rd,src,mtr,rw,mr,mw,branch,jump,aluop,opcode);
`endif
ALU_Controller ac(control,aluop,fn);
ALU alu(result,zero,a,b,control);
reg [15:0] imm=0;
wire [31:0] extended,shifted;
Sign_Extend sx(extended,imm);
Shift_Left_2_32BitsTo32Bits sh(shifted,extended);
reg clk=0,rst=0,write_enable=0,read_enable=0;
reg [31:0] address=0,write_data=0;
wire [31:0] read_data;
DataMemory dm(read_data,address,write_data,write_enable,read_enable,rst,clk);
task tick;begin #2;clk=1;#1;clk=0;#1;end endtask
task arithmetic;
input [5:0] function_code;input [31:0] av,bv;
begin opcode=0;fn=function_code;a=av;b=bv;#1;
$display("OBS ALU_%0d_%08x_%08x %08x",function_code,av,bv,result);end endtask
initial begin
arithmetic(32,7,5);arithmetic(34,7,5);arithmetic(36,7,5);arithmetic(37,7,5);
arithmetic(42,32'hffffffff,1);arithmetic(42,1,32'hffffffff);
opcode=8;#1;$display("OBS ADDI_MEMWRITE %08x",{31'd0,mw});
$display("OBS ADDI_REGWRITE %08x",{31'd0,rw});
opcode=35;#1;$display("OBS LW_MEMREAD %08x",{31'd0,mr});
opcode=43;#1;$display("OBS SW_MEMWRITE %08x",{31'd0,mw});
opcode=4;fn=0;a=7;b=7;#1;
$display("OBS BEQ_ZERO %08x",{31'd0,zero});
`ifndef PIPE_CONTROLLER
opcode=2;#1;$display("OBS JUMP_CONTROL %08x",{31'd0,jump});
`endif
imm=16'hfffc;#1;$display("OBS SIGNEXT_FFFC %08x",extended);
$display("OBS SHIFT_NEGATIVE %08x",shifted);
// Probe the implementation's declared byte-address sparse word slots.
// Aligned slots 0..60 exist; address100 does not. A dense word array would
// instead use ADDR>>2 and permit byte addresses through252. Do not conflate them.
dm.memory[63]=32'hdeadc0de;rst=1;#1;rst=0;
$display("OBS RESET_LAST_WORD %08x",dm.memory[63]);
dm.memory[1]=32'd22;dm.memory[4]=32'd77;dm.memory[25]=32'd99;
read_enable=1;address=4;#1;$display("OBS SPARSE_READ_4 %08x",read_data);
address=100;#1;$display("OBS CAPACITY_READ_100 %08x",read_data);
read_enable=0;write_enable=1;address=8;write_data=123;tick;
$display("OBS SPARSE_STORE_WORD2_UNCHANGED %08x",dm.memory[2]);
$display("OBS SPARSE_STORE_SLOT8 %08x",dm.memory[8]);
$finish(0);
end
endmodule
