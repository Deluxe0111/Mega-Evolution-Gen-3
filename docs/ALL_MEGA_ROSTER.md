# Full Mega roster — experimental stock Gen1Recomp gameplay

This branch enables **all 98 EBDX form keys** instead of only Mega Venusaur.
There are 92 distinct held Mega Stone items already registered, and the Key
Stone remains required in the Bag. The 98 variants include the X/Y/Z forms,
several same-stone original-form variants and Mega Rayquaza.

## How to use

1. Install the full-roster Mega mod branch and a compatible species pack for
   Pokémon absent from original Gen III (e.g. National Dex Gen 3).
2. Give the trainer Key Stone (item ID 1599) in the Key Items pocket.
3. Give the Pokémon the exact Mega Stone registered for its species/variant.
   Mega Rayquaza instead needs to know Dragon Ascent and cannot hold a
   competing Mega Stone. Dragon Ascent must exist in the move provider.
4. Open FIGHT, press START (or click the available Mega label), choose a move.
   Transform before move resolution; keep the temporary Mega until faint/end.

## Implementation and rules

- `data/mega_battle_forms.lua` is generated from pinned EBDX PBS metadata:
  all 98 slugs, exact stones and original forms, 6 base stats, types, abilities.
- `src/mega_battle.lua` replaces the single-form controller. Never changes
  a permanent species slot, saved mon data, nickname, IV/EV, or provenance.
- Non-HP Mega stats are calculated from the **Mega form's** base stats and the
  Pokémon's current level, personality (nature), IVs, and EVs. Max HP remains
  unchanged in battle. Turn-order code sees the new speed from the **next**
  turn, while the activation turn retains pre-Mega Speed.
- The live battler's ability and recognized types temporarily change. On
  switch-in the same Mega form is restored. On faint/end the original live
  battler fields are restored, with no refund of the one-Mega allowance.
- Per-form front, back, shiny art all use the existing animation atlas. The
  excellent tested Mega Venusaur presentation is unchanged. Untuned Mega art
  gets first-pass per-animation dimensions using common alpha bounds, retaining
  the original transparent bottom gap for deliberate flying/hovering. The full
  roster must be visually calibrated species by species.
- Same-stone variations (Meowstic, Zygarde, Magearna, Tatsugiri) are selected
  **only** if the original mon's `form`/`formId` matches the pinned source
  base-form number. This avoids silently picking the wrong representation.
- Native Gen3 on-entry effects are dispatched only when the existing engine
  knows the ability. There is no attempt to fabricate effects for new abilities.

## Known gameplay gaps — important

Enabling a form does **not** imply all post-Gen-III mechanics work:
- Stock Gen 3 has no Fairy type ID or Fairy type-effectiveness chart. If a Mega
  gains Fairy, we leave its current battle typing unchanged rather than use
  a bogus type number. Type-expansion integration is required for correct Fairy.
- A number of EBDX abilities (e.g. Pixilate, Tough Claws, Parental Bond and
  original abilities from later generations) do not have native Gen3 engine
  implementations. Ability identity changes, but such effects do not magically
  exist. Native abilities work to the extent the engine implements them.
- No opponent/trainer Mega commands, full transformation cinematic, dedicated
  cries or moves not available from installed move providers.
- Original battle presentation of many Megas remains a *first-pass estimate*.
  Hovering/airborne sprites are **never automatically grounded**.
- Rayquaza works only if the currently installed move pack exposes Dragon
  Ascent in its move IDs and the mon actually knows it.
- Testing in headless Lua mocks and CI is not a substitute for Emerald/FireRed
  playtests, especially doubles, changed typing and cross-mod interactions.

## Testing checklist

- Test Venusaur as a regression first, then Charizard X/Y, Blastoise, Rayquaza,
  Meowstic's two forms, Zygarde, Magearna and all three Tatsugiri.
- Test Gen I-III and National Dex species with the G9 and HD mods both
  enabled, then disable HD. Watch for animation clipping and enemy sprite scale.
- Confirm stats of the *live battler* change; original party record and save do
  not. Test switch/faint/restart, wrong stone, no Key Stone, cancelled move,
  different opponent and doubled-target selection.
- Check unsupported abilities and Fairy as **known limitations** and do not
  describe them as faithfully implemented until their effects exist.
