module IF_ID (PC_4_out, IM_out, PC_4, IM, IF_ID_WRTIE, CLK, RST);

output reg [31:0] PC_4_out, IM_out;
input [31:0] PC_4, IM;
input CLK,RST, IF_ID_WRTIE;

always@(posedge CLK or posedge RST) begin
	if(RST) begin
		PC_4_out <= 32'b0;
		IM_out <= 32'b0;
	end
	else begin
		if (IF_ID_WRTIE == 1'b0) begin
			PC_4_out <= PC_4_out ;
			IM_out <= IM_out ;
		end
		else begin
			PC_4_out <= PC_4;
			IM_out <= IM;
		end
	end
end

endmodule
