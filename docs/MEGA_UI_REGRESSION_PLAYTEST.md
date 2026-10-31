# Mega battle/UI rendering regression checks

A full-roster Emerald/FireRed playtest showed:

- Gigantic/off-screen **ordinary enemy** sprites, even in battle intros.
- Untuned Mega backs too small and floating above the pad.
- Oversized non-Mega summary pictures.
- Party/summary continuing to show base icons, stats, abilities and artwork
  while a Pokémon has Mega Evolved **in an active battle**.

## Root causes and resolution

The G9 battle sprite provider lazily installs its own persistent
`love.graphics.draw` interception. An earlier build installed a temporary
Mega-origin shim on *every* `Ui.draw` frame, including the very first normal
battle frame. If G9 installed while the shim was active, it could capture the
temporary function as its permanent predecessor. That order can distort
other Pokémon and even other UI screens.

The full roster controller now activates this shim **only when a visible
battler already has an active Mega form**. Stock/G9 drawing remains fully
unmodified in ordinary battles, including intros. When Gen 3 HD Sprites has
its Battle HD pass enabled, the Mega renderer skips the shim entirely and
uses its existing `hd.tag` with full-resolution sprite and separate pivot.

For the two backs shown in the bug report, the normalised animation index
provides these common frame envelopes:

| Mega back | Frame | Alpha envelope Y | First-pass scale / feet |
|---|---|---|---|
| Charizard X | 135px | 19..115 | 0.72 / 121 (small deliberate hover) |
| Mewtwo X | 96px | 9..85 | 0.90 / 86 |
| Venusaur (previously calibrated) | 121px | 21..99 | 0.85 / 100 |

Other untuned Mega backs now target 68 visible game pixels, up from 62,
but deliberately retain their original bottom-of-frame offset pending QA.
They are **not auto-grounded** frame by frame, preserving flying motion.

The new `src/mega_ui.lua` is a *display adapter*, not a species/save
override. While a battle is active, it resolves the form of one party mon
and provides:

- Fitted **64px front Mega image** in summary, never a huge battle canvas.
- A separate **32px icon image** in the party and summary UI.
- A **temporary, shallow party-mon view copy** carrying Mega stat numbers,
  and a human-readable Mega ability, for summary draw calls. The actual
  party array entry is restored immediately, including when drawing errors.
- Emerald/Ruby/Sapphire's native summary uses the same view. Its ability
  label is overridden only during the display pass (ability mechanics are
  separate from label display).

## Expected game behaviour

A Mega form is temporary. **After the battle ends, the summary and party
screen must return to the original Pokémon's stats, sprite, icon and
ability.** The display changes apply only *during an active Mega battle*.

## Manual check (restart fully first)

1. Completely quit and reopen Gen1Recomp to clear the previously captured
   global G9 draw handler. Verify an ordinary wild battle with Zigzagoon or
   Rockruff **before any Mega activation**.
2. Fight with normal Venusaur; activate Mega and confirm normal opponent
   size. Repeat with Charizard X and Mewtwo X, front/back, HD on/off.
3. While that battle is still running, open party/summary and confirm the
   Mega's fitted picture, 32px icon, temporary numbers and ability label.
4. Return to battle, switch out/in, check ability/stats remain Mega.
5. End the battle. Verify saved party, boxes and summary show the base
   Pokémon again; reload save and check no Mega data is persisted.
6. Test an unrelated Pokémon's summary/party in the same battle. Its
   artwork, stats and ability must remain unchanged.

New scoped-draw and summary-copy tests cover the main regressions, but
actual G9/HD runtime interactions still need live validation.
