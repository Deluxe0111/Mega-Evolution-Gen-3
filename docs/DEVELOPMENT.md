# Development and contribution guide

**Current status:** This is a Beta Gen 3 Mega Evolution mechanics mod with 98 Mega form entries, a battle command, item/shop registration, runtime art, modern ability integrations and a ROM-aware trainer roster. The older prototype-only statements have been superseded.

## Checkout and validation

Clone the repository from [Deluxe0111/Mega-Evolution-Gen-3](https://github.com/Deluxe0111/Mega-Evolution-Gen-3), then work from the repository root.

Requirements: **Python 3.11+**, **Lua 5.4** for unit tests, and a compatible **Gen1Recomp** build for live tests. Source import tools have no required third-party Python modules for the base validation commands.

```powershell
py -3 tests/check_project.py
py -3 tools/validate_assets.py --root assets/source/ebdx --strict --no-report
lua tests/test_mega_boss_roster.lua
lua tests/test_mega_trainer_audit_menu.lua
```

For the full runtime suite and atlas checks, follow `.github/workflows/runtime-art-provider.yml`, `.github/workflows/validate.yml` and the other workflow scripts. Developers should run relevant focused Lua tests when touching abilities, battle UI, party display or animation.

## Source and runtime boundaries

- `data/mega_forms.lua`: stable Mega slug, original form, stone and sprite mapping.
- `data/mega_battle_forms.lua`: base stats, type and ability settings derived from the pinned form dataset.
- `data/mega_items.lua`: fixed item ID assignments **must never be renumbered** once saves use them.
- `src/mega_standalone.lua`: wraps existing Gen1Recomp battle functions; preserve previous wrapper chains and avoid replacing another mod's global rendering APIs.
- `src/mega_boss_roster.lua`: only operate on a **copied per-battle foe party**, after validating the imported ROM's real ID, species, level, class and game edition.
- `src/mega_atlas.lua`: render temporary Mega forms, not the ordinary G9/HD art provider's generic Pokémon assets.

The manifest declares `engine_internals`, as the mod requires and wraps Gen1Recomp's private battle modules. This is expected for the current architecture; the project does not need network access.

The mod should **never change a Pokémon's saved species or encounter identity** when Mega Evolving. Track missing newer moves/types/abilities as integration gaps, not as if the base Gen3 engine supported them automatically. See [Architecture](ARCHITECTURE.md).

## Asset workflow

- Original credited art remains under `assets/source/ebdx`. It includes files referenced at runtime (notably item icons and audio), not merely disposable intermediate build assets.
- Packed PNG atlases and indexed lookup files live in `assets/runtime`; regeneration runs through `tools/build_mega_atlas.py`.
- The pinned upstream source and credit record are described in [Asset import](ASSET_IMPORT.md) and [Credits](../CREDITS.md).
- Importer logs, local asset coverage reports, Python caches and generated previews are ignored. Commit deliberate changes to runtime art and matching indexes together.
- Do **not** blanket-relicense third-party artwork, item icons, cries or underlying EBDX source contributions.

## Changes and pull requests

1. Branch from `main` and keep gameplay, art and documentation changes separate where possible.
2. Document which Gen1Recomp version, imported ROM and optional content mods were used; put every new dependency's exact `manifest.json` ID and GitHub source in the manifest/docs.
3. Add or update Lua regression cases for new battle logic, with both allowed and fail-closed scenarios.
4. Run focused checks and verify live FireRed/Emerald gameplay for battle-hook changes.
5. Open a PR explaining runtime impact, required dependencies, release/asset implications, test evidence and remaining gaps. Never merge merely because a workflow ran; inspect its actual result.

### Adding new trainer decisions

- First export **START → MEGA AUDIT → SELECT** from the target imported ROM.
- Match name, class, numerical ID and **complete ordered party**, including level.
- Record the approved Mega slug and action (existing, add, replace, disable).
- Replace a full-party member only after an explicit per-encounter decision. Keep scripted signature species where approved.
- In doubles, ensure the target is a single-owner native trainer battle. Do not guess the partition of `twoOpponents` or `foeHalf`.
- Verify that the base species is actually registered by the current game/National Dex provider.

### Adding a dependency

Find the other mod's own `manifest.json`; use its **id**, not its repository title. Add to `optional_dependencies` if core Mega gameplay works without it, or to `dependencies` only if its absence prevents the mod loading. Add an exact repository hint in `dependency_sources` and update [Dependencies](DEPENDENCIES.md). Never vendor another mod automatically into this repository.

## Readiness and release

At present, the repository contains the working development source and art; there is **no GitHub Release**. Do not publish an incomplete, stripped ZIP (missing atlas pages, source-backed icons, cries or attribution) as a tested player build.

Follow the [Release checklist](TESTING.md), [Roadmap](ROADMAP.md) and [Installation](INSTALLATION.md) before tagging a release.
