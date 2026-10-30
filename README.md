# Mega Evolution Gen 3

**Standalone Mega Evolution project for Gen1Recomp's Generation 3 games:** FireRed, LeafGreen, Ruby, Sapphire and Emerald.

> **Status: experimental full 98-form Mega roster (PR #13). Mega Venusaur is gameplay tested; the other forms require in-game QA.**
> Works against **stock Gen1Recomp** using scoped runtime wrappers on its existing Gen 3 Lua battle functions. No engine fork, binary patch, or custom Gen1Recomp hook PR is required. Engine internals can change between updates, so gameplay still needs in-game compatibility testing.

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
- **92 Mega Stones and one Key Stone** registered through the public Gen 3 item registry, with fixed numeric IDs and a strict read-only eligibility checker. A professor's lab aide offers the Key Stone for ₽10,000 and each Mega Stone for ₽5,000 through the native Poké Mart interface.
- Experimental **full-roster Mega gameplay** in PR #13: all 98 form variants from the pinned EBDX definitions can be selected with their required stones/Key Stone (Mega Rayquaza uses Dragon Ascent), and have temporary calculated stats, live battler type/ability overrides where supported, and animated battle art. **No engine changes needed.** Stock Gen 3 does not implement all newer abilities or Fairy typing, so exact mechanics still require compatibility work.

**The original EBDX strips and converted PNG atlas pages are both committed.** The atlas has 24,018 frames across 156 pages; the provider loads only the requested pages. Having renderable art does **not** mean an in-game Mega transformation is implemented.

## Repository layout

```text
manifest.json                 Gen1Recomp mod metadata
main.lua                      Mega art API, item registration and standalone bridge setup
src/mega_standalone.lua        Stock Gen 3 battle wrappers; no engine source changes
src/mega_battle.lua           Data-driven battle-only form controller for all 98 Megas
data/mega_battle_forms.lua    Generated 98-form battle stat/type/ability catalogue
src/mega_venusaur.lua        Legacy Mega Venusaur proof controller (tests only)
src/mega_selection.lua        Per-battle toggle, move commitment and Mega allowance
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

## Buying Mega Stones

Visit **Professor Oak's Lab** in Pallet Town (FireRed/LeafGreen) or **Professor Birch's Lab** in Littleroot Town (Ruby/Sapphire/Emerald). An additional scientist aide raises funds for the lab by selling special stones. Speak to the aide to open a normal in-game shop.

- **Key Stone:** ₽10,000 (one needed to use Mega Evolution; hidden from the shop on later visits once owned).
- **Mega Stones:** ₽5,000 each, all 92 varieties in alphabetical order.

The player pays using normal in-game money; purchases go to the appropriate Bag pocket. The Mega Stone must still be held by the corresponding Pokémon. The aide is placed at runtime on map entry without overwriting the starter-story NPCs, and does not appear without this mod.

## Checking the imported artwork

Python 3 is required; the asset import and validation tools need no third-party packages.

```powershell
py -3 tests/check_project.py
py -3 tools/validate_assets.py --root assets/source/ebdx --strict
```

On Windows, `2_CHECK_EBDX_ASSETS.bat` runs the artwork checker. Reports go into the **ignored** `reports/` folder, not the committed artwork directory. CI uses `--no-report` to avoid generating files.

The source artwork has **already been imported**. `1_IMPORT_EBDX_ASSETS.bat` is for recovering or intentionally refreshing the pinned upstream set; `3_IMPORT_WITH_BASE_FORMS.bat` additionally downloads the normal/reversion form artwork. Avoid replacing hand-curated assets without reviewing the source and licences.

## Next milestones

1. Test the full-roster branch on an unmodified Gen1Recomp build, especially Charizard X/Y, Rayquaza, same-stone forms and post-Gen3 species.
2. Validate G9/HD front/back/shiny presentation, switching, fainting, doubles and save isolation across the 98 forms.
3. Implement and verify post-Gen3 typing/ability compatibility, including Fairy, for forms that need it.
4. Add the full Mega transformation cinematic/audio, trainer Megas and individual form presentation calibration.

See [Full 98-form gameplay and limitations](docs/ALL_MEGA_ROSTER.md), [Mega Venusaur playtest](docs/PLAYTEST_MEGA_VENUSAUR.md), [ORAS-style Mega battle command design](docs/MEGA_BATTLE_COMMAND.md), [Roadmap](docs/ROADMAP.md), [Four-mod rendering integration research](docs/RENDERING_INTEGRATION.md), [Animation pipeline](docs/ANIMATION_PIPELINE.md), [Asset import](docs/ASSET_IMPORT.md), [Implementation notes](docs/IMPLEMENTATION_NOTES.md) and [Development guide](docs/DEVELOPMENT.md).

## Credits and rights

Mega artwork credits: [Aronousqui20](https://www.deviantart.com/aronousqui20/gallery) and [mangalos810](https://www.deviantart.com/mangalos810/gallery/103628774/new-work). See [CREDITS.md](CREDITS.md) and `assets/source/ebdx/source_metadata/README.md` for the wider EBDX contributor list. Artwork, audio, icons and code can have **different permissions**; do not treat those assets as one blanket-licensed package.

**Project repository:** [Deluxe0111/Mega-Evolution-Gen-3](https://github.com/Deluxe0111/Mega-Evolution-Gen-3).
