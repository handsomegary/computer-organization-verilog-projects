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
    companion=json.loads((ROOT/'vivado-materials.json').read_text(encoding='utf-8'))
    extra={record['path'] for record in companion['zip_variant']['files']}
    assert files|extra==actual,((files|extra)-actual,actual-(files|extra))
    for record in records:
        path=ROOT/record['path']
        assert path.is_file()
        assert hashlib.sha256(path.read_bytes()).hexdigest()==record['archived_sha256'],record['path']
        assert path.stat().st_size<100000,'Unexpected large generated file'
    forbidden={'.pdf','.pptx','.zip','.rar','.exe','.vvp','.vcd','.fst','.wdb','.png','.jpg','.jpeg','.log'}
    public=[path for path in ROOT.rglob('*') if path.is_file() and '.git' not in path.parts and '__pycache__' not in path.parts]
    allowed_pptx=ROOT/'originals/計算機組織FinalProject.pptx'
    materials=json.loads((ROOT/'originals/archive/materials.json').read_text(encoding='utf-8'))
    allowed_materials={ROOT/record['path'] for record in materials['files']}
    assert not [path.relative_to(ROOT).as_posix() for path in public if path.suffix.lower() in forbidden and path!=allowed_pptx and path not in allowed_materials]
    from check_vivado_materials import main as check_vivado_materials
    check_vivado_materials()
    from check_original_materials import main as check_original_materials
    check_original_materials()
    print('INVENTORY VERIFIED: original 115 HDL files plus separate 34-file ZIP variant; hashes match; official PPTX and exact manifest-declared original materials permitted; no simulation artifacts.')


if __name__=='__main__':main()
