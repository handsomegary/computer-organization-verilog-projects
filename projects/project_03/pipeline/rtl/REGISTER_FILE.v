module Register_file(
READ_DATA_1, READ_DATA_2,READ_ADDR_1, READ_ADDR_2, WRITE_ADDR, WRITE_DATA,
REGWRITE, CLK,RST
);
output [31:0] READ_DATA_1, READ_DATA_2;
input [31:0] WRITE_DATA;
input [4:0] READ_ADDR_1, READ_ADDR_2, WRITE_ADDR;
input REGWRITE, CLK,RST;

reg [31:0] Regfile [31:0];
integer i;

assign READ_DATA_1 =  Regfile[READ_ADDR_1];
assign READ_DATA_2 =  Regfile[READ_ADDR_2];

always@(negedge CLK or posedge RST)
begin
	if(RST)begin
		for(i=0; i<32; i=i+1)
			Regfile[i] <= 32'b0;
	end
	else begin
		if (REGWRITE==1'b1 && WRITE_ADDR!=0)
			Regfile[WRITE_ADDR] <= WRITE_DATA;
		else
			Regfile[WRITE_ADDR] <= Regfile[WRITE_ADDR];
	end

end

endmodule
