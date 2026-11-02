# Differences from vanilla Gen 3

This document records gameplay and presentation divergences introduced by **Mega Evolution Gen 3**. It is separate from Gen1Recomp's base-engine `known-differences.md` ledger. Nothing here represents a change to the player's ROM image.

| Area | Vanilla FireRed/LeafGreen/Ruby/Sapphire/Emerald | With Mega Evolution Gen 3 enabled |
| --- | --- | --- |
| Battle forms | No Mega Evolution mechanic | Eligible Pokémon can Mega Evolve before their selected move, with one activation per trainer side per battle |
| Requirements | No Key Stone or Mega Stones | The player requires a Key Stone plus an eligible held Mega Stone; Mega Rayquaza instead requires Dragon Ascent where the move is supplied |
| Battle stats | Normal species stats, types and abilities | Mega form's temporary battle stats, type and available ability rules apply, reverting when the Mega state ends |
| Battle presentation | No Mega button, emblem or Mega health-box indicator | Adds selection UI, transformation animation, Mega-specific sprites, icons and cries when their assets exist |
| Shops | No Mega Stone vendor in the professors' labs | Adds an aide selling Key Stones and Mega Stones in applicable Kanto/Hoenn labs |
| Enemy battles | Trainers cannot Mega Evolve | Eligible trainers may Mega Evolve; configured major fights use party/ROM-aware matching and may be skipped if mismatched |
| Start menu | No Mega trainer audit option | Adds a MEGA AUDIT diagnostic menu |

## Compatibility conditions

- The mod only activates in the Gen 3 games declared by its manifest. Its current `"gen3"` target covers the engine's Gen 3 family; full live verification across all five games is still outstanding.
- Later-generation Pokémon, types, moves or abilities need a compatible external provider; the base mod cannot add every such species on its own.
- Battle internals are accessed under the declared `engine_internals` permission, so changes in Gen1Recomp's host implementation may require a compatibility update.
- The mod is intended to keep permanent species and save records unchanged by temporary Mega forms. Save persistence, disable/re-enable and previous-version migration behaviour require release testing.

## Testing status

Automated project and trainer-roster tests are not a substitute for clean ZIP installation, live in-game checks, existing-save migration checks or cross-mod playtesting. Consult `docs/TESTING.md` for the game-by-game matrix.
