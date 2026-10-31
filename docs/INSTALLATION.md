# Installation and first battle

This is an **experimental Gen1Recomp Mod API 2 mod** for FireRed, LeafGreen, Ruby, Sapphire and Emerald. It uses the current Gen 3 runtime, not a patched GBA ROM. It has no downloadable release attached to this repository yet; use a repository checkout or ZIP while the project is in development.

## 1. Install Mega Evolution

1. Obtain a compatible [Gen1Recomp](https://github.com/bryanthaboi/gen1recomp) build and import your own legally obtained Gen 3 game in the host application.
2. On this repository's GitHub page, choose **Code → Download ZIP** (or clone the repository). The repository must be accessible to you; it may be private during development.
3. In the Gen1Recomp launcher, open **MODS** and import the ZIP. The launcher accepts a mod with `manifest.json` at the ZIP root or inside one top-level folder.
4. Enable **Mega Evolution Gen 3** in the launcher; start FireRed, LeafGreen, Ruby, Sapphire or Emerald.
5. Confirm the Mega mod is active. The regular Pokémon and save data remain separate from this mod's temporary in-battle forms.

For a manual development installation, the mod directory must contain `manifest.json`, `main.lua`, `src/`, `data/` and `assets/` directly beneath the mod folder. Prefer the launcher import rather than assuming a particular Windows or portable install path.

**Do not install just `main.lua` or the `assets/runtime` folder.** The runtime index, atlas pages, Mega Stone icons, source-backed cries and scripts must stay together. Do not delete `assets/source/ebdx` as part of a cleanup: some runtime item artwork is loaded from that folder.

## 2. Optional mods and installation order

The base mod is usable for compatible species already supported by the original Gen 3 game. To use **post-Gen-3 Mega candidates** such as Glimmora, Meowstic and Tatsugiri, also install **[National Dex Gen 3](https://github.com/poooooby/national_dex_gen3)**. Its species/move/ability/type provider is required for those species to resolve correctly.

For expanded Pokémon sprite support, add [G9 Battle Sprites (Gen 3)](https://github.com/poooooby/g9-battle-sprites-gen3), which **itself requires National Dex Gen 3**. [Gen 3 HD Sprites](https://github.com/poooooby/gen3-hd-sprites), [Modern Spawns](https://github.com/poooooby/g1r_modern_spawns), the [Untamed Advanced fork](https://github.com/Deluxe0111/untamed-advanced) and the [Nuzlocke fork](https://github.com/Deluxe0111/nuzlocke) are optional, not bundled. See [Dependencies and compatibility](DEPENDENCIES.md).

The mod's `manifest.json` declares optional dependencies using their real mod IDs and includes `dependency_sources` so the launcher can link to the correct repositories. Gen1Recomp orders installed, active optional dependencies **before** this mod; you do not need to rename folders to force priority. Listing a dependency does **not** install it automatically.

## 3. Obtain and use the stones

1. Visit **Professor Oak's Lab** in Pallet Town (FireRed/LeafGreen) or **Professor Birch's Lab** in Littleroot Town (Ruby/Sapphire/Emerald).
2. Talk to the added lab scientist and buy a **Key Stone for ₽10,000**. Purchase the appropriate **Mega Stone for ₽5,000**.
3. Keep the Key Stone in the Bag and give the Pokémon its corresponding Mega Stone **to hold**.
4. In a normal battle, choose **FIGHT**, toggle Mega using **START** (or the visible Mega control), then select the move. The Pokémon transforms before its attack and stays Mega until the battle ends or it faints.

Only one Pokémon can Mega Evolve per side per battle. The player's allowance is independent of an opponent trainer's. Mega Rayquaza is the exception: it requires **Dragon Ascent** rather than the normal held-stone path; the installed move provider must supply that move. Cancelled move selection must not consume the Mega opportunity.

The source set covers **98 Mega form entries** and **92 distinct Mega Stones**; these counts describe the assets/forms and **do not guarantee every modern ability, type or art placement has passed live testing**.

## 4. Verify it works

- Check that the mod is enabled and its registered items appear in the lab shop.
- Confirm Mega Evolution is unavailable without the Key Stone, with an incorrect held stone, or after using the turn's one-Mega allowance.
- Try one original Gen 3 Mega candidate first (for example Venusaur or Blastoise); then test National Dex species if installed.
- For trainer changes, open **START → MEGA AUDIT**. Press **SELECT** to export `exports/mega_trainer_audit.txt` from the mod cache for an exact imported-ROM party review.
- If an approved special trainer has an unrecognised ID or different Pokémon party, the curated edit is deliberately skipped rather than altering an unknown team.

For deeper tests and diagnostics, see [Testing](TESTING.md). For known caveats, see [Dependencies and compatibility](DEPENDENCIES.md).

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Mega button or shop missing | Mod enabled, correct Gen 3 game, current Gen1Recomp battle modules available; inspect mod logs |
| Mega not eligible | Key Stone, correct held Mega Stone, original species/form, once-per-battle status, supported battle type |
| Glimmora / Meowstic / Tatsugiri missing | Enable National Dex Gen 3 before this mod; confirm the imported game's species provider |
| Wrong sprite size/position | Try without HD rendering, compare with G9 enabled, and record the species, form, side and shiny state |
| Boss team unchanged | Use MEGA AUDIT to inspect exact trainer ID, original party and status; mismatches are intentionally blocked |
| Old artwork index or missing item icon | Keep the committed runtime atlas and source icon folders; run the repository validators |

**Please do not distribute Nintendo ROM files, a preconfigured game installation, or third-party art under a blanket licence.** See [Credits](../CREDITS.md).
