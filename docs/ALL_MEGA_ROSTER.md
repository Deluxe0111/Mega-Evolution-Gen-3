# Complete Mega form roster: gameplay and limitations

The mod declares **98 Mega form entries** derived from the committed EBDX source inventory and registers **92 distinct Mega Stone items** plus the Key Stone. These include X/Y/Z-style variants, different original-form representations and Mega Rayquaza. The form and item source of truth lives in `data/mega_forms.lua`, `data/mega_battle_forms.lua` and `data/mega_items.lua`.

## How Mega Evolution works

1. The player must own the Key Stone in the Bag. The Pokémon usually must hold its matching Mega Stone; Mega Rayquaza instead requires Dragon Ascent from the installed move provider.
2. During an eligible battle, toggle Mega from the **FIGHT** menu and commit an ordinary move.
3. Transform **before the attack resolves**; apply the Mega's temporary stats, compatible types/abilities, art and cry.
4. A Mega form persists through switching out and back in, until it faints or the battle ends. Fainting does not restore the one-Mega allowance.
5. Only **one Mega per side per battle**. Eligible ordinary NPC trainers can use one too, with reviewed overrides for notable trainers.

Temporary battle data must not rewrite a permanent Pokémon species slot, nickname, IV/EV, shiny identity, encounter provenance or save/PC records.

## Form and species requirements

- Base-game Mega candidates such as Venusaur, Blastoise and Gengar can work without a separate species pack when all required native abilities/moves exist.
- Later-generation candidates, including **Glimmora, Meowstic and Tatsugiri**, require an active compatible species provider, preferably [National Dex Gen 3](https://github.com/poooooby/national_dex_gen3).
- Where multiple Mega entries share a stone or species (for example X/Y, Meowstic forms, Tatsugiri forms or Zygarde), the base form/held stone and specifically selected form must be respected. Do not silently choose the wrong variant.
- Sprite presence **does not imply** that the species, form, move or corresponding modern mechanics exist in the current game.

## Combat compatibility

Base Mega stats are calculated as temporary battler state. The current mod also implements numerous modern effects in its focused Mega ability modules; [ability audit](MEGA_ABILITY_AUDIT.md) is the feature-level inventory.

Not every post-Gen3 interaction is identical across host engine and content-pack versions. Especially test Fairy type/effectiveness, move providers, priority, weather, immunity and multi-hit interactions. Changes to modern ability handlers or added moves can require new hooks.

## Visual presentation

Normal/shiny front/back Mega sprites and icons come from the source set and atlas provider. Frame positioning, hover behaviour, health-box indicator, switch menu and cry playback have been developed; **every species/form still needs live visual QA**. Normal, non-Mega Pokémon should keep their active G9/HD artwork ownership.

The source artwork, item icons and cries are committed. Do not delete `assets/source/ebdx` while packaging merely because the battle animation atlas exists.

## Trainer roster

The mod supports the selected 32 famous trainer identities with per-ROM audit, add-only defaults and **explicit approved Emerald replacements**. Full parties are not silently rewritten. See [Trainer Mega review](MEGA_TRAINER_REVIEW.md) for FireRed Giovanni, Emerald Juan/Roxanne/Tate & Liza, Wally and the remaining per-battle decisions.

## Test priorities

Start with Venusaur, both Charizard variants, Blastoise, both Mewtwos, Rayquaza, Meowstic, all Tatsugiri, then large/hovering art and shiny gender variants. Run with no optional mods, then with National Dex, G9 and HD, and test faint/switch/save isolation and boss battles.

See [Testing](TESTING.md) for a reproducible matrix and [Dependencies](DEPENDENCIES.md) for prerequisite mod IDs and links.
