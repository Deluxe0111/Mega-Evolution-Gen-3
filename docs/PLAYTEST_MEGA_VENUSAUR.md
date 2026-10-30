# Mega Venusaur playtest (experimental PR #8)

This is the **first single-form gameplay proof**, not a 98-form release.
It requires the companion Gen1Recomp engine branch/PR that adds the five
scoped Gen 3 battle seams. On stock Gen1Recomp the mod fails closed:
items and art still load, but `isActive()` stays false and no Mega button
is installed. Do **not** describe it as playable on stock builds.

## Required setup

1. Use a disposable **Pokémon Emerald** save and matching Gen1Recomp
   engine with battle hooks: `battle.move_menu_input`, `battle.move_command`,
   `battle.before_move`, `battle.stat_value`, `battle.battler_picture`.
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
  with pre-Mega Speed. Immediately before the move resolves, Venusaur
  becomes Mega Venusaur for battle calculations, ability and drawing.
- Base stats are **80/100/123/122/120/80** (HP/Atk/Def/SpA/SpD/Spe);
  level, IVs, EVs and nature are preserved. Thick Fat applies.
- Only that Pokémon shows its animated Mega sprite (front/back and shiny).
  A second Venusaur on the field remains normal.
- Switching out and back restores the Mega form and Thick Fat.
- A fainted Mega is cleared without refunding the trainer's one-per-battle
  limit. Battle end removes all temporary form state.
- Saved species, original calculated stats, nickname, moves, PP, encounter
  history and Nuzlocke identity must remain unchanged.

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
- No actual in-game test has been performed by this PR authoring session;
  the Lua headless unit tests and GitHub Actions are the preliminary gate.
  Do not merge until tests pass and an Emerald gameplay capture is reviewed.
