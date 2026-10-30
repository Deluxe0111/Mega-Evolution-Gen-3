# Mega Venusaur playtest (experimental PR #8)

This is the **first single-form gameplay proof**, not a 98-form release. User gameplay testing confirmed that the Key Stone unlocks the Mega toggle; visual sizing remains under review.
It is intended for **unmodified, stock Gen1Recomp**: the mod itself wraps
existing Gen 3 Lua battle functions. No custom battle hooks, patches or
upstream PRs are needed. This is still **experimental** and must pass an actual
Emerald session before being promoted from Draft.

## Required setup

1. Use an unmodified current **Gen1Recomp** build with a disposable
   **Pokémon Emerald** save. No engine fork or extra API hooks.
2. Install this Mega mod and, ideally, National Dex + G9 Battle Sprites
   + Gen 3 HD Sprites + Untamed Advanced + Nuzlocke as a compatibility stack.
3. Give the player the Key Stone (registered item ID **1599**) and a Venusaur
   with **Venusaurite** held. The mod intentionally does **not** grant either
   item or alter existing saves. Use a controlled development save/item
   injection mechanism (avoid modifying an actual challenge run).
4. Use a battle with a second non-Mega Pokémon for comparison.

## Expected behaviour

- Enter **FIGHT**. If eligible, the small prompt **START: MEGA** appears.
- Press **START** to arm the Mega; the prompt reads **MEGA READY**.
  START again disarms. Backing out with B cancels. No extra action/turn.
- Select a valid move (and target in doubles). Turn order stays as planned
  with pre-Mega Speed. A scoped wrapper of the stock move executor activates
  Mega Venusaur immediately before the move resolves. Ability and artwork
  follow the live battler; damage reads a temporary Pokémon stat copy.
- Base stats are **80/100/123/122/120/80** (HP/Atk/Def/SpA/SpD/Spe);
  level, IVs, EVs and nature are preserved. Thick Fat applies.
- Only that Pokémon shows its animated Mega sprite (front/back and shiny).
  A second Venusaur on the field remains normal.
- Switching out and back restores the Mega form and Thick Fat.
- A fainted Mega is cleared without refunding the trainer's one-per-battle
  limit. Battle end removes all temporary form state.
- Saved species, original calculated stats, nickname, moves, PP, encounter
  history and Nuzlocke identity must remain unchanged.

## Mega Venusaur sprite sizing regression

The original playable build fitted every Mega back sprite into a 64×64 canvas,
making it **smaller** than the already large G9 normal Venusaur. In the
follow-up fix, battle-only frames use `data/mega_presentation.lua`: Venusaur's
121px Mega back frame is drawn at 0.80 source scale, aligned by its feet to
the G9 player back baseline. Its 117px front frame has separate tuning.
The battle renderer uses a wider logical canvas (with the native
32px draw origin translated), or the Gen 3 HD Sprites `tag` API when HD
battle mode is enabled. Standard exports and icons still fit 64×64.

**Test Emerald and FireRed separately**: compare original Venusaur to Mega
Venusaur on the same pad, check that Mega is similarly sized (not shrunk),
remains feet-aligned, is not clipped at the top/left, and retains animation
without blur. Repeat with HD enabled and disabled, and on a shiny Venusaur.
The initial 0.80 / 0.74 presentation values are test defaults and may need
fine adjustment from gameplay screenshots.

## Opponent sprite regression — scoped drawing

The previous large-Mega-canvas fix left a global `love.graphics.draw`
wrapper installed. Player screenshots show Mega Venusaur at the intended size
but unrelated enemy Pokémon (Zigzagoon and Rockruff) enlarged off-screen.

The corrected adapter installs its Mega-only pivot translation **only while
stock `Ui.draw` paints a battle frame**, restores the existing G9/HD draw
handler afterwards (even after an exception), and passes all non-Mega draws
through with the original argument count and exact values.

