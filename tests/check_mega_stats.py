#!/usr/bin/env python3
"""Check all 98 Mega base-stat records against pinned EBDX and audited errata.

EBDX PBS order: HP, Attack, Defense, Speed, Special Attack, Special Defense.
This protects the battle table from accidental source regeneration drift.
Official comparisons were independently reviewed against Serebii's
Sun/Moon (48 classic Megas) and Legends: Z-A (50 form entries) tables.
"""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parent.parent
source = json.loads((ROOT / "assets/source/ebdx/mega_forms.json").read_text(encoding="utf-8"))
errata = json.loads((ROOT / "data/mega_stat_errata.json").read_text(encoding="utf-8"))
runtime = (ROOT / "data/mega_battle_forms.lua").read_text(encoding="utf-8")
pattern = re.compile(
    r'\{\s*slug="([^"]+)",\s*species="([^"]+)",\s*stone="([^"]*)",'
    r'\s*move="([^"]*)",\s*baseForm=(\d+),\s*form=(\d+),'
    r'\s*stats=\{hp=(\d+),\s*attack=(\d+),\s*defense=(\d+),'
    r'\s*speed=(\d+),\s*spAtk=(\d+),\s*spDef=(\d+)\}'
)
names = ("hp", "attack", "defense", "speed", "spAtk", "spDef")
rows = {}
for match in pattern.finditer(runtime):
    slug, species, stone, move, base_form, form, *vals = match.groups()
    assert slug not in rows, f"Duplicate runtime Mega form: {slug}"
    rows[slug] = {
        "species": species, "stone": stone, "form": int(form),
        "base_form": int(base_form), "stats": dict(zip(names, map(int, vals)))
    }
assert len(rows) == len(source["forms"]) == 98, (
    f"Expected 98 source/runtime forms; found {len(rows)} runtime")
used = set()
for entry in source["forms"]:
    slug = entry["slug"]
    row = rows.pop(slug, None)
    assert row is not None, f"Missing runtime Mega form: {slug}"
    assert row["species"] == entry["species"] and row["form"] == int(entry["form"]), slug
    assert row["base_form"] == int(entry["base_form"]), slug
    assert row["stone"] == entry.get("MegaStone", ""), slug
    raw = [int(x) for x in entry["BaseStats"].split(",")]
    assert len(raw) == 6, f"Invalid source stat count: {slug}"
    expected = dict(zip(names, raw))
    if slug in errata:
        used.add(slug)
        correction = errata[slug]
        field = correction["field"]
        assert field in expected, slug
        assert expected[field] == correction["imported_value"], (
            f"Source erratum changed upstream: {slug}")
        assert correction["corrected_value"] > 0
        assert correction["pbs_key"] == entry["pbs_key"], slug
        assert correction["source"].startswith("https://"), slug
        expected[field] = correction["corrected_value"]
    assert row["stats"] == expected, (
        f"{slug}: battle stats {row['stats']} differ from verified {expected}")
    assert all(1 <= val <= 255 for val in expected.values()), slug
assert not rows, f"Unexpected runtime Mega slugs: {sorted(rows)}"
assert used == set(errata), f"Orphan stat errata: {set(errata) - used}"
# Cross-check confirmed official discrepancy and BST (including the attack correction).
assert used == {"mega_starmie"}
assert sum(
    int(x) for x in source["forms"][
        next(i for i, e in enumerate(source["forms"]) if e["slug"] == "mega_starmie")
    ]["BaseStats"].split(",")
) == 620, "Pinned source changed unexpectedly"
assert sum((60, 140, 105, 120, 130, 105)) == 660
print("PASS: 98 Mega base-stat records, source fidelity and audited Starmie correction (BST 660)")
