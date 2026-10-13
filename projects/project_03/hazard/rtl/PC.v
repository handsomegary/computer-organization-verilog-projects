`timescale 1ns / 1ps


module PC(clk,npc1,pcsel,insout,pcout,
          IF_ID_Write,PC_Write);
input pcsel;
input clk;
input [31:0]npc1;
input IF_ID_Write,PC_Write;

output reg [31:0]insout;
output reg [31:0]pcout = 32'b0;
reg [31:0]pc = -4;
reg [31:0]ins;
reg [31:0]pc4 = 32'b0;
reg [31:0]npc = 32'b0;

    always@(pc)
    begin
        case(pc)
     





            0:ins  = 32'b101011_10001_10010_0000000010000000;
            4:ins  = 32'b100011_10001_10011_0000000010000000;
            8:ins  = 32'b000000_10001_10011_10101_00000_100000;
            12:ins = 32'b000000_10101_10001_10011_00000_100000;
            16:ins = 32'b00000000000000000000000000000000;
            
            default:ins=0;
            endcase           
     end
    
  always@(pc) begin
        pc4 = pc + 4;
    end
    always@(*) begin
        if(pcsel == 1)
            npc = npc1;
        else
            npc = pc4;
    end

    always@(posedge clk)begin
        if(IF_ID_Write == 1 && PC_Write == 1) begin
            insout <= ins;
            pcout <= pc4 ;
            pc <= npc;
        end
        else if(IF_ID_Write == 0 && PC_Write == 0) begin
            insout <= insout;
            pcout <= pcout ;
            pc <= pc;
        end
    end
 

  
endmodule

