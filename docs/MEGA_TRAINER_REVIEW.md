# Trainer Mega Evolution — curated roster and ROM audit

**Current implementation:** One eligible Mega per enemy trainer side in normal supported battles, selected as the last eligible Pokémon unless a verified boss choice explicitly overrides it. Famous trainer teams are selected by **imported ROM name/class/ID and party**. Only approved edits are permitted, without changing save data or the original ROM trainer pack.

The listed choices require verification against the active imported-ROM trainer records. **Not every selection is guaranteed to execute:** a species may be absent, a full party may be awaiting a decision, or an imported-ROM trainer record may differ.

## 1. Curated FireRed selections (14)

| Trainer | Mega choice | Notes |
| --- | --- | --- |
| Brock | Aerodactyl | Add if space, otherwise review |
| Misty | Starmie | Existing when ROM party matches |
| Lt. Surge | Raichu X | Exact variant |
| Erika | Victreebel | Existing if present |
| Koga | Beedrill | Add if space |
| Sabrina | Alakazam | Existing if present |
| Blaine | Pyroar | National Dex species; add if space |
| Giovanni — Gym | Kangaskhan | Distinct from Rocket battles |
| Lorelei | Slowbro | Match eligible ROM party |
| Bruno | Steelix | Add if absent and space |
| Agatha | Gengar | Last matching Gengar wins |
| Lance | Dragonite | Last matching Dragonite wins |
| Champion Rival | Rival's own final-stage starter | Charizard X, Venusaur or Blastoise; must be real named six-Pokémon Champion party |
| Giovanni — Rocket | Mewtwo Y | **FireRed #349 only**; early #348 explicitly OFF |

### FireRed imported-ROM corrections

- Rocket Giovanni **#348** (early battle, Kangaskhan Lv.29) is **disabled for Mega Evolution**, not simply missing a curated option. This prevents ordinary NPC rules from accidentally selecting Kangaskhan.
- Rocket Giovanni **#349** (later battle, native ace Nidoqueen Lv.41) receives Mega Mewtwo Y in the open fifth slot at Lv.41. The Gym battle remains Mega Kangaskhan.
- The **unnamed Champion #38** with a single Lv.5 Ekans is a false match and excluded. Confirmed Champion Rival families from the FireRed audit include #438–440 and rematches #739–741.
- With duplicate eligible Pokémon, use the **last matching party slot** (Agatha's and Lance's rematch examples).
- Exact Rocket ID exceptions are restricted to **FireRed**. Do not apply them to LeafGreen without a separate audit.

## 2. Curated Hoenn selections (18)

| Trainer | Mega choice | Edition / caveat |
| --- | --- | --- |
| Roxanne | Glimmora | Extra species requires National Dex; specific Emerald #773 replacement below |
| Brawly | Medicham | Existing in some rematches; add where space |
| Wattson | Manectric | Present in audited Emerald parties |
| Flannery | Camerupt | Present in audited Emerald parties |
| Norman | Kangaskhan | Existing in later rematches; add where space |
| Winona | Altaria | Present in audited Emerald parties |
| Tate & Liza | Meowstic | Single-owner doubles, Emerald exact IDs/parties below |
| Wallace — Gym | Gyarados | Ruby/Sapphire only |
| Juan — Gym | Tatsugiri (Curly) | Emerald only; specific replacements below |
| Sidney | Absol | Eligible existing Pokémon |
| Phoebe | Banette | Last matching copy |
| Glacia | Glalie | Last matching copy |
| Drake | Salamence | Eligible existing Pokémon |
| Steven — Champion | Metagross | Ruby/Sapphire only |
| Wallace — Champion | Gyarados | Emerald only |
| Maxie | Houndoom | Add if absent and space |
| Archie | Sharpedo | Eligible existing Pokémon |
| Wally | Gardevoir | **Audit-only** until real imported trainer entries verified |

### Emerald: approved exact-party edits

The following are **not general-purpose changes** to every same-name trainer. They apply only when the imported Emerald trainer identity and the **entire ordered original party signature** match the verified export.

