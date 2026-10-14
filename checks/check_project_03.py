"""Read-only, reproducible audits of three archived CPUs; audit success != CPU pass."""
import argparse
import hashlib
import re
from pathlib import Path
from hdl import ROOT, compile_and_run

BASE = ROOT / 'projects/project_03'
VARIANTS = {'single_cycle': ('CPU_SingleCycle', 'CPU_SingleCycle_tb'),
            'pipeline': ('CPU_Pipeline', 'CPU_Pipeline_tb'),
            'hazard': ('CPU', 'TB')}

# Measured in CI run38482714485; healthy unit-ALU checks remain required.
MEASURED_FAILURES = {
    'single_cycle': {'ADDI_MEMWRITE': '00000001', 'RESET_LAST_WORD': 'deadc0de',
                     'CPU_ADDI_MEMORY_UNCHANGED': 'deadc0de'},
    'pipeline': {'ADDI_MEMWRITE': '00000001', 'RESET_LAST_WORD': 'deadc0de',
                 'CPU_ADDI_MEMORY_UNCHANGED': 'deadc0de', 'BRANCH_SKIPPED_R5': '0000000c',
                 'BRANCH_SKIPPED_R6': '00000007', 'BRANCH_SKIPPED_R7': '00000005',
                 'JUMP_SKIPPED_R5': '0000000c'},
    'hazard': {
        'slt_true_is_one': 'ffffffff', 'slt_negative_lt_zero': '00000000',
        'slt_zero_lt_negative': 'ffffffff', 'store_offset_with_rt_bypass': '00000020',
        'decode_addi_alu_writeback': '00000000', 'decode_jump_disables_regwrite': '00000001',
        'register_30_second_read': '000055aa', 'mixed_forward_rs_ex_rt_wb': '00000008',
        'mixed_forward_rs_wb_rt_ex': '00000002', 'load_then_overwrite_false_stall': '00000000',
        'memory_consecutive_sw': '00000000', 'memory_changed_store_data': '00000016',
        'memory_consecutive_lw': '0000000b', 'memory_address_zero_retained': '00000000',
        'store_bypass_isolated_data': '00000000', 'mixed_core_reg12': '00000000',
        'addi_core_negative_result': '00000000',
    },
}


def assert_measured_baseline(variant, rows):
    actual = {name: row['actual'] for name, row in rows.items() if not row['passed']}
    assert actual == MEASURED_FAILURES[variant], (
        f'{variant}: measured failure set changed; review source/probe/report instead of silently passing. '
        f'Expected {MEASURED_FAILURES[variant]}, observed {actual}')


def signed32(value):
    value &= 0xffffffff
    return value - (1 << 32) if value & (1 << 31) else value


def alu_reference(function, a, b):
    if function == 32: result = a + b
    elif function == 34: result = a - b
    elif function == 36: result = a & b
    elif function == 37: result = a | b
    elif function == 42: result = int(signed32(a) < signed32(b))
    else: raise ValueError('function outside required R-type subset')
    return result & 0xffffffff


def program2_reference():
    """Sequential ISA oracle uses numeric register IDs, not an ABI alias table."""
    registers = {1: 20, 3: 8, 5: 15, 6: 160, 15: 0xcafebabe}
    registers[2] = alu_reference(34, registers[1], registers[3])
    registers[12] = alu_reference(36, registers[2], registers[5])
    registers[13] = alu_reference(37, registers[6], registers[2])
    registers[14] = alu_reference(32, registers[2], registers[2])
    memory = {registers[2] + 100: registers[15]}
    return registers, memory


def model_checks():
    assert alu_reference(42, 0xffffffff, 1) == 1
    assert alu_reference(42, 1, 0xffffffff) == 0
    assert signed32(0xfffc | 0xffff0000) == -4
    assert (20 + (-4 << 2)) & 0xffffffff == 4
    assert (0x10000000 & 0xf0000000) | (5 << 2) == 0x10000014
    registers, memory = program2_reference()
    assert [registers[r] for r in (2, 12, 13, 14)] == [12, 12, 172, 24]
    assert memory == {112: 0xcafebabe}
    files = sorted(BASE.rglob('*.v'))
    assert len(files) == 42, 'Update the report if the extracted source inventory changes'
    assert [len(list((BASE / name).rglob('*.v'))) for name in VARIANTS] == [15, 19, 8]
    # Exact static evidence. This is not a substitute for HDL elaboration/runtime.
    for name, controller in [('single_cycle', 'Controller.v'), ('pipeline', 'CONTROLLER.v')]:
        text = (BASE / name / 'rtl' / controller).read_text(encoding='utf-8')
        block = text.split("6'b001000", 1)[1].split('end', 1)[0]
        assert re.search(r"MEMWRITE\s*=\s*1'b1", block)
    pipeline = (BASE / 'pipeline/rtl/CONTROLLER.v').read_text(encoding='utf-8')
    assert "6'b000010" not in pipeline
    return {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in files}


