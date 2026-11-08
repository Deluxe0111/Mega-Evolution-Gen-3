# Changelog

## v1.0.0 — 8 November 2026 (release candidate)

- Promoted the project manifest to `1.0.0`, with a separate `v1.0.0` release tag planned.
- Added a reproducible Windows release-preparation command that stages the minimal player inventory and runs strict Gen1Recomp Modkit validation, lint, Gen 3 compatibility and package generation.
- Preserved the 98 Mega form entries, 92 Mega Stones, Key Stone, battle mechanics, trainer choices and credited source assets from the Beta line.
- Full cross-mod and five-game gameplay coverage remains in progress; see [Testing](docs/TESTING.md).

## v1.0.0-Beta — 31 October 2026

First versioned Gen1Recomp Gen 3 Mega Evolution pre-release.

- 98 Mega form entries with battle presentation and 92 Mega Stones plus a Key Stone.
- In-battle Mega selection, temporary form stats, abilities, animations, shiny art, party icons and cries.
- Oak/Birch laboratory Mega Stone shops and one Mega Evolution per trainer side per battle.
- ROM-aware curated Kanto/Hoenn trainer roster and in-game MEGA AUDIT.
- Compatibility integrations for optional National Dex, G9 art, HD sprites, Untamed Advanced, Modern Spawns and Nuzlocke packs.
- Minimal installable ZIP with only runtime Lua, indexed atlas pages, directly-loaded UI/icon/audio, README and full attribution; includes SHA-256 checksum.
- Classified as `MECHANIC` in Gen1Recomp; no experimental activation warning.

**Beta limitations (historical):** Full five-game and cross-mod gameplay certification was not completed for the initial pre-release. The old Beta archive predates the strict Modkit packaging gate.

## Earlier development preview

- Ported Mega Evolution functionality into the Gen 3 runtime without a separate ROM patch.
- Added save-isolated temporary battle form handling, status corrections, atlas generation and Lua regression tests.
- Corrected FireRed Giovanni/Champion matches and Emerald Roxanne/Juan/Tate & Liza team changes.
- Added trainer audit and Mega presentation tuning tools.

See [Testing](docs/TESTING.md) and [Credits](CREDITS.md) for outstanding verification and attribution.
