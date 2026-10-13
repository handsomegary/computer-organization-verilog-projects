"""Reproduce archived project_01 defects without modifying its RTL.

Success means the audit reproduced documented observations, not CPU compliance.
All compiled probes and simulator output stay in temporary directories.
"""
from pathlib import Path
import re
from hdl import ROOT, compile_and_run

PREFIX = "projects/project_01/rtl/"
MAIN = [PREFIX + name for name in ("CPU_Top.v", "IF.v", "ID.v", "EX.v", "MEM.v", "WB.v")]


def probe():
    registers = ",\n".join(f".register{i}(32'd{i*10+2})" for i in range(12))
    bank_outputs = ",\n".join(f".register{i}(bank{i})" for i in range(12))
    bank_wires = "\n".join(f"wire [31:0] bank{i};" for i in range(12))
    alias_seed = "\n".join(f"core.uu5.register{i}=32'd{100+i};" for i in range(12))
    return r'''`timescale 1ns/1ps
module audit_project_01;
reg clk=0, core_reset=1, ex_reset=1, mem_reset=1;
reg [31:0] a=0,b=0,ex_instruction=0,immediate=0;
wire [31:0] ex_result,ex_out,store_data;
wire ex_branch,ex_jump;
EX execute(.Read_data1(a),.Read_data2(b),.instruction_Reg(ex_instruction),.Alu_result(ex_result),
 .instruction_Alu(ex_out),.Write_data_mem(store_data),.clk(clk),.sign_extend(immediate),
 .rst(ex_reset),.newpc(32'd0),.branch(ex_branch),.jump(ex_jump));
reg [31:0] decode_instruction=0;
wire [31:0] decoded_instruction,read_a,read_b,extended;
wire [4:0] write_r,write_i;
ID decode(.clk(clk),.Read_Reg1(5'd0),.Read_Reg2(5'd0),.Writeregister1(5'd0),.Writedata(32'd0),
 .instruction(decode_instruction),.instruction_Reg(decoded_instruction),.Read_data_mem(32'd26),
 .Read_data1(read_a),.Read_data2(read_b),.sign_extend(extended),.Write_Reg_Rtype(write_r),
 .Write_Reg_lw(write_i),''' + registers + r''');
reg [31:0] mem_instruction=0;
wire [31:0] mem_read,mem_result,mem_out;
MEM memory(.Read_data_mem(mem_read),.instruction_Alu(mem_instruction),.Alu_result(mem_result),
 .clk(clk),.Write_data_mem(32'd123),.rst(mem_reset),.instruction_Mem(mem_out));
reg [31:0] wb_instruction=32'hxxxxxxxx,wb_alu=0,wb_read=0;
''' + bank_wires + r'''
WB writeback(.instruction_Mem(wb_instruction),.Read_data_mem(wb_read),.Alu_result(wb_alu),
 .clk(clk),''' + bank_outputs + r''');
reg fetch_clock=0,fetch_reset=0,branch=0,jump=0;
reg [31:0] start_pc=0;
wire [31:0] next_pc,fetched;
wire [4:0] rs,rt;
wire [5:0] alu_control;
IF fetch(.pc(start_pc),.newpc(next_pc),.clk(clk),.rst(fetch_reset),.instruction(fetched),
 .Read_Reg1(rs),.Read_Reg2(rt),.Alu_control(alu_control),.branch(branch),.jump(jump),.PC_CLK(fetch_clock));
wire [31:0] core_pc,core_s0,core_s5;
wire core_clock;
CPU_Top core(.pc(32'd0),.clk(clk),.rst(core_reset),.NEWPC(core_pc),.PC_CLK(core_clock),.s0(core_s0),.s5(core_s5));
integer i;
task tick; begin #5;clk=1;#1;end endtask
task tock; begin #4;clk=0;#1;end endtask
task step; begin tick;tock;end endtask
task fetch_step; begin #1;fetch_clock=1;#1;fetch_clock=0;#1;end endtask
initial begin
 #1;
 $display("OBS WB_UNINITIALIZED %0d", (^bank1 === 1'bx));
 step;
 $display("OBS EX_JUMP_RESET_UNKNOWN %0d", (ex_jump === 1'bx));
 $display("OBS MEM_ADDRESS_UNDRIVEN %0d", (^mem_result === 1'bx));
 $display("OBS CORE_ALU_UNKNOWN %0d", (^core.Alu_result === 1'bx));
 ex_reset=0;a=7;b=5;
 ex_instruction=32'h00221820;step;$display("OBS EX_ADD %0d",ex_result);
 ex_instruction=32'h00221822;step;$display("OBS EX_SUB %0d",ex_result);
 ex_instruction=32'h00221824;step;$display("OBS EX_AND %0d",ex_result);
 ex_instruction=32'h00221825;step;$display("OBS EX_OR %0d",ex_result);
 a=32'hffffffff;b=1;ex_instruction=32'h0022182a;
 step;$display("OBS EX_SLT_STALE %0d",ex_result);
 a=12;immediate=32'hfffffffc;ex_instruction=32'h2022fffc;
 step;$display("OBS EX_SIGNED_ADDI %0d",ex_result);
 a=1;b=1;ex_instruction=32'h10220001;step;
 ex_instruction=32'h08000019;step;
 $display("OBS EX_JUMP_AFTER_J %0d %0d",ex_jump,ex_branch);
 a=7;b=5;ex_instruction=32'h00221820;step;
 $display("OBS EX_JUMP_STICKY %0d",ex_jump);
 decode_instruction=32'h00222020;step;
 $display("OBS ID_RTYPE %0d %0d",read_a,read_b);
 decode_instruction=32'hacc70000;step;
 $display("OBS ID_STORE_STALE %0d %0d",read_a,read_b);
 $display("OBS ID_DEST_FROM_DATA %0d",write_i);
 decode_instruction=32'h10e7fffb;step;
 $display("OBS ID_BEQ_STALE %0d %0d %h",read_a,read_b,extended);
 decode_instruction=32'h8cc7fffc;step;
 $display("OBS ID_NEGATIVE_IMM %h",extended);
 decode_instruction=32'h08000019;step;
 $display("OBS ID_JUMP_UNDECODED %h",extended);
 decode_instruction=32'h01856820;step;
 $display("OBS ID_REGISTER12_UNSUPPORTED %0d %0d %0d",read_a,read_b,write_r);
 mem_instruction=32'h8c010004;mem_reset=0;step;
 $display("OBS MEM_LOAD_NO_ADDRESS %0d",mem_read);
 wb_alu=9;wb_instruction=32'h00222020;step;
 $display("OBS WB_ADD_ROUTE %0d",bank4);
 wb_instruction=0;wb_alu=123;step;
 $display("OBS WB_NOP_WRITES_R0 %0d",bank0);
 start_pc=24;fetch_reset=1;#1;fetch_reset=0;branch=1;jump=0;fetch_step;
 $display("OBS IF_BRANCH_INSTRUCTION_PC %h",next_pc);
 start_pc=28;fetch_reset=1;#1;fetch_reset=0;branch=0;jump=1;fetch_step;
 $display("OBS IF_JUMP_INSTRUCTION_PC %h",next_pc);
 ''' + alias_seed + r'''
 #1;$display("OBS CORE_ALIASES %0d %0d",core_s0,core_s5);
 core_reset=0;
 for(i=0;i<15;i=i+1)begin
  tick;$display("OBS CORE_TICK %0d %0d %0d %h",i,core.CLKcounter,core_clock,core_pc);tock;
 end
 $display("OBS DONE");$finish(0);
end
endmodule
'''


