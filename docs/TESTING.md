# Testing and release checklist

Automation checks the mod source and a mocked Gen 3 battle runtime. **A green CI run does not verify every FireRed/Emerald gameplay path**, sprite presentation or third-party load combination.

## Local prerequisites

- Python 3.11+ for the asset tools (standard library; no pip packages required for the project checker/import validator).
- Lua 5.4 to run the runtime regression scripts.
- A compatible Gen1Recomp installation and your own imported Gen 3 game for live testing.

From the repository root:

```powershell
py -3 tests/check_project.py
py -3 tools/validate_assets.py --root assets/source/ebdx --strict --no-report
py -3 tests/check_mega_stats.py
lua tests/test_mega_boss_roster.lua
lua tests/test_mega_trainer_audit_menu.lua
```

The repository's GitHub Actions also runs the runtime Mega provider and broader Lua test suite in `.github/workflows/runtime-art-provider.yml`, plus format, asset and trainer audits in `.github/workflows/validate.yml`. See the workflows for the exact current command list.

## Core gameplay acceptance

- [ ] Key Stone absent / present; correct and incorrect held Mega Stone; cancelled move selection and move-change scenarios.
- [ ] Player's Mega toggles using FIGHT → START → move; activates before the move, one Mega per side per battle.
- [ ] Mega persists after switching out and back in. Faint animation retains Mega art until the sprite is hidden; base species is restored at the right lifecycle boundary.
- [ ] Normal, shiny, male/female and form-specific Mega art; in-battle front/back, HP nameplate, party-swap icon and appropriate cry.
- [ ] Compare Venusaur, Blastoise, both Charizards, both Mewtwos, Rayquaza, Meowstic, Tatsugiri and hovering/large sprites.
- [ ] Verify Mega-only stats, types, abilities and turn order where implemented. Modern interactions need separate comparison with the installed type/move provider.
- [ ] No permanent save, PC, Pokédex, Nuzlocke encounter or graveyard corruption after battle, fainting, quitting and reloading.
- [ ] Wild, spectator, link, tutorial, Safari, Battle Tower, Frontier, Trainer Tower and other deliberately excluded battles never receive an unintended enemy Mega.

## Trainer roster acceptance

- [ ] FireRed: Giovanni Rocket #348 is explicitly **OFF**; #349 has Mewtwo Y; Gym Giovanni retains Kangaskhan.
- [ ] FireRed: reject the false unnamed Champion #38; match real Champion rival parties by their final-stage starter; choose last eligible copy when a boss has duplicates.
- [ ] Emerald: Roxanne #773 swaps Golem → Glimmora, preserves Nosepass.
- [ ] Emerald: Juan #800/#801 swaps Crawdaunt → Tatsugiri (Curly), preserves Kingdra.
- [ ] Emerald: Tate & Liza #271/#794 append Meowstic; #795–797 replace Drowzee/Hypno; preserve Lunatone/Solrock; verify single-owner double battle.
- [ ] Emerald: identify Wally's actual imported trainer records. The host constants suggest #519, #656–660, but no replacement is approved based on constants alone.
- [ ] Export MEGA AUDIT and confirm `existing`, `add`, `replace` (SWAP), `disabled_by_choice`, and review/mismatch statuses reflect actual ROM records.
- [ ] For edited/randomised trainer packs or missing National Dex species, the curated alteration must fail closed.

## Compatibility matrix to record

Run a basic Mega activation and sprite/faint/switch test in each configuration:

| Configuration | FireRed | Emerald | Other Gen 3 editions |
| --- | --- | --- | --- |
| Mega Evolution only | Pending repeatable QA | Pending repeatable QA | Pending |
| + National Dex Gen 3 | Pending | Pending | Pending |
| + G9 Battle Sprites | Pending | Pending | Pending |
| + Gen 3 HD Sprites | Pending | Pending | Pending |
| + Nuzlocke / Modern Spawns | Pending | Pending | Pending |
| + Untamed Advanced | Pending | Pending | Pending |

**Pending** means no complete documented compatibility certification, not that the mod is known to fail. Keep distinct records for the Gen1Recomp commit, all mod versions, game/ROM identity and enabled mod list.

## Bug report template

Please provide: game and imported ROM version; Gen1Recomp version or commit; Mega mod commit/version; enabled mods and versions; Pokémon/form/shiny/gender; trainer ID if applicable; exact steps to reproduce; expected vs actual behaviour; screenshot/video where useful; relevant log excerpt or MEGA AUDIT export. Do not attach the copyrighted ROM or anyone's private save without permission.

## Release gate

Before publishing a downloadable mod ZIP: confirm the intended ZIP layout, all runtime PNG atlas pages, source-backed item icons and cries; smoke-test the ZIP via the launcher; check rights and attribution for every art/audio category; confirm current CI; complete at least one FireRed and Emerald full-battle test with and without National Dex. Until then use the repository checkout as an experimental development build.
