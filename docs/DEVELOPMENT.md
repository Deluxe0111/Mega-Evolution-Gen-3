# Development and contribution guide

This repository is the **source foundation**, not a finished Mega Evolution gameplay mod.

## Local setup

1. Clone `https://github.com/Deluxe0111/Mega-Evolution-Gen-3.git`.
2. Install Python 3.11 or newer.
3. Run `python tests/check_project.py`.
4. Run `python tools/validate_assets.py --root assets/source/ebdx --strict`.
5. Review the source-to-runtime boundaries in [Implementation notes](IMPLEMENTATION_NOTES.md).

The artwork is already committed; there is no need to download the entire Pokémon Essentials project. The Windows import launchers are optional recovery tools.

## Source art versus runtime art

- `assets/source/ebdx`: **preserve original EBDX files** and their filename/form mapping, item images and attribution. Do not pack these unconverted files directly into a player mod release.
- `assets/runtime`: future derived atlases and metadata for Gen1Recomp.
- `reports/`: generated local audits and downloader logs; ignored by Git.
- `mega_forms.json` and `mega_roster.csv` are intentionally retained **stable source inventories**, regenerated only when the pinned upstream revision is deliberately changed.

The import is pinned in `tools/extract_ebdx_megas.py`. An upstream update needs a separate PR explaining changed forms, hashes and credits.

## Contributions

- Make focused changes in a branch and open a pull request against `main`.
- Run the project checker and strict artwork checker before proposing changes.
- Include source references and specific attribution when adding or replacing art. Do not merge artist permissions and code permissions.
- Never commit machine-specific paths, temporary download logs or raw downloads unrelated to the Mega roster.
- Keep battle hooks, save data and species-slot changes out of the source-art pipeline.
- Do not publish a playable release until the Gen 3 battle integration and actual in-game tests exist.

## Current boundaries

The `main.lua` entry point deliberately exports `isActive() == false`. The project has **not** implemented battle transformations, Mega Stone inventory entries, atlas playback, or certified compatibility with other mods.

Before a playable release, verify real FireRed and Emerald saves, then LeafGreen, Ruby and Sapphire, and test missing optional mods, shinies, Nuzlocke, battle reversion and provider-owned rendering.