def arithmetic_expectations(prefix=''):
    tests = [(32, 7, 5), (34, 7, 5), (36, 7, 5), (37, 7, 5),
             (42, 0xffffffff, 1), (42, 1, 0xffffffff)]
    return {f'{prefix}ALU_{fn}_{a:08x}_{b:08x}': (alu_reference(fn, a, b), 'isa')
            for fn, a, b in tests}


def unit_expectations(variant):
    expected = arithmetic_expectations()
    expected.update({
        'ADDI_MEMWRITE': (0, 'isa'), 'ADDI_REGWRITE': (1, 'isa'),
        'LW_MEMREAD': (1, 'isa'), 'SW_MEMWRITE': (1, 'isa'), 'BEQ_ZERO': (1, 'isa'),
        'SIGNEXT_FFFC': (0xfffffffc, 'isa'), 'SHIFT_NEGATIVE': (0xfffffff0, 'isa'),
        'RESET_LAST_WORD': (0, 'implementation'),
        'SPARSE_READ_4': (77, 'storage-interface'),
        'CAPACITY_READ_100': ('unknown', 'capacity'),
        'SPARSE_STORE_WORD2_UNCHANGED': (0, 'storage-interface'),
        'SPARSE_STORE_SLOT8': (123, 'storage-interface'),
    })
    if variant == 'single_cycle': expected['JUMP_CONTROL'] = 1, 'isa'
    return expected


def cpu_expectations(variant):
    expected = arithmetic_expectations('CPU_')
    expected.update({
        'SEQUENTIAL_PC': (28 if variant == 'pipeline' else 4, 'isa'),
        'CPU_ADDI_NEGATIVE': (3, 'isa'), 'CPU_ADDI_MEMORY_UNCHANGED': (77, 'isa'),
        'CPU_LW_BYTE20': (123, 'storage-interface'), 'CPU_SW_BYTE20': (123, 'storage-interface'),
        'BRANCH_SKIPPED_R5': (77, 'no-delay-slot-isa'), 'BRANCH_SKIPPED_R6': (77, 'no-delay-slot-isa'),
        'BRANCH_SKIPPED_R7': (77, 'no-delay-slot-isa'), 'BRANCH_TARGET_R8': (2, 'isa'),
        'BRANCH_NOT_TAKEN_R5': (12, 'isa'), 'NEGATIVE_BRANCH_TARGET': (4, 'isa'),
        'JUMP_SKIPPED_R5': (77, 'no-delay-slot-isa'), 'JUMP_TARGET_R8': (2, 'isa'),
    })
    if variant == 'single_cycle': expected['JUMP_UPPER_PC4'] = 0x10000014, 'isa'
    return expected


def read_observations(stdout, expected):
    rows = {}
    for line in stdout.splitlines():
        if line.startswith('OBS '):
            _, name, actual = line.split()
            assert name not in rows, 'Duplicate observation ' + name
            assert name in expected, 'Unknown observation ' + name
            value, category = expected[name]
            actual = actual.lower()
            if value == 'unknown': passed = any(c in actual for c in 'xz')
            else: passed = not any(c in actual for c in 'xz') and int(actual, 16) == value
            rows[name] = {'category': category, 'expected': value, 'actual': actual, 'passed': passed}
    assert set(rows) == set(expected), 'Missing observations: ' + str(set(expected) - set(rows))
    return rows


def relative(path):
    return path.relative_to(ROOT).as_posix()


def probe(sources, top, bench, expected):
    result = compile_and_run(sources, top, bench, timeout=25)
    # If the original top compiled, a broken adapter is an audit error, not a CPU defect.
    assert result['compiled'], result['diagnostics']
    assert result.get('returncode') == 0, result.get('stderr', 'Probe failed to finish')
    return read_observations(result['stdout'], expected)


