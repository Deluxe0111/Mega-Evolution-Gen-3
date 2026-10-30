-- Headless proof of a REAL temporary Mega form without native engine saves.
local Selection = dofile("src/mega_selection.lua")
local Venusaur = dofile("src/mega_venusaur.lua")
local flow = Selection.new()
local art = {
  hasSprite = function(slug, variant)
    return slug == "mega_venusaur" and (variant == "back" or variant == "front")
  end,
  picture = function(slug, side, shiny)
    return { image = "sprite:" .. slug .. ":" .. side .. ":" .. tostring(shiny), w = 64, h = 64 }
  end,
}
local eligibility = function(_, b)
  if b.item == 1500 and b.mon and b.mon.species == 3 then return "mega_venusaur" end
  return nil
end
local game = Venusaur.new(flow, eligibility, art)
local st = {}
local mon = {
  species = 3, level = 50, personality = 0, hp = 155, maxHp = 155,
  ivs = {atk=31,def=31,spa=31,spd=31,spe=31},
  evs = {atk=0,def=0,spa=0,spd=0,spe=0},
  moves = {"RAZOR_LEAF"}, pp = {10},
  attack = 102, defense = 103, spAtk = 120, spDef = 120, speed = 100,
}
local b = { mon=mon, species=3, side="player", item=1500,
            ability="OVERGROW", type1=12, type2=3 }
local oldStats = { attack=mon.attack, defense=mon.defense,
                   spAtk=mon.spAtk, spDef=mon.spDef, speed=mon.speed }
local function key(which)
  return { wasPressed = function(_, k) return k == which end }
end
assert(game.status(st, b) == "START: MEGA")
assert(not game.input(st, b, key("down")))
assert(game.input(st, b, key("start")))
assert(game.status(st, b) == "MEGA READY")
assert(game.input(st, b, key("start")))
assert(game.status(st, b) == "START: MEGA")
assert(game.input(st, b, key("start")))
local selected = game.command(st, b, {kind="move",slot=1,move="RAZOR_LEAF",battler=0})
assert(selected.megaEvolution and selected.megaEvolution.mon == mon)
assert(game.status(st, b) == nil)
-- Engine.planTurnActions copies action; this copy is not the selected table.
local planned = {}
for k, value in pairs(selected) do planned[k] = value end
assert(game.beforeMove(st, planned, b))
assert(b.ability == "THICK_FAT")
local expected = { attack=120, defense=143, spAtk=142, spDef=140, speed=100 }
for stat, val in pairs(expected) do
  assert(game.stat(b, stat, 1) == val, stat .. ": " .. tostring(game.stat(b, stat, 1)))
  assert(mon[stat] == oldStats[stat], "saved stat mutated: " .. stat)
end
assert(mon.species == 3 and mon.hp == 155 and mon.ability == nil)
assert(game.activeForm(mon) == "mega_venusaur")
assert(game.picture(b, true, false, nil).image == "sprite:mega_venusaur:back:false")
assert(game.picture(b, false, true, nil).image == "sprite:mega_venusaur:front:true")
-- A newly made live battler for the SAME party mon retains the temporary form.
local switchedIn = {mon=mon, species=3, side="player", item=1500, ability="OVERGROW"}
assert(game.stat(switchedIn, "defense", 1) == 143)
assert(switchedIn.ability == "THICK_FAT")
-- A second Venusaur remains ordinary and cannot Mega while the allowance is used.
local second = {species=3, level=50}
local secondB = {mon=second, species=3, side="player", item=1500, ability="OVERGROW"}
assert(game.stat(secondB, "defense", 99) == 99)
assert(not game.input(st, secondB, key("start")))
assert(mon.species == 3 and mon.attack == 102)
game.turnEnded()
assert(game.activeForm(mon) == "mega_venusaur")
game.fainted(mon)
assert(not game.activeForm(mon))
assert(b.ability == "OVERGROW" and switchedIn.ability == "OVERGROW")
assert(not game.input(st, secondB, key("start"))) -- no Mega refund on faint
game.finish()
assert(mon.species == 3 and mon.attack == 102)
assert(game.status(st, b) == "START: MEGA") -- brand-new battle resets allowance
-- Failed transformation never consumes allowance or mutates battler.
assert(game.input(st, b, key("start")))
local selection2 = game.command(st, b, {kind="move",slot=1,move="RAZOR_LEAF"})
local planned2 = {}
for k, value in pairs(selection2) do planned2[k] = value end
planned2.slot = 2 -- rejected by the planner identity guard
assert(not game.beforeMove(st, planned2, b))
assert(b.ability == "OVERGROW" and not game.activeForm(mon))
game.finish()
print("PASS: Mega Venusaur move toggle, copied action, exact stats, per-mon art, switching, fainting and save isolation")
