`timescale 1ns / 1ps

module Controller ( REGDST, ALUSRC, MEMTOREG, REGWRITE, MEMREAD, MEMWRITE, BRANCH, ALUOP, OPCODE ) ;

	output reg REGDST, ALUSRC, MEMTOREG, REGWRITE, MEMREAD, MEMWRITE, BRANCH ; 
	output reg [1:0]ALUOP ;
	input [5:0]OPCODE ;

	always @(OPCODE) begin
		case (OPCODE)    
			6'b000000 : begin  // R-Format
				REGDST = 1'b1 ;
				ALUSRC = 1'b0 ;
				MEMTOREG = 1'b1 ;
				REGWRITE = 1'b1 ;
				MEMREAD = 1'b0 ;
				MEMWRITE = 1'b0 ;
				BRANCH = 1'b0 ;
				ALUOP = 2'b10 ;
			end
			6'b100011 : begin  // lw
				REGDST = 1'b0 ;
				ALUSRC = 1'b1 ;
				MEMTOREG = 1'b0 ;
				REGWRITE = 1'b1 ;
				MEMREAD = 1'b1 ;
				MEMWRITE = 1'b0 ;
				BRANCH = 1'b0 ;
				ALUOP = 2'b00 ;
			end
			6'b101011 : begin  // sw
				REGDST = 1'b0 ;   
				ALUSRC = 1'b1 ;
				MEMTOREG = 1'b1 ; 
				REGWRITE = 1'b0 ;
				MEMREAD = 1'b0 ;
				MEMWRITE = 1'b1 ;
				BRANCH = 1'b0 ;
				ALUOP = 2'b00 ;
			end
			6'b001000 : begin  // addi
				REGDST = 1'b0 ;  
				ALUSRC = 1'b1 ;
				MEMTOREG = 1'b1 ; 
				REGWRITE = 1'b1 ;
				MEMREAD = 1'b0 ;
				MEMWRITE = 1'b0 ;
				BRANCH = 1'b0 ;
				ALUOP = 2'b00 ;  
			end 

			6'b000100 : begin  // beq
				REGDST = 1'b0 ; // X
				ALUSRC = 1'b0 ;
				MEMTOREG = 1'b1 ; // X
				REGWRITE = 1'b0 ;
				MEMREAD = 1'b0 ;
				MEMWRITE = 1'b0 ;
				BRANCH = 1'b1 ;
				ALUOP = 2'b01 ;
			end
			default : begin  // Error !!! 
				REGDST = 1'b0 ; // X
				ALUSRC = 1'b0 ; // X
				MEMTOREG = 1'b1 ; // X
				REGWRITE = 1'b0 ; // X
				MEMREAD = 1'b0 ; // X
				MEMWRITE = 1'b0 ; // X
				BRANCH = 1'b0 ; // X
				ALUOP = 2'b00 ; // X
			end
		endcase
	end

endmodule