def hazard_probe(sources):
    bench = (ROOT / 'checks/project_03_hazard.v').read_text(encoding='utf-8')
    result = compile_and_run(sources, 'audit_hazard_tb', bench, timeout=25,
                             extra_flags=('-gno-io-range-error',))
    assert result['compiled'], result['diagnostics']
    assert result.get('returncode') == 0, result.get('stderr', 'Probe failed to finish')
    rows = {}
    for line in result['stdout'].splitlines():
        if line.startswith('OBS '):
            _, name, exp, actual, status = line.split()
            assert name not in rows, 'Duplicate hazard observation ' + name
            expected_value = exp.split('=')[1].lower()
            actual_value = actual.split('=')[1].lower()
            passed = not any(c in actual_value for c in 'xz') and int(actual_value, 16) == int(expected_value, 16)
            assert (status == 'status=PASS') == passed, 'Inconsistent bench status ' + name
            rows[name] = {'expected': expected_value, 'actual': actual_value,
                          'passed': passed,
                          'category': 'performance' if name == 'load_then_overwrite_false_stall' else 'directed-hazard/isa'}
    assert rows and 'AUDIT_SUMMARY' in result['stdout'], 'Hazard audit did not complete'
    registers, memory = program2_reference()
    required = {'program2_reg2': registers[2], 'program2_reg12': registers[12],
                'program2_reg13': registers[13], 'program2_reg14': registers[14],
                'program2_store_address': 112, 'program2_store_data': memory[112]}
    for name, expected in required.items():
        assert name in rows and int(rows[name]['expected'], 16) == expected, name
    assert len(rows) == 45, 'Update audit coverage if the hazard probes change'
    return rows


def summary(variant, compiled, original_tb, rows):
    failed = {name: data for name, data in rows.items() if not data['passed']}
    print(f'AUDIT project_03/{variant}: RTL compile={compiled}, archive-TB compile={original_tb}, '
          f'observations={len(rows)}, mismatches={len(failed)}; CPU certification not granted')
    for name, data in failed.items():
        expected = data['expected']
        if isinstance(expected, int): expected = f'{expected:08x}'
        print(f'  {name}: expected={expected} actual={data["actual"]} category={data["category"]}')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--model-only', action='store_true',
                        help='Run static/model checks without claiming compile or simulation')
    args = parser.parse_args()
    before = model_checks()
    if args.model_only:
        print('STATIC/MODEL project_03: 42 authored Verilog files, three variants; '
              'addi memory side effect and missing pipeline jump confirmed; HDL not run')
        return
    for variant, (top, archive_tb_top) in VARIANTS.items():
        rtl = [relative(path) for path in sorted((BASE / variant / 'rtl').glob('*.v'))]
        original_tb = [relative(path) for path in sorted((BASE / variant / 'tb').glob('*.v'))]
        compiled = compile_and_run(rtl, top, run=False)
        archived = compile_and_run(rtl + original_tb, archive_tb_top, run=False)
        strict_expected = variant != 'hazard'
        assert compiled['compiled'] == strict_expected, 'Original top compile baseline changed: ' + variant
        assert archived['compiled'] == strict_expected, 'Archive TB compile baseline changed: ' + variant
        rows = {}
        if variant == 'hazard':
            compatible = compile_and_run(rtl, top, run=False, extra_flags=('-gno-io-range-error',))
            compatible_tb = compile_and_run(rtl + original_tb, archive_tb_top, run=False,
                                             extra_flags=('-gno-io-range-error',))
            assert 'Read_Data1_out' in compiled['diagnostics'] and 'Reg.v' in compiled['diagnostics'], compiled
            assert compatible['compiled'] and compatible_tb['compiled'], 'Hazard compatibility elaboration failed'
            print('  hazard compatibility -gno-io-range-error: RTL compile='
                  + str(compatible['compiled']) + ', archive-TB compile=' + str(compatible_tb['compiled']))
            rows = hazard_probe(rtl)
        else:
            prefix = '`define PIPE_CONTROLLER\n' if variant == 'pipeline' else ''
            bench = prefix + (ROOT / 'checks/project_03_units.v').read_text(encoding='utf-8')
            # Compile full RTL to preserve the same module implementations.
            rows.update(probe(rtl, 'probe', bench, unit_expectations(variant)))
            prefix = '`define PIPE_CPU\n' if variant == 'pipeline' else ''
            bench = prefix + (ROOT / 'checks/project_03_cpu.v').read_text(encoding='utf-8')
            rows.update(probe(rtl, 'probe', bench, cpu_expectations(variant)))
        assert_measured_baseline(variant, rows)
        summary(variant, compiled['compiled'], archived['compiled'], rows)
        if not compiled['compiled']: print('  compile diagnostic:', compiled['diagnostics'].strip().splitlines()[-1])
    after = {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in before}
    assert before == after, 'Archived RTL changed during audit'


if __name__ == '__main__':
    main()
