# Runtime implementation notes (planning only)

- **Form identity:** Mega is temporary battle presentation/state. Preserve permanent native Pokémon slot/ID and nickname, shiny and OT data. End-of-battle reversion must happen even after an abnormal battle end.
- **Data:** PBS `BaseStats` order in Pokémon Essentials differs from some engine-native stat ordering. Verify rather than copy without conversion. New abilities and move effects must follow the active National Dex/Gen1Recomp mechanics.
- **Art ownership:** G9 Battle Sprites currently owns `Pokemon.frontPic`/`backPic` rendering when installed. Coordinate on a delegated art API; do not blindly wrap/hijack hooks with a competing owner.
- **Items:** Source Mega Stone graphics and PBS item definitions are references, not automatically registered or usable Gen1Recomp inventory entries.
- **Compatibility:** Optional companions may load in different orders. Probe public APIs safely and fail closed when absent. Never assume sprite availability implies mechanics support.
- **Testing:** Start with a normal and shiny Mega Venusaur in a disposable FireRed/Emerald save; include switching, fainting, evolution cancellation, Nuzlocke perma-death and save reload.
