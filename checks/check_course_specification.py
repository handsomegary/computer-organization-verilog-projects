"""Verify the byte-exact official assignment deck and its embedded assets."""
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / "originals/specifications.json").read_text(encoding="utf-8"))
for record in manifest["documents"]:
    path = root / record["path"]
    assert path.is_file(), record["path"]
    assert hashlib.sha256(path.read_bytes()).hexdigest() == record["sha256"], record["path"]
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None
        slides = [n for n in archive.namelist() if n.startswith("ppt/slides/slide") and n.endswith(".xml")]
        media = [n for n in archive.namelist() if n.startswith("ppt/media/")]
        assert len(slides) == record["slides"]
        assert len(media) == record["embedded_media_files"]
        for name in archive.namelist():
            if name.endswith(".rels"):
                assert not any(item.get("TargetMode") == "External" for item in ET.fromstring(archive.read(name))), name
print("PASS official project specification: original SHA256, slides and all embedded media; no external linked assets")
