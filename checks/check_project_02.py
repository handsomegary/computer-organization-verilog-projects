"""Reproduce project_02 archive findings without changing its HDL.

Passing this audit means the stated observations are reproducible. It does not
mean the three archived processors implement the required ISA correctly.
"""

import argparse
from pathlib import Path
import re

from hdl import ROOT, compile_and_run


BASE = Path('projects/project_02')
VARIANTS = ('single_cycle', 'pipeline', 'hazard')
TOPS = {'single_cycle': 'CPU_SingleCycle', 'pipeline': 'CPU_Pipeline',
        'hazard': 'CPU_NoHazard'}
ORIGINAL_TB = {'single_cycle': 'CPU_SingleCycle_tb', 'pipeline': 'CPU_Pipeline_tb',
               'hazard': 'CPU_NoHazard_tb'}


def sources(variant):
    return sorted((BASE / variant / 'rtl' / path.name).as_posix()
                  for path in (ROOT / BASE / variant / 'rtl').glob('*.v'))


def named_source(variant, filename):
    return next(path for path in (ROOT / BASE / variant / 'rtl').glob('*.v')
                if path.name.lower() == filename.lower())


def static_findings(variant):
    controller = named_source(variant, 'Controller.v').read_text(encoding='utf-8')
    memory = named_source(variant, 'DataMemory.v').read_text(encoding='utf-8')
    top = named_source(variant, TOPS[variant] + '.v').read_text(encoding='utf-8')
    # The opcode case arm must contain the specific erroneous archive setting.
    opcode = '1001000' if variant == 'hazard' else '001000'
    case = re.search(r"(?:6|7)'b" + opcode + r'\s*:\s*begin(.*?)end', controller, re.S)
    assert case and re.search(r"MEMWRITE\s*=\s*1'b1", case.group(1))
    assert re.search(r'memory\[ADDR\]', memory)
    assert re.search(r'i\s*<\s*63', memory)
    if variant != 'single_cycle':
        assert 'JUMP' not in controller and 'JUMP' not in top
        assert 'flush' not in top.lower()
    if variant == 'hazard':
        assert '.READ_DATA_2(READ_DATA_2_ID_EX)' in top
        assert '.IN0(READ_DATA_2_ID_EX)' in top
    return {'addi_memwrite': 'known defect', 'byte_word_mapping': 'raw byte-index mapping / limited range',
            'reset_last_word': 'known omission',
            'jump': 'present' if variant == 'single_cycle' else 'missing',
            'store_forwarding': 'not applicable' if variant != 'hazard' else 'missing'}


def r_type(rs, rt, rd, function):
    return rs << 21 | rt << 16 | rd << 11 | function


PADDING = r_type(31, 31, 31, 37)  # OR r31,r31,r31 preserves r31.


def i_type(opcode, rs, rt, immediate):
    return opcode << 26 | rs << 21 | rt << 16 | (immediate & 65535)


def signed(value):
    return value if value < 0x80000000 else value - 0x100000000


