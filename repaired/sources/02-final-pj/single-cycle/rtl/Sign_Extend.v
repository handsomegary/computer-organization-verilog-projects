`timescale 1ns / 1ps
module Sign_Extend(OUT_32BITS, IN_16BITS);
  output [31:0] OUT_32BITS;
  input [15:0] IN_16BITS;
  assign OUT_32BITS = {{16{IN_16BITS[15]}}, IN_16BITS};
endmodule
