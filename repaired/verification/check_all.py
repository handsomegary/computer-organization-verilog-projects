"""Run all corrected-project and authored-reference checks (Python 3 + Icarus)."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
SUITES=[('regression','run_checks.py'),('reference','reference_check.py'),
        ('pipeline','repaired_pipeline.py'),('stress','repaired_stress_run.py')]

def counts(name,data):
    if name=='regression':
        return sum(r['functional_status']=='PASS' and r['elaboration_status']=='ELABORATED' for r in data['cases']),len(data['cases'])
    if name=='reference':
        return data['summary']['passed'],data['summary']['total']
    if name=='pipeline':
        return sum(r['passed'] for r in data),len(data)
    return data['pass_count'],data['test_count']

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--iverilog',default='iverilog')
    ap.add_argument('--vvp',default='vvp')
    ap.add_argument('--iverilog-base',type=Path)
    ap.add_argument('--output-dir',type=Path,default=ROOT/'.verification-build')
    args=ap.parse_args()
    iv=Path(shutil.which(args.iverilog) or args.iverilog).resolve()
    vv=Path(shutil.which(args.vvp) or args.vvp).resolve()
    if not iv.is_file() or not vv.is_file():
        ap.error('Icarus Verilog is required; install iverilog/vvp or pass their paths.')
    os.environ['PATH']=str(iv.parent)+os.pathsep+os.environ.get('PATH','')
    output=args.output_dir.resolve();output.mkdir(parents=True,exist_ok=True)
    common=['--iverilog',str(iv),'--vvp',str(vv)]
    if args.iverilog_base:
        common+=['--iverilog-base',str(args.iverilog_base.resolve())]
    def run(suite):
        name,script=suite
        target=output/name;target.mkdir(exist_ok=True)
        cmd=[sys.executable,str(ROOT/'verification'/script),*common,'--output-dir',str(target)]
        with (target/'runner.log').open('w',encoding='utf-8') as log:
            process=subprocess.run(cmd,cwd=ROOT,stdin=subprocess.DEVNULL,stdout=log,stderr=subprocess.STDOUT)
        result=target/'results.json'
        passed,total=counts(name,json.loads(result.read_text(encoding='utf-8'))) if result.exists() else (0,0)
        row=dict(suite=name,returncode=process.returncode,passed=passed,total=total,
                 ok=process.returncode==0 and total>0 and passed==total,
                 results=str(result),log=str(target/'runner.log'))
        print(f"{name}: {passed}/{total} {'PASS' if row['ok'] else 'FAIL'}",flush=True)
        return row
    with ThreadPoolExecutor(max_workers=4) as pool:
        suites=list(pool.map(run,SUITES))
    manifest=ROOT/'source-manifest.json'
    summary=dict(passed=sum(r['passed'] for r in suites),total=sum(r['total'] for r in suites),
                 all_passed=all(r['ok'] for r in suites),suites=suites,
                 manifest_sha256=hashlib.sha256(manifest.read_bytes()).hexdigest())
    (output/'summary.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
    print(f"ALL: {summary['passed']}/{summary['total']}",flush=True)
    return int(not summary['all_passed'])

if __name__=='__main__':
    raise SystemExit(main())
