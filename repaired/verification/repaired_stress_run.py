"""Run independent repaired-CPU stress assertions (Python3 + Icarus Verilog).

Run from any directory. Pass --iverilog, --vvp and optionally --iverilog-base
for a portable toolchain. Test inventory is repaired_stress_cases.json.
"""
import argparse
import glob
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def command(args, timeout=30):
    with tempfile.TemporaryFile() as stdout, tempfile.TemporaryFile() as stderr:
        p = subprocess.Popen(args, cwd=ROOT, stdin=subprocess.DEVNULL,
                             stdout=stdout, stderr=stderr)
        timed_out = False
        try:
            returncode = p.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            p.kill()
            returncode = p.wait()
        stdout.seek(0)
        stderr.seek(0)
        return dict(returncode=returncode, timeout=timed_out,
                    stdout=stdout.read().decode('utf-8', errors='replace'),
                    stderr=stderr.read().decode('utf-8', errors='replace'))


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--iverilog', default='iverilog')
    ap.add_argument('--vvp', default='vvp')
    ap.add_argument('--iverilog-base', type=Path)
    ap.add_argument('--output-dir', type=Path, default=ROOT/'.verification-stress')
    ap.add_argument('--case', action='append')
    args = ap.parse_args()
    out = args.output_dir.resolve()
    out.mkdir(parents=True, exist_ok=True)
    cases = json.loads((ROOT/'verification/repaired_stress_cases.json').read_text(encoding='utf-8'))
    results = []
    for case in cases:
        if args.case and case['id'] not in args.case:
            continue
        files = list(case.get('files', []))
        for pattern in case.get('globs', []):
            files.extend(Path(p).relative_to(ROOT).as_posix()
                         for p in sorted(glob.glob(str(ROOT/pattern))))
        artifact = out/(case['id']+'.vvp')
        if artifact.exists():
            artifact.unlink()
        cmd = [args.iverilog, '-g2012', '-Wall', '-s', case['top'], '-o', str(artifact)]
        if args.iverilog_base:
            cmd += ['-B', str(args.iverilog_base.resolve())]
        cmd += ['-D'+d for d in case.get('defines', [])]
        cmd += files
        comp = command(cmd)
        sim = command([args.vvp, str(artifact)]) if comp['returncode']==0 and artifact.exists() else None
        passed = (comp['returncode']==0 and not comp['timeout'] and sim is not None
                  and sim['returncode']==0 and not sim['timeout'] and 'PASS' in sim['stdout'])
        row = dict(id=case['id'], description=case.get('description',''), compile_command=cmd,
                   compile=comp, simulation=sim, passed=passed)
        results.append(row)
        print(case['id'], 'PASS' if passed else 'FAIL', flush=True)
        if not passed:
            print(comp['stdout']+comp['stderr']+(sim['stdout']+sim['stderr'] if sim else ''), flush=True)
    report = dict(test_count=len(results), pass_count=sum(r['passed'] for r in results), tests=results)
    (out/'results.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    return int(not all(r['passed'] for r in results))


if __name__ == '__main__':
    raise SystemExit(main())
