`timescale 1ns / 1ps


module CPU_SingleCycle_tb;

	
	reg CLK;
	reg RST;

	
	wire [31:0] PC_NEXT;
    wire [31:0]READ_DATA_2, Signextend_out, ALU_Input0, ALU_Input1, ALU_result, DataMem_out, WRITE_DATA; 
	
	CPU_SingleCycle uut (
		.PC_NEXT(PC_NEXT), 
		.CLK(CLK), 
		.RST(RST),
		.READ_DATA_2(READ_DATA_2),
		.Signextend_out(Signextend_out),
		.ALU_Input0(ALU_Input0),
		.ALU_Input1(ALU_Input1),
		.ALU_result(ALU_result),
		.DataMem_out(DataMem_out),
		.WRITE_DATA(WRITE_DATA)
	);

	initial begin 
		CLK = 1'b0 ;
		forever #10 CLK = ~CLK ;
	end 

	initial begin
		
		RST = 0;

		
		#100;
        
		
		RST = 1 ;
		#50 RST = 0 ;
		
		#450 ;

		$finish ;

	end
      
    
    

endmodule

