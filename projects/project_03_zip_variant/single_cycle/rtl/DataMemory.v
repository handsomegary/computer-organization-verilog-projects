`timescale 1ns / 1ps

module DataMemory (
  output [31:0] READ_DATA,      // Output of Memory Address Contents
  input [31:0] ADDR,          // Memory Address
  input [31:0] WRITE_DATA,    // Memory Address Contents
  input MEM_WRITE, MEM_READ,
  input RST, 
  input CLK                 // All synchronous elements, including memories, should have a clock signal
);

  reg [31:0] memory[0:63];  // 64 words of 32-bit memory

  assign READ_DATA = memory[ADDR] ;


  integer i;
  // Using @(addr) will lead to unexpected behavior as memories are synchronous elements like registers
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

/*
  integer i;

  // Using @(addr) will lead to unexpected behavior as memories are synchronous elements like registers
  always @(posedge CLK or posedge RST) begin

    if ( RST == 1 ) begin 
     	for (i = 0; i < 63; i = i + 1) begin
    	memory[i] <= 32'b0 ;
     	end
    end

    else begin
    	if ( MEM_WRITE == 1'b1 && MEM_READ == 1'b0 ) 
      		memory[ADDR] <= WRITE_DATA ;
	    // Use MEM_READ to indicate a valid address is on the line and read the memory into a register at that address when MEM_READ is asserted
	    else if ( MEM_WRITE == 1'b0 && MEM_READ == 1'b1 ) 
	     	READ_DATA <= memory[ADDR] ;
	    else 
	     	READ_DATA <= 32'bZ ;
    end
    

  end
*/
