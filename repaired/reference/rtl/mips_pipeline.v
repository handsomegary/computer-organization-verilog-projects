`timescale 1ns/1ps
// Five stages: IF, ID, EX, MEM, WB. HAZARD_ENABLE=0 is level B, whose
// programs must schedule RAW dependencies. HAZARD_ENABLE=1 is level C.
// Branch and jump resolve in EX and squash both younger instructions.
module mips_pipeline #(parameter HAZARD_ENABLE=1, IMEM_WORDS=1024, DMEM_WORDS=1024)
    (input clk, input reset, output reg [31:0] pc, output stall);
    reg [31:0] regs [0:31];
    reg [31:0] imem [0:IMEM_WORDS-1];
    reg [31:0] dmem [0:DMEM_WORDS-1];
    integer i;
    initial begin
        pc=0;
        for(i=0;i<32;i=i+1) regs[i]=0;
        for(i=0;i<IMEM_WORDS;i=i+1) imem[i]=0;
        for(i=0;i<DMEM_WORDS;i=i+1) dmem[i]=0;
        if(IMEM_WORDS>52) begin
            imem[0]=32'h2001000c;
            imem[4]=32'h2002fffc;
            imem[8]=32'h00221820;
            imem[12]=32'h00222022;
            imem[16]=32'h00232824;
            imem[20]=32'h00643025;
            imem[24]=32'h0041382a;
            imem[28]=32'hac060190;
            imem[32]=32'h8c080190;
            imem[36]=32'h11060007;
            imem[40]=32'h20090063;
            imem[44]=32'h08000034;
            imem[48]=32'h20090058;
            imem[52]=32'h20090007;
        end
    end
    localparam A_AND=3'd0, A_OR=3'd1, A_ADD=3'd2, A_SUB=3'd3, A_SLT=3'd4;
    reg if_id_valid;
    reg [31:0] if_id_ins, if_id_pc4;
    reg id_ex_valid, id_ex_regwrite, id_ex_memread, id_ex_memwrite;
    reg id_ex_memtoreg, id_ex_alusrc, id_ex_branch, id_ex_jump;
    reg [2:0] id_ex_alu;
    reg [4:0] id_ex_rs, id_ex_rt, id_ex_dest;
    reg [31:0] id_ex_a, id_ex_b, id_ex_immediate, id_ex_pc4, id_ex_jump_target;
    reg ex_mem_valid, ex_mem_regwrite, ex_mem_memread, ex_mem_memwrite, ex_mem_memtoreg;
    reg [4:0] ex_mem_dest;
    reg [31:0] ex_mem_result, ex_mem_store;
    reg mem_wb_valid, mem_wb_regwrite, mem_wb_memtoreg;
    reg [4:0] mem_wb_dest;
    reg [31:0] mem_wb_result, mem_wb_load;
    wire [31:0] wb_value=mem_wb_memtoreg ? mem_wb_load : mem_wb_result;
    wire wb_enable=mem_wb_valid && mem_wb_regwrite && mem_wb_dest!=0;

    reg dec_legal, dec_regwrite, dec_memread, dec_memwrite, dec_memtoreg;
    reg dec_alusrc, dec_branch, dec_jump, dec_use_rs, dec_use_rt;
    reg [2:0] dec_alu;
    reg [4:0] dec_dest;
    wire [4:0] dec_rs=if_id_ins[25:21], dec_rt=if_id_ins[20:16];
    wire [31:0] dec_immediate={{16{if_id_ins[15]}},if_id_ins[15:0]};
    // WB-to-ID bypass defines same-edge register writes independently of
    // simulator scheduling and is present in both pipeline levels.
    wire [31:0] dec_a = dec_rs==0 ? 32'b0 :
        ((wb_enable && mem_wb_dest==dec_rs) ? wb_value : regs[dec_rs]);
    wire [31:0] dec_b = dec_rt==0 ? 32'b0 :
        ((wb_enable && mem_wb_dest==dec_rt) ? wb_value : regs[dec_rt]);
    always @* begin
        dec_legal=1; dec_regwrite=0; dec_memread=0; dec_memwrite=0;
        dec_memtoreg=0; dec_alusrc=0; dec_branch=0; dec_jump=0;
        dec_use_rs=0; dec_use_rt=0; dec_alu=A_ADD; dec_dest=dec_rt;
        case(if_id_ins[31:26])
            6'h00: begin
                dec_dest=if_id_ins[15:11]; dec_use_rs=1; dec_use_rt=1;
                dec_regwrite=1;
                case(if_id_ins[5:0])
                    6'h20: dec_alu=A_ADD;
                    6'h22: dec_alu=A_SUB;
                    6'h24: dec_alu=A_AND;
                    6'h25: dec_alu=A_OR;
                    6'h2a: dec_alu=A_SLT;
                    default: begin dec_legal=0;dec_regwrite=0;dec_use_rs=0;dec_use_rt=0;end
                endcase
            end
            6'h08: begin dec_regwrite=1;dec_alusrc=1;dec_use_rs=1;end
            6'h23: begin dec_regwrite=1;dec_memread=1;dec_memtoreg=1;dec_alusrc=1;dec_use_rs=1;end
            6'h2b: begin dec_memwrite=1;dec_alusrc=1;dec_use_rs=1;dec_use_rt=1;end
            6'h04: begin dec_branch=1;dec_use_rs=1;dec_use_rt=1;dec_alu=A_SUB;end
            6'h02: dec_jump=1;
            default: dec_legal=0;
        endcase
    end
    reg [31:0] ex_a, ex_register_b, ex_result;
    wire [31:0] ex_b=id_ex_alusrc ? id_ex_immediate : ex_register_b;
    always @* begin
        ex_a=id_ex_a; ex_register_b=id_ex_b;
        if(HAZARD_ENABLE) begin
            if(ex_mem_valid && ex_mem_regwrite && !ex_mem_memread &&
               ex_mem_dest!=0 && ex_mem_dest==id_ex_rs) ex_a=ex_mem_result;
            else if(wb_enable && mem_wb_dest==id_ex_rs) ex_a=wb_value;
            if(ex_mem_valid && ex_mem_regwrite && !ex_mem_memread &&
               ex_mem_dest!=0 && ex_mem_dest==id_ex_rt) ex_register_b=ex_mem_result;
            else if(wb_enable && mem_wb_dest==id_ex_rt) ex_register_b=wb_value;
        end
        case(id_ex_alu)
            A_AND: ex_result=ex_a&ex_b;
            A_OR: ex_result=ex_a|ex_b;
            A_ADD: ex_result=ex_a+ex_b;
            A_SUB: ex_result=ex_a-ex_b;
            A_SLT: ex_result=($signed(ex_a)<$signed(ex_b)) ? 32'd1 : 32'd0;
            default: ex_result=0;
        endcase
    end
    wire redirect=id_ex_valid && (id_ex_jump || (id_ex_branch && ex_a==ex_register_b));
    wire [31:0] redirect_target=id_ex_jump ? id_ex_jump_target : id_ex_pc4+(id_ex_immediate<<2);
    wire load_use=HAZARD_ENABLE && id_ex_valid && id_ex_memread && id_ex_dest!=0 &&
        if_id_valid && ((dec_use_rs && dec_rs==id_ex_dest) || (dec_use_rt && dec_rt==id_ex_dest));
    assign stall=!reset && !redirect && load_use;
    wire [31:0] fetch=(pc[1:0]==0 && pc[31:2]<IMEM_WORDS) ? imem[pc[31:2]] : 32'b0;
    wire mem_address_valid=ex_mem_result[1:0]==0 && ex_mem_result[31:2]<DMEM_WORDS;
    wire [31:0] memory_value=(ex_mem_valid && ex_mem_memread && mem_address_valid) ?
        dmem[ex_mem_result[31:2]] : 32'b0;

    always @(posedge clk) begin
        if(reset) begin
            pc<=0; if_id_valid<=0; if_id_ins<=0; if_id_pc4<=0;
            id_ex_valid<=0;id_ex_regwrite<=0;id_ex_memread<=0;id_ex_memwrite<=0;
            id_ex_memtoreg<=0;id_ex_alusrc<=0;id_ex_branch<=0;id_ex_jump<=0;
            id_ex_alu<=A_ADD;id_ex_rs<=0;id_ex_rt<=0;id_ex_dest<=0;
            id_ex_a<=0;id_ex_b<=0;id_ex_immediate<=0;id_ex_pc4<=0;id_ex_jump_target<=0;
            ex_mem_valid<=0;ex_mem_regwrite<=0;ex_mem_memread<=0;ex_mem_memwrite<=0;
            ex_mem_memtoreg<=0;ex_mem_dest<=0;ex_mem_result<=0;ex_mem_store<=0;
            mem_wb_valid<=0;mem_wb_regwrite<=0;mem_wb_memtoreg<=0;
            mem_wb_dest<=0;mem_wb_result<=0;mem_wb_load<=0;
            for(i=0;i<32;i=i+1) regs[i]<=0;
        end else begin
            regs[0]<=0;
            if(wb_enable) regs[mem_wb_dest]<=wb_value;
            if(ex_mem_valid && ex_mem_memwrite && mem_address_valid)
                dmem[ex_mem_result[31:2]]<=ex_mem_store;
            mem_wb_valid<=ex_mem_valid;
            mem_wb_regwrite<=ex_mem_regwrite;
            mem_wb_memtoreg<=ex_mem_memtoreg;
            mem_wb_dest<=ex_mem_dest;mem_wb_result<=ex_mem_result;mem_wb_load<=memory_value;
            ex_mem_valid<=id_ex_valid;
            ex_mem_regwrite<=id_ex_regwrite;ex_mem_memread<=id_ex_memread;
            ex_mem_memwrite<=id_ex_memwrite;ex_mem_memtoreg<=id_ex_memtoreg;
            ex_mem_dest<=id_ex_dest;ex_mem_result<=ex_result;ex_mem_store<=ex_register_b;
            if(redirect) begin
                pc<=redirect_target;
                if_id_valid<=0; if_id_ins<=0;
                id_ex_valid<=0;
            end else if(load_use) begin
                // Hold PC and IF/ID, inject a bubble, advance older stages.
                id_ex_valid<=0;
            end else begin
                pc<=pc+32'd4; if_id_valid<=1; if_id_ins<=fetch; if_id_pc4<=pc+32'd4;
                id_ex_valid<=if_id_valid && dec_legal;
                id_ex_regwrite<=dec_regwrite;id_ex_memread<=dec_memread;
                id_ex_memwrite<=dec_memwrite;id_ex_memtoreg<=dec_memtoreg;
                id_ex_alusrc<=dec_alusrc;id_ex_branch<=dec_branch;id_ex_jump<=dec_jump;
                id_ex_alu<=dec_alu;id_ex_rs<=dec_rs;id_ex_rt<=dec_rt;id_ex_dest<=dec_dest;
                id_ex_a<=dec_a;id_ex_b<=dec_b;id_ex_immediate<=dec_immediate;
                id_ex_pc4<=if_id_pc4;
                id_ex_jump_target<={if_id_pc4[31:28],if_id_ins[25:0],2'b00};
            end
        end
    end
endmodule
