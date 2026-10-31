## Emerald verified roster decisions — 31 October 2026 (latest)

These supersede the older **add-only/no-replacements** policy below **for
the exact trainer IDs and full six-slot party fingerprints listed here**.
All records were transcribed from the user's exported imported-ROM
`mega_trainer_audit(2).txt`. In every other game/encounter the original
conservative add-only policy remains in force.

| Trainer | Imported Emerald IDs | Approved action |
| --- | --- | --- |
| Juan | #800 (Lv.58 Crawdaunt), #801 (Lv.63 Crawdaunt) | Replace Crawdaunt in slot 5 with Tatsugiri (Curly) at the same level; keep Kingdra in slot 6 |
| Roxanne | #773 (Lv.47 Golem) | Replace slot 2 Golem with Glimmora Lv.47; preserve Nosepass slot 6 |
| Tate & Liza | #271 (4 Pokémon), #794 (5 Pokémon) | Append Meowstic using the former final party Pokémon's level |
| Tate & Liza | #795 (Lv.53 Drowzee), #796 (Lv.58 Hypno), #797 (Lv.63 Hypno) | Replace slot 1 with Meowstic at the removed Pokémon's level; preserve Lunatone and Solrock |
| Wally | Candidate IDs #519, #656–660 from Gen1Recomp Emerald constants; **not matched in supplied audit** | Keep Mega Gardevoir preference, but **no curated changes** until a fresh ROM audit confirms each trainer identity and party |

### Safeguards

- Emerald replacements/additions above check the **exact numeric ID,
  trainer identity/class, and full ordered original party species/levels**.
  A mismatched, edited, or alternate ROM remains unchanged.
- Tate & Liza must be a *single* imported ROM double trainer
  (`Trainers.get(id).doubleBattle == true`, with one shared party).
  Gen1Recomp separately supports two-owner battles using `twoOpponents`,
  `trainerIdB`, `foeHalf`, or `partyOwner`. Those layouts **fail closed**
  rather than risking swapping Pokémon in the wrong owner's party.
- Only one enemy Mega per battle, activated before that Pokémon's
  first resolved move; no NPC Mega Stone or permanent save/ROM team mutation.
  Newly generated Pokémon derive battle stats/moves from the native builder;
  replaced Pokémon keep their level/IV baseline but do **not** transfer
  their old held item or moves to the new species.
- Other Emerald additions already approved by the add-only roster remain
  unchanged. If a curated encounter fails verification, the generic NPC
  Mega fallback must not pick an unrelated Mega instead.
- Wally: `START → MEGA AUDIT → SELECT` now includes any Wally-name
  or Wally-script candidate from the imported trainer pack with its actual
  numeric ID, class, party species/levels. Status
  `trainer_identity_unverified` is **not** an authorisation to edit.
  If no candidate is found, the unresolved Wally record stays visible.
- Battle rules verify against the active Gen1Recomp Gen 3 engine's
  `Trainers.get` and `State.new` party ownership model. Live Emerald
  gameplay validation is still required, especially Tate & Liza.

---

## Verified FireRed ROM audit corrections — 31 October 2026

These decisions are grounded in the exported `mega_trainer_audit.txt`
from the user's imported FireRed ROM.

- **Rocket Giovanni, trainer #348:** early encounter's final original
  Pokémon is Kangaskhan Lv.29. **Do not Mega Evolve any Pokémon** in this
  battle. An explicit disabled choice overrides the generic NPC Mega rule.
- **Rocket Giovanni, trainer #349:** later encounter's final original
  Pokémon is Nidoqueen Lv.41. **Add Mega Mewtwo Y** in the open fifth
  slot at Lv.41. Giovanni's Gym (trainer #350) still uses Mega Kangaskhan.
  The exact #348/#349 restrictions are applied only to the verified
  FireRed ROM; LeafGreen Rocket encounter IDs need separate verification.
- **Fake Champion #38:** unnamed ROM placeholder with one Ekans Lv.5.
  This is **not the Champion Rival** and will not appear in the Mega
  trainer audit. Rival Champions must have a real name, six-member party
  and a final-stage starter. Verified FireRed Champion encounters
  #438–440 and rematches #739–741 remain eligible.
- **Duplicate boss species:** select the **last** matching Pokémon in
  the original party. In the FireRed audit, Agatha's regular and rematch
  Gengars are slots 5 (Lv.58 and Lv.70 respectively), and Lance's
  rematch Dragonite is slot 5 (Lv.72).

