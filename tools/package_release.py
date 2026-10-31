#!/usr/bin/env python3
"""Validate and package a reproducible Gen1Recomp Mega Evolution player archive.

Public redistribution is permitted only after the project maintainer has
verified applicable third-party asset licences and permissions.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parent.parent
ALLOWED = (
    "src/*.lua",
    "data/*.lua",
    "assets/runtime/atlas/*.png",
    "assets/source/ebdx/mega_stones/*.png",
    "assets/source/ebdx/megas/*/icon*.png",
    "assets/source/ebdx/megas/*/cry.ogg",
)
REQUIRED = (
    "manifest.json",
    "main.lua",
    "README.md",
    "CREDITS.md",
    "assets/runtime/mega_atlas_index.lua",
    "assets/source/ebdx/ui_reference/Graphics/EBDX/Pictures/UI/megaButton.png",
    "assets/source/ebdx/ui_reference/Graphics/EBDX/Pictures/UI/symMega.png",
    "assets/source/ebdx/ui_reference/Graphics/EBDX/Pictures/mega_sym.png",
    "assets/source/ebdx/ui_reference/Graphics/Items/MEGARING.png",
    "assets/source/ebdx/SOURCE_AND_CREDITS.txt",
    "assets/source/ebdx/source_metadata/README.md",
)


def inventory():
    selected = {ROOT / rel for rel in REQUIRED}
    for pattern in ALLOWED:
        selected.update(path for path in ROOT.glob(pattern) if path.is_file())
    missing = sorted(p.relative_to(ROOT).as_posix() for p in selected if not p.is_file())
    if missing:
        raise ValueError("Missing required release files:\n  " + "\n  ".join(missing))
    files = sorted(selected, key=lambda path: path.relative_to(ROOT).as_posix())
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    if not re.fullmatch(r"\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?", manifest["version"]):
        raise ValueError("Manifest version is not a semantic version")
    if manifest.get("entry") != "main.lua":
        raise ValueError("Manifest entry does not match packaged runtime")

    index = json.loads((ROOT / "assets/runtime/mega_atlas_index.json").read_text(encoding="utf-8"))
    forms = index.get("forms", {})
    if len(forms) != 98:
        raise ValueError(f"Expected 98 indexed Mega forms, found {len(forms)}")
    referenced = set()
    for slug, entry in forms.items():
        for variant, spec in entry.get("variants", {}).items():
            for segment in spec.get("segments", []):
                referenced.add(f"assets/runtime/atlas/battle_{variant}_{segment['sheet']}.png")
    included = {path.relative_to(ROOT).as_posix() for path in files}
    # Party and summary icons load directly from source strips, not only the atlas.
    # Omitting these images makes Mega icons disappear in FireRed/other party menus.
    missing_icons = sorted(
        f"assets/source/ebdx/megas/{slug}/{name}"
        for slug in forms
        for name in ("icon.png", "icon_shiny.png")
        if f"assets/source/ebdx/megas/{slug}/{name}" not in included
    )
    if missing_icons:
        raise ValueError("Missing direct party-icon strips:\n  " + "\n  ".join(missing_icons))
    missing_pages = referenced - included
    if missing_pages:
        raise ValueError("Missing referenced atlas pages:\n  " + "\n  ".join(sorted(missing_pages)))
    if len(list(ROOT.glob("assets/source/ebdx/mega_stones/*.png"))) != 92:
        raise ValueError("Expected 92 Mega Stone icon PNGs")
    if not (ROOT / "assets/source/ebdx/ui_reference/Graphics/Items/MEGARING.png").is_file():
        raise ValueError("Key Stone icon is missing")
    credits = (ROOT / "CREDITS.md").read_text(encoding="utf-8")
    if "Aronousqui" not in credits or "mangalos810" not in credits:
        raise ValueError("Required sprite attribution is absent")
    prohibited = {".gba", ".gbc", ".gb", ".sav", ".srm", ".iso", ".nds", ".exe"}
    unexpected = [name for name in included if Path(name).suffix.lower() in prohibited]
    if unexpected:
        raise ValueError("ROM/save/executable paths cannot be packaged: " + ", ".join(unexpected))
    return files, manifest["version"], len(referenced)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Audit runtime package inventory only; write nothing")
    parser.add_argument("--rights-cleared", action="store_true",
                        help="Confirm distribution rights have been checked for bundled artwork/audio")
    parser.add_argument("--private-preview", action="store_true",
                        help="Build an installable test archive for private review; not a rights-cleared public release")
    parser.add_argument("--out-dir", type=Path, default=ROOT / "dist")
    args = parser.parse_args()
    files, version, pages = inventory()
    cries = len(list(ROOT.glob("assets/source/ebdx/megas/*/cry.ogg")))
    print(f"Inventory OK: {len(files)} files, {pages} referenced atlas pages, {cries} imported Mega cries.")
    if args.check:
        return
    if args.rights_cleared == args.private_preview:
        parser.error("Use --private-preview for a private test ZIP or --rights-cleared for a public release ZIP")
    args.out_dir.mkdir(parents=True, exist_ok=True)
    suffix = "-private-preview" if args.private_preview else ""
    name = f"mega-evolution-gen3-v{version}{suffix}.zip"
    output = args.out_dir / name
    with ZipFile(output, "w", compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for file in files:
            rel = file.relative_to(ROOT).as_posix()
            metadata = ZipInfo(rel, date_time=(2020, 1, 1, 0, 0, 0))
            metadata.create_system = 3
            metadata.external_attr = 0o100644 << 16
            metadata.compress_type = ZIP_DEFLATED
            archive.writestr(metadata, file.read_bytes(), compress_type=ZIP_DEFLATED, compresslevel=9)
    with ZipFile(output) as archive:
        bad = archive.testzip()
        if bad:
            raise ValueError(f"Corrupt archive entry: {bad}")
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    checksum = args.out_dir / (name + ".sha256")
    checksum.write_text(f"{digest}  {name}\n", encoding="utf-8")
    print(f"Created {output} and {checksum}")


if __name__ == "__main__":
    main()
