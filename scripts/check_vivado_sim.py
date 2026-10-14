"""Verify Tcl source selection and command flow without claiming a Vivado run.

Uses Python's standard-library tkinter.Tcl interpreter; no GUI is created.
Vivado commands are mocks. HDL functionality is tested separately with Icarus.
"""
from pathlib import Path
import argparse
import hashlib
import json
import tempfile
import tkinter

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'scripts/create_vivado_sim.tcl'
PACKAGE = ROOT if (ROOT / 'reference/rtl').is_dir() else ROOT / 'repaired'
VARIANTS = {
    'reference': ('mips_single_cycle', 'reference_demo_tb', 2),
    's02-single-cycle': ('CPU_SingleCycle', 'CPU_SingleCycle_tb', 14),
    's02-pipeline': ('CPU_Pipeline', 'CPU_Pipeline_tb', 18),
    's02-hazard': ('CPU_NoHazard', 'CPU_NoHazard_tb', 21),
    's03-single-cycle': ('CPU_SingleCycle', 'CPU_SingleCycle_tb', 14),
    's03-pipeline': ('CPU_Pipeline', 'CPU_Pipeline_tb', 18),
}


def interpreter(args, mode='plain', log_mode='pass', fail_command=None):
    tcl = tkinter.Tcl()
    calls = []
    output = []
    tcl.createcommand('python_puts', lambda *args: output.append(' '.join(args)) or '')
    tcl.eval('rename puts original_puts; proc puts {args} {python_puts {*}$args}')
    tcl.setvar('argv', tcl.call('list', *map(str, args)))
    if mode == 'mock':
        def record(command, *items):
            calls.append([command, list(items)])
            if command == 'create_project':
                assert len(items) == 4 and items[2] == '-part'
                assert not Path(items[1]).exists()
                Path(items[1]).mkdir(parents=True)
                (Path(items[1]) / (items[0]+'.xpr')).write_text('mock project\n')
            if command == 'run':
                assert items == ('-all',)
                project = str(tcl.getvar('::org_project'))
                folder = Path(str(tcl.getvar('::org_out'))) / (project+'.sim') / 'sim_1/behav/xsim'
                folder.mkdir(parents=True, exist_ok=True)
                marker = str(tcl.getvar('::org_pass_marker'))
                text = {'pass': marker+'\n', 'missing': 'simulation ended\n',
                        'failure': 'FATAL: injected failure\n'+marker+'\n'}[log_mode]
                (folder/'simulate.log').write_text(text)
            if command == 'current_project':
                return 'mock_project'
            if command == 'get_filesets':
                assert len(items) == 1 and items[0] in {'sources_1','sim_1'}
                return items[0]
            if command == 'get_files':
                assert len(items) == 1
                return items[0]
            return ''
        tcl.createcommand('python_record', record)
        for name in ['create_project','current_project','set_property','add_files',
                     'get_filesets','get_files','update_compile_order','launch_simulation',
                     'run','close_sim','close_project']:
            if name == fail_command:
                tcl.eval(f'proc {name} {{args}} {{error "injected {name} failure"}}')
            else:
                tcl.eval(f'proc {name} {{args}} {{python_record {name} {{*}}$args}}')
    return tcl, calls, output


def source(tcl):
    return tcl.call('source', str(SCRIPT.resolve()).replace('\\','/'))


def expect_error(args, expected, **kwargs):
    tcl, calls, output = interpreter(args, **kwargs)
    try:
        source(tcl)
    except tkinter.TclError as error:
        assert expected in str(error), (expected, str(error))
        return calls, output
    raise AssertionError('Expected error: '+expected)


