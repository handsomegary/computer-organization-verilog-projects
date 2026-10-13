`timescale 1ns / 1ps

module Controller ( REGDST, ALUSRC, MEMTOREG, REGWRITE, MEMREAD, MEMWRITE, BRANCH, ALUOP, OPCODE, Sel ) ;

	output reg REGDST, ALUSRC, MEMTOREG, REGWRITE, MEMREAD, MEMWRITE, BRANCH ; 
	output reg [1:0]ALUOP ;
	input [5:0]OPCODE ;
	input Sel ; 


	always @(Sel,OPCODE) begin
		case ( {Sel,OPCODE} )    
			7'b1000000 : begin  
				REGDST = 1'b1 ;
				ALUSRC = 1'b0 ;
				MEMTOREG = 1'b1 ;
				REGWRITE = 1'b1 ;
				MEMREAD = 1'b0 ;
				MEMWRITE = 1'b0 ;
				BRANCH = 1'b0 ;
				ALUOP = 2'b10 ;
			end
			7'b1100011 : begin  
				REGDST = 1'b0 ;
				ALUSRC = 1'b1 ;
				MEMTOREG = 1'b0 ;
				REGWRITE = 1'b1 ;
				MEMREAD = 1'b1 ;
				MEMWRITE = 1'b0 ;
				BRANCH = 1'b0 ;
				ALUOP = 2'b00 ;
			end
			7'b1101011 : begin  
				REGDST = 1'b0 ;   
				ALUSRC = 1'b1 ;
				MEMTOREG = 1'b1 ; 
				REGWRITE = 1'b0 ;
				MEMREAD = 1'b0 ;
				MEMWRITE = 1'b1 ;
				BRANCH = 1'b0 ;
				ALUOP = 2'b00 ;
			end
			7'b1001000 : begin  
				REGDST = 1'b0 ;  
				ALUSRC = 1'b1 ;
				MEMTOREG = 1'b1 ; 
				REGWRITE = 1'b1 ;
				MEMREAD = 1'b0 ;
				MEMWRITE = 1'b1 ;
				BRANCH = 1'b0 ;
				ALUOP = 2'b00 ;  
			end 

			7'b1000100 : begin  
				REGDST = 1'b0 ; 
				ALUSRC = 1'b0 ;
				MEMTOREG = 1'b1 ; 
				REGWRITE = 1'b0 ;
				MEMREAD = 1'b0 ;
				MEMWRITE = 1'b0 ;
				BRANCH = 1'b1 ;
				ALUOP = 2'b01 ;
			end
			default : begin  
				REGDST = 1'b0 ; 
				ALUSRC = 1'b0 ; 
				MEMTOREG = 1'b0 ; 
				REGWRITE = 1'b0 ; 
				MEMREAD = 1'b0 ; 
				MEMWRITE = 1'b0 ; 
				BRANCH = 1'b0 ; 
				ALUOP = 2'b00 ; 
			end
		endcase
	end

endmodule
