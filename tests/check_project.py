#!/usr/bin/env python3
"""Basic repository and imported EBDX source-inventory checks (stdlib only)."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
assert manifest["id"] == "mega-evolution-gen3"
assert manifest["api"] == 2
assert manifest["entry"] == "main.lua" and (ROOT / manifest["entry"]).is_file()
assert "gen3" in manifest["games"]
assert manifest["github"] == "Deluxe0111/Mega-Evolution-Gen-3"
assert re.fullmatch(r"\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?", manifest["version"])
credits = (ROOT / "CREDITS.md").read_text(encoding="utf-8")
assert "Aronousqui" in credits and "mangalos810" in credits
assert "deviantart.com" in credits.lower()

source = ROOT / "assets/source/ebdx"
roster = json.loads((source / "mega_forms.json").read_text(encoding="utf-8"))
forms = roster["forms"]
assert len(forms) == 98, f"Unexpected Mega-form count: {len(forms)}"
assert len({entry["slug"] for entry in forms}) == len(forms)
assert len({entry["pbs_key"] for entry in forms}) == len(forms)
assert (source / "mega_roster.csv").is_file()
assert (source / "source_metadata/README.md").is_file()

for form in forms:
    assert form["source_filename"].endswith(".png")
    assert form["slug"].startswith("mega_")

print("Manifest, scaffold safety, artist credits and 98-form source inventory: PASS")
