# Mega battle button and symbols

This change replaces the old text block `START: MEGA` / `MEGA READY` in
the move-select overlay with the original EBDX art:

| Asset | Source in this mod | Placement |
| --- | --- | --- |
| `megaButton.png` | `assets/source/ebdx/ui_reference/Graphics/EBDX/Pictures/UI/megaButton.png` | At game-space **(0,89)**, rendered **22×22** directly above the move panel and touching the **left screen edge** |
| `symMega.png` | `assets/source/ebdx/ui_reference/Graphics/EBDX/Pictures/UI/symMega.png` | Crisp **13×17** symbol below the name/gender row and left of the HP bar, shown after Mega reveal |
| `mega_sym.png` | `assets/source/ebdx/ui_reference/Graphics/EBDX/Pictures/mega_sym.png` | Short transparent emblem bloom over the player's Pokémon at the moment of Mega activation |

`megaButton.png` is an **88×44** sheet: left **44×44 inactive** and right
**44×44 selected**. The renderer samples the corresponding half of the
**existing image** and scales it to 22×22 in native GBA coordinates;
no new/generated icons or source-image edits are necessary.

## Controls

- **START**: unchanged existing Mega toggle while choosing a move
- **Mouse/touch click** on the artwork: same toggle, not a separate state
- **D-pad LEFT** from a left-column move: focus the Mega button (2-column move menus)
- **A** while Mega button is focused: toggle Mega on/off
- **RIGHT** or **B** while focused: return focus to the move selection
- Choose a move as normal to commit the selected Mega for the turn

The Mega button only appears when the current Pokémon is eligible and
the player hasn't already consumed the once-per-battle Mega allowance.
Its active half means **armed for the current move**, not simply holding a
Mega Stone. The symbol next to the HP bar means **currently Mega Evolved**,
not merely eligible.

The emblem's white-silhouette sequence is **render-only**: the original Pokémon fades to an alpha-preserving white silhouette (0–0.48s), holds white until 0.72s, then the **white Mega sprite** is revealed and its full colours return by 1.36s. The original Mega symbol keeps growing and fading throughout. The native engine still resolves Mega abilities, speed, types and the selected attack immediately; no artificial battle delay, save edits or unrelated enemy/background tint. The optional shader is scoped to the specific Pokémon image and the draw hook restores itself even when rendering fails. If the shader is unsupported, the EBDX emblem and sprite reveal still work without a crash.

The badge uses **nearest-neighbour** filtering and uniform half-size rendering of the 26×34 EBDX source. It stays below the nickname/gender row rather than stretching into it.

The badge is positioned from Gen1Recomp's own `Healthbox.center()`
together with animation offsets, including double battles. We do not
override `Pokemon.frontPic`, `Pokemon.backPic`, battle backgrounds or G9
sprite scaling. The transform emblem is a brief *cosmetic* flourish, not
a change to turn order or a new cutscene; it requires live testing for
timing against the battle text.

## Playtest

1. Fully restart Gen1Recomp with this feature branch and the same G9/HD
   mods used for the rest of the Mega tests.
2. In FireRed or Emerald, give a Pokémon its correct Mega Stone and have
   a Key Stone in the Bag.
3. Enter move selection: verify the inactive icon at the **left edge above
   moves**, with no text overlapping the PP panel.
4. Toggle with START and verify the **right-hand active artwork**. Repeat
   by clicking, and with LEFT/A/RIGHT focus.
5. Select a move: check transformation emblem briefly flashes and
   `symMega.png` appears **left of the active battler's HP bar**.
6. Check single and double battles, switching, fainting, and a new
   ordinary battle to confirm the icon disappears.
7. Check an ineligible Pokémon: it must not receive an actionable Mega
   button or active HP badge. Normal opposing sprites must retain
   their G9 scale.

No changes to Gen1Recomp or player save data.
