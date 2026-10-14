module PC(PC_OUT, PC_IN, CLK, RST);
output reg [31:0] PC_OUT;
input [31:0] PC_IN;
input CLK, RST;

always @(posedge CLK or posedge RST) begin
	if(RST)begin
		PC_OUT<=0;
	end
	else begin
		PC_OUT<=PC_IN;
	end
end

endmodule