**Restart Gen1Recomp fully before testing this branch**, because the earlier
global graphics wrapper may still be active in an already-running process.
First test an ordinary wild battle **without Mega Evolution**, then toggle
Mega Venusaur and verify both sprites. Repeat in Emerald and FireRed with
G9 and HD enabled; test at least one enemy with a different sprite size.
These screenshots are a reported regression, not a validated fix yet.

## G9 / HD sprite presentation calibration

Source inspection and a real screenshot comparison found the initial Mega back
presentation `scale = 0.80`, `feet = 111`, `baseline = 57` was not aligned to
the actual 74-frame sprite animation. Both shiny and normal Mega Venusaur back
atlas entries in `assets/runtime/mega_atlas_index.lua` have a common alpha
envelope at source rows 21..99, with **bottom at y=100**. The legacy anchor
put its visible feet **8.8 game pixels above** baseline 57 (11 * 0.80).

The new tested default is **back scale 0.85**, source feet **100**, baseline
**57**. G9 normal Venusaur uses a typical 63px-tall back-sprite body
(`cy0=13`, `cy1=76`), multiplied by its default approximate 1.069
HD scale (`bn=1.063` plus default realism for a 2m Pokémon), resulting
in ~67.3 game pixels. Mega Venusaur's alpha envelope is 79px tall,
and **79 × 0.85 = 67.15px**. The change matches *visible height*, not
the misleading full transparent source-square size.

For the enemy view, Mega front `feet` changes from 108 to the atlas alpha
bottom **98** (common crop y=19, height=79); the existing front scale 0.74
is retained pending visual checks.

With **G9 Battle Sprites**, sprite sizes come from
`src/atlas.lua:backLayout` and `frontLayout` plus species metadata
(`bfr/bfl`, bounding boxes, per-game `coordShift`). When **Gen 3 HD
Sprites** is active, G9 additionally passes source quads, per-side scale,
pivot, lowPivot, frame top, and optional body bounds through `hd.tag()`.
Mega Evolution uses the same HD tag interface but currently has separate
presentation metadata; the goal is to match the normal Venusaur reference
without applying a global camera or pixel scaling hack.

**Test from a full app restart:** screenshot normal Venusaur before Mega,
then transformed Venusaur on the same pad. Confirm feet align with the
platform and visible height is similar. Repeat with HD Battle on/off.
Ruby/Sapphire require separate verification of G9's 4px game-specific back
shift; this fix targets the tested FireRed/Emerald coordinate system.

## Negative tests

- No Key Stone, no Venusaurite, wrong stone, fainted or transformed Pokémon,
  safari/tutorial/link scenes: no live Mega toggle.
- Reject invalid move or cancelled target without spending the allowance.
- Switching after activation should preserve active form; an attempted Mega
  on another Pokémon must fail.
- Test all five games' move-menu layouts, singles and doubles; check SELECT
  move swap, START toggle, B backtracking and held-item changes.
- Disable G9 or HD independently and verify fallback art does not break UI.

## Known limitations

- Only Mega Venusaur is wired to battle rules. Other 97 forms are art/roster
  data, not usable battle transformations yet.
- The first visual treatment uses the new Mega art and a compact battle
  indicator, **not yet the full ORAS cinematic, cry or bespoke UI art**.
- Held-item acquisition, NPC trainer Mega stones, Rayquaza's special rule
  and Z-form policies remain separate milestones.
- No actual in-game test has been performed by this PR authoring session.
  Lua tests validate the wrapper chain and save isolation but do not substitute
  for integration tests. Do not merge until CI passes and Emerald gameplay
  has been reviewed.
- The implementation wraps internal public Lua functions
  (`Ui.handleInput`, `Ui.takeCommand`, `Engine.resolveMove`,
  `Damage.base`, `Ui.sidePic`, `Battle.start/reset`). A future engine
  update may change these signatures. Keep fallback behaviour intact when
  the stock API is unavailable.
