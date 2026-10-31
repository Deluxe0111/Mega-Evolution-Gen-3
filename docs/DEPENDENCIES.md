# Dependencies and compatibility

The repository's `manifest.json` is the authoritative machine-readable dependency declaration. These entries use the **mod ID** (which may differ from the GitHub repository name), and `dependency_sources` supplies GitHub links for the launcher.

**Base installation:** The Mega Evolution mod depends on **Gen1Recomp's Gen 3 runtime**, but does **not** require a second mod merely to use supported Gen 1–3 Mega candidates. All six items below are **optional at installation time**. Some are **feature prerequisites**, as noted.

| Mod / repository | Manifest ID | Needed for | Status |
| --- | --- | --- | --- |
| [National Dex Gen 3](https://github.com/poooooby/national_dex_gen3) | `national_dex_gen3` | Species #387+, their forms, newer move/ability/type support; needed for selected bosses using Glimmora, Meowstic or Tatsugiri | **Required for expanded species features**, optional for base game |
| [G9 Battle Sprites (Gen 3)](https://github.com/poooooby/g9-battle-sprites-gen3) | `g9-battle-sprites-gen3` | Expanded animated Pokémon art, especially outside Gen 3 | Optional; **G9 itself requires National Dex Gen 3** |
| [Gen 3 HD Sprites / WoobleView](https://github.com/poooooby/gen3-hd-sprites) | `gen3-hd-sprites` | High-resolution battle framing and display | Optional; check Mega sprite scaling and alignment |
| [Modern Spawns](https://github.com/poooooby/g1r_modern_spawns) | `modern_spawns` | Wider wild encounter rosters; complements expanded Mega candidates | Optional encounter mod; does not supply Mega Evolution |
| [Untamed Advanced — compatible fork](https://github.com/Deluxe0111/untamed-advanced) | `untamed_advanced` | Overworld wild Pokémon and follower gameplay | Optional; battle and overworld integration need in-game checks |
| [Nuzlocke — Gen 3 fork](https://github.com/Deluxe0111/nuzlocke) | `nuzlocke` | Challenge rules, randomiser, catch restrictions and run summaries | Optional; test permadeath, encounter identity and victory/defeat sequences |

Sources above were checked against the repositories' own `manifest.json` IDs. The listed Untamed Advanced and Nuzlocke links point to the compatible forks used for integration; behaviour may differ from other branches or public releases.

## What the dependency fields mean

- `dependencies: []`: No other mod is **always required** to load the basic Mega experience.
- `optional_dependencies`: If one is installed and enabled, Gen1Recomp loads it before Mega Evolution. Missing optional mods do not block Mega's loading.
- `dependency_sources`: Repository hints for the launcher to show installation/download links. They are **not vendored mod contents** and do **not** silently download or install dependencies.
- `category: "MECHANIC"`, `experimental: false`: The mod is listed under Mechanics and does not trigger the experimental confirmation prompt. This does not imply complete gameplay or compatibility certification.
- `permissions: [\"engine_internals\"]`: The mod wraps native Gen 3 battle/UI modules through the host's private Lua interfaces. This is an **engine permission**, not another mod dependency. No network access is requested.

In particular, **do not convert National Dex to an unconditional hard dependency**. Doing so would unnecessarily prevent base-game Mega Evolution. Equally, **do not describe expanded boss teams as standalone**: Pokémon not registered by the active species provider cannot be safely inserted.

## Recommended combinations

| Goal | Enable |
| --- | --- |
| Original Gen 3 Mega gameplay | Mega Evolution only |
| All available Mega forms and expanded bosses | Mega Evolution + National Dex Gen 3 |
| Expanded Pokémon with animated normal battle art | Above + G9 Battle Sprites |
| Larger, sharper battle presentation | Above + Gen 3 HD Sprites |
| Challenge/randomised encounters and followers | Add Nuzlocke, Modern Spawns or Untamed Advanced according to your desired gameplay |

A combination being listed here is **not a claim of exhaustive compatibility testing**. The Mega mod supplies its own Mega art while cooperating with other mods' normal sprite providers; overlapping rendering hooks remain a QA priority.

## Known limitations / integration boundaries

- **Fairy and other newer mechanics:** Native stock Gen 3 rules are not a substitute for the modern type chart, moves and abilities. National Dex can provide modern data, but interactions still need cross-mod verification.
- **Rayquaza:** Dragon Ascent must exist in the active move provider and be known by the Pokémon.
- **Multiple Mega variants:** X/Y and alternate original forms must use the correct stone, base form and explicitly curated choice where applicable.
- **Trainer bosses:** Special team changes are validated against exact imported-ROM trainer IDs and party signatures; another region, ROM revision or randomiser may cause them to be skipped.
- **Double battles:** Tate & Liza additions/replacements only run for the verified single-owner ROM double-battle layout, not a two-trainer merged battle.
- **Overworld:** This project implements *battle* Mega Evolution. It does not automatically change overworld followers or random encounter sprites into Mega representations.
- **Saves:** Mega forms are temporary. The mod should not rewrite a Pokémon's saved species, personality, encounter provenance or Nuzlocke graveyard status.

## Version policy

Dependencies are listed by ID without hard-pinned version ranges because compatibility has not been certified across an exact six-mod release matrix. Before publishing a stable release, run the [testing matrix](TESTING.md) on known Gen1Recomp and mod versions; then add version constraints where evidence warrants them. Do not assume that installing the latest commit of every upstream project is automatically safe.

The imported Mega artwork and cry source is **not** a runtime dependency on Pokémon Essentials/EBDX. Those files have already been imported into this repository; see [Credits and rights](../CREDITS.md).
