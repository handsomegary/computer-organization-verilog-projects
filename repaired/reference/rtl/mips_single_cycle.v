`timescale 1ns/1ps
// Assignment ISA: lw, sw, add, addi, sub, and, or, slt, beq, j.
// Byte addresses, signed immediates/SLT, no branch delay slot. Reset clears
// architectural registers and PC; data memory survives reset.
module mips_single_cycle #(parameter IMEM_WORDS=1024, DMEM_WORDS=1024)
    (input clk, input reset, output reg [31:0] pc);
    reg [31:0] regs [0:31];
    reg [31:0] imem [0:IMEM_WORDS-1];
    reg [31:0] dmem [0:DMEM_WORDS-1];
    integer i;
    initial begin
        pc=0;
        for(i=0;i<32;i=i+1) regs[i]=0;
        for(i=0;i<IMEM_WORDS;i=i+1) imem[i]=0;
        for(i=0;i<DMEM_WORDS;i=i+1) dmem[i]=0;
        // The bundled program is also safe for the level-B scheduled pipeline.
        if(IMEM_WORDS>52) begin
            imem[0]=32'h2001000c;  // addi r1,r0,12
            imem[4]=32'h2002fffc;  // addi r2,r0,-4
            imem[8]=32'h00221820;  // add r3,r1,r2
            imem[12]=32'h00222022; // sub r4,r1,r2
            imem[16]=32'h00232824; // and r5,r1,r3
            imem[20]=32'h00643025; // or r6,r3,r4
            imem[24]=32'h0041382a; // slt r7,r2,r1
            imem[28]=32'hac060190; // sw r6,400(r0)
            imem[32]=32'h8c080190; // lw r8,400(r0)
            imem[36]=32'h11060007; // beq r8,r6,word44
            imem[40]=32'h20090063; // skipped
            imem[44]=32'h08000034; // j word52
            imem[48]=32'h20090058; // skipped
            imem[52]=32'h20090007; // addi r9,r0,7
        end
    end
    wire [31:0] ins = (pc[1:0]==0 && pc[31:2]<IMEM_WORDS) ? imem[pc[31:2]] : 32'b0;
    wire [31:0] a = ins[25:21]==0 ? 32'b0 : regs[ins[25:21]];
    wire [31:0] b = ins[20:16]==0 ? 32'b0 : regs[ins[20:16]];
    wire [31:0] immediate = {{16{ins[15]}},ins[15:0]};
    wire [31:0] pc4=pc+32'd4;
    reg [31:0] next_pc, result, address;
    reg [4:0] destination;
    reg write_register, write_memory;
    always @* begin
        next_pc=pc4; result=0; address=a+immediate;
        destination=ins[20:16]; write_register=0; write_memory=0;
        case(ins[31:26])
            6'h00: begin
                destination=ins[15:11];
                case(ins[5:0])
                    6'h20: begin result=a+b; write_register=1; end
                    6'h22: begin result=a-b; write_register=1; end
                    6'h24: begin result=a&b; write_register=1; end
                    6'h25: begin result=a|b; write_register=1; end
                    6'h2a: begin result=($signed(a)<$signed(b)) ? 32'd1 : 32'd0; write_register=1; end
                    default: begin end // all-zero instruction is a NOP
                endcase
            end
            6'h08: begin result=address; write_register=1; end
            6'h23: begin
                result=(address[1:0]==0 && address[31:2]<DMEM_WORDS) ? dmem[address[31:2]] : 32'b0;
                write_register=1;
            end
            6'h2b: write_memory=1;
            6'h04: if(a==b) next_pc=pc4+(immediate<<2);
            6'h02: next_pc={pc4[31:28],ins[25:0],2'b00};
            default: begin end
        endcase
    end
    always @(posedge clk) begin
        if(reset) begin
            pc<=0;
            for(i=0;i<32;i=i+1) regs[i]<=0;
        end else begin
            pc<=next_pc;
            if(write_register && destination!=0) regs[destination]<=result;
            if(write_memory && address[1:0]==0 && address[31:2]<DMEM_WORDS)
                dmem[address[31:2]]<=b;
            regs[0]<=0;
        end
    end
endmodule
