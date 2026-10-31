# Changelog

This repository currently has **no tagged player release**. The manifest's `0.1.0` version is an experimental development identifier; the entries below describe changes already represented in the working repository, not a certified release.

## Unreleased — repository maintenance

- Replaced obsolete prototype README and development instructions with current gameplay, install and contributor documentation.
- Added authoritative dependency links, using verified mod IDs and repositories for National Dex Gen 3, G9 Battle Sprites, Gen 3 HD Sprites, Modern Spawns, Untamed Advanced and Nuzlocke.
- Declared the host's `engine_internals` permission used by scoped battle wrappers.
- Added documentation-link and manifest dependency tests to CI.
- Moved historical trainer proposals into an explicitly marked archive.

## Current experimental implementation (through 31 October 2026)

- Battle Mega toggle, stone and lab-shop system, temporary Mega form stats/abilities, indexed art, cries and party icons.
- Expanded 98-entry Mega form and 92-stone roster with Mega-specific art/ability handling.
- NPC trainer Mega policy and selected Kanto/Hoenn Gym, Elite Four, rival and villain Megas.
- FireRed Giovanni, Champion and duplicate-ace audit corrections.
- Emerald Roxanne, Juan and Tate & Liza audited trainer-party changes, plus read-only Wally candidate discovery.
- Start-menu MEGA AUDIT screen with exportable imported-ROM records and a faint animation visual fix.

For individual feature history, consult merged GitHub pull requests. See the [roadmap](docs/ROADMAP.md) and [testing gate](docs/TESTING.md) for work remaining before a public release.
