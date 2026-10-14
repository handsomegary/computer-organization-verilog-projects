`timescale 1ns / 1ps
module DataMemory (
  output [31:0] READ_DATA,
  input [31:0] ADDR, WRITE_DATA,
  input MEM_WRITE, MEM_READ, RST, CLK
);
  // 4 KiB of word storage addressed using MIPS byte addresses.
  // Invalid/misaligned accesses are deterministic and have no write effect.
  reg [31:0] memory[0:1023];
  wire valid_addr = (ADDR[31:12] == 0) && (ADDR[1:0] == 0);
  assign READ_DATA = (MEM_READ && valid_addr) ? memory[ADDR[11:2]] : 32'b0;
  integer i;
  always @(posedge CLK or posedge RST) begin
    if (RST) begin
      for (i = 0; i < 1024; i = i + 1) memory[i] <= 32'b0;
    end else if (MEM_WRITE && !MEM_READ && valid_addr) begin
      memory[ADDR[11:2]] <= WRITE_DATA;
    end
  end
endmodule
