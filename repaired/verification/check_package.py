"""Verify that the corrected CPU package includes every manifested HDL source."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    manifest = json.loads((ROOT / 'source-manifest.json').read_text(encoding='utf-8'))
    required = ['check_all.py', 'run_checks.py', 'reference_check.py',
                'repaired_pipeline.py', 'repaired_stress_run.py']
    errors = []
    for entry in manifest['files']:
        path = ROOT / entry['path']
        if not path.is_file():
            errors.append('Missing HDL: ' + entry['path'])
        elif hashlib.sha256(path.read_bytes()).hexdigest() != entry['sha256']:
            errors.append('HDL hash differs: ' + entry['path'])
    for name in required:
        if not (ROOT / 'verification' / name).is_file():
            errors.append('Missing verification runner: ' + name)
    if errors:
        raise SystemExit('\n'.join(errors))
    print(f"PASS: {len(manifest['files'])} corrected/reference HDL sources and all verification runners present.")


if __name__ == '__main__':
    main()
