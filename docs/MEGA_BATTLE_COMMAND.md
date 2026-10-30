# Omega Ruby / Alpha Sapphire-style Mega Evolution command

Reference: https://bulbapedia.bulbagarden.net/wiki/Mega_Evolution#In_battle

## Proposed user interaction

Mega Evolution is NOT one of FIGHT/BAG/POKéMON/RUN. It is a selectable toggle inside the FIGHT move-selection screen:

1. Player selects FIGHT.
2. If the active Pokémon is eligible, show a visible **MEGA EVOLVE** button/indicator beside the four moves, with a controller shortcut (to be selected after actual input-map testing). An ineligible Pokémon sees no misleading live button.
3. Toggle ON: **MEGA READY**. Toggle again: normal move. No move or turn is consumed yet.
4. Player selects a valid move, and, in double battles, confirms the target. The selected move remains the normal action, tagged with an optional Mega request.
5. Turn-order planning proceeds as normal (Gen VI/ORAS timing: the transformation-turn Speed change does not recalculate order).
6. Just before that Pokémon acts, the battle adapter checks the request, applies the correct form's stats/typing/ability, and plays a transformation sequence (where the battle rules permit). Then the previously selected move executes.
7. After Mega Evolution, the one-per-trainer allowance is used, the Mega artwork/name remain until faint or battle end, and switching out does not undo the temporary form.

A request is cancelled when backing out of move selection, cancelling a partner's turn selection, or the engine rejecting the final action. Merely toggling the button does **not** reserve the once-per-battle allowance permanently.

### Existing Gen1Recomp code seams to integrate

Audited against bryanthaboi/gen1recomp (dev) on 2026-10-30:

- src/core/game3/battle/ui.lua: open_move_menu, Ui.handleInput, target-selection completion, Ui.takeCommand and draw_move_menu variants for FireRed/LeafGreen, Ruby/Sapphire and Emerald.
- src/core/game3/battle/commands.lua: Commands.playerAction returns a regular kind="move" command; do not change the move slot.
- src/core/game3/battle/engine.lua: turn planning and Engine.resolveMove; preserve the original action and turn-order semantics.
- src/core/game3/battle/init.lua: turn execution, double-battle action queue, pursuit/switch exceptions and battle cleanup. Must review all relevant resolve paths before installing hooks.
- src/core/game3/battle/ui.lua also exposes a battle.overlay hook, which may assist visual display, but **not** input acceptance. An overlay by itself would be a dead button.

This is an architecture and tested selection-state milestone, **not** an implemented on-screen control or a working transformation. We intentionally avoid installing an inert UI button.

## Code already implemented

src/mega_selection.lua is an isolated controller with:

- toggle(side, pokemonIdentity, megaSlug, eligible) to arm/disarm
- commit(side, pokemonIdentity, normalMoveAction) to attach Mega metadata to a copy of a validated move
- cancel(side, pokemonIdentity, action?) to safely undo any pending request
- activate(side, pokemonIdentity, decoratedMoveAction, success) to mark a successful transformation and consume that side's allowance
- faint, activeForm and finishBattle to preserve or revert form appropriately

Nothing in this module updates engine Pokémon data; it only records temporary intent and activation state. The future battle adapter owns eligibility and actual transformation, while the G9-compatible art provider supplies frames. No public release should describe this controller as playable Mega Evolution.

## Rules to verify during next implementation

- One Mega per trainer per battle. Trainer Key Stone and a compatible held Mega Stone (or documented Rayquaza exception); two-form species choose the form from the held stone.
- No extra turn or action consumed; a non-move action cannot Mega Evolve.
- Transform/Imposter and battles where a Pokémon cannot act appropriately restricted.
- Generation VI turn-speed precedence preserved for the activation turn; changed stats/types/ability are active for damage when the move is executed.
- Reversion on fainting or battle end; persists through switching, but not into save data.
- Both sides can use a Mega in the same battle; in double battles, only one member per side.
- Graphics render correctly for normal/shiny and all five Gen 3 games; no G9/HD hooks overwritten.
- Only eligible Pokémon can see/activate the button; move swap (SELECT), normal move controls and back navigation stay intact.
