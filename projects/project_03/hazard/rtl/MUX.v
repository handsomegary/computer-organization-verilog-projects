`timescale 1ns / 1ps





















module MUX(pcsel,pc4,npc1,npc);
input pcsel;
input [31:0]pc4;
input [31:0]npc1;
output reg [31:0]npc;
endmodule
