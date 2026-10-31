# Implementation overview

This project is a Gen1Recomp **Gen 3 content mod**, not a ROM hack or Pokémon Essentials plugin. Its game-facing code is Lua, battle-art processing is Python, and output art is retained as indexed PNG atlases.

## Main runtime modules

| Location | Responsibility |
| --- | --- |
| `manifest.json` / `main.lua` | Mod identity, startup, item/option registration, exported Mega API, feature setup |
| `data/mega_forms.lua`, `data/mega_battle_forms.lua`, `data/mega_items.lua` | Mega forms, stats/typing/ability metadata and 92 stone IDs + Key Stone |
| `src/mega_selection.lua`, `src/mega_eligibility.lua`, `src/mega_battle.lua` | One-Mega rule, eligibility, temporary form and combat stats |
| `src/mega_standalone.lua`, `src/mega_battle_ui.lua` | Scoped wrappers around existing native Gen 3 battle entrypoints and UI |
| `src/mega_trainer_policy.lua`, `src/mega_boss_roster.lua` | NPC Mega selection and ROM-verified curated boss parties |
| `data/mega_boss_selections.lua`, `data/mega_trainer_choices.lua` | Approved boss decisions and per-game overrides |
| `src/mega_trainer_audit_model.lua`, `src/mega_trainer_audit_screen.lua` | In-game read-only trainer audit and text export |
| `src/mega_atlas.lua`, `data/mega_presentation.lua`, `assets/runtime/` | Lazy battle art, animation frames, calibrated presentation |
| `src/mega_item_icons.lua`, `src/mega_lab_shop.lua` | Native Bag icons and Oak/Birch laboratory shop |
| `src/mega_*abilities*.lua` and focused ability modules | Modern Mega ability effects that require explicit Gen 3 integration |
| `tools/` and `tests/` | Asset import, atlas validation and regression coverage |

### Runtime ownership rules

- **Species ownership:** The native game/National Dex provider owns actual species IDs and permanent Pokémon data. Mega forms are temporary battle overlays.
- **Normal artwork ownership:** G9 Battle Sprites and HD mods own their ordinary Pokémon rendering hooks. Mega art is selected for the active Mega battler, not installed as an unconditional global Pokémon sprite replacement.
- **Trainer data ownership:** The imported ROM trainer pack is read-only. Party add/swap operations copy only the per-encounter foe party and validate the original ROM species/levels.
- **Compatibility:** No engine fork is needed, but this mod uses scoped wrappers on stock Gen1Recomp Lua entrypoints. Upstream changes to those entrypoints can break the integration.
- **Dependency boundaries:** Optional mods register species/art/overworld/encounter features. They are enabled independently, loaded before Mega if present, and are never copied or bundled here.

The 98 base-stat entries are checked against their pinned EBDX source
with explicitly documented official corrections. See
[Mega stat audit](MEGA_STAT_AUDIT.md) and
`data/mega_stat_errata.json` before rebuilding form tables.

## Asset pipeline

The committed source set in `assets/source/ebdx` retains attributed EBDX art, imported icons/cries, PBS metadata and a stable roster inventory. `tools/build_mega_atlas.py` converts that art into bounded PNG pages and Lua/JSON lookup tables under `assets/runtime`.

`src/mega_atlas.lua` loads only requested pages and uses per-form presentation metrics. The runtime **also accesses some source-backed icons and cries**, so do not delete source art directories simply because the atlas exists.

## Documentation by purpose

- [Install and quick start](INSTALLATION.md)
- [Dependencies and known interoperability](DEPENDENCIES.md)
- [Trainer Mega selections and ROM audit](MEGA_TRAINER_REVIEW.md)
- [Testing and release gates](TESTING.md)
- [Development and contributing](DEVELOPMENT.md)
- [Artwork attribution](../CREDITS.md)

The older design and milestone notes in `docs/` are retained for technical history; when they contradict the above documents, current code and the maintained references take precedence.
