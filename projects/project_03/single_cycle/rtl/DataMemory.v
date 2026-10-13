`timescale 1ns / 1ps

module DataMemory (
  output [31:0] READ_DATA,      
  input [31:0] ADDR,          
  input [31:0] WRITE_DATA,    
  input MEM_WRITE, MEM_READ,
  input RST, 
  input CLK                 
);

  reg [31:0] memory[0:63];  

  assign READ_DATA = memory[ADDR] ;


  integer i;
  
  always @(posedge CLK or posedge RST) begin

    if ( RST == 1 ) begin 
     	for (i = 0; i < 63; i = i + 1) begin
    	memory[i] <= 32'b0 ;
     	end
    end

    else begin
    	if ( MEM_WRITE == 1'b1 && MEM_READ == 1'b0 ) 
      		memory[ADDR] <= WRITE_DATA ;
      	else 
      		memory[ADDR] <= memory[ADDR] ;
    end
    
  end

endmodule


