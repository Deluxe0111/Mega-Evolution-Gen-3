# Mega Evolution Gen 3

**Mega Evolution for Pokémon FireRed, LeafGreen, Ruby, Sapphire and Emerald in [Gen1Recomp](https://github.com/bryanthaboi/gen1recomp).**

> **Status: experimental / active development.** The mod currently contains 98 Mega form entries, 92 held Mega Stones plus a Key Stone, a battle Mega command, temporary Mega form/stats/art, trainer Mega behaviour and a ROM-aware curated boss roster. Headless tests and selected gameplay scenarios have been exercised, but **full cross-mod and five-game QA is not complete**. There is **no published GitHub Release** yet.

No patched GBA ROM, game binary modification or separate Gen1Recomp engine fork is needed. Battle integration uses existing Gen 3 Lua entrypoints and may need maintenance as the host engine evolves.

## Quick start

1. Download this repository as a ZIP or clone it; import it from the Gen1Recomp launcher's **MODS** screen.
2. Enable **Mega Evolution Gen 3** for a supported Gen 3 game.
3. In Oak's Lab (FireRed/LeafGreen) or Birch's Lab (Ruby/Sapphire/Emerald), buy the **Key Stone (₽10,000)** and the Pokémon's **Mega Stone (₽5,000)** from the added lab aide.
4. Give the Pokémon its Mega Stone, open **FIGHT**, toggle Mega with **START** (or the on-screen control), then select its move.

The player gets **one Mega Evolution per battle**. The form appears before the move resolves, remains in battle through switching, and reverts after fainting/battle end. Mega Rayquaza instead requires Dragon Ascent, with that move supplied by the active game's move provider.

**[Detailed installation and troubleshooting →](docs/INSTALLATION.md)**

## Dependencies

**The base mod has no hard mod-to-mod dependencies.** Gen1Recomp is the host and is required. Additional Pokémon not in Gen 1–3 **do** require an active species provider (recommended: National Dex Gen 3). The mod's manifest declares the following verified optional IDs and source repositories so the launcher can show the correct dependencies:

| Mod | When to use |
| --- | --- |
| [National Dex Gen 3](https://github.com/poooooby/national_dex_gen3) | **Feature requirement** for later-generation Mega candidates (e.g. Glimmora, Meowstic, Tatsugiri), modern species/moves/types |
| [G9 Battle Sprites (Gen 3)](https://github.com/poooooby/g9-battle-sprites-gen3) | Expanded normal Pokémon artwork; **G9 itself requires National Dex Gen 3** |
| [Gen 3 HD Sprites / WoobleView](https://github.com/poooooby/gen3-hd-sprites) | Larger, sharper battle/presentation drawing |
| [Modern Spawns](https://github.com/poooooby/g1r_modern_spawns) | Broader wild encounter roster; complements expanded species |
| [Untamed Advanced — compatible fork](https://github.com/Deluxe0111/untamed-advanced) | Followers and overworld wild encounters |
| [Nuzlocke — Gen 3 fork](https://github.com/Deluxe0111/nuzlocke) | Nuzlocke run rules and randomiser integration |

All six are **optional to install**, but National Dex is **necessary for features involving those extra species**. Dependencies are **not bundled** with the Mega mod and aren't installed automatically by the manifest. Each repository's manifest controls its own dependencies; for example, G9 requires National Dex.

**[Exact mod IDs, install order, recommended setups and limitations →](docs/DEPENDENCIES.md)**

## Features

- **98 Mega form entries / 92 Mega Stones:** animated and static source coverage, normal/shiny front/back art, party icons, imported cries and variant-specific metadata.
- **Player battle command:** eligibility check, Key Stone and held-stone verification, move selection, transformation and persistent temporary battle form.
- **Mega combat data:** Mega base stats, type/ability overrides and focused modern ability implementations. Not all modern effects or Fairy interactions are certified with every installed species/move provider.
- **Automatic enemy trainer Megas:** chooses the last eligible Pokémon by default; one Mega per enemy side, separate from the player.
- **Curated notable trainer battles:** chosen Megas for Kanto and Hoenn leaders, Elite Four, rivals and bosses. Exact IDs, team species/levels and ROM edition are checked before any proposed addition or replacement.
- **Trainer audit menu:** **START → MEGA AUDIT**, with trainer IDs, original parties, review statuses and a text export for troubleshooting.
- **Scoped art/runtime integration:** Mega art and party icons without rewriting the saved Pokémon or taking permanent ownership of another mod's regular sprite provider.

## Trainer roster at a glance

**FireRed:** the approved boss roster includes Brock, Misty, Surge, Erika, Koga, Sabrina, Blaine, Giovanni, the Elite Four and Champion Rival. The imported-ROM audit fixes Giovanni's early Rocket battle (#348, **no Mega**) and later Rocket battle (#349, **Mega Mewtwo Y**), filters a false Champion #38, and selects the last eligible duplicate Pokémon.

**Emerald:** approved selections include Roxanne (Glimmora), Tate & Liza (Meowstic), Juan (Tatsugiri Curly), the Elite Four and major villains. Exact audited rematches now support safe replacement of Golem/Crawdaunt/Drowzee/Hypno in designated battles. Wally remains **Gardevoir selected but audit-only** until his imported-ROM trainer records are confirmed; the host's Emerald constant candidates are #519 and #656–660.

For exact rules, party fingerprints, version caveats and the complete 32-entry roster, see **[Trainer Mega choices and audit](docs/MEGA_TRAINER_REVIEW.md)**.

## Repository map

| Folder / file | Purpose |
| --- | --- |
| `manifest.json`, `main.lua` | Mod metadata, integration and exported API |
| `src/` | Temporary battle forms, Mega command, trainer roster, UI, art rendering, abilities and items |
| `data/` | Form/stone catalogue, presentation settings, curated boss selections |
| `assets/source/ebdx/` | Credited upstream art, icons, cries and source inventories; some assets are loaded at runtime |
| `assets/runtime/` | Generated atlas pages and lookup indices used in-game |
| `tools/` | Source-art import and atlas regeneration |
| `tests/` | Python validation and Lua regression suites |
| `docs/` | Installation, dependencies, architecture, playtesting and development |

**Do not remove source artwork assuming it is only a build input.** Certain item icons and audio assets are loaded directly from `assets/source/ebdx` while battle animation is loaded from `assets/runtime`.

## Development and testing

With Python 3.11+ and Lua 5.4 available:

```powershell
py -3 tests/check_project.py
py -3 tools/validate_assets.py --root assets/source/ebdx --strict --no-report
lua tests/test_mega_boss_roster.lua
lua tests/test_mega_trainer_audit_menu.lua
```

The existing GitHub Actions workflows also check the art provider, animation inventory, runtime Lua tests and trainer roster. These tests **do not** replace live gameplay QA. See [Testing and release checklist](docs/TESTING.md) and [Development guide](docs/DEVELOPMENT.md).

## Documentation

- [Install / quick start](docs/INSTALLATION.md)
- [Dependencies / compatibility](docs/DEPENDENCIES.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Trainer Mega review and exact ROM audits](docs/MEGA_TRAINER_REVIEW.md)
- [Testing / release checklist](docs/TESTING.md)
- [Full-form mechanics and limitations](docs/ALL_MEGA_ROSTER.md)
- [Animation pipeline](docs/ANIMATION_PIPELINE.md)
- [Development](docs/DEVELOPMENT.md) · [Roadmap](docs/ROADMAP.md)
- [Credits and asset rights](CREDITS.md)

## Rights and credits

Mega sprite attribution includes [Aronousqui20](https://www.deviantart.com/aronousqui20/gallery) and [mangalos810](https://www.deviantart.com/mangalos810/gallery/103628774/new-work), alongside the upstream EBDX, Pokémon Essentials and other contributor credits in [CREDITS.md](CREDITS.md) and [source_metadata/README.md](assets/source/ebdx/source_metadata/README.md).

Artwork, audio, UI assets and source code can have **different licence/permission terms**. Do not publish these as if one permissive code licence automatically covers third-party art, and never redistribute Pokémon ROM data.

---

Maintained at [Deluxe0111/Mega-Evolution-Gen-3](https://github.com/Deluxe0111/Mega-Evolution-Gen-3). **Experimental mod, not an official Pokémon project.**