def verify_selection(tcl, variant):
    top, bench, count = VARIANTS[variant]
    assert tcl.getvar('org_design_top') == top
    assert tcl.getvar('org_sim_top') == bench
    rtl = [Path(str(x)) for x in tcl.splitlist(tcl.getvar('org_rtl'))]
    tb = [Path(str(x)) for x in tcl.splitlist(tcl.getvar('org_bench'))]
    assert len(rtl) == count and len(tb) == 1, (variant,len(rtl),len(tb))
    for p in rtl+tb:
        assert p.is_file() and p.resolve().is_relative_to(PACKAGE.resolve())
    assert 'module '+bench in tb[0].read_text(encoding='utf-8')
    return rtl, tb


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--report', type=Path)
    options = parser.parse_args()
    results = []
    temp_parent = ROOT / '.verification-build'
    temp_parent.mkdir(exist_ok=True)
    assert temp_parent.resolve().is_relative_to(ROOT.resolve())
    with tempfile.TemporaryDirectory(prefix='vivado-tcl-preflight-', dir=temp_parent) as temp:
        folder = Path(temp)
        for variant in VARIANTS:
            out = folder / ('preflight-'+variant)
            tcl, calls, output = interpreter(['-variant', variant,'-out-dir',out,'-check-only'])
            source(tcl)
            rtl,tb = verify_selection(tcl,variant)
            assert not calls and not out.exists()
            assert any('SOURCE PREFLIGHT ONLY' in x for x in output)
            results.append({'name':variant+' source preflight','passed':True,'rtl_count':len(rtl),'tb_count':len(tb)})
            for run in (False,True):
                out = folder / ('mock-'+variant+('-run' if run else '-create'))
                args = ['-variant',variant,'-part','xc7a35tcsg324-1','-out-dir',out]
                if run:args.append('-run')
                tcl,calls,output = interpreter(args,mode='mock')
                source(tcl)
                verify_selection(tcl,variant)
                assert calls[0][0] == 'create_project'
                assert calls[-1][0] == 'close_project'
                assert all('-force' not in c[1] and '-quiet' not in c[1] for c in calls)
                selected = [c for c in calls if c[0]=='add_files']
                assert len(selected)==2
                assert selected[0][1][:3] == ['-norecurse','-fileset','sources_1']
                assert selected[1][1][:3] == ['-norecurse','-fileset','sim_1']
                top,bench,_ = VARIANTS[variant]
                props=[x[1] for x in calls if x[0]=='set_property']
                assert ['top',top,'sources_1'] in props
                assert ['top',bench,'sim_1'] in props
                file_types = [p for p in props if p[:2] == ['file_type','SystemVerilog']]
                assert len(file_types) == 1
                assert [str(x) for x in tcl.splitlist(file_types[0][2])] == [str(x) for x in tcl.splitlist(tcl.getvar('org_bench'))]
                if run:
                    assert ['launch_simulation',['-mode','behavioral','-simset','sim_1']] in calls
                    assert ['run',['-all']] in calls and ['close_sim',[]] in calls
                    assert any('PASS marker verified' in x for x in output)
                else:
                    assert not any(c[0] in {'launch_simulation','run','close_sim'} for c in calls)
                results.append({'name':variant+(' mocked simulation' if run else ' mocked project creation'),'passed':True})
        existing = folder/'existing';existing.mkdir()
        sentinel = existing/'retain.txt';sentinel.write_bytes(b'do not overwrite')
        for check_only in (False,True):
            args = ['-variant','reference','-out-dir',existing]
            if check_only:args.append('-check-only')
            calls,_ = expect_error(args,'Output path already exists',mode='mock')
            assert not calls and sentinel.read_bytes()==b'do not overwrite'
        existing_file = folder/'existing-file';existing_file.write_bytes(b'retain file')
        calls,_ = expect_error(['-out-dir',existing_file], 'Output path already exists',mode='mock')
        assert not calls and existing_file.read_bytes()==b'retain file'
        results.append({'name':'existing output directories and files rejected without mutation','passed':True})
        for args, message in [(['-variant'],'Missing value'),(['-unknown'],'Unknown option'),
                              (['-variant','missing'],'Unknown variant')]:
            calls,_ = expect_error(args,message,mode='mock');assert not calls
        results.append({'name':'malformed and unknown options rejected before project creation','passed':True})
        expect_error(['-out-dir',folder/'no-vivado'],'Run this script with Vivado')
        results.append({'name':'plain Tcl cannot claim project creation','passed':True})
        for log_mode,msg in [('missing','PASS marker not found'),('failure','contains a failure')]:
            expect_error(['-out-dir',folder/('badlog-'+log_mode),'-run'],msg,mode='mock',log_mode=log_mode)
            results.append({'name':log_mode+' simulation log rejected','passed':True})
        expect_error(['-out-dir',folder/'compile-error','-run'],'injected launch_simulation failure',mode='mock',fail_command='launch_simulation')
        results.append({'name':'Vivado compile/elaboration error propagates','passed':True})
    result={'passed':True,'vivado_executed':False,'method':'tkinter.Tcl source preflight and mocked Vivado command flow, not Vivado compilation or simulation.',
            'script_sha256':hashlib.sha256(SCRIPT.read_bytes()).hexdigest(),'variant_count':len(VARIANTS),'checks':results}
    if options.report:
        options.report.parent.mkdir(parents=True,exist_ok=True)
        options.report.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(f'PASS: {len(results)} Tcl checks for {len(VARIANTS)} variants; source selection, mocked creation/run flow, error propagation and no-overwrite guards. Vivado not executed.')


if __name__ == '__main__':
    main()
