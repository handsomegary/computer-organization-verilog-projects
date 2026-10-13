`timescale 1ns / 1ps


module ALU(ALUresult, ALUop, address, readdata1, readdata2, Zero, ALUsrc, branch_PC, PC, regdst, Rt, Rd, writereg,
           EX_MEM_DATA, MEM_WB_DATA, Forward1, Forward2);
input [31:0] readdata1, readdata2, PC;
input [4:0]Rt,Rd;
input [1:0] ALUop;
input [31:0] address;
input ALUsrc,regdst;

input [31:0]EX_MEM_DATA, MEM_WB_DATA;
input [1:0]Forward1, Forward2;

output reg Zero;
output reg [31:0] ALUresult;
output reg [31:0]branch_PC;
output reg [4:0] writereg;

reg [3:0] ALUctr;
reg [31:0]offset;
wire [31:0] X1, Y1;
wire [31:0] X2, Y2;
wire [31:0] X3, Y3;
reg  [31:0] X, Y;

assign X1 = readdata1;
assign Y1 =  (ALUsrc)?address:readdata2;

assign X2 = MEM_WB_DATA;
assign Y2 = MEM_WB_DATA;

assign X3 = EX_MEM_DATA;
assign Y3 = EX_MEM_DATA;

always@(*) begin
    if(Forward1 == 2'b00) begin
        X = X1;
    end
    else if(Forward1 == 2'b01) begin
        X = X2;
    end
    else if(Forward1 == 2'b10) begin
        X = X3;
    end
    else begin
        X = X;
    end
end

always@(*) begin
    if(Forward2 == 2'b00) begin
        Y = Y1;
    end
    else if(Forward2 == 2'b01) begin
        Y = Y2;
    end
    else if(Forward2 == 2'b10) begin
        Y = Y3;
    end
    else begin
        Y = Y;
    end
end


always@(*)
begin
 case(ALUop)
  2'd0: ALUctr = 4'd2;
  2'd1: ALUctr = 4'd6;
  2'd2: begin
     case(address[5:0])
      6'b100000: ALUctr = 4'd2;
      6'b100010: ALUctr = 4'd6;
      6'b100100: ALUctr = 4'd0;
      6'b100101: ALUctr = 4'd1;
      6'b101010: ALUctr = 4'd7;
      default: ALUctr = 4'd15;
     endcase
    end
  default: ALUctr = 4'd15;
 endcase
end

always@(*)
begin
 case(ALUctr)
  4'd0: ALUresult = X & Y;
  4'd1: ALUresult = X | Y;
  4'd2: ALUresult = X + Y;
  4'd6: ALUresult = X - Y;
  4'd7: ALUresult = (X<Y)? 32'b1111_1111_1111_1111_1111_1111_1111_1111:32'd0;
  default: ALUresult = 32'd0;
 endcase
end
always@(*)
begin
 Zero = (ALUresult == 0)? 1'b1:1'b0;
 if(regdst == 1'b1)
    writereg = Rd;
 else if(regdst == 1'b0)
    writereg = Rt;
end
always@(address or PC)
begin
 offset[31:2] = address[29:0];
 offset[1:0] = 2'b00;
 branch_PC =PC+offset;
end

endmodule
