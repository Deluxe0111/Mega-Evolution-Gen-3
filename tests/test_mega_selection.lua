-- Headless ORAS-style Mega selection flow tests (Lua 5.4).
local Selection = dofile("src/mega_selection.lua")

local flow = Selection.new()
local monA, monB, foe = {}, {}, {}
local validAction = { kind = "move", slot = 2, move = "SLUDGE_BOMB", target = 1 }
local ok, state = flow.toggle("player", monA, "mega_venusaur", false)
assert(not ok and state == "ineligible")
assert(not flow.status("player", monA).armed)

ok, state = flow.toggle("player", monA, "mega_venusaur", true)
assert(ok and state == "armed")
assert(flow.status("player", monA).armed and not flow.status("player", monB).armed)
-- Move selection can be backed out of without spending Mega.
ok, state = flow.toggle("player", monA, "mega_venusaur", true)
assert(ok and state == "disarmed")
assert(not flow.status("player", monA).armed)
ok = flow.toggle("player", monA, "mega_venusaur", true)
assert(ok)
local same, used, reason = flow.commit("player", monA, { kind = "switch" })
assert(not used and reason == "not_a_move")
assert(flow.status("player", monA).armed)

local decorated, committed, why = flow.commit("player", monA, validAction)
assert(committed and why == "committed")
assert(decorated ~= validAction)
assert(decorated.kind == "move" and decorated.slot == 2 and decorated.move == "SLUDGE_BOMB")
assert(not validAction.megaEvolution and decorated.megaEvolution.form == "mega_venusaur")
assert(decorated.megaEvolution.mon == monA and decorated.megaEvolution.side == "player")
assert(flow.status("player", monA).pending)
assert(not flow.status("player", monA).used)

-- No second member of the same team can queue a concurrent Mega.
ok, why = flow.toggle("player", monB, "mega_charizard_x", true)
assert(not ok and why == "mega_move_already_selected")
-- Opposing trainer has an independent once-per-battle allowance.
ok, why = flow.toggle("enemy", foe, "mega_charizard_y", true)
assert(ok and why == "armed")
local enemyAction, enemyQueued = flow.commit("enemy", foe, { kind="move", slot=1, move="FLAMETHROWER" })
assert(enemyQueued)
-- A request cannot mark Mega active before actual transformation succeeds.
local form, fail = flow.activate("player", monA, decorated, false)
assert(form == nil and fail == "transformation_not_completed")
assert(not flow.status("player", monA).used)
form, fail = flow.activate("player", monA, validAction, true)
assert(form == nil and fail == "not_committed")
form, fail = flow.activate("player", monA, decorated, true)
assert(form == "mega_venusaur" and fail == "activated")
assert(flow.status("player", monA).used)
assert(flow.activeForm(monA) == "mega_venusaur")
assert(flow.activeForm(monB) == nil)

-- Switching does not clear the original battler's temporary form.
assert(flow.activeForm(monA) == "mega_venusaur")
-- Two trainers can activate separate Megas.
form = flow.activate("enemy", foe, enemyAction, true)
assert(form == "mega_charizard_y")
-- One Mega per trainer for the entire battle, even after a faint.
assert(flow.faint(monA))
assert(flow.activeForm(monA) == nil)
ok, why = flow.toggle("player", monB, "mega_charizard_x", true)
assert(not ok and why == "already_mega_evolved")
assert(not flow.faint(monA))

-- Planner copies move rows, so the planned action must still activate.
flow.finishBattle()
assert(flow.toggle("player", monA, "mega_venusaur", true))
local sent, sentOk = flow.commit("player", monA, validAction)
assert(sentOk)
local plannedCopy = {}
for key, value in pairs(sent) do plannedCopy[key] = value end
assert(flow.activatePlanned("player", monA, sent, false) == nil)
local wrong = {}
for key, value in pairs(plannedCopy) do wrong[key] = value end
wrong.slot = 4
assert(flow.activatePlanned("player", monA, wrong, true) == nil)
assert(flow.activatePlanned("player", monB, plannedCopy, true) == nil)
assert(not flow.status("player", monA).used)
assert(flow.activatePlanned("player", monA, plannedCopy, true) == "mega_venusaur")
assert(flow.status("player", monA).used)

-- Cancellation of a committed request frees up that side before activation.
flow.finishBattle()
ok = flow.toggle("player", monA, "mega_venusaur", true)
assert(ok)
local a2, yes = flow.commit("player", monA, validAction)
assert(yes)
assert(not flow.cancel("player", monA, validAction))
assert(flow.cancel("player", monA, a2))
ok, why = flow.toggle("player", monB, "mega_charizard_x", true)
assert(ok and why == "armed")
assert(flow.cancel("player", monB))
assert(not flow.status("player", monB).armed)

-- Full battle cleanup makes the trainer allowance available in the next battle.
flow.beginBattle()
assert(not flow.status("player", monA).used and flow.activeForm(monA) == nil)
assert(not flow.status("enemy", foe).used)
assert(not flow.status("player", monB).armed)
print("PASS: arm, cancel, commit-to-move, independent sides, once-per-battle, faint/reversion")
