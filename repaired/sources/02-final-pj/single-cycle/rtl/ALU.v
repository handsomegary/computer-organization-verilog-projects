`timescale 1ns / 1ps
module ALU(OUT, ZERO, IN0, IN1, ALU_CONTROL);
  output reg signed [31:0] OUT;
  output ZERO;
  input signed [31:0] IN0, IN1;
  input [3:0] ALU_CONTROL;
  always @* begin
    case (ALU_CONTROL)
      4'b0000: OUT = IN0 & IN1;
      4'b0001: OUT = IN0 | IN1;
      4'b0010: OUT = IN0 + IN1;
      4'b0110: OUT = IN0 - IN1;
      4'b0111: OUT = ($signed(IN0) < $signed(IN1)) ? 32'd1 : 32'd0;
      4'b1100: OUT = ~(IN0 | IN1);
      default: OUT = 32'd0;
    endcase
  end
  assign ZERO = (OUT == 32'd0);
endmodule
