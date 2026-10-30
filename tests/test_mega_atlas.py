#!/usr/bin/env python3
"""Pixel-for-pixel synthetic tests for the PNG animation atlas builder."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import build_mega_atlas as atlas


class MegaAtlasTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.source = self.root / "assets/source/ebdx"
        self.out = self.root / "assets/runtime"
        self.forms = []
        for slug, fs, n in [("mega_small", 32, 10), ("mega_long", 64, 40)]:
            form = {"slug": slug, "species": "TEST", "form": 1,
                    "display_name": "Mega Test", "pbs_key": "TEST,1",
                    "MegaStone": "TESTITE"}
            self.forms.append(form)
            for kind in atlas.KINDS:
                path = self.source / "megas" / slug / (kind + ".png")
                path.parent.mkdir(parents=True, exist_ok=True)
                im = Image.new("RGBA", (fs * n, fs))
                for i in range(n):
                    colour = (i * 17 % 256, i * 23 % 256, i * 31 % 256, 255)
                    im.paste(Image.new("RGBA", (fs, fs), colour), (i * fs, 0))
                im.save(path)
        (self.source / "mega_forms.json").write_text(
            json.dumps({"forms": self.forms}), encoding="utf-8")

    def test_lossless_frames_and_split_pages(self):
        valid, bad = atlas.scan(self.source, self.forms)
        self.assertEqual(len(valid), 12)
        self.assertFalse(bad)
        index = atlas.build(self.source, self.out, self.forms, valid, 256, 8, 2)
        self.assertGreater(len(index["forms"]["mega_long"]["variants"]["front"]["segments"]), 1)
        for form in self.forms:
            slug = form["slug"]
            for kind in atlas.KINDS:
                with Image.open(self.source / "megas" / slug / (kind + ".png")) as original:
                    fs = original.height
                    for n in [0, 1, original.width // fs - 1]:
                        frame = original.crop((n * fs, 0, (n + 1) * fs, fs)).convert("RGBA")
                        packed = atlas.get_frame(self.out, index, slug, kind, n)
                        self.assertEqual(frame.tobytes(), packed.tobytes(),
                                         (slug, kind, n))
        self.assertIn('["mega_small"]',
                      (self.out / "mega_atlas_index.lua").read_text())
        self.assertTrue((self.out / "mega_atlas_index.json").exists())

    def test_normalized_shared_crop_preserves_flying_and_bouncing_motion(self):
        # Every frame has a different vertical pose. A per-frame crop would
        # move them all to y=0 and erase the hover/bounce animation.
        fs, count = 32, 10
        path = self.source / "megas/mega_small/back.png"
        sheet = Image.new("RGBA", (fs * count, fs))
        for i in range(count):
            top = 4 + (i % 4) * 3  # independent source-frame motion
            sheet.paste(Image.new("RGBA", (9, 6), (30 + i, 80, 200, 255)),
                        (i * fs + 6 + (i % 3), top))
        sheet.save(path)
        valid, bad = atlas.scan(self.source, self.forms)
        self.assertFalse(bad)
        index = atlas.build(self.source, self.out, self.forms, valid,
                            256, 8, 2, normalize_padding=True)
        cell = index["forms"]["mega_small"]["variants"]["back"]
        segment = cell["segments"][0]
        self.assertEqual(segment["fs"], fs)
        self.assertGreater(segment["cx"], 0)
        self.assertGreater(segment["cy"], 0)
        self.assertLess(segment["fw"], fs)
        self.assertLess(segment["fh"], fs)
        positions = []
        for i in range(count):
            original = sheet.crop((i * fs, 0, (i + 1) * fs, fs))
            packed = atlas.get_frame(self.out, index, "mega_small", "back", i)
            self.assertEqual(original.tobytes(), packed.tobytes(),
                             "normalising must not move a single opaque pixel")
            positions.append(packed.getchannel("A").getbbox()[1])
        self.assertEqual(positions, [4 + (i % 4) * 3 for i in range(count)])
        self.assertGreater(len(set(positions)), 1)

    def test_fully_transparent_animation_keeps_safe_frame_geometry(self):
        path = self.source / "megas/mega_small/front.png"
        Image.new("RGBA", (32 * 10, 32)).save(path)
        valid, bad = atlas.scan(self.source, self.forms)
        self.assertFalse(bad)
        index = atlas.build(self.source, self.out, self.forms, valid,
                            256, 8, 2, normalize_padding=True)
        seg = index["forms"]["mega_small"]["variants"]["front"]["segments"][0]
        self.assertEqual((seg["fw"], seg["fh"], seg["cx"], seg["cy"]),
                         (32, 32, 0, 0))

    def test_invalid_geometry_is_not_guessed(self):
        Image.new("RGBA", (63, 32)).save(
            self.source / "megas/mega_small/front.png")
        _, invalid = atlas.scan(self.source, self.forms)
        self.assertTrue(any(x["kind"] == "front" and x["mega"] == "mega_small"
                            for x in invalid))

    def test_missing_variant_is_reported(self):
        (self.source / "megas/mega_small/front_shiny.png").unlink()
        _, invalid = atlas.scan(self.source, self.forms)
        self.assertEqual(len(invalid), 1)

    def test_deterministic_index(self):
        valid, _ = atlas.scan(self.source, self.forms)
        atlas.build(self.source, self.out, self.forms, valid, 256, 8, 2)
        old = (self.out / "mega_atlas_index.lua").read_bytes()
        atlas.build(self.source, self.out, self.forms, valid, 256, 8, 2)
        self.assertEqual(old, (self.out / "mega_atlas_index.lua").read_bytes())


if __name__ == "__main__":
    unittest.main()