The audit displays intentionally suppressed encounters as **OFF**,
separate from READY and NEEDS REVIEW. They are included in the
text export with an explicit no-Mega rule. No original party Pokémon
are replaced or permanently changed.

---

## In-game trainer Mega audit

Open **START → MEGA AUDIT** (shown by default; can be disabled using
the `TRAINER MEGA AUDIT` mod option). The screen reads the currently
imported ROM's actual trainer pack; it never grants Pokémon or alters
trainer teams.

- **Up/Down:** select a matching trainer. **Left/Right:** move by seven.
- **L/R:** filter ALL / READY / NEEDS REVIEW.
- **A:** show the trainer's verified numeric ROM ID, selected Mega, audit
  status, and each original party Pokémon's species/level. **B:** back.
- **START:** refresh the import audit after a ROM/content-pack change.
- **SELECT:** export a full text report to
  `exports/mega_trainer_audit.txt` in the mod's cache (or a compatibility
  filesystem fallback). The report includes every encountered variant,
  party entries, and flags for a required team replacement.
- If an approved trainer ID cannot be matched, it appears as
  `trainer_identity_not_found`, not silently omitted.

**Battle fix:** Mega Evolution now stays visually active until the
native faint sink/slide animation has completed, then restores the
original form before battle replacement/cleanup. A KO no longer shows
a brief normal Charizard/other base sprite during the death animation.

---

## Approved selections — 31 October 2026

All **32 submitted choices** are recorded in
`data/mega_boss_selections.lua`. This overrides the earlier proposals in
this document. Approval covers the selected Mega form and **adding a new
Pokémon only when the verified trainer party has fewer than six slots**;
**no replacements are authorised**. Existing Pokémon are preferred.
The runtime `exports.bossMegaAudit()` reads the ROM-generated trainer
pack and returns each candidate's actual numeric trainer ID, class,
existing party size and one of these statuses:

- `existing`: selected species already on the trainer team; select it.
- `add`: verified original team has room; add at its final member's level,
  without changing or deleting any existing Pokémon.
- `full_party_needs_approval`: leave team untouched, request a replacement
  decision for that exact original party.
- `species_not_registered`: the selected National Dex Pokémon is not
  available; leave team unchanged.
- `trainer_identity_not_found`, `rom_party_mismatch`,
  `ambiguous_boss_match`: skip changes until actual ROM trainer IDs,
  classes and party composition are resolved.
- `double_party_review`: Tate & Liza require the original double-battle
  party ownership boundaries to be checked before adding Meowstic.
- `starter_not_present`: the Champion Rival has no suitable final-stage
  starter; do not silently substitute an unrelated Pokémon.

### Kanto choices

| Trainer | Approved Mega |
| --- | --- |
| Brock | Aerodactyl |
| Misty | Starmie |
| Lt. Surge | Raichu X |
| Erika | Victreebel |
| Koga | Beedrill |
| Sabrina | Alakazam |
| Blaine | Pyroar |
| Giovanni (Gym) | Kangaskhan |
| Lorelei | Slowbro |
| Bruno | Steelix (add if absent; do not replace Onix without approval) |
| Agatha | Gengar |
| Lance | Dragonite |
| Champion Rival | Their fully evolved starter (Charizard X where applicable) |
| Giovanni (Team Rocket) | Mewtwo Y |

### Hoenn choices

| Trainer | Approved Mega |
| --- | --- |
| Roxanne | Glimmora |
| Brawly | Medicham |
| Wattson | Manectric |
| Flannery | Camerupt |
| Norman | Kangaskhan |
| Winona | Altaria |
| Tate & Liza | Meowstic (double-party insertion needs review) |
| Wallace (Ruby/Sapphire Gym) | Gyarados |
| Juan (Emerald Gym) | Tatsugiri (Curly) |
| Sidney | Absol |
| Phoebe | Banette |
| Glacia | Glalie |
| Drake | Salamence |
| Champion Steven (Ruby/Sapphire) | Metagross |
| Champion Wallace (Emerald) | Gyarados |
| Maxie | Houndoom |
| Archie | Sharpedo |
| Wally | Gardevoir |

**Verification detail:** The repository does not contain the player's
generated GBA ROM trainer pack. We do **not** invent trainer IDs or assume
a generic ROM's party exactly matches theirs. Trainer IDs, class names,
party species and levels are checked against the **loaded imported ROM**
at battle start. Only matching `existing` and `add` entries execute.

No item is added to NPC storage. Added trainer Pokémon receive the
original ace's level; the native Gen3 party builder derives legal moves
and battle stats. The generated boss audit allows exact encounter-by-
encounter review before any replacement or special double-team patch.

---

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
