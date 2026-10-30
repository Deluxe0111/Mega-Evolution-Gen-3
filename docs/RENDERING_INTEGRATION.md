# Rendering integration: four-mod compatibility research

## Reference projects

The following references describe the four Gen 3 companion mods and the lessons applied here.

| Project | Relevant code | Lesson |
| --- | --- | --- |
| [National Dex Gen 3](https://github.com/poooooby/national_dex_gen3) | src/api.lua, data/species/forms.lua | Ordinary alternate forms have append-only engine slots **because those slots persist in saves**. Megas should **not** receive slots: temporary battle states must leave saved Pokémon species unchanged. The slotOf and idOfSlot APIs resolve base species. |
| [G9 Battle Sprites (Gen 3)](https://github.com/poooooby/g9-battle-sprites-gen3) | src/hooks.lua, src/atlas.lua, src/api.lua | **Owns Pokemon.frontPic, Pokemon.backPic, Pokemon.icon and RSE entry animation/Pokédex handling.** Draws PNG atlas frames into 64x64 logical image entries. Uncoordinated extra picture hooks are unsafe. Its public exports currently include isActive, provider, hasSprite; **no foreign sprite registration API** exists. |
| [Gen 3 HD Sprites](https://github.com/poooooby/gen3-hd-sprites) | src/api.lua | Public tag(image, spec), untag, enabled(pass) support full-resolution tagged sprites and feet anchoring. A later Mega renderer can use this without interfering with other tagged images. |
| [Modern Spawns](https://github.com/poooooby/g1r_modern_spawns) | src/api.lua, src/adapters/gen3.lua | Spawns are separate from temporary Mega battle forms. Never modify wild encounter tables or randomiser IDs to change battle presentation. Feature-test exports and preserve ownership of returned data. |

## Current renderer foundation

The module src/mega_atlas.lua is a **lazy-loading, form-keyed art provider**, not an auto-hook.

main.lua exposes these through mod.exports:

- apiVersion = 1, isActive() = false (gameplay absent), artAvailable()
- hasSprite("mega_venusaur", "front")
- formInfo("mega_venusaur"): small copy of stable form identity
- frameLocation(slug, variant, frame): page / coordinates without GPU loading
- frame(slug, variant, frame?): Love2D texture, quad and source dimensions; omitted frame uses the timer
- picture(slug, side, shiny, frame?): standalone {image, w=64, h=64} presentation entry (provisional fit-to-box)
- cacheStats(): counts of loaded pages and cached picture frames

PNG pages load **only when requested**. Memory is capped at six texture pages and 48 rendered picture entries; the 156 PNG pages are never loaded wholesale. Failures return nil and do not damage the normal sprite provider.

**The current mod does not install any Pokémon, battle, party icon or Pokédex hooks.** It does not yet implement Mega Evolution mechanics.

## Required compatibility work

1. **Per-battler state:** two Venusaur in one battle must not automatically both display Mega Venusaur. Store a temporary form per Pokémon/battler and clear it after battle, switching and abnormal exit.
2. **Rendering ownership:** prefer asking G9's maintainer for a small optional external sprite-provider registration API. If unavailable, develop a narrowly scoped adapter only after testing G9 load order, reload and fallback behaviour. Avoid competing global wrappers merely for a demo.
3. **Battle sizing and positioning:** G9 has feet-aligned fronts, larger player backs, per-game offsets (R/S vs FR/LG/E), and optional HD tagging. The provider's current 64x64 fit is not the final battle layout.
4. **Shinies and icons:** query actual Pokémon shiny state; source has distinct variants. Do not infer shiny state from species IDs.
5. **Gameplay data:** sprite indices contain no stats or items. Battle stats, types, abilities and Mega Stone triggers require explicit conversion and game integration.
6. **Saved identity:** never persist Mega species slots or alter Nuzlocke encounters, National Dex data or Modern Spawns tables.
7. **Failure handling:** art lookup errors must fall back to existing G9/native art, without breaking battle draw or leaving modified save data.

## Next milestone

Add an **explicit temporary battler-state resolver** and a rendering adapter that consumes these exports only when that particular battler has Mega Evolved. Prove opponent then player Mega Venusaur, two identical species, shiny variants, switching and battle end, with G9 and HD individually enabled/disabled.
