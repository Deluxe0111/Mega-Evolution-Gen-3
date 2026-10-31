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

# The documented cross-mod dependencies must be discoverable by the
# Gen1Recomp launcher using the exact IDs from their own manifests.
expected_deps = {
    "national_dex_gen3": "poooooby/national_dex_gen3",
    "g9-battle-sprites-gen3": "poooooby/g9-battle-sprites-gen3",
    "gen3-hd-sprites": "poooooby/gen3-hd-sprites",
    "modern_spawns": "poooooby/g1r_modern_spawns",
    "untamed_advanced": "Deluxe0111/untamed-advanced",
    "nuzlocke": "Deluxe0111/nuzlocke",
}
optional = manifest.get("optional_dependencies", [])
assert len(optional) == len(set(optional)), "Duplicate optional mod IDs"
assert set(optional) == set(expected_deps), (
    "Optional dependencies changed: update verified sources + docs")
assert manifest.get("dependency_sources") == expected_deps, (
    "Missing/stale GitHub dependency source hints")
assert not manifest.get("dependencies"), "Base game should remain standalone"
assert manifest.get("experimental") is True, (
    "Do not publish an unverified build as stable")
for doc in [
    "docs/INSTALLATION.md", "docs/DEPENDENCIES.md", "docs/ARCHITECTURE.md",
    "docs/MEGA_TRAINER_REVIEW.md", "docs/TESTING.md",
]:
    assert (ROOT / doc).is_file(), "Missing maintained guide: " + doc

print("Manifest, source roster, optional dependency IDs and docs: PASS")
