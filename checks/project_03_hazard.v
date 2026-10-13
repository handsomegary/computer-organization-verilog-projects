`timescale 1ns / 1ps

// Audit adapter for the unchanged hazard RTL. No waveform or external data files.
// Compile this top and rtl/*.v only; exclude the archived tb/TB.v.
// Icarus compatibility for Reg.v's legacy scalar-port/vector-reg declarations:
// -g2012 -gno-io-range-error (also record the strict elaboration diagnostic).
// FAIL observations describe RTL behavior; this audit completes all cases normally.
module audit_hazard_tb;
    integer passed = 0, failed = 0;
    integer scenario = 0, stall_count = 0;
    reg cpu_clk = 0;
    reg [31:0] injected_instruction;
    CPU dut(.CLK(cpu_clk));

    function [31:0] r_ins;
        input [4:0] rs, rt, rd;
        input [5:0] fn;
        begin r_ins = {6'b000000, rs, rt, rd, 5'b00000, fn}; end
    endfunction
    function [31:0] i_ins;
        input [5:0] op;
        input [4:0] rs, rt;
        input [15:0] imm;
        begin i_ins = {op, rs, rt, imm}; end
    endfunction

    task observe;
        input [255:0] id;
        input [31:0] expected, actual;
        begin
            if (actual === expected) begin
                passed = passed + 1;
                $display("OBS %0s expected=%08h actual=%08h status=PASS", id, expected, actual);
            end else begin
                failed = failed + 1;
                $display("OBS %0s expected=%08h actual=%08h status=FAIL", id, expected, actual);
            end
        end
    endtask

    // The archived PC ROM is fixed to four different instructions. This fixture
    // replaces only its internal combinational instruction value, leaving its
    // original PC / IF-ID pipeline / stall / writeback logic active.
    always @(*) begin
        // Identity OR is within the required ISA, unlike a zero/sll filler.
        injected_instruction = r_ins(31, 31, 31, 6'h25);
        case (scenario)
            1: case (dut.block1.pc)
                16: injected_instruction = r_ins(1, 3, 2, 6'h22);
                20: injected_instruction = r_ins(2, 5, 12, 6'h24);
                24: injected_instruction = r_ins(6, 2, 13, 6'h25);
                28: injected_instruction = r_ins(2, 2, 14, 6'h20);
                32: injected_instruction = i_ins(6'h2b, 2, 15, 16'd100);
            endcase
            2: case (dut.block1.pc)
                16: injected_instruction = i_ins(6'h23, 1, 2, 16'd0);
                20: injected_instruction = r_ins(2, 5, 12, 6'h20);
            endcase
            3: case (dut.block1.pc)
                16: injected_instruction = r_ins(1, 3, 2, 6'h22);
                // New store datum equals the offset, isolating the missing
                // store-data bypass from the separate ALU offset mux defect.
                20: injected_instruction = i_ins(6'h2b, 6, 2, 16'd12);
            endcase
            4: case (dut.block1.pc)
                16: injected_instruction = r_ins(1, 3, 8, 6'h20);
                20: injected_instruction = r_ins(1, 3, 2, 6'h22);
                24: injected_instruction = r_ins(2, 8, 12, 6'h24);
            endcase
            5: case (dut.block1.pc)
                16: injected_instruction = i_ins(6'h08, 1, 2, 16'hfffc);
            endcase
        endcase
    end
    always @(posedge cpu_clk)
        if (scenario == 2 && dut.IF_ID_Write === 1'b0)
            stall_count = stall_count + 1;

    task cpu_tick;
        begin cpu_clk = 0; #5; cpu_clk = 1; #5; cpu_clk = 0; #5; end
    endtask

    // Testbench seeding is explicit because the original CPU has no reset port.
    // Hierarchy field names below are the source's storage names. All instruction
    // operands and expected results use numeric register IDs, not course aliases.
    task core_fixture;
        input integer program_id;
        begin
            cpu_clk = 0;
            scenario = program_id;
            stall_count = 0;
            dut.block1.pc = 32'hfffffffc;
            dut.block1.pc4 = 0;
            dut.block1.npc = 0;
            dut.block1.pcout = 0;
            dut.block1.insout = 0;
            #2;
            repeat (5) cpu_tick;
            dut.block2.Zero = 0;
            dut.block2.ra = 0;      // numeric register31, identity-OR filler
            dut.block2.at = 20;     // numeric register 1
            dut.block2.v0 = 0;      // numeric register 2
            dut.block2.v1 = 8;      // numeric register 3
            dut.block2.a1 = 15;     // numeric register 5
            dut.block2.a2 = 160;    // numeric register 6
            dut.block2.t0 = 0;      // numeric register 8
            dut.block2.t4 = 0;      // numeric register 12
            dut.block2.t5 = 0;      // numeric register 13
            dut.block2.t6 = 0;      // numeric register 14
            dut.block2.t7 = 32'hcafebabe; // numeric register 15
            dut.block5.tempaddr0 = 0; dut.block5.tempaddr1 = 0;
            dut.block5.tempaddr2 = 0; dut.block5.tempaddr3 = 0;
            dut.block5.tempaddr4 = 0; dut.block5.tempaddr5 = 0;
            dut.block5.memory0 = 0; dut.block5.memory1 = 0;
            dut.block5.memory2 = 0; dut.block5.memory3 = 0;
            dut.block5.memory4 = 0; dut.block5.memory5 = 0;
            dut.block5.read_data = 0;
            if (program_id == 2) begin
                dut.block2.at = 16;
                dut.block2.a1 = 3;
                dut.block5.tempaddr0 = 16;
                dut.block5.memory0 = 21;
            end
            #2;
        end
    endtask

    reg [31:0] alu_a = 0, alu_b = 0, alu_imm = 0, alu_pc = 0;
    reg [31:0] alu_ex = 0, alu_wb = 0;
    reg [1:0] alu_op = 2, alu_f1 = 0, alu_f2 = 0;
    reg alu_src = 0, alu_dst = 1;
    reg [4:0] alu_rt = 2, alu_rd = 12;
    wire [31:0] alu_result, alu_branch;
    wire alu_zero;
    wire [4:0] alu_write_reg;
    ALU unit_alu(.ALUresult(alu_result), .ALUop(alu_op), .address(alu_imm),
        .readdata1(alu_a), .readdata2(alu_b), .Zero(alu_zero), .ALUsrc(alu_src),
        .branch_PC(alu_branch), .PC(alu_pc), .regdst(alu_dst),
        .Rt(alu_rt), .Rd(alu_rd), .writereg(alu_write_reg),
        .EX_MEM_DATA(alu_ex), .MEM_WB_DATA(alu_wb), .Forward1(alu_f1), .Forward2(alu_f2));

    reg reg_clk = 0, reg_wb = 0, reg_control = 1;
    reg [31:0] reg_instruction = 0, reg_pc = 32'h104, reg_wdata = 0;
    reg [4:0] reg_wdest = 1;
    wire [31:0] reg_data1, reg_data2, reg_pc_out, reg_imm;
    wire [4:0] reg_rt, reg_rd, reg_source_rs, reg_source_rt;
    wire reg_dst, reg_branch, reg_memread, reg_memtoreg, reg_memwrite, reg_alusrc, reg_write;
    wire [1:0] reg_aluop;
    Reg unit_reg(.Instruction(reg_instruction), .CLK(reg_clk), .RegWrite(reg_wb),
        .WriteReg(reg_wdest), .Writedata(reg_wdata), .PC(reg_pc),
        .Read_Data1_out(reg_data1), .Read_Data2_out(reg_data2), .PC_out(reg_pc_out),
        .Instruction16_20_out(reg_rt), .Instruction11_15_out(reg_rd),
        .Instruction0_15_to_32_out(reg_imm), .RegDst_out(reg_dst),
        .Branch_out(reg_branch), .MemRead_out(reg_memread), .MemtoReg_out(reg_memtoreg),
        .ALUOp_out(reg_aluop), .MemWrite_out(reg_memwrite), .ALUSrc_out(reg_alusrc),
        .RegWrite_out(reg_write), .ID_EX_Rt(reg_source_rt), .ID_EX_Rs(reg_source_rs),
        .Control_Slt(reg_control));

    task decode_tick;
        begin reg_clk = 1; #2; reg_clk = 0; #2; reg_clk = 1; #2; end
    endtask

    reg mem_clk = 0, mem_write = 0, mem_read = 0;
    reg [31:0] mem_address = 0, mem_data = 0;
    wire [31:0] mem_readback, mem_address_out;
    wire mem_pcsrc, mem_wb_out, mem_mux_out;
    wire [4:0] mem_dest_out;
    Dmemory unit_mem(.addr(mem_address), .write_data(mem_data), .memwrite(mem_write),
        .memread(mem_read), .clk(mem_clk), .write_back(1'b0), .mem_to_reg(1'b0),
        .write_reg(5'd1), .read_data1(mem_readback), .addr1(mem_address_out),
        .m(1'b0), .zero(1'b0), .PCsrc(mem_pcsrc), .write_reg1(mem_dest_out),
        .write_back1(mem_wb_out), .mem_to_reg1(mem_mux_out));

    task memory_clear;
        begin
            mem_write = 0; mem_read = 0; #2;
            unit_mem.tempaddr0 = 0; unit_mem.tempaddr1 = 0;
            unit_mem.tempaddr2 = 0; unit_mem.tempaddr3 = 0;
            unit_mem.tempaddr4 = 0; unit_mem.tempaddr5 = 0;
            unit_mem.memory0 = 0; unit_mem.memory1 = 0;
            unit_mem.memory2 = 0; unit_mem.memory3 = 0;
            unit_mem.memory4 = 0; unit_mem.memory5 = 0;
            unit_mem.read_data = 0;
        end
    endtask
    task memory_tick;
        begin mem_clk = 1; #2; mem_clk = 0; #2; end
    endtask

    reg probe_ex_write = 0, probe_wb_write = 0, probe_load = 0;
    reg [4:0] probe_ex_dest = 1, probe_wb_dest = 1, probe_rs = 1, probe_rt = 1;
    reg [31:0] probe_instruction = 0;

    initial begin
        force dut.block1.ins = injected_instruction;
        #2;

        alu_a = 20; alu_b = 8; alu_imm = 6'h20; #2;
        observe("alu_add", 28, alu_result);
        alu_imm = 6'h22; #2; observe("alu_sub", 12, alu_result);
        alu_a = 3; alu_b = 5; alu_imm = 6'h24; #2;
        observe("alu_and", 1, alu_result);
        alu_imm = 6'h25; #2; observe("alu_or", 7, alu_result);
        alu_a = 1; alu_b = 2; alu_imm = 6'h2a; #2;
        observe("slt_true_is_one", 1, alu_result);
        alu_a = 32'hffffffff; alu_b = 0; #2;
        observe("slt_negative_lt_zero", 1, alu_result);
        alu_a = 0; alu_b = 32'hffffffff; #2;
        observe("slt_zero_lt_negative", 0, alu_result);
        alu_a = 20; alu_op = 0; alu_src = 1; alu_imm = 32'hfffffffc; #2;
        observe("alu_addi_negative", 16, alu_result);
        alu_imm = 4; alu_ex = 12; alu_f2 = 2; #2;
        observe("store_offset_with_rt_bypass", 24, alu_result);
        alu_f2 = 0; alu_src = 0; alu_op = 1; alu_a = 12; alu_b = 12;
        alu_imm = 32'hfffffffe; alu_pc = 32'h104; #2;
        observe("branch_equal_zero", 1, {31'b0, alu_zero});
        observe("branch_pc_signed_offset", 32'hfc, alu_branch);

        unit_reg.Zero = 0; unit_reg.at = 20;
        reg_instruction = i_ins(6'h08, 1, 2, 16'hfffc); #2; decode_tick;
        observe("decode_sign_extend", 32'hfffffffc, reg_imm);
        // This RTL uses MemtoReg=1 for ALU and =0 for memory. lw/R-type
        // are internally consistent; addi should select the ALU convention.
        observe("decode_addi_alu_writeback", 1, {31'b0, reg_memtoreg});
        reg_instruction = i_ins(6'h23, 1, 2, 16'd0); #2; decode_tick;
        observe("decode_lw_memory_select", 0, {31'b0, reg_memtoreg});
        observe("decode_lw_read_enable", 1, {31'b0, reg_memread});
        reg_instruction = r_ins(1, 3, 12, 6'h20); reg_control = 0; #2; decode_tick;
        observe("load_use_bubble_controls", 0,
                {29'b0, reg_write, reg_memwrite, reg_memread});
        reg_control = 1;
        reg_instruction = i_ins(6'h08, 1, 2, 16'd7); #2; decode_tick;
        reg_instruction = {6'h02, 26'd8}; #2; decode_tick;
        observe("decode_jump_disables_regwrite", 0, {31'b0, reg_write});
        unit_reg.fp = 32'haa55; unit_reg.sp = 32'h55aa;
        reg_instruction = r_ins(1, 30, 12, 6'h20); #2; decode_tick;
        observe("register_30_second_read", 32'haa55, reg_data2);

        // Probe the original CPU forwarding/hazard always blocks directly.
        // Independent expected selector values: 00=register, 10=EX/MEM,
        // 01=MEM/WB. Each source must choose independently.
        force dut.write_back = probe_ex_write;
        force dut.write_reg = probe_ex_dest;
        force dut.RegWrite = probe_wb_write;
        force dut.WriteReg = probe_wb_dest;
        force dut.ID_EX_Rs = probe_rs;
        force dut.ID_EX_Rt = probe_rt;
        force dut.MemRead = probe_load;
        force dut.Instruction = probe_instruction;
        probe_ex_write = 1; probe_ex_dest = 2;
        probe_wb_write = 1; probe_wb_dest = 8;
        probe_rs = 2; probe_rt = 8; #2;
        observe("mixed_forward_rs_ex_rt_wb", 9, {28'b0, dut.Forward1, dut.Forward2});
        probe_rs = 8; probe_rt = 2; #2;
        observe("mixed_forward_rs_wb_rt_ex", 6, {28'b0, dut.Forward1, dut.Forward2});
        probe_rs = 2; probe_rt = 2; probe_wb_dest = 2; #2;
        observe("newest_forward_wins_both", 10, {28'b0, dut.Forward1, dut.Forward2});
        probe_ex_dest = 9; #2;
        observe("wb_forward_both_sources", 5, {28'b0, dut.Forward1, dut.Forward2});
        probe_load = 1; probe_rt = 2;
        probe_instruction = r_ins(2, 5, 12, 6'h20); #2;
        observe("load_use_stall_controls", 0,
                {29'b0, dut.IF_ID_Write, dut.PC_Write, dut.Control_Slt});
        // addi's rt is a destination, so this is a performance false stall,
        // not a direct numerical ISA-failure assertion.
        probe_instruction = i_ins(6'h08, 1, 2, 16'd7); #2;
        observe("load_then_overwrite_false_stall", 7,
                {29'b0, dut.IF_ID_Write, dut.PC_Write, dut.Control_Slt});
        release dut.write_back; release dut.write_reg;
        release dut.RegWrite; release dut.WriteReg;
        release dut.ID_EX_Rs; release dut.ID_EX_Rt;
        release dut.MemRead; release dut.Instruction;
        #2;

        memory_clear;
        mem_address = 4; mem_data = 11; mem_write = 1; #2;
        mem_write = 0; mem_read = 1; #2; memory_tick;
        observe("memory_initial_sw_lw", 11, mem_readback);
        memory_clear;
        mem_address = 4; mem_data = 11; mem_write = 1; #2;
        mem_address = 8; mem_data = 22; #2;
        mem_write = 0; mem_read = 1; #2; memory_tick;
        observe("memory_consecutive_sw", 22, mem_readback);
        memory_clear;
        mem_address = 4; mem_data = 22; mem_write = 1; #2;
        mem_data = 33; #2;
        mem_write = 0; mem_read = 1; #2; memory_tick;
        observe("memory_changed_store_data", 33, mem_readback);
        memory_clear;
        unit_mem.tempaddr0 = 4; unit_mem.memory0 = 11;
        unit_mem.tempaddr1 = 8; unit_mem.memory1 = 22;
        mem_address = 4; mem_read = 1; #2; memory_tick;
        observe("memory_first_read", 11, mem_readback);
        mem_address = 8; #2; memory_tick;
        observe("memory_consecutive_lw", 22, mem_readback);
        memory_clear;
        mem_address = 0; mem_data = 32'haa; mem_write = 1; #2;
        mem_write = 0; #2; mem_address = 4; mem_data = 32'hbb;
        mem_write = 1; #2; mem_write = 0; mem_address = 0; mem_read = 1; #2; memory_tick;
        observe("memory_address_zero_retained", 32'haa, mem_readback);

        core_fixture(1); repeat (12) cpu_tick;
        observe("program2_reg2", 12, dut.block2.v0);
        observe("program2_reg12", 12, dut.block2.t4);
        observe("program2_reg13", 172, dut.block2.t5);
        observe("program2_reg14", 24, dut.block2.t6);
        observe("program2_store_address", 112, dut.block5.tempaddr0);
        observe("program2_store_data", 32'hcafebabe, dut.block5.memory0);
        core_fixture(2); repeat (12) cpu_tick;
        observe("load_use_reg2", 21, dut.block2.v0);
        observe("load_use_reg12", 24, dut.block2.t4);
        observe("load_use_exact_one_stall", 1, stall_count);
        core_fixture(3); repeat (12) cpu_tick;
        observe("store_bypass_isolated_address", 172, dut.block5.tempaddr0);
        observe("store_bypass_isolated_data", 12, dut.block5.memory0);
        core_fixture(4); repeat (12) cpu_tick;
        observe("mixed_core_reg8", 28, dut.block2.t0);
        observe("mixed_core_reg2", 12, dut.block2.v0);
        observe("mixed_core_reg12", 12, dut.block2.t4);
        core_fixture(5); repeat (12) cpu_tick;
        observe("addi_core_negative_result", 16, dut.block2.v0);
        $display("AUDIT_SUMMARY cases=%0d pass=%0d fail=%0d", passed + failed, passed, failed);
        $finish;
    end
endmodule
