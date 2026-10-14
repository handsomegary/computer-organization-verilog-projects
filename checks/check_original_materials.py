"""Verify declared original documents and complete local/container coverage."""
from collections import Counter
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'originals/archive/materials.json'
ARCHIVE = MANIFEST.parent


def digest(data):
    return hashlib.sha256(data).hexdigest()


def checked_path(relative):
    pure = PurePosixPath(relative)
    assert not pure.is_absolute() and '..' not in pure.parts and '\\' not in relative, relative
    path = ROOT.joinpath(*pure.parts)
    assert path.resolve().is_relative_to(ROOT.resolve()), relative
    assert path.is_file(), relative
    return path


def check_coverage_entries(entries, allowed_targets, expected_counts):
    allowed_statuses = {
        'retained_original_material', 'duplicate_original_material',
        'already_retained_hdl', 'duplicate_retained_hdl',
        'container_members_preserved_anonymously', 'retained_byte_exact_safe_container',
        'excluded_generated_or_compiled', 'intentionally_excluded_superseded',
        'intentionally_excluded_exemption_material',
    }
    assert dict(Counter(r['status'] for r in entries)) == expected_counts
    assert len({r['source_entry_id'] for r in entries}) == len(entries)
    for r in entries:
        assert re.fullmatch('[a-f0-9]{20}', r['source_entry_id'])
        assert r['status'] in allowed_statuses, r['status']
        assert r['source_bytes'] >= 0
        if 'source_sha256' in r:
            assert re.fullmatch('[a-f0-9]{64}', r['source_sha256'])
        for target in ([r['target']] if 'target' in r else r.get('targets', [])):
            assert target in allowed_targets, target
            checked_path(target)
        if r['status'] in {'retained_original_material', 'duplicate_original_material',
                           'retained_byte_exact_safe_container'}:
            assert 'target' in r
        if r['status'] in {'already_retained_hdl', 'duplicate_retained_hdl'}:
            assert r.get('targets')
        if r['status'].startswith('excluded_') or r['status'].startswith('intentionally_excluded_'):
            assert r['reason']


