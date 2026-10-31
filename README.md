# Mega Evolution Gen 3

**Bring Mega Evolution to Pokémon FireRed, LeafGreen, Ruby, Sapphire and Emerald with [Gen1Recomp](https://github.com/bryanthaboi/gen1recomp).**

Experience the classic Gen 3 adventures with Mega Stones, in-battle transformations, enhanced Pokémon forms and surprise Mega-powered trainer battles — **without modifying a GBA ROM**. This mechanics mod adds **98 Mega form entries** and **92 Mega Stones**, alongside animated sprites, new battle presentation and optional integration with expanded Pokémon content packs.

> **Status: v1.0.0-Beta (pre-release).** Includes 98 Mega form entries, 92 held Mega Stones plus a Key Stone, battle Mega selection, temporary form/stats/art, trainer Mega behaviour and curated boss encounters. Automated tests cover the current implementation, but **full cross-mod and five-game gameplay QA is not complete**. This release is currently available through the private development repository.

No patched GBA ROM, game binary modification or separate Gen1Recomp engine fork is needed. Battle integration uses existing Gen 3 Lua entrypoints and may need maintenance as the host engine evolves. The manifest explicitly requests Gen1Recomp's **engine_internals** permission because the mod wraps private battle functions; it does not request network permission.

## Quick start

1. Download the `mega-evolution-gen3-v1.0.0-Beta.zip` **release asset** (not GitHub's automatic Source code ZIP) and import it from the Gen1Recomp **MODS** screen.
2. Enable **Mega Evolution Gen 3** for a supported Gen 3 game.
3. In Oak's Lab (FireRed/LeafGreen) or Birch's Lab (Ruby/Sapphire/Emerald), buy the **Key Stone (₽10,000)** and the Pokémon's **Mega Stone (₽5,000)** from the added lab aide.
4. Give the Pokémon its Mega Stone, open **FIGHT**, toggle Mega with **START** (or the on-screen control), then select its move.

The player gets **one Mega Evolution per battle**. The form appears before the move resolves, remains in battle through switching, and reverts after fainting/battle end. Mega Rayquaza instead requires Dragon Ascent, with that move supplied by the active game's move provider.

**[Detailed installation and troubleshooting →](docs/INSTALLATION.md)**

The player ZIP is generated from a vetted runtime-file inventory, not from GitHub's full source archive. See [release and testing policy](docs/RELEASE.md).

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

### Mega Evolution battle mechanics

- **98 Mega form entries, 92 Mega Stones and the Key Stone.** Includes multiple variant forms where supported; the available Mega depends on the Pokémon and its required stone or move.
- **In-battle Mega selection.** An on-screen Mega button appears alongside move selection for eligible Pokémon. Activate it with **START**, the directional controls or a mouse/touch click, then choose a move.
- **Transform before attacking.** Mega Evolution applies temporary base stats, type and ability changes in battle. Mega-specific ability integrations are implemented, with some newer interactions dependent on compatible move/type providers.
- **One Mega Evolution per side, per battle.** The transformation persists when a Pokémon switches out and back in, and ends on fainting or battle completion. Permanent Pokémon data and saves are not overwritten.
- **Mega Rayquaza support.** Its special condition uses **Dragon Ascent** instead of a held Mega Stone, when that move is available from the active game/mod provider.

### Art, animation and items

- **Animated Mega transformations.** A Mega emblem and white-silhouette reveal introduce the new form, followed by its own cry where available.
- **Normal and shiny battle artwork.** Front and back Mega sprites, battle health-box indicators, plus matching animated party/switch icons and their shiny variants.
- **Mega Stone shop.** Find a new lab aide in **Professor Oak's Lab** (Kanto) or **Professor Birch's Lab** (Hoenn) to purchase the **Key Stone (₽10,000)** and individual **Mega Stones (₽5,000)**.

### Trainers, replayability and compatibility

- **Enemy trainers can Mega Evolve.** Opponents have an independent Mega allowance, with automatic selection for eligible ordinary trainers.
- **Curated Kanto and Hoenn boss Megas.** Selected Gym Leaders, Elite Four members, rivals and villains use ROM-aware team matching. Some additions require National Dex species, and unverified or incompatible trainer records are deliberately skipped rather than changed blindly.
- **Built-in trainer audit.** Open **START → MEGA AUDIT** to inspect available trainer parties, Mega selections and compatibility status; export a diagnostic report when needed.
- **Optional content-pack integration.** Compatible with the project’s supported **National Dex Gen 3**, **G9 Battle Sprites**, **Gen 3 HD Sprites**, **Modern Spawns**, **Untamed Advanced** and **Nuzlocke** integrations. The base mod has no additional mandatory mod dependency; later-generation Pokémon require a species provider such as National Dex.
- **ROM-safe installation.** Installs as a Gen1Recomp Mechanics mod via a release ZIP, with no ROM patch or separate engine fork.

**Beta note:** The core release is functional and covered by automated tests, but not every Mega, boss encounter, newer-generation ability interaction or combination of optional mods has completed live testing. See [Testing](docs/TESTING.md) and [Dependencies](docs/DEPENDENCIES.md).

## Trainer roster at a glance

**FireRed:** the curated boss roster includes Brock, Misty, Surge, Erika, Koga, Sabrina, Blaine, Giovanni, the Elite Four and Champion Rival. The imported-ROM audit fixes Giovanni's early Rocket battle (#348, **no Mega**) and later Rocket battle (#349, **Mega Mewtwo Y**), filters a false Champion #38, and selects the last eligible duplicate Pokémon.

**Emerald:** curated selections include Roxanne (Glimmora), Tate & Liza (Meowstic), Juan (Tatsugiri Curly), the Elite Four and major villains. Audited rematches support safe replacement of Golem/Crawdaunt/Drowzee/Hypno in designated battles. Wally remains **Gardevoir selected but audit-only** until his imported-ROM trainer records are confirmed; the host's Emerald constant candidates are #519 and #656–660.

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
- [Verified Mega base stats and source corrections](docs/MEGA_STAT_AUDIT.md)
- [Full-form mechanics and limitations](docs/ALL_MEGA_ROSTER.md)
- [Animation pipeline](docs/ANIMATION_PIPELINE.md)
- [Development](docs/DEVELOPMENT.md) · [Roadmap](docs/ROADMAP.md)
- [Contributing](CONTRIBUTING.md) · [Changelog](CHANGELOG.md)
- [Credits and asset rights](CREDITS.md) · [Release requirements](docs/RELEASE.md)

## Rights and credits

Mega sprite attribution includes [Aronousqui20](https://www.deviantart.com/aronousqui20/gallery) and [mangalos810](https://www.deviantart.com/mangalos810/gallery/103628774/new-work), alongside the upstream EBDX, Pokémon Essentials and other contributor credits in [CREDITS.md](CREDITS.md) and [source_metadata/README.md](assets/source/ebdx/source_metadata/README.md).


---

Maintained at [Deluxe0111/Mega-Evolution-Gen-3](https://github.com/Deluxe0111/Mega-Evolution-Gen-3). **Beta mechanics mod; not an official Pokémon project.**
