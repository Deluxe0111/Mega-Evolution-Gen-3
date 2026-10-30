# Roadmap

## Milestone 0 — Repository foundation

- [x] Mod metadata and non-invasive entry point
- [x] Credited EBDX asset intake
- [x] Asset inventory and missing-file validation
- [x] Import and commit the source-art folders to the repository
- [x] Separate generated machine-specific audit reports from source artwork and CI

## Milestone 1 — Animation pipeline

- [ ] Inspect EBDX PNG animation sheet geometry and the source animation timing rules
- [ ] Convert Mega front/back and normal/shiny sprite sheets to a packed, animated Gen1Recomp atlas
- [ ] Prepare party icons and static fallbacks
- [ ] Preview all sprites without touching Pokémon battle state

## Milestone 2 — Mega Venusaur proof of concept

- [ ] Identify the correct Gen1Recomp Gen 3 battle hook and rendering seam
- [ ] Expose a Mega command for one eligible Pokémon holding its Mega Stone
- [ ] Apply temporary stats, typing, ability, artwork and battle display name
- [ ] Return to normal form at battle end and keep save species identity unchanged
- [ ] Test switching, fainting, capture, reconnect, shiny status and save/load

## Milestone 3 — Complete Mega roster

- [ ] Import every supported Mega Stone/form and exceptions (X/Y, Z, Rayquaza)
- [ ] Add battle-once Mega rules, trainer Megas, opponent support and transformation animation
- [ ] Add detailed gameplay tests in FireRed and Emerald, then all five Gen 3 editions

## Milestone 4 — Optional integrations

- [ ] National Dex Gen 3 species/form metadata
- [ ] G9 Battle Sprites and HD sprite drawing ownership
- [ ] Untamed Advanced follower/overworld visuals when relevant
- [ ] Nuzlocke randomiser/encounter/permadeath and results display compatibility

**No mechanic is complete merely because its sprites are present.**
