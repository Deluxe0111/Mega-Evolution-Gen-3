# Mega Evolution base-stat audit — 31 October 2026

## Result

**98/98 runtime Mega form records reviewed.** The committed EBDX input
(`assets/source/ebdx/mega_forms.json`) has 48 classic Mega records and
50 entries introduced in **Pokémon Legends: Z-A / Mega Dimension** (some
are repeated variants for forms sharing stats).

- The six base stats in `data/mega_battle_forms.lua` were independently
  checked against the published reference tables:
  - [Serebii — Sun/Moon Mega Evolution](https://www.serebii.net/sunmoon/megaevolutions.shtml)
    (48 older Mega records)
  - [Serebii — Legends: Z-A Mega Evolutions](https://www.serebii.net/legendsz-a/megaevolutions.shtml)
    (50 newer Mega form entries)
- **97 entries matched** the published tables and the pinned source as
  originally imported.
- **Mega Starmie differed:** pinned EBDX has Attack **100**; the
  published Legends: Z-A value is Attack **140**, verified again by
  [PokéJungle's stat breakdown](https://pokejungle.net/pokemon-legends-z-a/new-mega-evolutions/).
  The correct total is **660**, not 620.
- The runtime catalogue now uses Attack **140** for Mega Starmie.
  Other five base stats remain HP 60, Defense 105, Sp. Attack 130,
  Sp. Defense 105 and Speed 120.
- The original, pinned EBDX source file stays unchanged for provenance.
  The intentional runtime deviation is recorded in
  `data/mega_stat_errata.json` so rebuilding the stat table does not
  silently reintroduce Attack 100.

## Stat field order

The upstream Pokémon Essentials PBS `BaseStats` values are ordered
**HP, Attack, Defense, Speed, Special Attack, Special Defense**.
This is *not* the usual on-screen order HP, Attack, Defense,
Special Attack, Special Defense, Speed.

The runtime mapping is:

| PBS position | Runtime key |
| --- | --- |
| 1 | `hp` |
| 2 | `attack` |
| 3 | `defense` |
| 4 | `speed` |
| 5 | `spAtk` |
| 6 | `spDef` |

**Tests:** `python tests/check_mega_stats.py` verifies all 98 complete
six-stat records against their pinned source with the one explicit
cited correction, alongside species, form ID and stone. CI runs this
validator and the existing Lua 98-form battle simulation.

## Important distinction: base stats vs in-battle stats

The Pokémon's **base stats** are constants; the numbers displayed in
battle depend on level, individual values, effort values and nature.
`src/mega_battle.lua` calculates the five non-HP Mega stats using the
normal Pokémon formula and preserves current/max HP throughout
transformation, without changing the saved Pokémon. Those pathways are
tested in `tests/test_mega_full_roster.lua`.

These 98 base-stat comparisons do **not** mean all form abilities,
type changes, battle effects or art have passed cross-mod gameplay
verification. Those are documented separately in
[the ability audit](MEGA_ABILITY_AUDIT.md) and
[the test plan](TESTING.md).

## Regeneration rule

If you regenerate `data/mega_battle_forms.lua` from the pinned EBDX
dataset, **reapply every entry in `data/mega_stat_errata.json`** and
run `python tests/check_mega_stats.py`. Do not silently modify the
third-party source to conceal a discrepancy; retain traceability.