| Trainer ID | Exact action | Signature Pokémon preserved |
| --- | --- | --- |
| Roxanne #773 | Replace Golem (slot 2, Lv.47) with Glimmora Lv.47 | Nosepass slot 6 |
| Juan #800 | Replace Crawdaunt (slot 5, Lv.58) with Tatsugiri Curly Lv.58 | Kingdra slot 6 |
| Juan #801 | Replace Crawdaunt (slot 5, Lv.63) with Tatsugiri Curly Lv.63 | Kingdra slot 6 |
| Tate & Liza #271 | Add Meowstic in new slot 5 at Lv.42 | Lunatone, Solrock |
| Tate & Liza #794 | Add Meowstic in new slot 6 at Lv.50 | Lunatone, Solrock |
| Tate & Liza #795 | Replace Drowzee (slot 1, Lv.53) with Meowstic Lv.53 | Lunatone, Solrock |
| Tate & Liza #796 | Replace Hypno (slot 1, Lv.58) with Meowstic Lv.58 | Lunatone, Solrock |
| Tate & Liza #797 | Replace Hypno (slot 1, Lv.63) with Meowstic Lv.63 | Lunatone, Solrock |

Exact full party signatures are encoded in `data/mega_boss_selections.lua`. The controller checks the correct trainer name/class, current game, numerical ID, exact ordered species/levels and native party ownership before proposing a per-battle change.

**Doubles:** Tate & Liza must be one verified imported-ROM trainer with `doubleBattle` true, using a shared party. Any `twoOpponents`, second trainer ID, `foeHalf`, `multi` or `partyOwner` layout fails closed.

**Species provider:** Glimmora, Tatsugiri and Meowstic are not stock Gen 3 species. Install [National Dex Gen 3](https://github.com/poooooby/national_dex_gen3) or an equivalent compatible species provider. No invalid species ID should be added if they are absent.

### Wally status

Chosen Mega: **Mega Gardevoir**. The Emerald trainer audit has **not** resolved Wally's actual trainer records. Gen1Recomp's Emerald constants identify plausible trainer IDs **#519 and #656–660**. These IDs are included in candidate discovery, but **they are not proof that the imported ROM data matches**. The in-game audit displays available candidate IDs and parties with `trainer_identity_unverified`; no curated Wally team change is enabled.

## 3. Battle and data safety rules

- An ordinary NPC trainer with eligible Pokémon chooses the **last eligible living member**. A verified boss selection specifies the exact slot and Mega slug. Both sides have an independent one-Mega allowance.
- Enemy Mega Evolution activates before its first resolved move, not merely when sent out. Fainting does not refund the Mega opportunity; the displayed Mega sprite should persist until its faint animation completes.
- Do not grant an NPC actual held Mega Stones or Key Stones merely to use this system.
- No save file, Pokémon permanent species/form, player items or original imported ROM trainer pack is modified by the roster overlay.
- Existing matching Mega-capable species are preferred. Otherwise a new Pokémon is **added only when a party slot exists**. Full-party replacement requires **an explicit approved ROM-ID-and-party-specific decision** (the Emerald table above), never an arbitrary swap.
- A failed curated match **must not fall back** to a different automatic Mega. Wild, link, spectator, Safari, tutorial, ghost, secret-base, e-Reader, Trainer Tower, Battle Tower and Frontier encounter exclusions remain enforced.

## 4. Trainer audit menu and status labels

Open **START → MEGA AUDIT** (default visible; optional toggle in the mod settings).

| Control | Action |
| --- | --- |
| Up / Down | Select trainer record |
| Left / Right | Page through the list |
| L / R | Filter ALL / READY / NEEDS REVIEW |
| A | Inspect original party species/levels and selected Mega |
| B | Back / exit |
| START | Refresh imported ROM trainer records |
| SELECT | Export `exports/mega_trainer_audit.txt` into the mod's cache |

Status examples: `existing` (eligible Pokémon already in party), `add` (safe append), `replace` (approved SWAP), `disabled_by_choice` (OFF), `species_not_registered`, `full_party_needs_approval`, `audited_party_mismatch`, `double_party_ownership_unverified`, `trainer_identity_unverified` and `trainer_identity_not_found`.

The export is the starting point for new decisions. It shows **what the currently imported game actually contains**, rather than inferring trainer IDs from an unrelated ROM revision.

## 5. Remaining reviews

- Wally: confirm imported IDs, class, levels, Gardevoir occurrences and which fights should Mega.
- LeafGreen Rocket Giovanni and any variant-specific trainer ID changes.
- Tate & Liza: live double-battle verification across all five Emerald party versions.
- Other full six-member boss teams still blocked pending a specific approved replacement.
- Full balance review for early Gym Megas and later optional boss encounters.
- National Dex compatibility and remaining species/art/ability tests across all five Gen 3 games.

See [Testing](TESTING.md) for the full acceptance matrix and [Dependencies](DEPENDENCIES.md) for species requirements.
