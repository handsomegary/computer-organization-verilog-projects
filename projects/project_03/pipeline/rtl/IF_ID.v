module IF_ID (PC_4_out, IM_out, PC_4, IM, CLK, RST);

output reg [31:0] PC_4_out, IM_out ;
input [31:0] PC_4, IM;
input CLK,RST;

always@(posedge CLK or posedge RST) begin
	if(RST) begin
		PC_4_out <= 32'b0;
		IM_out <= 32'b0;
	end
	else begin
		PC_4_out <= PC_4;
		IM_out <= IM;
	end
end

endmodule