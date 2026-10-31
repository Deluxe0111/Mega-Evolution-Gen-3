# Roadmap — Mega Evolution Gen 3

This roadmap describes the **current implementation** rather than the original Mega Venusaur-only prototype. A checked item means code/assets exist; it does **not** guarantee that every real-ROM scenario passed testing.

## Foundations and asset pipeline

- [x] Mod API 2 entry point for all five Gen 3 games without an engine fork
- [x] Source art intake and original contributor attribution
- [x] 98 form entries, 92 Mega Stone icons, source-backed cries and complete asset inventory
- [x] Bounded PNG atlas pages, Lua/JSON index and lazy Mega art provider
- [x] Normal, shiny, front/back and party icon pipeline with per-form presentation calibration
- [ ] Finish visual QA for all 98 forms, including hovering, male/female variants and sprite scale

## Player Mega battle experience

- [x] Key Stone and Mega Stone registration with fixed item IDs
- [x] Native Oak/Birch lab aide shop and source item icons
- [x] FIGHT → Mega toggle → select move → activate before move resolution
- [x] Temporary form stats, artwork, cry and battle-lifecycle integration
- [x] Switch/re-entry, one-Mega allowance and delayed Mega faint visual cleanup
- [x] Many modern Mega ability modules and targeted edge-case regressions
- [ ] Complete live testing of all X/Y/Z and original-form exceptions
- [ ] Certify modern Fairy type, move and ability interoperability across selected National Dex versions
- [ ] Complete live UI, sound, shiny and party-swap visual regression across all five Gen 3 games

## Trainer Megas and curated bosses

- [x] Automatic single enemy Mega for eligible standard trainers
- [x] 32 notable Kanto and Hoenn curated choices, subject to imported-ROM verification
- [x] FireRed Giovanni #348/#349 corrections, false Champion filter and last eligible duplicate
- [x] Emerald Juan, Roxanne and Tate & Liza audited add/replace decisions
- [x] START → MEGA AUDIT menu and text export with reviewed/mismatch statuses
- [ ] Confirm Wally's actual imported-ROM identity/party before any curated roster change
- [ ] In-game QA of Tate & Liza double battles and all scripted rematches
- [ ] Review additional notable rivals, villain encounters and other postgame trainers
- [ ] Approve replacements for other six-member boss parties case by case

## Cross-mod integration and packaging

- [x] Declare exact optional dependency IDs and verified GitHub sources
- [x] Document base-vs-expanded National Dex requirements and G9's transitive dependency
- [x] Preserve G9/HD ownership of normal sprites and keep Mega artwork scoped
- [ ] Full FireRed/Emerald test matrix with National Dex, G9, HD, Untamed Advanced, Nuzlocke and Modern Spawns
- [ ] Verify Ruby, Sapphire and LeafGreen battle/roster variants
- [ ] Audit distribution rights for every art/audio category and record permitted release contents
- [ ] Publish a tested player ZIP and versioned GitHub Release **only after** a full installation smoke test

**Maintained references:** [Install](INSTALLATION.md), [Dependencies](DEPENDENCIES.md), [Trainer roster](MEGA_TRAINER_REVIEW.md), [Testing](TESTING.md). Refer to [Release requirements](RELEASE.md) before publishing a player build.
