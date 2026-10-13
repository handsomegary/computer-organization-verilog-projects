`timescale 1ns / 1ps





















module TB;

reg CLK;

CPU hazard(CLK);
initial begin
CLK = 1;
end
always begin
#15 CLK =~ CLK;
end

initial 
#1000 $finish;

endmodule

