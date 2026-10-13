"""Validate the complete extracted HDL inventory, integrity and artifact exclusions."""
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]


def main():
    book=json.loads((ROOT/'inventory.json').read_text(encoding='utf-8'))
    records=book['files']
    assert len(records)==115
    counts={group:sum(record['group']==group for record in records) for group in range(1,5)}
    assert counts=={1:10,2:56,3:42,4:7},counts
    files={record['path'] for record in records}
    actual={path.relative_to(ROOT).as_posix() for path in (ROOT/'projects').rglob('*')
            if path.is_file() and path.suffix.lower() in ['.v','.sv','.verilog']}
    assert files==actual,(files-actual,actual-files)
    for record in records:
        path=ROOT/record['path']
        assert path.is_file()
        assert hashlib.sha256(path.read_bytes()).hexdigest()==record['archived_sha256'],record['path']
        assert path.stat().st_size<100000,'Unexpected large generated file'
    forbidden={'.pdf','.pptx','.zip','.rar','.exe','.vvp','.vcd','.fst','.wdb','.png','.jpg','.jpeg','.log'}
    public=[path for path in ROOT.rglob('*') if path.is_file() and '.git' not in path.parts and '__pycache__' not in path.parts]
    assert not [path.relative_to(ROOT).as_posix() for path in public if path.suffix.lower() in forbidden]
    print('INVENTORY VERIFIED: 115 HDL files across 4 source groups; archived hashes match; no source attachments or simulation artifacts.')


if __name__=='__main__':main()
