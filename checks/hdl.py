"""Compile/run audit probes in temporary directories; do not change archived RTL."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]


def compile_and_run(sources,top,bench=None,run=True,timeout=15,extra_flags=()):
    compiler=os.environ.get('IVERILOG','iverilog')
    runtime=os.environ.get('VVP','vvp')
    if not shutil.which(compiler) or (run and not shutil.which(runtime)):
        raise RuntimeError('Icarus Verilog is required; CI installs iverilog/vvp.')
    with tempfile.TemporaryDirectory(prefix='cpu_audit_') as name:
        directory=Path(name)
        files=[str(ROOT/path) for path in sources]
        if bench is not None:
            probe=directory/'probe.v'
            probe.write_text(bench,encoding='utf-8')
            files.append(str(probe))
        executable=directory/'simulation.vvp'
        command=[compiler,'-g2012',*extra_flags,'-Wall','-s',top,'-o',str(executable),*files]
        compiled=subprocess.run(command,text=True,capture_output=True,timeout=timeout)
        result={'compiled':compiled.returncode==0,'diagnostics':compiled.stderr.replace(str(ROOT)+os.sep,'').replace(str(directory),'TEMP')}
        if not result['compiled'] or not run:
            return result
        try:
            simulated=subprocess.run([runtime,str(executable)],cwd=directory,text=True,capture_output=True,timeout=timeout)
            result.update(returncode=simulated.returncode,stdout=simulated.stdout,stderr=simulated.stderr)
        except subprocess.TimeoutExpired:
            result.update(returncode=None,stdout='',stderr='simulation timeout')
        return result
