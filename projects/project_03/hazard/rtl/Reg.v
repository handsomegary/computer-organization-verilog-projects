`timescale 1ns / 1ps

module Reg(Instruction,CLK,RegWrite,WriteReg,Writedata,PC,Read_Data1_out,Read_Data2_out,PC_out,Instruction16_20_out,Instruction11_15_out,Instruction0_15_to_32_out,
           RegDst_out,Branch_out,MemRead_out,MemtoReg_out,ALUOp_out,MemWrite_out,ALUSrc_out,RegWrite_out,ID_EX_Rt,ID_EX_Rs,Control_Slt);

input [31:0]Instruction;
input RegWrite,CLK;
input [31:0]PC;
input [4:0]WriteReg;
input [31:0]Writedata;
input Control_Slt;
output Read_Data1_out,Read_Data2_out;
output Instruction11_15_out,Instruction16_20_out,Instruction0_15_to_32_out,PC_out;
output MemRead_out,MemtoReg_out,MemWrite_out; 
output ID_EX_Rt,ID_EX_Rs; 
output RegDst_out;
output Branch_out;
output RegWrite_out;
output ALUSrc_out;
output ALUOp_out;
reg [4:0]ID_EX_Rt;
reg [4:0]ID_EX_Rs;
reg RegDst_out,Branch_out,MemRead_out,MemtoReg_out,MemWrite_out,ALUSrc_out,RegWrite_out;
reg RegDst_store,Branch_store,MemRead_store,MemtoReg_store,MemWrite_store,ALUSrc_store,RegWrite_store;
reg [1:0]ALUOp_store;
reg [1:0]ALUOp_out;
reg [4:0]Instruction16_20_out;
reg [4:0]Instruction11_15_out;
reg [31:0]Instruction0_15_to_32_out; 
reg [31:0]Instruction0_15_to_32;
reg [31:0]PC_out;
reg [31:0]Read_Data1;
reg [31:0]Read_Data2;
reg [31:0]Read_Data1_out;
reg [31:0]Read_Data2_out;
reg [4:0]Readregsister1;
reg [4:0]Readregsister2;

reg [31:0]Zero = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]at   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]v0   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]v1   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]a0   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]a1   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]a2   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]a3   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]t0   = 32'b0000_0000_0000_0000_0000_0000_0000_1111;
reg [31:0]t1   = 32'b0000_0000_0000_0000_0000_0000_0000_1100;
reg [31:0]t2   = 32'b0000_0000_0000_0000_0000_0000_1100_0000;
reg [31:0]t3   = 32'b0000_0000_0000_0000_0000_0000_0100_1100;
reg [31:0]t4   = 32'b0000_0000_0000_0000_0000_0000_0110_0000;
reg [31:0]t5   = 32'b0000_0000_0000_0000_0000_0000_0001_0100;
reg [31:0]t6   = 32'b0000_0000_0000_0000_0000_0000_0000_0100;
reg [31:0]t7   = 32'b0000_0000_0000_0000_0000_0000_0000_0110;
reg [31:0]s0   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]s1   = 32'b0000_0000_0000_0000_0000_0010_0011_0111;
reg [31:0]s2   = 32'b0000_0000_0000_0000_0000_0000_0001_0010;
reg [31:0]s3   = 32'b0000_0000_0000_0000_0000_0000_0100_1100;
reg [31:0]s4   = 32'b0000_0000_0000_0000_0000_0000_0110_1100;
reg [31:0]s5   = 32'b0000_0000_0000_0000_0000_0000_0001_0110;
reg [31:0]s6   = 32'b0000_0000_0000_0000_0000_0000_0000_1100;
reg [31:0]s7   = 32'b0000_0000_0000_0000_0000_0000_0000_0110;
reg [31:0]t8   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]t9   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]k0   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]k1   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]gp   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]sp   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]fp   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
reg [31:0]ra   = 32'b0000_0000_0000_0000_0000_0000_0000_0000;

always@(posedge CLK) begin
    PC_out <= PC;
    Instruction16_20_out <= Instruction[20:16];
    Instruction11_15_out <= Instruction[15:11];
    Instruction0_15_to_32_out <= Instruction0_15_to_32;
    
    ALUOp_out <= ALUOp_store;
    RegDst_out <= RegDst_store;
    Branch_out <= Branch_store;
    MemRead_out <= MemRead_store;
    MemtoReg_out <= MemtoReg_store;
    MemWrite_out <= MemWrite_store;
    ALUSrc_out <= ALUSrc_store;
    RegWrite_out <= RegWrite_store;
    
    ID_EX_Rt <= Instruction[20:16];
    ID_EX_Rs <= Instruction[25:21];
    
    Read_Data1_out <= Read_Data1;
    Read_Data2_out <= Read_Data2;
end




always@(Instruction) begin
    Readregsister1 = Instruction[25:21];
    Readregsister2 = Instruction[20:16];
end

always@(Instruction) begin 
    if(Instruction[15] == 0)begin
        Instruction0_15_to_32[31:16] <= 16'b0000_0000_0000_0000;
        Instruction0_15_to_32[15:0]  <= Instruction[15:0];
    end
    
    else if(Instruction[15] == 1)begin
        Instruction0_15_to_32[31:16] <= 16'b1111_1111_1111_1111;
        Instruction0_15_to_32[15:0]  <= Instruction[15:0];
    end
end

always@(negedge CLK) begin
    case(Readregsister1)
    5'b00000:Read_Data1 <= Zero; 
    5'b00001:Read_Data1 <= at; 
    5'b00010:Read_Data1 <= v0; 
    5'b00011:Read_Data1 <= v1; 
    5'b00100:Read_Data1 <= a0; 
    5'b00101:Read_Data1 <= a1; 
    5'b00110:Read_Data1 <= a2; 
    5'b00111:Read_Data1 <= a3; 
    5'b01000:Read_Data1 <= t0; 
    5'b01001:Read_Data1 <= t1; 
    5'b01010:Read_Data1 <= t2; 
    5'b01011:Read_Data1 <= t3; 
    5'b01100:Read_Data1 <= t4; 
    5'b01101:Read_Data1 <= t5; 
    5'b01110:Read_Data1 <= t6; 
    5'b01111:Read_Data1 <= t7; 
    5'b10000:Read_Data1 <= s0; 
    5'b10001:Read_Data1 <= s1; 
    5'b10010:Read_Data1 <= s2; 
    5'b10011:Read_Data1 <= s3; 
    5'b10100:Read_Data1 <= s4; 
    5'b10101:Read_Data1 <= s5; 
    5'b10110:Read_Data1 <= s6; 
    5'b10111:Read_Data1 <= s7; 
    5'b11000:Read_Data1 <= t8; 
    5'b11001:Read_Data1 <= t9; 
    5'b11010:Read_Data1 <= k0; 
    5'b11011:Read_Data1 <= k1; 
    5'b11100:Read_Data1 <= gp; 
    5'b11101:Read_Data1 <= sp; 
    5'b11110:Read_Data1 <= fp; 
    5'b11111:Read_Data1 <= ra; 
    endcase
end
always@(*) begin
    if(RegWrite == 1'b0) begin
        case(WriteReg)
        5'b00000:Zero <= Zero; 
        5'b00001:at <= at; 
        5'b00010:v0 <= v0; 
        5'b00011:v1 <= v1; 
        5'b00100:a0 <= a0; 
        5'b00101:a1 <= a1; 
        5'b00110:a2 <= a2; 
        5'b00111:a3 <= a3; 
        5'b01000:t0 <= t0; 
        5'b01001:t1 <= t1; 
        5'b01010:t2 <= t2; 
        5'b01011:t3 <= t3; 
        5'b01100:t4 <= t4; 
        5'b01101:t5 <= t5; 
        5'b01110:t6 <= t6; 
        5'b01111:t7 <= t7; 
        5'b10000:s0 <= s0; 
        5'b10001:s1 <= s1; 
        5'b10010:s2 <= s2; 
        5'b10011:s3 <= s3; 
        5'b10100:s4 <= s4; 
        5'b10101:s5 <= s5; 
        5'b10110:s6 <= s6; 
        5'b10111:s7 <= s7; 
        5'b11000:t8 <= t8; 
        5'b11001:t9 <= t9; 
        5'b11010:k0 <= k0; 
        5'b11011:k1 <= k1; 
        5'b11100:gp <= gp; 
        5'b11101:sp <= sp; 
        5'b11110:fp <= fp; 
        5'b11111:ra <= ra; 
        endcase
    end
    else if(RegWrite == 1'b1) begin
        case(WriteReg)
        5'b00000:Zero <= Writedata; 
        5'b00001:at <= Writedata; 
        5'b00010:v0 <= Writedata; 
        5'b00011:v1 <= Writedata; 
        5'b00100:a0 <= Writedata; 
        5'b00101:a1 <= Writedata; 
        5'b00110:a2 <= Writedata; 
        5'b00111:a3 <= Writedata; 
        5'b01000:t0 <= Writedata; 
        5'b01001:t1 <= Writedata; 
        5'b01010:t2 <= Writedata; 
        5'b01011:t3 <= Writedata; 
        5'b01100:t4 <= Writedata; 
        5'b01101:t5 <= Writedata; 
        5'b01110:t6 <= Writedata; 
        5'b01111:t7 <= Writedata; 
        5'b10000:s0 <= Writedata; 
        5'b10001:s1 <= Writedata; 
        5'b10010:s2 <= Writedata; 
        5'b10011:s3 <= Writedata; 
        5'b10100:s4 <= Writedata; 
        5'b10101:s5 <= Writedata; 
        5'b10110:s6 <= Writedata; 
        5'b10111:s7 <= Writedata; 
        5'b11000:t8 <= Writedata; 
        5'b11001:t9 <= Writedata; 
        5'b11010:k0 <= Writedata; 
        5'b11011:k1 <= Writedata; 
        5'b11100:gp <= Writedata; 
        5'b11101:sp <= Writedata; 
        5'b11110:fp <= Writedata; 
        5'b11111:ra <= Writedata; 
        endcase
    end
end
always@(Instruction or Control_Slt) begin 
    if(Control_Slt == 0) begin
        ALUOp_store <= 2'b00;
        RegDst_store <= 1'b0;
        Branch_store <= 1'b0;
        MemRead_store <= 1'b0;
        MemtoReg_store <= 1'b0;
        MemWrite_store <= 1'b0;
        ALUSrc_store <= 1'b0;
        RegWrite_store <= 1'b0;
    end
    else if(Control_Slt == 1) begin
        if(Instruction[31:26] == 6'b000000) begin 
            if(Instruction == 0) begin
                ALUOp_store <= 2'b00;
                RegDst_store <= 1'b0;
                Branch_store <= 1'b0;
                MemRead_store <= 1'b0;
                MemtoReg_store <= 1'b0;
                MemWrite_store <= 1'b0;
                ALUSrc_store <= 1'b0;
                RegWrite_store <= 1'b0;
            end
            else begin
                ALUOp_store <= 2'b10;
                RegDst_store <= 1'b1;
                Branch_store <= 1'b0;
                MemRead_store <= 1'b0;
                MemtoReg_store <= 1'b1;
                MemWrite_store <= 1'b0;
                ALUSrc_store <= 1'b0;
                RegWrite_store <= 1'b1;
            end
        end
    
        else if(Instruction[31:26] == 6'b100011) begin 
            ALUOp_store <= 2'b00;
            RegDst_store <= 1'b0;
            Branch_store <= 1'b0;
            MemRead_store <= 1'b1;
            MemtoReg_store <= 1'b0;
            MemWrite_store <= 1'b0;
            ALUSrc_store <= 1'b1;
            RegWrite_store <= 1'b1;
        end
    
        else if(Instruction[31:26] == 6'b101011) begin 
            ALUOp_store <= 2'b00;
            RegDst_store <= 1'b0; 
            Branch_store <= 1'b0;
            MemRead_store <= 1'b0;
            MemtoReg_store <= 1'b0; 
            MemWrite_store <= 1'b1;
            ALUSrc_store <= 1'b1;
            RegWrite_store <= 1'b0;
        end
    
        else if(Instruction[31:26] == 6'b001000) begin 
            ALUOp_store <= 2'b00;
            RegDst_store <= 1'b0;
            Branch_store <= 1'b0;
            MemRead_store <= 1'b0;
            MemtoReg_store <= 1'b0;
            MemWrite_store <= 1'b0;
            ALUSrc_store <= 1'b1;
            RegWrite_store <= 1'b1;
        end
    
        else if(Instruction[31:26] == 6'b000100) begin 
            ALUOp_store <= 2'b01;
            RegDst_store <= 1'b0;
            Branch_store <= 1'b1;
            MemRead_store <= 1'b0;
            MemtoReg_store <= 1'b0;
            MemWrite_store <= 1'b0;
            ALUSrc_store <= 1'b0;
            RegWrite_store <= 1'b0;
        end
    end
end



always@(negedge CLK) begin
    case(Readregsister2)
    5'b00000:Read_Data2 <= Zero; 
    5'b00001:Read_Data2 <= at; 
    5'b00010:Read_Data2 <= v0; 
    5'b00011:Read_Data2 <= v1; 
    5'b00100:Read_Data2 <= a0; 
    5'b00101:Read_Data2 <= a1; 
    5'b00110:Read_Data2 <= a2; 
    5'b00111:Read_Data2 <= a3; 
    5'b01000:Read_Data2 <= t0; 
    5'b01001:Read_Data2 <= t1; 
    5'b01010:Read_Data2 <= t2; 
    5'b01011:Read_Data2 <= t3; 
    5'b01100:Read_Data2 <= t4; 
    5'b01101:Read_Data2 <= t5; 
    5'b01110:Read_Data2 <= t6; 
    5'b01111:Read_Data2 <= t7; 
    5'b10000:Read_Data2 <= s0; 
    5'b10001:Read_Data2 <= s1; 
    5'b10010:Read_Data2 <= s2; 
    5'b10011:Read_Data2 <= s3; 
    5'b10100:Read_Data2 <= s4; 
    5'b10101:Read_Data2 <= s5; 
    5'b10110:Read_Data2 <= s6; 
    5'b10111:Read_Data2 <= s7; 
    5'b11000:Read_Data2 <= t8; 
    5'b11001:Read_Data2 <= t9; 
    5'b11010:Read_Data2 <= k0; 
    5'b11011:Read_Data2 <= k1; 
    5'b11100:Read_Data2 <= gp; 
    5'b11101:Read_Data2 <= sp; 
    5'b11110:Read_Data2 <= sp; 
    5'b11111:Read_Data2 <= ra; 
    endcase
end





endmodule
