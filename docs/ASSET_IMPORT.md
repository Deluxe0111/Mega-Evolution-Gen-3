# EBDX asset import contract

## Source revision

The included tool downloads from the fixed EBDX commit `452d27cab271f7cf8f10d07e2236abb5c53b4899`, preserving reproducible source filenames. To update the revision, review changes in the upstream form definitions, sprites and artist credits first.

Run from the repository root:

```powershell
py -3 tools/extract_ebdx_megas.py --out assets/source/ebdx --preview
py -3 tools/extract_ebdx_megas.py --out assets/source/ebdx
py -3 tools/validate_assets.py --root assets/source/ebdx
```

### File layout produced by the extractor

```text
assets/source/ebdx/
  megas/
    mega_venusaur/
      front.png
      back.png
      front_shiny.png
      back_shiny.png
      icon.png
      icon_shiny.png
      cry.ogg                Optional: some Mega forms lack a distinct cry
  mega_stones/
    VENUSAURITE.png
  ui_reference/
    Graphics/...            Original file names and directories retained
  source_metadata/
    PBS/...                 Source form, item and sprite metrics
    README.md               Complete upstream contributor credits
  mega_forms.json           Parsed form metadata including original PBS key
  mega_roster.csv
  asset_plan.csv
  download_results.csv
  missing_assets.csv
  mega_coverage.csv
```

Source files are not GIFs. EBDX `front.png`/`back.png` are sprite sheets with engine-specific animation; inspect the frame shape and timing before adapting them. This repository intentionally does not assume all sheets use the same frame count.

### What belongs in version control?

Keep the curated Mega art, corresponding item icons, source metadata, credits, and conversion scripts. Do **not** copy the entire Essentials game (`Game.exe`, engine code, ROMs, unrelated Pokémon, full audio collection, etc.). Do not overwrite existing hand-curated art blindly; maintain provenance when swapping a sprite source.

When you later implement gameplay, use parsed, explicitly mapped IDs rather than treating a Mega form's EBDX PBS index as a Gen1Recomp species slot.
