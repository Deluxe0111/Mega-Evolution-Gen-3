# Gen 3 Mega ability compatibility audit

Audit basis: `data/mega_battle_forms.lua` (98 Mega forms, 85 explicit ability
overrides spanning **60 distinct ability names**, 13 forms retaining original
ability), Gen1Recomp Gen3's native ability adapter, and all previously merged
Mega ability modules. This document tracks *code coverage*, not a claim that
every interaction has been validated in FireRed and Emerald.

## Coverage

| Layer | Abilities and responsibilities |
| --- | --- |
| Native Gen3 engine | Drought, Huge Power, Inner Focus, Insomnia, Intimidate, Levitate, Lightning Rod, Shadow Tag, Shell Armor, Speed Boost, Swift Swim, Thick Fat, Trace. These should keep using the native adapter/ability resolver. |
| `mega_abilities.lua` | Adaptability, Aerilate, Dragonize, Filter, Iron Fist, Mega Launcher, Multiscale, No Guard (accuracy), Pixilate, Refrigerate, Sand Force, Scrappy, Sharpness, Strong Jaw, Technician, Tough Claws. |
| `mega_reactive_abilities.lua` | Berserk, Bulletproof, Magic Bounce, Regenerator. |
| `mega_tactical_abilities.lua` | Defiant, Infiltrator, Prankster, Protean. |
| `mega_weather_abilities.lua` | Delta Stream, Electric Surge, Snow Warning, Solar Power. |
| `mega_specialized_abilities.lua` | Contrary, Mold Breaker, Sheer Force, Skill Link. |
| `mega_precision_abilities.lua` | Parental Bond, Stalwart, Steadfast, Unseen Fist. |
| `mega_champions_abilities.lua` | Aura Guard, Fire Mane, Mega Sol, Piercing Drill, Spicy Spray; Unseen Fist protection correction. |
| `mega_field_abilities.lua` | Eelevate, Fairy Aura, Innards Out, Thermal Exchange; Power Construct Complete-Forme guard. |
| `mega_ability_interactions.lua` | Healer (Mega Audino); Intimidate ↔ Contrary/Defiant interoperability. |

The inventory and mapping above should be revisited if the Mega form roster or
core Gen3 move/ability engine changes. **Implemented does not mean battle-tested.**

## Confirmed integration gaps and restrictions

1. **No Guard:** the accuracy-roll hook does not yet bypass native Fly/Dig/Dive
   semi-invulnerable checks.
2. **Prankster:** modern Dark-type immunity to targeted priority status moves
   and priority on the initial Mega turn are unimplemented.
3. **Parental Bond:** the native multi-hit loop performs the secondary-effect
   check once for the attack, not once per successful hit.
4. **Electric Terrain:** direct sleep is blocked for grounded Pokémon, but
   indirect sleep (such as Yawn expiring at end of turn) still needs a native
   `applyStatus` entrypoint test and possibly an additional guard.
5. **Thermal Exchange:** burn protection is currently scoped to native
   move-resolution; out-of-turn scripted status needs verification.
6. **Power Construct:** both Mega Zygarde entries already activate with Complete
   Forme's 216 base HP. No second transformation is appropriate for those
   entries. Separate non-Mega 10%/50% → Complete handling is *not* implemented.
7. **Intimidate/Contrary:** the stage values are now corrected, but the native
   Intimidate text/animation may still describe a decrease when Contrary raised
   Attack. Requires visual/gameplay QA.
8. **Fairy:** Pixilate, Fairy Aura and the Mega forms with Fairy typing depend
   on a separately installed Fairy type provider. We must not assign a
   competing numeric ID.
9. **Eelevate:** reuses Levitate for Gen3 hit and Spikes checks. Additional
   hazards supplied by content packs may require explicit compatibility.
10. **Weather / custom ability combinations:** verify Delta Stream against
    Drought/Drizzle/Sand Stream, Solar Power under effective weather, and any
    additional modern move status/targeting hooks.

## High-priority in-game regression matrix

| Scenario | Expected result |
| --- | --- |
| Mega Staraptor / Mega Malamar (Contrary) hit by Intimidate | Attack **rises by one**, up to +6. Mist/Substitute still block the interaction. |
| Mega Falinks (Defiant) hit by Intimidate | Attack **falls by one, then rises by two** (net +1); do not trigger when blocked. |
| Mega Audino (Healer), double battle, ally poisoned | At the holder's end-of-turn ability step, **30% chance** to cure the ally only. No activation in singles or when the ally is fainted. |
| Mega Kangaskhan (Parental Bond), damaging single-target move | One PP, two hits (second 25%), one secondary roll in current Gen3 integration. |
| Mega Eelektross (Eelevate) with a Ground attack | Immune through native Levitate checks; KO improves the highest non-HP stat once per foe. |
| Mega Rayquaza (Delta Stream) active with opponent's Drought | Strong winds remain until Delta Stream leaves/faints. |
| Mega Scovillain (Spicy Spray), opponent attacks through Substitute | No burn if only Substitute takes damage. |
| Mega Victreebel (Innards Out), multi-hit KO | Recoil damage equals **total target HP lost** across the move, not just the final strike. |
| Mega Feraligatr (Dragonize) and Mega Altaria (Fairy typing) | Correct provider-driven attack typing and sprites with expanded content packs. |
| Disable/uninstall the Mega mod during combat | Native functions and adapter state should return to their original behaviour. |

## Engineering rules

- Preserve the original `mon` data, ROM move rows and global type/ability IDs.
- Scope temporary adapter/target changes with protected calls and restore on
  both successful returns and errors.
- Extend existing Gen3 action boundaries, not guessed global battle events.
- Keep feature branches **draft** until the unit suite passes **and** FireRed /
  Emerald gameplay tests cover edge cases.
- Changes to the underlying Gen1Recomp engine require compatibility review,
  especially native direct stage modifications, residual `applyStatus`,
  targeting and semi-invulnerable checks.