def main():
    wb_text = (ROOT/PREFIX/"WB.v").read_text(encoding="utf-8")
    written_registers = {int(bits,2) for bits in re.findall(r"5'b([01]{5}):begin register\d+<=",wb_text)}
    assert written_registers == set(range(12)), written_registers
    # Program 2 uses numeric destinations 12,13,14, independently of ABI aliases.
    assert not {12,13,14} & written_registers
    # Preserve and deliberately diagnose each duplicate pair in isolation.
    for file, implementation, module in [("ALUcontrol.v", "EX.v", "EX"), ("DataMem.v", "MEM.v", "MEM")]:
        result = compile_and_run([PREFIX+file], module, run=False)
        assert result["compiled"], result
        text = (ROOT/PREFIX/file).read_text(encoding="utf-8")
        assert re.search(r"module\s+"+module+r"\s*\(\s*\)\s*;\s*endmodule", text), file
        duplicate = compile_and_run([PREFIX+file, PREFIX+implementation], module, run=False)
        assert not duplicate["compiled"], duplicate
        assert "already" in duplicate["diagnostics"].lower() and module in duplicate["diagnostics"], duplicate
        print(f"REPRODUCED: {file} is an empty {module}; compiling with {implementation} conflicts.")
    for bench, module in [(PREFIX+"CPU_Alternate.v", "CPU_Alternate"), ("projects/project_01/tb/finaltb.v", "finaltb")]:
        result = compile_and_run(MAIN+[bench], module, run=False)
        assert result["compiled"], result
    result = compile_and_run(MAIN, "audit_project_01", probe())
    assert result["compiled"] and result.get("returncode") == 0, result
    observations = {}
    ticks = []
    for line in result["stdout"].splitlines():
        if not line.startswith("OBS "):
            continue  # Simulator termination notices are not probe observations.
        words = line.split()
        if words[1] == "CORE_TICK":
            ticks.append(words[2:])
        else:
            assert words[1] not in observations, line
            observations[words[1]] = words[2:]
    expected = {
        "WB_UNINITIALIZED":["1"], "EX_JUMP_RESET_UNKNOWN":["1"],
        "MEM_ADDRESS_UNDRIVEN":["1"], "CORE_ALU_UNKNOWN":["1"],
        "EX_ADD":["12"], "EX_SUB":["2"], "EX_AND":["5"], "EX_OR":["7"],
        "EX_SLT_STALE":["7"], "EX_SIGNED_ADDI":["8"],
        "EX_JUMP_AFTER_J":["1","1"], "EX_JUMP_STICKY":["1"],
        "ID_RTYPE":["12","22"], "ID_STORE_STALE":["62","22"],
        "ID_DEST_FROM_DATA":["26"], "ID_BEQ_STALE":["72","22","ffffffec"],
        "ID_NEGATIVE_IMM":["fffffffc"], "ID_JUMP_UNDECODED":["fffffffc"],
        "ID_REGISTER12_UNSUPPORTED":["62","52","13"],
        "MEM_LOAD_NO_ADDRESS":["0"], "WB_ADD_ROUTE":["9"], "WB_NOP_WRITES_R0":["123"],
        "IF_BRANCH_INSTRUCTION_PC":["8c200000"], "IF_JUMP_INSTRUCTION_PC":["08000019"],
        "CORE_ALIASES":["111","106"], "DONE":[]}
    assert observations == expected, (observations, expected)
    assert len(ticks)==15, ticks
    assert [int(row[2]) for row in ticks] == [int(i%5==1) for i in range(15)], ticks
    # Independent ISA reference values show concrete deviations, not a passing CPU.
    assert int(observations["EX_SLT_STALE"][0]) != int(-1 < 1)
    assert int(observations["IF_BRANCH_INSTRUCTION_PC"][0],16) != 24+4-5*4
    assert int(observations["IF_JUMP_INSTRUCTION_PC"][0],16) != 25*4
    assert int(observations["ID_STORE_STALE"][1]) != 7*10+2
    print("AUDIT PASS project_01: 26 observations and 15 clock samples reproduced; CPU is non-compliant.")


if __name__ == "__main__":
    main()
