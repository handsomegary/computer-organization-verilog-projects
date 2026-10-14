"""Check additional ZIP source bytes and portable original Vivado projects."""
from pathlib import Path
import copy
import hashlib
import json
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def metadata_digest(tree):
    tree = copy.deepcopy(tree)
    tree.set('Path', '<relocated-project>')
    for node in tree.findall('./FileSets/FileSet/File'):
        node.set('Path', '<relocated-file>')
    for node in tree.findall('./FileSets/FileSet/Config/Option'):
        if node.get('Name') == 'XSimWcfgFile':
            node.set('Val', '<relocated-waveform>')
    return digest(ET.tostring(tree, encoding='utf-8'))


def resolve_reference(xpr, text):
    assert text.startswith('$PPRDIR/'), text
    target = (xpr.parent / text[len('$PPRDIR/'):]).resolve()
    assert target.is_relative_to(ROOT.resolve()), text
    assert target.is_file(), text
    return target


def main():
    manifest = json.loads((ROOT / 'vivado-materials.json').read_text(encoding='utf-8'))
    files = manifest['zip_variant']['files']
    assert len(files) == 34
    actual = {p.relative_to(ROOT).as_posix() for p in
              (ROOT / 'projects/project_03_zip_variant').rglob('*.v')}
    assert actual == {f['path'] for f in files}
    for record in files:
        data = (ROOT / record['path']).read_bytes()
        assert record['byte_exact'] and digest(data) == record['source_sha256'] == record['archived_sha256'], record['path']
        assert len(data) == record['source_bytes']
        assert not re.search(rb'110501[0-9]{3}|[A-Za-z]:[/\\](?:Users|USER|user)|/home/|/Users/', data), record['path']
    assert sum(f['matches_project_02_original_bytes'] for f in files) == 32
    assert len(manifest['zip_variant']['comparison']['different_rom_paths']) == 2
    projects = manifest['projects']
    assert len(projects) == 6
    assert {p.relative_to(ROOT).as_posix() for p in (ROOT/'projects').rglob('*.xpr')} == {p['path'] for p in projects}
    count = 0
    for record in projects:
        path = ROOT / record['path']
        data = path.read_bytes()
        assert digest(data) == record['portable_xpr_sha256']
        assert not re.search(rb'[A-Za-z]:[/\\]|/home/|/Users/|110501[0-9]{3}', data), record['path']
        tree = ET.fromstring(data)
        assert tree.get('Path') == path.name
        assert metadata_digest(tree) == record['preserved_metadata_sha256'], record['path']
        assert record['vivado_version'].encode() in data
        options = {o.get('Name'): o.get('Val') for o in tree.findall('./Configuration/Option')}
        assert options['Part'] == record['part']
        refs = {(f['fileset'], f['xpr_reference']):f for f in record['files']}
        actual_refs = set()
        for fs in tree.findall('./FileSets/FileSet'):
            expected = next(f for f in record['filesets'] if f['name'] == fs.get('Name'))
            assert expected['type'] == fs.get('Type')
            preserved = [dict(o.attrib) for o in fs.findall('./Config/Option') if o.get('Name') != 'XSimWcfgFile']
            assert preserved == expected['options']
            for node in fs.findall('./File'):
                key = (fs.get('Name'),node.get('Path'))
                target = resolve_reference(path,node.get('Path'))
                assert target.relative_to(ROOT.resolve()).as_posix() == refs[key]['path']
                assert digest(target.read_bytes()) == refs[key]['sha256']
                actual_refs.add(key)
                count += 1
            for option in fs.findall('./Config/Option'):
                if option.get('Name') == 'XSimWcfgFile' and option.get('Val'):
                    resolve_reference(path, option.get('Val'))
        assert actual_refs == set(refs)
        for extra in record['supplementary_files']:
            data = (ROOT / extra['path']).read_bytes()
            assert digest(data) == extra['source_sha256'] == extra['archived_sha256']
            assert not re.search(rb'[A-Za-z]:[/\\]|/home/|/Users/|110501[0-9]{3}',data)
    assert count == 98
    print('PASS: 34 exact ZIP HDL files; six portable XPRs; 98 existing source/waveform references; original filesets/top/generics/part/version retained.')


if __name__ == '__main__':
    main()