def main():
    book = json.loads(MANIFEST.read_text(encoding='utf-8'))
    assert book['finalized'] is True and book['coverage_pending'] is False
    assert book['privacy_review']['completed'] is True
    assert book['selection_review']['latest_only_instruction_policy_verified'] is True
    records = book['files']
    paths = {r['path'] for r in records}
    assert len(paths) == len(records) == 66
    physical = {p.relative_to(ROOT).as_posix() for p in ARCHIVE.rglob('*') if p.is_file()}
    assert physical == paths | {'originals/archive/materials.json'}, (physical - paths, paths - physical)
    assert book['summary'] == {
        'new_material_file_count': len(records),
        'review_mirror_file_count': sum(r['review_mirror'] for r in records),
        'pdf_count': sum(r['path'].endswith('.pdf') for r in records),
        'pdf_page_count': sum(r.get('page_count') or 0 for r in records),
        'byte_exact_file_count': sum(r['byte_exact'] for r in records),
    }
    assert book['summary']['review_mirror_file_count'] == 13
    assert book['summary']['pdf_count'] == 53 and book['summary']['pdf_page_count'] == 1810
    allowed_suffixes = {'.pdf', '.docx', '.xlsx', '.png', '.jpg', '.url', '.xise', '.ucf', '.zip', '.md'}
    for r in records:
        assert r['path'].startswith('originals/archive/')
        assert not any(token in r['path'].lower() for token in ['抵免', '免修', 'exemption', 'waiver'])
        p = checked_path(r['path'])
        assert p.suffix.lower() in allowed_suffixes, r['path']
        data = p.read_bytes()
        assert digest(data) == r['archived_sha256'], r['path']
        assert len(data) == r['archived_bytes']
        assert len(data) < 100_000_000
        assert re.fullmatch('[a-f0-9]{64}', r['source_sha256'])
        assert r['byte_exact'] == (r['source_sha256'] == r['archived_sha256'])
        if r['byte_exact']:
            assert r['source_bytes'] == r['archived_bytes']
        else:
            assert r['transformations'], r['path']
        assert r['privacyQA']
        if p.suffix.lower() == '.pdf':
            assert data.startswith(b'%PDF-') and r['page_count'] > 0
            assert r['privacyQA']['text_metadata_and_structure_identity_scan_passed']
            if r['review_mirror']:
                assert r['verification']['visual_review_completed'] is True
                assert r['privacyQA']['visual_page_review_count'] == r['page_count']
        if p.suffix.lower() in {'.docx', '.xlsx', '.zip'}:
            with zipfile.ZipFile(p) as z:
                assert z.testzip() is None
                if p.suffix.lower() in {'.docx', '.xlsx'}:
                    assert '[Content_Types].xml' in z.namelist()
                    assert ('word/document.xml' if p.suffix.lower() == '.docx' else 'xl/workbook.xml') in z.namelist()
                    if 'docProps/core.xml' in z.namelist():
                        core = ET.fromstring(z.read('docProps/core.xml'))
                        for field in core:
                            if field.tag.rsplit('}', 1)[-1] in {'creator', 'lastModifiedBy'}:
                                assert not (field.text or '').strip(), r['path']
                if p.suffix.lower() == '.docx':
                    assert r['privacyQA']['native_word_read_only_render']
                    assert r['privacyQA']['reviewed_document_sha256'] == r['archived_sha256']
                if p.suffix.lower() == '.zip':
                    assert r['category'] == 'safe_original_publisher_archive' and r['byte_exact']
                    covered = next(c for c in book['source_coverage']['containers'] if c['source_sha256'] == r['source_sha256'])
                    actual = Counter((digest(z.read(i)), i.file_size) for i in z.infolist() if not i.is_dir())
                    expected = Counter((e['source_sha256'], e['source_bytes']) for e in covered['entries'])
                    assert actual == expected
                    assert all(e['status'] in {'retained_original_material', 'duplicate_original_material'} for e in covered['entries'])
    for relative, sha in book['existing_integrity_baseline'].items():
        assert digest(checked_path(relative).read_bytes()) == sha, relative
    coverage = book['source_coverage']
    assert coverage['expanded_local_file_count'] == len(coverage['expanded_files']) == 684
    assert coverage['unique_container_count'] == len(coverage['containers']) == 7
    assert coverage['unhandled_noncompiled_count'] == 0
    # Existing retained HDL, portable XPR/waveform and official slides remain
    # exact manifest targets; this does not permit arbitrary extra documents.
    allowed = paths | {p.relative_to(ROOT).as_posix() for p in (ROOT / 'projects').rglob('*') if p.is_file()}
    allowed |= {r['path'] for r in json.loads((ROOT / 'originals/specifications.json').read_text(encoding='utf-8'))['documents']}
    check_coverage_entries(coverage['expanded_files'], allowed, coverage['expanded_status_counts'])
    assert len({c['source_sha256'] for c in coverage['containers']}) == 7
    for container in coverage['containers']:
        assert container['file_count'] == len(container['entries'])
        assert container['container_type'] in {'zip', 'rar'} and container['occurrence_count'] > 0
        check_coverage_entries(container['entries'], allowed, container['status_counts'])
    corrupt = checked_path('originals/archive/project_01/corrupt-Final.xise').read_bytes()
    assert len(corrupt) == 37203 and corrupt == bytes(37203)
    assert checked_path('originals/archive/project_01/EX.ucf').stat().st_size == 0
    ise = checked_path('originals/archive/project_01/legacy-ise.xise')
    tree = ET.parse(ise)
    refs = [n.attrib['{http://www.xilinx.com/XMLSchema}name'] for n in tree.findall('.//{http://www.xilinx.com/XMLSchema}file')]
    assert len(refs) == 7
    for ref in refs:
        p = (ise.parent / ref).resolve()
        assert p.is_relative_to((ROOT / 'projects/project_01/rtl').resolve()) and p.is_file()
    assert len(book['superseded']) == 1
    older = book['superseded'][0]
    assert older['status'] == 'intentionally_excluded_superseded'
    assert older['source_sha256'] not in {r['source_sha256'] for r in records}
    assert older['retained_source_sha256'] in {r['source_sha256'] for r in records}
    assert older['duplicate_verification']['all_page_content_streams_equal']
    print('ORIGINAL MATERIALS VERIFIED: 66 files, 13 project companions, 684 local entries and 7 ZIP/RAR containers; no uncovered noncompiled inputs; latest-only selection; hashes and historical config status match.')


if __name__ == '__main__':
    main()
