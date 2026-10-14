`timescale 1ns / 1ps
module Register_file(
  output [31:0] READ_DATA_1, READ_DATA_2,
  input [4:0] READ_ADDR_1, READ_ADDR_2, WRITE_ADDR,
  input [31:0] WRITE_DATA,
  input REGWRITE, CLK, RST
);
  reg [31:0] Regfile[31:0];
  integer i;
  // Register $zero is hardwired to zero on both read ports.
  assign READ_DATA_1 = (READ_ADDR_1 == 0) ? 32'b0 : Regfile[READ_ADDR_1];
  assign READ_DATA_2 = (READ_ADDR_2 == 0) ? 32'b0 : Regfile[READ_ADDR_2];

  always @(posedge CLK or posedge RST) begin
    if (RST) begin
      for (i = 0; i < 32; i = i + 1)
        Regfile[i] <= 32'b0;
    end else if (REGWRITE && WRITE_ADDR != 0) begin
      Regfile[WRITE_ADDR] <= WRITE_DATA;
    end
  end
endmodule
