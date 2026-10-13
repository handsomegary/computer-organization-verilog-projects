module PC(PC_OUT, PC_IN, PCWrite, CLK, RST);
output reg [31:0] PC_OUT;
input [31:0] PC_IN;
input PCWrite;
input CLK, RST;

always @(posedge CLK or posedge RST) begin
	if(RST)
		PC_OUT<=1'b0;

	else begin

		if(PCWrite == 1'b1)
			PC_OUT<=PC_IN;
		else 
			PC_OUT<=PC_OUT;

	end
end

endmodule
