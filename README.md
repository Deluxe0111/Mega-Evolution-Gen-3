# Mega Evolution Gen 3

**Standalone Mega Evolution project for Gen1Recomp's Generation 3 games:** FireRed, LeafGreen, Ruby, Sapphire and Emerald.

> **Status: source assets imported / gameplay not implemented (v0.1.0).**
> The mod's `main.lua` is an intentionally non-invasive scaffold. Mega Evolution, battle transformation, Mega Stones, battle sprites and items are **not currently playable**.

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
- An asset import/checker tool and a safe Gen1Recomp Mod API 2 scaffold.
- A **PNG animation atlas converter** with strict geometry audit, lossless frame packing, preview GIFs and a six-variant Mega Venusaur proof build. **Not wired into the game yet.**

**These are original EBDX PNG source sheets, not yet an animated Gen1Recomp sprite atlas.** Having art in Git does not mean the corresponding battle mechanic is implemented or that a shiny variant is visually distinct.

## Repository layout

```text
manifest.json                 Gen1Recomp mod metadata
main.lua                      No-op API scaffold (no battle hooks yet)
assets/
  source/ebdx/
    megas/                    Original EBDX form art + cries (committed)
    mega_stones/              Item icons (committed)
    ui_reference/             Reference UI artwork (committed)
    source_metadata/          Original PBS definitions and upstream credits
    mega_forms.json           Parsed source form definitions
    mega_roster.csv           Stable form/filename mapping
  runtime/                    Future Gen1Recomp-ready animation atlases
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

1. **Animation atlas pipeline (implemented):** validate EBDX horizontal PNG frame strips, pack six variants into atlas pages, and generate Mega Venusaur GIF previews. Inspect preview frames and adjust timing/placement before gameplay integration.
2. **Runtime animation renderer (next):** load form-keyed atlas data, draw live animation and compose safely with G9 Battle Sprites/HD Sprites without creating permanent species IDs.
3. Implement the battle transformation for Mega Venusaur, including accurate stats/ability changes and safe reversion.
4. Expand to other Mega forms and test all five Gen 3 games and optional mods.

See [Roadmap](docs/ROADMAP.md), [Animation pipeline](docs/ANIMATION_PIPELINE.md), [Asset import](docs/ASSET_IMPORT.md), [Implementation notes](docs/IMPLEMENTATION_NOTES.md) and [Development guide](docs/DEVELOPMENT.md).

To generate animated Mega Venusaur GIF previews on Windows, run **4_PREVIEW_MEGA_VENUSAUR.bat**; the originals are left untouched.

## Credits and rights

Mega artwork credits: [Aronousqui20](https://www.deviantart.com/aronousqui20/gallery) and [mangalos810](https://www.deviantart.com/mangalos810/gallery/103628774/new-work). See [CREDITS.md](CREDITS.md) and `assets/source/ebdx/source_metadata/README.md` for the wider EBDX contributor list. Artwork, audio, icons and code can have **different permissions**; do not treat those assets as one blanket-licensed package.

**Project repository:** [Deluxe0111/Mega-Evolution-Gen-3](https://github.com/Deluxe0111/Mega-Evolution-Gen-3).
