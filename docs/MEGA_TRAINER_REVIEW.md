# Enemy trainer Mega Evolution: automatic rule and boss roster review

## Rules implemented in the first trainer-Mega foundation

- **Any regular NPC trainer** with a Pokémon whose current species and base
  form match the Mega catalogue is eligible; the policy selects the **last
  eligible living party slot** (a deterministic "ace"). No pre-existing
  Mega Stone or Key Stone is required in an NPC's actual Bag/party data.
- Only **one Pokémon on the enemy side** Mega Evolves during an entire battle.
  It triggers **immediately before the selected Pokémon's first resolved move**,
  following the same battle form/stat/ability/art pathway as player Mega.
- Switch-out and re-entry retain the Mega. Fainting removes the active form
  without refunding the one-Mega allowance. Party species, levels, moves,
  held items, and saves are unchanged.
- Wild, link, spectator, Safari, tutorial, ghost, secret-base, e-Reader,
  Trainer Tower, Battle Tower, and Frontier trainer battles are excluded
  initially to prevent altering special battle rules without separate review.
- When multiple Mega variants exist (Charizard X/Y, Mewtwo X/Y, etc), the
  catalogue's first matching row is the automatic default. Any reviewed
  trainer may instead specify its exact variant in
  `data/mega_trainer_choices.lua`.
- The per-game override maps are **empty**. No Gym Leader or boss gets a
  new or replaced Pokémon in this PR. A curated choice may nominate a
  Pokémon **already in that trainer's party**; adding/replacing a party
  member will be handled in a separate, reviewed patch against the
  ROM-derived trainer ID and game edition.

## Review board — Kanto, FireRed / LeafGreen

These are **proposals**, not edited trainer teams. "Existing" means
likely in a conventional FRLG boss lineup; confirm the exact game/version
and rematch party from the imported ROM before making an override.

| Trainer | Proposed signature Mega | Change |
| --- | --- | --- |
| Brock | Steelix | Evolve/replace Onix |
| Misty | Starmie | Existing |
| Lt. Surge | Raichu X or Y | Existing Raichu; choose variant |
| Erika | Victreebel | Existing |
| Koga | Beedrill | Add or replace a Poison-type |
| Sabrina | Alakazam | Existing |
| Blaine | Houndoom or Camerupt | Add or replace a Fire-type |
| Giovanni (Gym) | Kangaskhan or Gyarados | Add/swap; review other Giovanni encounters separately |
| Elite Four Lorelei | Slowbro | Existing |
| Elite Four Bruno | Steelix | Evolve/replace Onix |
| Elite Four Agatha | Gengar | Existing |
| Elite Four Lance | Aerodactyl, Gyarados or Dragonite | Existing; choose one |
| Champion rival | Starter final evolution, Pidgeot or Gyarados | Match rival starter and version |

## Review board — Hoenn, Ruby / Sapphire / Emerald

Teams differ between versions and some rematches. These are proposals,
not assertions of their exact original party composition.

| Trainer | Proposed signature Mega | Change |
| --- | --- | --- |
| Roxanne | Aggron or Steelix | Add/swap |
| Brawly | Medicham | Add/swap or evolve Meditite where present |
| Wattson | Manectric | Existing where present |
| Flannery | Camerupt | Add/swap or evolve Numel where present |
| Norman | Kangaskhan | Add/swap |
| Winona | Altaria | Existing |
| Tate & Liza | Metagross or Gardevoir | Add/swap; choose one Mega for combined battle |
| Wallace (Gym in Ruby/Sapphire) | Gyarados or Sharpedo | Confirm original party / add-swap |
| Juan (Gym in Emerald) | Gyarados or Sharpedo | Add/swap |
| Elite Four Sidney | Absol or Sharpedo | Existing |
| Elite Four Phoebe | Banette or Sableye | Existing |
| Elite Four Glacia | Glalie | Existing |
| Elite Four Drake | Salamence | Existing |
| Champion Steven (Ruby/Sapphire) | Metagross | Existing |
| Champion Wallace (Emerald) | Gyarados or Sharpedo | Add/swap if required |
| Maxie | Camerupt | Existing where present |
| Archie | Sharpedo | Existing where present |
| Wally | Gardevoir or Gallade | Existing Gardevoir where present; Gallade would be a swap |

Other storyline or rematch bosses can be added once the main trainer
teams are reviewed.

## What we must decide together

1. For each game/version and boss: choose the Mega, including X/Y/Z variant,
   and whether the original Pokémon is kept, evolved, replaced or an
   extra Pokémon is added.
2. Preserve an appropriate challenge curve. Giving a level-14 Gym Leader a
   level-100 Mega or a seventh team member would damage progression.
   Better to preserve each Pokémon's original level/EV/IV/moves unless
   we explicitly author a balanced replacement.
3. Resolve the **ROM trainer ID** (and rematch variants) against that game's
   generated trainer pack. Trainer names and class names alone are
   insufficient: repeated rival battles and duplicate trainer names exist.
4. Decide whether to extend the NPC Mega rule to optional battle facilities,
   double trainer pairs and postgame rematches. This first implementation is
   intentionally conservative.

## Override schema

```lua
-- data/mega_trainer_choices.lua, illustrative IDs ONLY
return {
  firered = {
    -- [ACTUAL_ROM_TRAINER_ID] = { slot = 2, slug = "mega_alakazam" },
  },
  emerald = {
    -- [ACTUAL_ROM_TRAINER_ID] = { disabled = true },
  },
}
```

The runtime validates species and base form before applying a curated
override, and doesn't grant/replace Pokémon. Incorrect overrides fail
closed instead of selecting an unrelated trainer Pokémon.

## Testing priorities

- Ordinary wild Pokémon cannot Mega; ordinary trainers can Mega only when
  their existing roster has an eligible species.
- Trainers with multiple eligible Pokémon choose the final eligible slot,
  never more than one enemy Mega in that battle.
- Other trainers with no eligible Pokémon never Mega.
- The player's one-Mega-per-battle allowance is independent of the NPC's.
- NPC Mega transforms before its selected attack and retains the form on
  switch/re-entry. Battle end/faint returns party/battle state to normal.
- FireRed, LeafGreen, Ruby, Sapphire, Emerald, and later-generation
  National Dex Pokémon. Verify enemy sprite size and cry direction,
  damage calculation, switch AI and defeat/rematch behaviour.
- Boss curated edits use the actual trainer ID and preserve ROM/script
  progression; no permanent Pokémon changes, item drops or unwanted
  Mega Stones on capture.
