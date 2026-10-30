# Mega Evolution Gen 3

**Standalone Mega Evolution project for Gen1Recomp's Generation 3 games:** FireRed, LeafGreen, Ruby, Sapphire and Emerald.

> **Status: experimental Mega Venusaur gameplay on the matching Gen 3 engine hook branch (v0.1.0; not a stock-engine playable release).**
> PR #8 introduces a battle-only START toggle, selected-move activation, temporary Venusaur stats/Thick Fat and animated front/back/shiny art. It requires a **separate upstream Gen1Recomp hook PR**; on stock builds gameplay fails closed while item registration and opt-in art remain available.

## Project goal

Build an optional Mega Evolution mod that works with the original Gen 3 games and cooperates with National Dex Gen 3, G9 Battle Sprites (Gen 3), Gen 3 HD Sprites, Untamed Advanced and Nuzlocke.

- Mega Evolution is a **temporary battle form**, not a change to the saved Pokémon's species, identity, shiny status or encounter provenance.
- Support form-specific stats, types, abilities and triggers, including X/Y, Z and Mega Rayquaza.
- Use animated Gen 5-style sprites wherever available, with a static fallback and corresponding normal/shiny, front/back and icon art.
- Integrations are optional. The mod must fail safely when another mod is absent.

## What's already in the repository

- **98 EBDX Mega-form variants** (including alternate gender/form representations) with all six source-artwork variants per form: front, back, shiny front, shiny back, icon and shiny icon.
- **92 Mega Stone icons**, 97 source Mega cries and selected UI reference graphics. Mega Slowbro has no separate cry at the pinned source revision.
- Pinned EBDX source definitions and metrics, a generated Mega roster and the original upstream credits.
- An asset import/checker tool, the **156-page converted atlas and its Lua/JSON indexes**, and a safe Gen1Recomp Mod API 2 art provider.
- Explicit APIs for checking Mega forms, locating animation frames and rendering an isolated 64×64 picture entry, without changing G9 Battle Sprites' hooks.
- **92 Mega Stones and one Key Stone** registered through the public Gen 3 item registry, with fixed numeric IDs, and a strict read-only eligibility checker. These items are **not distributed to players**.
- Experimental Mega Venusaur battle integration in PR #8: explicit START toggle in the FIGHT menu, per-battler form, true Mega stats, Thick Fat and animated battle art without editing saved Pokémon. **Requires matching engine hooks**; other forms are not yet playable.

**The original EBDX strips and converted PNG atlas pages are both committed.** The atlas has 24,018 frames across 156 pages; the provider loads only the requested pages. Having renderable art does **not** mean an in-game Mega transformation is implemented.

## Repository layout

```text
manifest.json                 Gen1Recomp mod metadata
main.lua                      Opt-in artwork API exports (no battle hooks yet)
src/mega_atlas.lua            Lazy PNG atlas frame locator and picture renderer
assets/
  source/ebdx/
    megas/                    Original EBDX form art + cries (committed)
    mega_stones/              Item icons (committed)
    ui_reference/             Reference UI artwork (committed)
    source_metadata/          Original PBS definitions and upstream credits
    mega_forms.json           Parsed source form definitions
    mega_roster.csv           Stable form/filename mapping
  runtime/                    Committed PNG atlases and frame index
tools/
  extract_ebdx_megas.py       Re-import/refresh source files from pinned revision
  validate_assets.py         Verify artwork, icons and available cries
tests/check_project.py        Verify scaffold metadata and source roster
docs/                         Roadmap, asset-source contract, development notes
```

## Checking the imported artwork

Python 3 is required; the asset import and validation tools need no third-party packages.

```powershell
py -3 tests/check_project.py
py -3 tools/validate_assets.py --root assets/source/ebdx --strict
```

On Windows, `2_CHECK_EBDX_ASSETS.bat` runs the artwork checker. Reports go into the **ignored** `reports/` folder, not the committed artwork directory. CI uses `--no-report` to avoid generating files.

The source artwork has **already been imported**. `1_IMPORT_EBDX_ASSETS.bat` is for recovering or intentionally refreshing the pinned upstream set; `3_IMPORT_WITH_BASE_FORMS.bat` additionally downloads the normal/reversion form artwork. Avoid replacing hand-curated assets without reviewing the source and licences.

## Next milestones

1. Merge and validate the companion generic Gen 3 battle hook PR, then test Mega Venusaur in a disposable Emerald save.
2. Review the full move-menu behaviour and per-battler G9/HD sprite positioning, including switch/faint save safety.
3. Add the ORAS transformation cinematic/audio and complete in-game compatibility testing.
4. Expand the battle mechanics and per-form data to the remaining Mega roster.

See [Mega Venusaur playtest](docs/PLAYTEST_MEGA_VENUSAUR.md), [ORAS-style Mega battle command design](docs/MEGA_BATTLE_COMMAND.md), [Roadmap](docs/ROADMAP.md), [Four-mod rendering integration research](docs/RENDERING_INTEGRATION.md), [Animation pipeline](docs/ANIMATION_PIPELINE.md), [Asset import](docs/ASSET_IMPORT.md), [Implementation notes](docs/IMPLEMENTATION_NOTES.md) and [Development guide](docs/DEVELOPMENT.md).

## Credits and rights

Mega artwork credits: [Aronousqui20](https://www.deviantart.com/aronousqui20/gallery) and [mangalos810](https://www.deviantart.com/mangalos810/gallery/103628774/new-work). See [CREDITS.md](CREDITS.md) and `assets/source/ebdx/source_metadata/README.md` for the wider EBDX contributor list. Artwork, audio, icons and code can have **different permissions**; do not treat those assets as one blanket-licensed package.

**Project repository:** [Deluxe0111/Mega-Evolution-Gen-3](https://github.com/Deluxe0111/Mega-Evolution-Gen-3).
