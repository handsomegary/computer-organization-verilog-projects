"""Check the repaired Verilog projects. Requires Python 3 and Icarus Verilog.

No source is edited by this runner. Output goes to .verification-build by default.
Nonzero compile statuses and all diagnostics are always retained in results.json.
"""
import argparse
import glob
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def command(args, timeout):
    # Regular files avoid inherited pipe handles in the Windows Icarus driver.
    with tempfile.TemporaryFile() as stdout, tempfile.TemporaryFile() as stderr:
        p = subprocess.Popen(args, cwd=ROOT, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr)
        timed_out = False
        try:
            code = p.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            p.kill()
            p.wait()
            code = None
        stdout.seek(0)
        stderr.seek(0)
        return {'returncode': code, 'stdout': stdout.read().decode('utf-8', errors='replace'),
                'stderr': stderr.read().decode('utf-8', errors='replace'), 'timeout': timed_out}

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--iverilog', default='iverilog')
    ap.add_argument('--vvp', default='vvp')
    ap.add_argument('--iverilog-base', type=Path, help='Optional Icarus lib/ivl directory for a portable distribution')
    ap.add_argument('--output-dir', type=Path, default=ROOT / '.verification-build')
    ap.add_argument('--case', action='append', help='Only these case IDs (repeatable)')
    ns = ap.parse_args()
    out = ns.output_dir.resolve()
    out.mkdir(parents=True, exist_ok=True)
    iv = str(Path(shutil.which(ns.iverilog) or ns.iverilog).resolve())
    vv = str(Path(shutil.which(ns.vvp) or ns.vvp).resolve())
    os.environ['PATH'] = str(Path(iv).resolve().parent) + os.pathsep + os.environ.get('PATH', '')
    manifest = json.loads((ROOT / 'source-manifest.json').read_text(encoding='utf-8'))
    altered = [r['path'] for r in manifest['files'] if not (ROOT/r['path']).is_file() or
               hashlib.sha256((ROOT/r['path']).read_bytes()).hexdigest() != r['sha256']]
    if altered:
        raise SystemExit('Current sources differ from recorded SHA-256: ' + ', '.join(altered))
    cases = json.loads((ROOT/'verification/cases.json').read_text(encoding='utf-8'))
    results = []
    for case in cases:
        if ns.case and case['id'] not in ns.case:
            continue
        files = list(case.get('files', []))
        for pattern in case.get('globs', []):
            files.extend(Path(p).relative_to(ROOT).as_posix() for p in sorted(glob.glob(str(ROOT/pattern))))
        files = list(dict.fromkeys(files))
        artifact = out / (case['id'] + '.vvp')
        if artifact.exists():
            artifact.unlink()
        cmd = [iv, '-g2012', '-Wall', '-s', case['top'], '-o', str(artifact)]
        if ns.iverilog_base:
            cmd.extend(['-B', str(ns.iverilog_base.resolve())])
        cmd.extend('-D'+d for d in case.get('defines', []))
        cmd.extend(files)
        compile_result = command(cmd, case.get('compile_timeout', 30))
        diagnostics = compile_result['stdout'] + compile_result['stderr']
        environment_warning = 'An Application Control policy has blocked this file' in diagnostics
        if compile_result['returncode'] == 0 and artifact.exists():
            compiled = 'ELABORATED'
        else:
            compiled = 'COMPILE_FAILED'
        row = {'id': case['id'], 'kind': case.get('kind', 'directed'), 'top': case['top'],
               'files': files, 'compile_command': [Path(iv).name]+cmd[1:],
               'compile': compile_result, 'elaboration_status': compiled,
               'environment_warning': environment_warning, 'artifact_generated': artifact.exists(), 'simulation': None,
               'functional_status': 'NOT_RUN', 'assertions': []}
        if artifact.exists() and compiled != 'COMPILE_FAILED' and case.get('run', False):
            sim = command([vv, str(artifact)] + case.get('args', []), case.get('timeout', 15))
            row['simulation'] = sim
            combined = sim['stdout'] + sim['stderr']
            row['assertions'] = [line for line in combined.splitlines() if re.match(r'^(PASS|FAIL|RESULT|CHECK|CHECK_FAIL|OBSERVED|FATAL)\b', line)]
            if sim['timeout']:
                row['functional_status'] = 'TIMEOUT'
            elif re.search(r'^FAIL\b', combined, re.M) or sim['returncode'] != 0:
                row['functional_status'] = 'FAIL'
            elif case.get('kind') == 'original_top':
                row['functional_status'] = 'SMOKE_ONLY_NO_ASSERTIONS'
            elif re.search(r'^PASS\b', combined, re.M):
                row['functional_status'] = 'PASS'
            else:
                row['functional_status'] = 'NO_ASSERTION_RESULT'
        results.append(row)
        print(row['id'], compiled, row['functional_status'], flush=True)
    report = {'current_sha256_verified': len(manifest['files']), 'sources_altered': altered,
              'tool': command([iv, '-V'], 15), 'cases': results}
    (out/'results.json').write_text(json.dumps(report, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')
    print('Results:', out/'results.json')
    return int(any(r['elaboration_status']=='COMPILE_FAILED' or r['functional_status'] in ('FAIL','TIMEOUT','NO_ASSERTION_RESULT') for r in results))

if __name__ == '__main__':
    sys.exit(main())
