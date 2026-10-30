#!/usr/bin/env python3
"""Validate a generated 98-form EBDX Mega atlas without loading PNG pixels.

Run after tools/build_mega_atlas.py; validates schema and every frame range.
"""
from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "assets/runtime"
INDEX = DEST / "mega_atlas_index.json"
SOURCE = ROOT / "assets/source/ebdx"
KINDS = ("front", "front_shiny", "back", "back_shiny", "icon", "icon_shiny")


def dimensions(path):
    with path.open("rb") as file:
        header = file.read(24)
    assert header[:8] == b"\x89PNG\r\n\x1a\n" and header[12:16] == b"IHDR", path
    return struct.unpack(">II", header[16:24])


def main():
    index = json.loads(INDEX.read_text(encoding="utf8"))
    roster = json.loads((SOURCE / "mega_forms.json").read_text(encoding="utf8"))["forms"]
    assert len(roster) == 98, len(roster)
    assert len(index["forms"]) == 98
    assert index["schema"] == 1
    assert (DEST / "mega_atlas_index.lua").is_file()
    page_dims = {}
    nframes = 0
    for form in roster:
        slug = form["slug"]
        entry = index["forms"][slug]
        assert entry["pbs_key"] == form["pbs_key"]
        assert set(entry["variants"]) == set(KINDS)
        for kind in KINDS:
            cell = entry["variants"][kind]
            fs = cell["fs"]
            count = cell["frames"]
            assert fs > 0 and count >= 1 and 1 <= cell["fps"] <= 60
            source_w, source_h = dimensions(SOURCE / "megas" / slug / f"{kind}.png")
            assert fs == source_h and count * fs == source_w, (slug, kind)
            segments = cell["segments"]
            assert segments, (slug, kind)
            next_first = 0
            for seg in segments:
                assert seg["first"] == next_first, (slug, kind)
                assert seg["fs"] == fs and seg["frames"] >= 1
                assert seg["cols"] >= 1
                assert seg["ox"] >= 0 and seg["oy"] >= 0
                # Optional motion-preserving common crop. Without these fields
                # legacy packed atlases still use source-square frame geometry.
                fw, fh = seg.get("fw", fs), seg.get("fh", fs)
                cx, cy = seg.get("cx", 0), seg.get("cy", 0)
                assert 0 < fw <= fs and 0 < fh <= fs
                assert 0 <= cx <= fs - fw and 0 <= cy <= fs - fh
                page = DEST / "atlas" / f"battle_{kind}_{seg['sheet']}.png"
                if page not in page_dims:
                    page_dims[page] = dimensions(page)
                width, height = page_dims[page]
                row_count = (seg["frames"] + seg["cols"] - 1) // seg["cols"]
                step_x, step_y = seg.get("stepX", fw), seg.get("stepY", fh)
                gutter = seg.get("gutter", 0)
                assert step_x >= fw and step_y >= fh and gutter >= 0
                assert step_x >= fw + 2 * gutter and step_y >= fh + 2 * gutter
                cols_used = min(seg["frames"], seg["cols"])
                assert seg["ox"] + (cols_used - 1) * step_x + fw <= width, (slug, kind)
                assert seg["oy"] + (row_count - 1) * step_y + fh <= height, (slug, kind)
                next_first += seg["frames"]
            assert next_first == count, (slug, kind)
            nframes += count
    print(f"PASS: 98 forms, 588 sprite variants, {nframes:,} frames "
          f"mapped into {len(page_dims)} PNG atlas pages")


if __name__ == "__main__":
    main()