def interpret(program, registers=None, memory=None, steps=20):
    """Small numeric-register ISA oracle; r0 is not forcibly immutable.

    Word addresses in the memory dictionary are byte addresses, and no ABI
    register names are assumed. Padding uses the supported OR r31,r31,r31.
    """
    regs = [0] * 32
    for number, value in (registers or {}).items():
        regs[number] = value & 0xFFFFFFFF
    data = dict(memory or {})
    pc = 0
    for _ in range(steps):
        instruction = program.get(pc // 4, PADDING)
        next_pc = (pc + 4) & 0xFFFFFFFF
        opcode = instruction >> 26
        rs, rt, rd = instruction >> 21 & 31, instruction >> 16 & 31, instruction >> 11 & 31
        immediate = instruction & 65535
        immediate = immediate if immediate < 32768 else immediate - 65536
        if opcode == 0:
            function = instruction & 63
            a, b = regs[rs], regs[rt]
            value = {32: lambda: a + b, 34: lambda: a - b,
                     36: lambda: a & b, 37: lambda: a | b,
                     42: lambda: int(signed(a) < signed(b))}[function]()
            regs[rd] = value & 0xFFFFFFFF
        elif opcode == 8:
            regs[rt] = (regs[rs] + immediate) & 0xFFFFFFFF
        elif opcode in (35, 43):
            address = (regs[rs] + immediate) & 0xFFFFFFFF
            assert address % 4 == 0
            if opcode == 35:
                regs[rt] = data.get(address, 0)
            else:
                data[address] = regs[rt]
        elif opcode == 4:
            if regs[rs] == regs[rt]:
                next_pc = (next_pc + immediate * 4) & 0xFFFFFFFF
        elif opcode == 2:
            next_pc = (next_pc & 0xF0000000) | ((instruction & 0x3FFFFFF) * 4)
        else:
            raise AssertionError('unsupported oracle instruction')
        pc = next_pc
    return regs, data, pc


def oracle_checks():
    program = {0: i_type(8, 6, 1, -4), 1: i_type(8, 6, 2, 3),
               2: r_type(1, 2, 3, 32), 3: r_type(2, 1, 4, 34),
               4: r_type(1, 2, 5, 36), 5: r_type(1, 2, 7, 37),
               6: r_type(1, 2, 8, 42), 7: i_type(43, 6, 4, 16),
               8: i_type(35, 6, 9, 16), 9: i_type(4, 9, 4, 1),
               10: i_type(8, 6, 10, 99), 11: 2 << 26 | 13,
               12: i_type(8, 6, 11, 99), 13: i_type(8, 6, 12, 7)}
    registers, memory, _ = interpret(program, {6: 0}, steps=18)
    assert [registers[n] for n in (1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12)] == [
        0xFFFFFFFC, 3, 0xFFFFFFFF, 7, 0, 0xFFFFFFFF, 1, 7, 0, 0, 7]
    assert memory[16] == 7
    # Concatenation uses PC+4 high bits, including crossing a 256 MiB region.
    pc4 = (0x0FFFFFFC + 4) & 0xFFFFFFFF
    assert (pc4 & 0xF0000000) | (3 * 4) == 0x1000000C
    assert (4 + (-8) * 4) & 0xFFFFFFFF == 0xFFFFFFE4


def common_bench(variant):
    extra_port = ', .JUMP(jump)' if variant == 'single_cycle' else ', .Sel(1\'b1)' if variant == 'hazard' else ''
    return r'''`timescale 1ns/1ps
module probe;
reg [5:0] opcode, function_field;
wire regdst, alusrc, memtoreg, regwrite, memread, memwrite, branch, jump;
wire [1:0] aluop;
wire [3:0] control;
Controller decode(.REGDST(regdst),.ALUSRC(alusrc),.MEMTOREG(memtoreg),
 .REGWRITE(regwrite),.MEMREAD(memread),.MEMWRITE(memwrite),.BRANCH(branch),
 .ALUOP(aluop),.OPCODE(opcode) EXTRA_PORT);
ALU_Controller alu_decode(control,aluop,function_field);
reg [31:0] a,b;
wire [31:0] out;
wire zero;
ALU arithmetic(out,zero,a,b,control);
reg [15:0] immediate;
wire [31:0] extended,shifted,target;
Sign_Extend extend(extended,immediate);
Shift_Left_2_32BitsTo32Bits shift(shifted,extended);
Add branch_adder(target,32'd4,shifted);
reg clk,rst,mw,mr;
reg [31:0] address,write_data;
wire [31:0] read_data;
DataMemory memory_unit(read_data,address,write_data,mw,mr,rst,clk);
initial begin
 clk=0;rst=0;address=0;write_data=0;mw=0;mr=0;
 opcode=0;function_field=32;a=9;b=4;immediate=16'hfff8;
 #1;
 if(out!==13) $fatal(1,"add decode/ALU changed");
 function_field=34;#1;if(out!==5) $fatal(1,"sub changed");
 function_field=36;#1;if(out!==0) $fatal(1,"and changed");
 function_field=37;#1;if(out!==13) $fatal(1,"or changed");
 function_field=42;a=32'hffffffff;b=1;#1;
 if(out!==1) $fatal(1,"signed slt changed");
 if(extended!==32'hfffffff8||shifted!==32'hffffffe0||target!==32'hffffffe4)
  $fatal(1,"sign/branch arithmetic changed");
 opcode=8;a=3;b=4;#1;
 if(out!==7||regwrite!==1||alusrc!==1) $fatal(1,"addi arithmetic changed");
 $display("OBS addi_memwrite %0d",memwrite);
 opcode=35;#1;if(memread!==1||regwrite!==1||alusrc!==1) $fatal(1,"lw decode changed");
 opcode=43;#1;if(memwrite!==1||regwrite!==0) $fatal(1,"sw decode changed");
 opcode=4;a=7;b=7;#1;if(branch!==1||zero!==1) $fatal(1,"beq changed");
 rst=1;#1;
 $display("OBS reset_word63_unknown %0d",memory_unit.memory[63]===32'hxxxxxxxx);
 rst=0;address=16;write_data=32'h12345678;mw=1;mr=0;
 #1;clk=1;#1;clk=0;
 $display("OBS raw_byte_index %0d",memory_unit.memory[16]===32'h12345678 && memory_unit.memory[4]===0);
 address=252;write_data=32'h89abcdef;#1;clk=1;#1;clk=0;mw=0;mr=1;#1;
 $display("OBS byte252_out_of_range %0d",read_data===32'hxxxxxxxx);
 address=100;#1;$display("OBS byte100_out_of_range %0d",read_data===32'hxxxxxxxx);
 address=400;#1;$display("OBS byte400_out_of_range %0d",read_data===32'hxxxxxxxx);
 $display("OBS healthy_units 1");
 $finish;
end
endmodule
'''.replace('EXTRA_PORT', extra_port)


def cpu_bench(variant, program, registers=None, memory=None, fields=()):
    statements = [f'dut.IM.memory[{index}]=32\'h{word:08x};' for index, word in program.items()]
    statements += [f'dut.RF.Regfile[{index}]=32\'h{word & 0xFFFFFFFF:08x};'
                   for index, word in (registers or {}).items()]
    statements += [f'dut.DM.memory[{index}]=32\'h{word:08x};' for index, word in (memory or {}).items()]
    observations = []
    for name, expression in fields:
        observations.append(f'$display("OBS {name} %08h",{expression});')
    stall_count = ('always @(negedge clk) if(!rst && dut.PCWrite===0) stalls=stalls+1;'
                   if variant == 'hazard' else '')
    if variant == 'hazard':
        observations.append('$display("OBS stalls %0d",stalls);')
    return f'''`timescale 1ns/1ps
module probe;
reg clk=0,rst=0;
wire [31:0] pc;
integer i,stalls=0;
{TOPS[variant]} dut(.CLK(clk),.RST(rst),.PC_NEXT(pc));
{stall_count}
task tick;begin #2;clk=1;#2;clk=0;#1;end endtask
initial begin
 #1;rst=1;#2;rst=0;#1;
 for(i=0;i<64;i=i+1) dut.IM.memory[i]=32'h{PADDING:08x};
 {' '.join(statements)}
 for(i=0;i<20;i=i+1) tick;
 {' '.join(observations)}
 $finish;
end
endmodule
'''


def run_probe(variant, bench):
    result = compile_and_run(sources(variant), 'probe', bench, timeout=20)
    assert result['compiled'], result['diagnostics']
    assert result['returncode'] == 0, result.get('stdout', '') + result.get('stderr', '')
    observed = {}
    for line in result['stdout'].splitlines():
        if line.startswith('OBS '):
            _, key, value = line.split()
            observed[key] = value
    assert observed, 'probe did not produce observations'
    return observed


def hazard_unit_bench():
    return r'''`timescale 1ns/1ps
module probe;
reg [4:0] rs,rt,exrd,wbrd,ifrs,ifrt,loadrt;
reg exwrite,wbwrite,memread;
wire [1:0] fa,fb;
wire pcwrite,ifwrite,control;
ForwardingUnit forward(fa,fb,rs,rt,exrd,wbrd,exwrite,wbwrite);
Hazard_detection_unit hazard(pcwrite,ifwrite,control,ifrs,ifrt,loadrt,memread);
initial begin
 rs=2;rt=3;exrd=2;wbrd=2;exwrite=1;wbwrite=1;
 ifrs=4;ifrt=5;loadrt=4;memread=1;#1;
 if(fa!==2||fb!==0) $fatal(1,"EX/MEM priority changed");
 if({pcwrite,ifwrite,control}!==3'b000) $fatal(1,"load-use stall changed");
 wbrd=3;#1;if(fb!==1) $fatal(1,"MEM/WB forwarding changed");
 exrd=3;#1;if(fb!==2) $fatal(1,"EX/MEM must override MEM/WB");
 memread=0;#1;
 if({pcwrite,ifwrite,control}!==3'b111) $fatal(1,"normal advance changed");
 $display("OBS forward_priority 1");
 $display("OBS load_use_controls 1");
 memread=1;loadrt=4;ifrs=5;ifrt=4;#1;
 $display("OBS rt_only_stall %0d",pcwrite===0&&ifwrite===0&&control===0);
 $finish;
end
endmodule
'''


def dynamic_findings(variant):
    rtl = sources(variant)
    tb_sources = sorted((BASE / variant / 'tb' / path.name).as_posix()
                        for path in (ROOT / BASE / variant / 'tb').glob('*.v'))
    original = compile_and_run(rtl + tb_sources, ORIGINAL_TB[variant], run=False)
    assert original['compiled'], original['diagnostics']
    observed = run_probe(variant, common_bench(variant))
    assert observed == {'addi_memwrite': '1', 'reset_word63_unknown': '1',
                        'raw_byte_index': '1', 'byte252_out_of_range': '1',
                        'byte100_out_of_range': '1', 'byte400_out_of_range': '1',
                        'healthy_units': '1'}, observed
    # No ABI names and no writes to register zero in these integration probes.
    jump_program = {0: 2 << 26 | 8, 1: i_type(8, 0, 4, 99), 8: i_type(8, 0, 5, 7)}
    golden, _, _ = interpret(jump_program)
    assert golden[4] == 0 and golden[5] == 7
    jumping = run_probe(variant, cpu_bench(variant, jump_program, fields=[
        ('jump_wrong_path_r4', 'dut.RF.Regfile[4]'), ('jump_target_r5', 'dut.RF.Regfile[5]')]))
    expected_wrong_path = '00000000' if variant == 'single_cycle' else '00000063'
    assert jumping['jump_wrong_path_r4'] == expected_wrong_path, jumping
    assert jumping['jump_target_r5'] == '00000007', jumping

    branch_program = {0: i_type(4, 1, 1, 4), 1: i_type(8, 0, 4, 99), 5: i_type(8, 0, 5, 7)}
    golden, _, _ = interpret(branch_program, {1: 7})
    assert golden[4] == 0 and golden[5] == 7
    branching = run_probe(variant, cpu_bench(variant, branch_program, {1: 7}, fields=[
        ('branch_wrong_path_r4', 'dut.RF.Regfile[4]'), ('branch_target_r5', 'dut.RF.Regfile[5]')]))
    assert branching['branch_wrong_path_r4'] == expected_wrong_path, branching
    assert branching['branch_target_r5'] == '00000007', branching
    findings = {'compile_original_tb': 'OK', 'common': observed, 'jump': jumping, 'branch': branching}
    if variant == 'hazard':
        hazard_units = run_probe(variant, hazard_unit_bench())
        assert hazard_units == {'forward_priority': '1', 'load_use_controls': '1', 'rt_only_stall': '1'}, hazard_units
        findings['hazard_units'] = hazard_units
        forwarding = {0: r_type(1, 3, 2, 32), 1: i_type(43, 4, 2, 0)}
        golden, data, _ = interpret(forwarding, {1: 5, 3: 7, 4: 0})
        assert golden[2] == 12 and data[0] == 12
        store = run_probe(variant, cpu_bench(variant, forwarding, {1: 5, 3: 7, 4: 0}, fields=[
            ('store_forwarded_r2', 'dut.RF.Regfile[2]'), ('store_stale_data', 'dut.DM.memory[0]')]))
        assert store['store_forwarded_r2'] == '0000000c' and store['store_stale_data'] == '00000000', store
        load_program = {0: i_type(35, 1, 2, 0), 1: r_type(2, 2, 3, 32)}
        golden, _, _ = interpret(load_program, {1: 0}, {0: 21})
        assert golden[3] == 42
        load = run_probe(variant, cpu_bench(variant, load_program, {1: 0}, {0: 21}, fields=[
            ('load_use_r3', 'dut.RF.Regfile[3]')]))
        assert load['load_use_r3'] == '0000002a' and int(load['stalls']) >= 1, load
        master_program = {0: r_type(1, 3, 2, 34), 1: r_type(2, 5, 12, 36),
                          2: r_type(6, 2, 13, 37), 3: r_type(2, 2, 14, 32),
                          4: i_type(43, 2, 15, 100)}
        registers = {1: 4, 3: 44, 5: 3, 6: 8, 15: 55}
        golden, data, _ = interpret(master_program, registers)
        master = run_probe(variant, cpu_bench(variant, master_program, registers, fields=[
            ('master_r2', 'dut.RF.Regfile[2]'), ('master_r12', 'dut.RF.Regfile[12]'),
            ('master_r13', 'dut.RF.Regfile[13]'), ('master_r14', 'dut.RF.Regfile[14]'),
            ('master_raw_memory60', 'dut.DM.memory[60]')]))
        for register in (2, 12, 13, 14):
            assert master[f'master_r{register}'] == f'{golden[register]:08x}', master
        # Inspecting raw word60 records this archive's byte-index convention;
        # it is deliberately not a claim of correct word15 byte-address layout.
        assert master['master_raw_memory60'] == f'{data[60]:08x}', master
        findings.update(store=store, load_use=load, master_hazard=master)
    return findings


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--variant', choices=('all',) + VARIANTS, default='all')
    parser.add_argument('--static-only', action='store_true',
                        help='Verify source evidence and ISA oracle; do not claim HDL execution')
    args = parser.parse_args()
    oracle_checks()
    print('Independent numeric-register ISA oracle: 10 required instructions and PC arithmetic checked')
    selected = VARIANTS if args.variant == 'all' else (args.variant,)
    for variant in selected:
        evidence = static_findings(variant)
        print(variant, 'source evidence:', evidence)
        if not args.static_only:
            findings = dynamic_findings(variant)
            print(variant, 'ARCHIVE FINDINGS REPRODUCED;', len(findings), 'probe groups; not a CPU correctness PASS')
    if args.static_only:
        print('STATIC ONLY: no HDL compilation or simulation performed')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
