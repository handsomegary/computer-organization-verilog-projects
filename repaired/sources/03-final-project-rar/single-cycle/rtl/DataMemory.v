`timescale 1ns / 1ps

// MIPS byte addresses; 256 aligned 32-bit words (1024 bytes).
// Reads are combinational, stores occur at the rising edge of CLK.
// This teaching core has no exception unit: invalid accesses read zero and
// invalid stores do nothing. MEM_READ must be asserted for a valid read.
module DataMemory (
  output [31:0] READ_DATA,
  input [31:0] ADDR,
  input [31:0] WRITE_DATA,
  input MEM_WRITE, MEM_READ,
  input RST,
  input CLK
);
  reg [31:0] memory[0:255];
  wire valid_address;
  assign valid_address = (ADDR[1:0] == 2'b00) && (ADDR < 32'd1024);
  assign READ_DATA = (MEM_READ && valid_address) ? memory[ADDR[9:2]] : 32'b0;

  integer i;
  always @(posedge CLK or posedge RST) begin
    if (RST) begin
      for (i = 0; i < 256; i = i + 1)
        memory[i] <= 32'b0;
    end else if (MEM_WRITE && !MEM_READ && valid_address) begin
      memory[ADDR[9:2]] <= WRITE_DATA;
    end
  end
endmodule
