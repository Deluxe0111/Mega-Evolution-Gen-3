#!/usr/bin/env python3
"""Read-only EBDX artwork audit; optional local CSV report is kept outside source art."""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

KINDS = ("front", "back", "front_shiny", "back_shiny", "icon", "icon_shiny")
PNG = b"\x89PNG\r\n\x1a\n"


def valid_header(path: Path, magic: bytes) -> bool:
    with path.open("rb") as handle:
        return handle.read(len(magic)) == magic


def audit(root: Path):
    metadata = root / "mega_forms.json"
    if not metadata.is_file():
        return None, []

    forms = json.loads(metadata.read_text(encoding="utf-8"))["forms"]
    report = []
    for form in forms:
        slug = form["slug"]
        # Store relative paths: CSVs may be shared without leaking a computer's home directory.
        def check(kind: str, relative: Path, magic: bytes, optional: bool = False):
            path = root / relative
            if not path.is_file():
                status = "optional_absent" if optional else "missing"
            elif not valid_header(path, magic):
                status = "invalid_png" if magic == PNG else "invalid_ogg"
            else:
                status = "ok"
            report.append({
                "mega": slug, "kind": kind, "status": status,
                "path": relative.as_posix(),
            })

        for kind in KINDS:
            check(kind, Path("megas") / slug / (kind + ".png"), PNG)

        stone = form.get("MegaStone")
        if stone:
            check("stone", Path("mega_stones") / (stone + ".png"), PNG)

        check("cry", Path("megas") / slug / "cry.ogg", b"OggS", optional=True)

    return forms, report


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate the six artwork variants of each EBDX Mega")
    parser.add_argument("--root", type=Path, default=Path("assets/source/ebdx"))
    parser.add_argument("--strict", action="store_true", help="fail if any required artwork is missing or invalid")
    parser.add_argument("--no-report", action="store_true", help="do not write an audit CSV (recommended for CI)")
    parser.add_argument("--report", type=Path, default=Path("reports/ebdx_asset_audit.csv"),
                        help="audit CSV destination (default: ignored reports/ directory)")
    args = parser.parse_args()
    root = args.root.resolve()
    forms, report = audit(root)

    if forms is None:
        print("No mega_forms.json at", root)
        return 2 if args.strict else 0

    if not args.no_report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        with args.report.open("w", encoding="utf-8-sig", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=["mega", "kind", "status", "path"])
            writer.writeheader()
            writer.writerows(report)
        print("CSV report:", args.report)

    artwork = {(row["mega"], row["kind"]): row["status"]
               for row in report if row["kind"] in KINDS}
    complete = sum(all(artwork.get((form["slug"], kind)) == "ok" for kind in KINDS)
                   for form in forms)
    missing = [row for row in report if row["status"] not in ("ok", "optional_absent")]

    print(f"Forms with complete six-variant art: {complete}/{len(forms)}")
    print(f"Missing or invalid required assets: {len(missing)}")
    for row in missing[:25]:
        print(" ", row["mega"], row["kind"], row["status"])
    if len(missing) > 25:
        print(f"  ... and {len(missing) - 25} more")

    return 1 if args.strict and missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
