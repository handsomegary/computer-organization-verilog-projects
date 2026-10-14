"""Check the complete vendored repaired package and runnable case dependencies."""
import ast
import glob
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / 'repaired'


def main():
    provenance = json.loads((PACKAGE/'package-source.json').read_text(encoding='utf-8'))
    assert provenance['source_commit'] == '012b371e2ad6fd768170ad6aa9bc32254aadad04'
    records = provenance['files']
    assert len(records) == provenance['copied_tracked_files'] == 146
    assert len({record['path'] for record in records}) == len(records)
    altered_reports = []
    for record in records:
        path = PACKAGE/record['path']
        assert path.is_file(), 'Missing package file: '+record['path']
        assert path.resolve().is_relative_to(PACKAGE.resolve()), 'Path escapes repaired package'
        content = path.read_bytes()
        assert len(content) == record['packaged_bytes'], record['path']
        assert hashlib.sha256(content).hexdigest() == record['packaged_sha256'], record['path']
        assert not re.search(rb'[A-Za-z]:[\\/]+Users[\\/]', content), 'Private absolute host path: '+record['path']
        if record['source_sha256'] != record['packaged_sha256']:
            assert record['path'].startswith('reports/') and path.suffix == '.json'
            assert 'absolute host paths' in record['operation']
            altered_reports.append(record['path'])
        if path.suffix == '.py':
            ast.parse(content.decode('utf-8'), filename=record['path'])
        assert '.git' not in Path(record['path']).parts
        assert path.suffix.lower() not in {'.exe','.vvp','.vcd','.fst','.wdb','.log','.zip','.rar'}
    assert len(altered_reports) == 6
    source_manifest = json.loads((PACKAGE/'source-manifest.json').read_text(encoding='utf-8'))
    assert len(source_manifest['files']) == 124
    for record in source_manifest['files']:
        assert hashlib.sha256((PACKAGE/record['path']).read_bytes()).hexdigest() == record['sha256'], record['path']
    case_count = 0
    for file in ('cases.json','repaired_stress_cases.json'):
        cases = json.loads((PACKAGE/'verification'/file).read_text(encoding='utf-8'))
        for case in cases:
            case_count += 1
            for relative in case.get('files', []):
                assert (PACKAGE/relative).is_file(), 'Missing case dependency: '+relative
            for relative in case.get('globs', []):
                assert glob.glob(str(PACKAGE/relative)), 'Empty case source glob: '+relative
    assert case_count == 54
    for script in ('run_checks.py','reference_check.py','repaired_pipeline.py','repaired_stress_run.py','check_all.py'):
        assert (PACKAGE/'verification'/script).is_file()
    assert (PACKAGE/'README.md').is_file()
    print('REPAIRED PACKAGE VERIFIED: 146 upstream files, 124 unchanged HDL hashes, 54 case dependency groups; six historical reports have sanitized host paths.')


if __name__ == '__main__':
    main()
