# Roadmap

## Milestone 0 — Repository foundation

- [x] Mod metadata and non-invasive entry point
- [x] Credited EBDX asset intake
- [x] Asset inventory and missing-file validation
- [x] Import and commit the source-art folders to the repository
- [x] Separate generated machine-specific audit reports from source artwork and CI

## Milestone 1 — Animation pipeline

- [x] Implement strict geometry audit and inspect all imported PNG strip dimensions in CI
- [x] Convert Mega front/back, normal/shiny and party-icon PNG strips into lossless bounded atlas pages
- [x] Add a one-click full-roster launcher and index/page integrity checker
- [x] Emit stable form-keyed Lua/JSON animation index without touching species/save data
- [x] Export Mega Venusaur GIF previews and test frame-order/alpha preservation
- [ ] Visually review EBDX timing and normal/shiny alignment; use static fallback when required
- [x] Build a lazy-loaded form-keyed Lua picture provider with bounded GPU memory and no conflicting engine hooks
- [ ] Integrate the provider into an actual Gen1Recomp battle through an explicitly selected battler state, without interfering with G9 Battle Sprites

## Milestone 2 — Mega Venusaur proof of concept

- [x] Audit Gen1Recomp's normal move selection, double-battle targeting and action-resolution seams
- [x] Implement a standalone, tested Mega request/commit/cancel state controller (not yet wired to gameplay)
- [x] Register 92 fixed-ID Mega Stones and a Key Stone through the native Gen 3 item registry
- [x] Implement read-only live eligibility checks against held item, species and actual Bag Key Stone possession
- [ ] Add a visible Mega button inside the FIGHT move menu with eligibility and input controls
- [ ] Attach the request to the move after selection, then transform immediately before that move executes
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
