#!/usr/bin/env python3
"""Build form-keyed, page-bounded Mega animation atlases from EBDX PNG strips.

The result is artwork only, never a replacement Pokémon species ID or battle
hook. Uses Pillow; source files are preserved without resizing or alteration.
"""
from __future__ import annotations

import argparse
import csv
import json
import math
from pathlib import Path

try:
    from PIL import Image
except ImportError as exc:
    raise SystemExit("Install Pillow first: py -3 -m pip install --only-binary=:all: Pillow==13.0.0") from exc

KINDS = ("front", "front_shiny", "back", "back_shiny", "icon", "icon_shiny")
ICON_KINDS = {"icon", "icon_shiny"}


def inspect_png(path):
    with Image.open(path) as img:
        if img.format != "PNG":
            raise ValueError("not a PNG")
        w, h = img.size
        if h <= 0 or w < h or w % h:
            raise ValueError(f"not a horizontal strip of square frames: {w}x{h}")
        return {"width": w, "height": h, "fs": h, "frames": w // h}


def common_frame_bounds(img, fs, total):
    """One alpha crop for the ENTIRE animation, never individual frames.

    The original frame origin is retained in the index, so intentional
    per-frame movement, flying height and bouncing are not re-anchored.
    Alpha is the only basis for removal: transparent RGB is irrelevant.
    """
    alpha = img.getchannel("A")
    box = None
    for n in range(total):
        local = alpha.crop((n * fs, 0, (n + 1) * fs, fs)).getbbox()
        if local is None:
            continue
        if box is None:
            box = local
        else:
            box = (min(box[0], local[0]), min(box[1], local[1]),
                   max(box[2], local[2]), max(box[3], local[3]))
    return box or (0, 0, fs, fs)


def load_forms(root, only):
    forms = json.loads((root / "mega_forms.json").read_text(encoding="utf-8"))["forms"]
    by_slug = {form["slug"]: form for form in forms}
    if len(by_slug) != len(forms):
        raise ValueError("duplicate form slugs")
    if only:
        missing = set(only) - set(by_slug)
        if missing:
            raise ValueError("unknown Mega slug(s): " + ", ".join(sorted(missing)))
        return [by_slug[slug] for slug in sorted(set(only))]
    return sorted(forms, key=lambda form: form["slug"])


def scan(root, forms):
    valid, invalid = [], []
    for form in forms:
        for kind in KINDS:
            rel = Path("megas") / form["slug"] / (kind + ".png")
            row = {"mega": form["slug"], "kind": kind, "path": rel.as_posix()}
            try:
                row.update(inspect_png(root / rel))
                valid.append(row)
            except (OSError, ValueError) as exc:
                invalid.append({**row, "error": str(exc)})
    return valid, invalid


def audit_csv(path, valid, invalid):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as file:
        writer = csv.DictWriter(file,
            fieldnames=["mega", "kind", "path", "width", "height", "fs", "frames", "error"],
            extrasaction="ignore")
        writer.writeheader()
        writer.writerows(valid + invalid)


class Pages:
    """Deterministic shelf packer with only one live RGBA atlas page at a time."""

    def __init__(self, root, variant, size):
        self.root, self.variant, self.size = root, variant, size
        self.image = None
        self.number = 0
        self.x = self.y = self.row_height = 0
        self.used_w = self.used_h = 0

    def begin(self):
        self.image = Image.new("RGBA", (self.size, self.size))
        self.x = self.y = self.row_height = self.used_w = self.used_h = 0

    def flush(self):
        if self.image is None:
            return
        if self.used_w and self.used_h:
            self.root.mkdir(parents=True, exist_ok=True)
            path = self.root / f"battle_{self.variant}_{self.number}.png"
            self.image.crop((0, 0, self.used_w, self.used_h)).save(
                path, format="PNG", optimize=True, compress_level=9)
            self.number += 1
        self.image.close()
        self.image = None

    def place(self, w, h):
        if w > self.size or h > self.size:
            raise ValueError(f"block {w}x{h} exceeds page size {self.size}")
        if self.image is None:
            self.begin()
        if self.x + w > self.size:
            self.x = 0
            self.y += self.row_height
            self.row_height = 0
        if self.y + h > self.size:
            self.flush()
            self.begin()
        x, y = self.x, self.y
        self.x += w
        self.row_height = max(self.row_height, h)
        self.used_w = max(self.used_w, self.x)
        self.used_h = max(self.used_h, self.y + h)
        return self.number, x, y


def lua_literal(obj, depth=0):
    """Render safe data literals: the index never contains executable source."""
    if obj is None:
        return "nil"
    if obj is True:
        return "true"
    if obj is False:
        return "false"
    if isinstance(obj, (int, float)):
        return str(obj)
    if isinstance(obj, str):
        return json.dumps(obj, ensure_ascii=False)
    prefix, next_prefix = "  " * depth, "  " * (depth + 1)
    if isinstance(obj, dict):
        lines = [next_prefix + "[" + lua_literal(str(key)) + "] = " +
                 lua_literal(obj[key], depth + 1) + "," for key in sorted(obj)]
    elif isinstance(obj, list):
        lines = [next_prefix + lua_literal(value, depth + 1) + "," for value in obj]
    else:
        raise TypeError(type(obj).__name__)
    return "{\n" + "\n".join(lines) + "\n" + prefix + "}" if lines else "{}"


def build(root, dest, forms, valid, page_size, fps, icon_fps, normalize_padding=False):
    geometry = {(row["mega"], row["kind"]): row for row in valid}
    atlas_root = dest / "atlas"
    atlas_root.mkdir(parents=True, exist_ok=True)
    index = {"schema": 1, "source": "EBDX horizontal square-frame PNG strips",
             "page_size": page_size, "default_fps": fps, "forms": {}}
    for form in forms:
        index["forms"][form["slug"]] = {
            "display_name": form["display_name"], "species": form["species"],
            "source_form": form["form"], "pbs_key": form["pbs_key"],
            "mega_stone": form.get("MegaStone") or None, "variants": {},
        }

    for kind in KINDS:
        # This tool only owns these generated pages, never source art.
        for old in atlas_root.glob(f"battle_{kind}_*.png"):
            suffix = old.stem[len(f"battle_{kind}_"):]
            if suffix.isdigit():
                old.unlink()
        pages = Pages(atlas_root, kind, page_size)
        for form in forms:
            slug = form["slug"]
            row = geometry[(slug, kind)]
            fs, total = row["fs"], row["frames"]
            if fs > page_size:
                raise ValueError(f"{slug}/{kind} frame size {fs} exceeds page {page_size}")
            segments = []
            with Image.open(root / row["path"]) as source:
                img = source.convert("RGBA")
                # Shared bounds are calculated across ALL frames, including
                # airborne extremes and animation poses. Never centre or
                # ground individual frames. Their displacement is original.
                cx, cy, right, bottom = (
                    common_frame_bounds(img, fs, total)
                    if normalize_padding else (0, 0, fs, fs)
                )
                fw, fh = right - cx, bottom - cy
                max_cols = page_size // fw
                capacity = max_cols * (page_size // fh)
                for first in range(0, total, capacity):
                    count = min(total - first, capacity)
                    cols = min(max_cols, max(1, math.ceil(math.sqrt(count))))
                    rows = math.ceil(count / cols)
                    sheet, ox, oy = pages.place(cols * fw, rows * fh)
                    for i in range(count):
                        x = (first + i) * fs
                        frame = img.crop((x + cx, cy, x + right, bottom))
                        pages.image.paste(frame, (ox + (i % cols) * fw,
                                                  oy + (i // cols) * fh))
                    segment = {"sheet": sheet, "first": first, "frames": count,
                               "ox": ox, "oy": oy, "cols": cols, "fs": fs}
                    if normalize_padding:
                        segment.update({"fw": fw, "fh": fh, "cx": cx, "cy": cy})
                    segments.append(segment)
                img.close()
            index["forms"][slug]["variants"][kind] = {
                "fs": fs, "frames": total,
                "fps": icon_fps if kind in ICON_KINDS else fps,
                "segments": segments,
            }
        pages.flush()
        print(f"  {kind}: {pages.number} PNG page(s)")
    dest.mkdir(parents=True, exist_ok=True)
    (dest / "mega_atlas_index.json").write_text(
        json.dumps(index, indent=2, sort_keys=True, ensure_ascii=False) + "\n",
        encoding="utf-8")
    (dest / "mega_atlas_index.lua").write_text(
        "-- Generated by tools/build_mega_atlas.py; art keys are NOT species slots.\n"
        + "return " + lua_literal(index) + "\n", encoding="utf-8")
    return index


def get_frame(dest, index, slug, kind, frame):
    cell = index["forms"][slug]["variants"][kind]
    frame %= cell["frames"]
    for seg in cell["segments"]:
        if seg["first"] <= frame < seg["first"] + seg["frames"]:
            index_in_segment = frame - seg["first"]
            size = seg["fs"]
            fw, fh = seg.get("fw", size), seg.get("fh", size)
            cx, cy = seg.get("cx", 0), seg.get("cy", 0)
            x = seg["ox"] + (index_in_segment % seg["cols"]) * fw
            y = seg["oy"] + (index_in_segment // seg["cols"]) * fh
            page = dest / "atlas" / f"battle_{kind}_{seg['sheet']}.png"
            with Image.open(page) as image:
                cropped = image.crop((x, y, x + fw, y + fh)).convert("RGBA")
                if fw == size and fh == size and cx == 0 and cy == 0:
                    return cropped
                original = Image.new("RGBA", (size, size))
                original.paste(cropped, (cx, cy))
                return original
    raise ValueError(f"frame {frame} missing from {slug}/{kind}")


def preview(dest, index, slug):
    folder = dest / "previews"
    folder.mkdir(parents=True, exist_ok=True)
    for kind in KINDS:
        cell = index["forms"][slug]["variants"][kind]
        frames = []
        for n in range(min(96, cell["frames"])):
            image = get_frame(dest, index, slug, kind, n)
            scale = min(3, max(1, 256 // image.width))
            if scale > 1:
                image = image.resize((image.width * scale, image.height * scale),
                                     Image.Resampling.NEAREST)
            frames.append(image)
        path = folder / f"{slug}_{kind}.gif"
        frames[0].save(path, save_all=True, append_images=frames[1:],
                       duration=round(1000 / cell["fps"]), loop=0,
                       disposal=2, optimize=False)
        print(f"  preview: {path} ({len(frames)}/{cell['frames']} frames)")


def main():
    parser = argparse.ArgumentParser(description="Pack EBDX Mega animations into PNG atlas pages")
    parser.add_argument("--source", type=Path, default=Path("assets/source/ebdx"))
    parser.add_argument("--out", type=Path, default=Path("assets/runtime"))
    parser.add_argument("--report-dir", type=Path, default=Path("reports"))
    parser.add_argument("--only", action="append", default=[],
                        help="Mega slug to include; repeat to select more than one")
    parser.add_argument("--audit-only", action="store_true")
    parser.add_argument("--page-size", type=int, default=2048)
    parser.add_argument("--fps", type=int, default=8)
    parser.add_argument("--icon-fps", type=int, default=2)
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--normalize-padding", action="store_true",
                        help="Pack common transparent margins only; keep all frame-to-frame motion")
    args = parser.parse_args()
    if args.page_size < 256 or args.page_size > 4096 or args.page_size % 64:
        parser.error("page size must be 256..4096, divisible by 64")
    if not 1 <= args.fps <= 60 or not 1 <= args.icon_fps <= 60:
        parser.error("FPS must be in range 1..60")
    try:
        forms = load_forms(args.source, args.only)
        valid, invalid = scan(args.source, forms)
        audit_csv(args.report_dir / "mega_sheet_geometry.csv", valid, invalid)
        print(f"Scanned {len(forms)} forms, {len(valid)} valid strips, {len(invalid)} invalid/missing")
        for bad in invalid[:20]:
            print(f"  INVALID {bad['path']}: {bad['error']}")
        if invalid:
            return 1
        if args.audit_only:
            return 0
        index = build(args.source, args.out, forms, valid,
                      args.page_size, args.fps, args.icon_fps,
                      normalize_padding=args.normalize_padding)
        if args.preview:
            preview(args.out, index, forms[0]["slug"])
        print(f"Packed {len(forms)} forms into {args.out}")
        return 0
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
