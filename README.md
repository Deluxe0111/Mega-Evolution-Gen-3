# Mega Evolution Gen 3

**An independent Mega Evolution project for the Generation 3 games in [Gen1Recomp](https://github.com/bryanthaboi/gen1recomp).**

Planned games: **FireRed · LeafGreen · Ruby · Sapphire · Emerald**.

> **Status: initial repository foundation (v0.1.0).** The manifest loads a no-op entry point. It does **not** yet Mega Evolve Pokémon, modify battle stats, change artwork or add items to saves. No playable version is being claimed.

## Goal

- Mega Evolve eligible Pokémon during battles, restoring their normal forms when the battle ends.
- Support Mega Stones, Mega X/Y and Z forms, Mega Rayquaza's special trigger and form-specific stats, types and abilities.
- Use Gen 5-style animated battle artwork where available, with static fallbacks. Preserve regular/shiny, front/back and party icon variants.
- Cooperate with **National Dex Gen 3**, **G9 Battle Sprites (Gen 3)**, **Gen 3 HD Sprites**, **Untamed Advanced** and **Nuzlocke**, without requiring all of them.
- Keep the Pokémon's permanent identity (species, nickname, shiny state, provenance and run history) separate from its temporary Mega battle form.

## EBDX source-art pipeline

The upstream asset source is [ChromeValiant's Pokémon Essentials / EBDX project](https://github.com/ChromeValiant/Pokemon-Essentials-21-With-Unofficial-EBDX). Its original PNG sheets are **source files**, not Gen1Recomp-compatible animated sprites yet. We keep them unchanged so a later conversion process can read their layout.

The included extractor currently targets a **pinned upstream revision** and reads the EBDX PBS form definitions. It inventories **98 Mega form variants** (including separate additional variants of Meowstic and Zygarde), six picture/icon variants per form, Mega Stones, relevant UI reference graphics and available cries. This is a *source-asset inventory*, not a claim that those forms are implemented in-game.

### Import assets on Windows

1. Make sure Python 3 is installed.
2. Double-click **`1_IMPORT_EBDX_ASSETS.bat`**. This downloads the relevant Mega art to `assets/source/ebdx/` without installing the full Essentials project.
3. Double-click **`2_CHECK_EBDX_ASSETS.bat`** to generate an asset coverage report.
4. Commit the art and reports to Git only after checking the files and their attribution.

To include original forms for reverting a Pokémon after battle, use `3_IMPORT_WITH_BASE_FORMS.bat` instead. The downloader is repeat-safe and does not overwrite existing nonempty files. You can also copy your earlier `EBDX_Mega_Assets/` folder directly into `assets/source/ebdx/` and run the checker.

### Import from command line

```powershell
py -3 tools/extract_ebdx_megas.py --out assets/source/ebdx
py -3 tools/validate_assets.py --root assets/source/ebdx
```

No external Python packages are required for the download/check steps. Sprite-sheet animation conversion is a later milestone.

## Repository layout

```text
mega-evolution-gen3/
  manifest.json           Gen1Recomp Mod API 2 metadata
  main.lua                Safe no-op mod entry
  CREDITS.md              Artist/source credits and attribution notes
  docs/                   Asset format and implementation roadmap
  tools/                  Pinned EBDX extractor and audit tool
  assets/
    source/ebdx/          Downloaded original EBDX Mega source artwork
    runtime/              Future optimised Gen1Recomp sprites/atlases
```

## Scope and compatibility

- The **Mega mod owns the transformation**; Nuzlocke should only observe the original Pokémon identity and enforce existing encounter/permadeath rules.
- Do not assign permanent National Dex slots to temporary Mega states or write modified species IDs into a save.
- The G9 Battle Sprites and HD Sprites integrations will need an explicit rendering contract; merely shipping EBDX PNG sheets does not make them animate in Gen1Recomp.
- Mega sprites, alternate forms and item data should be referenced by explicit stable IDs, never inferred from raw EBDX filename numbers at runtime.

See [Roadmap](docs/ROADMAP.md), [Asset import details](docs/ASSET_IMPORT.md), and [Credits](CREDITS.md).

## Credits

Mega battle artwork is credited to **[Aronousqui20](https://www.deviantart.com/aronousqui20/gallery)** and **[mangalos810](https://www.deviantart.com/mangalos810/gallery/103628774/new-work)** as detailed in [CREDITS.md](CREDITS.md). Credit and permission to use artwork are distinct; preserve any individual artists' terms along with the source files. This repository's starter code does not impose a licence on third-party art.
