`timescale 1ns / 1ps























module finaltb;

	
	reg [31:0] pc;
	reg clk;
	reg rst;

	
	CPU_Top uut (
		.pc(pc), 
		.clk(clk), 
		.rst(rst)
	);
		always
    	#10 clk=~clk;
	initial begin
		
		pc = 0;
		clk = 0;
		rst = 1;

		
		#100; rst=0; 
        
		

	end
      
endmodule

