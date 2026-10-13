`timescale 1ns / 1ps



module Dmemory (addr,write_data,memwrite,memread,clk,write_back,mem_to_reg,write_reg,read_data1,addr1,m,zero,PCsrc,write_reg1,write_back1,mem_to_reg1);
input wire [31:0] addr;
input wire [31:0] write_data;
input wire memwrite, memread;
input wire clk, write_back, mem_to_reg;
input wire [4:0] write_reg;
input m, zero;
output reg [31:0] read_data1, addr1;
output reg PCsrc = 1'b0;
output reg [4:0] write_reg1;
output reg write_back1, mem_to_reg1;
reg [31:0] tempaddr0 = 32'b0;
reg [31:0] tempaddr1 = 32'b0;
reg [31:0] tempaddr2 = 32'b0;
reg [31:0] tempaddr3 = 32'b0;
reg [31:0] tempaddr4 = 32'b0;
reg [31:0] tempaddr5 = 32'b0;
reg [31:0] memory0 = 32'b0;
reg [31:0] memory1 = 32'b0;
reg [31:0] memory2 = 32'b0;
reg [31:0] memory3 = 32'b0;
reg [31:0] memory4 = 32'b0;
reg [31:0] memory5 = 32'b0;
reg [31:0] read_data = 32'b0;

integer i = 0;

always @(memwrite or memread)
begin
    if (tempaddr0 == addr)
    begin
        if (memwrite == 1'b1) 
        begin
            memory0 = write_data;
        end
        if (memread == 1'b1) 
        begin
            read_data = memory0;
        end
    end
    else if (tempaddr0 != addr && tempaddr0 == 0)
    begin
        if (memwrite == 1'b1) 
        begin
            tempaddr0 = addr;
            memory0 = write_data;
        end
        if (memread == 1'b1) 
        begin
            read_data = 32'b0;
        end
    end
    else if (tempaddr1 == addr)
    begin
        if (memwrite == 1'b1) 
        begin
            memory1 = write_data;
        end
        if (memread == 1'b1) 
        begin
            read_data = memory1;
        end
    end
    else if (tempaddr1 != addr && tempaddr1 == 0)
    begin
        if (memwrite == 1'b1) 
        begin
            tempaddr1 = addr;
            memory1 = write_data;
        end
        if (memread == 1'b1) 
        begin
            read_data = 32'b0;
        end
    end
    else if (tempaddr2 == addr)
    begin
        if (memwrite == 1'b1) 
        begin
            memory2 = write_data;
        end
        if (memread == 1'b1) 
        begin
            read_data = memory2;
        end
    end
    else if (tempaddr2 != addr && tempaddr2 == 0)
    begin
        if (memwrite == 1'b1) 
        begin
            tempaddr2 = addr;
            memory2 = write_data;
        end
        if (memread == 1'b1) 
        begin
            read_data = 32'b0;
        end
    end
    else if (tempaddr3 == addr)
    begin
        if (memwrite == 1'b1) 
        begin
            memory3 = write_data;
        end
        if (memread == 1'b1) 
        begin
            read_data = memory3;
        end
    end
    else if (tempaddr3 != addr && tempaddr3 == 0)
    begin
        if (memwrite == 1'b1) 
        begin
            tempaddr3 = addr;
            memory3 = write_data;
        end
        if (memread == 1'b1) 
        begin
            read_data = 32'b0;
        end
    end
    else if (tempaddr4 == addr)
    begin
        if (memwrite == 1'b1) 
        begin
            memory4 = write_data;
        end
        if (memread == 1'b1) 
        begin
            read_data = memory4;
        end
    end
    else if (tempaddr4 != addr && tempaddr4 == 0)
    begin
        if (memwrite == 1'b1) 
        begin
            tempaddr4 = addr;
            memory4 = write_data;
        end
        if (memread == 1'b1) 
        begin
            read_data = 32'b0;
        end
    end
    else if (tempaddr5 == addr)
    begin
        if (memwrite == 1'b1) 
        begin
            memory5 = write_data;
        end
        if (memread == 1'b1) 
        begin
            read_data = memory5;
        end
    end
    else if (tempaddr5 != addr && tempaddr5 == 0)
    begin
        if (memwrite == 1'b1) 
        begin
            tempaddr5 = addr;
            memory5 = write_data;
        end
        if (memread == 1'b1) 
        begin
            read_data = 32'b0;
        end
    end
end



always@(m or zero) begin
    if((m == 1) && (zero == 1))
        PCsrc = 1;
    else if((m == 0) && (zero == 1))
        PCsrc = 0;
    else if((m == 1) && (zero == 0))
        PCsrc = 0;
    else if((m == 0) && (zero == 0))
        PCsrc = 0;
end

always @(posedge clk)
begin
    mem_to_reg1 <= mem_to_reg;
    write_reg1 <= write_reg;
    read_data1 <= read_data;
    addr1 <= addr;
    write_back1 <= write_back;
end
endmodule
