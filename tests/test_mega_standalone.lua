-- No Gen1Recomp installation needed: Lua-only stock battle wrappers.
local Selection = dofile("src/mega_selection.lua")
local Venusaur = dofile("src/mega_venusaur.lua")
local Bridge = dofile("src/mega_standalone.lua")
local stone
for _, row in ipairs(dofile("data/mega_items.lua")) do
  if row.id == "VENUSAURITE" then stone = row.index end
end
assert(stone)

local mon = {
  species=3, level=50, hp=155, maxHp=155, personality=0,
  ivs={atk=31,def=31,spa=31,spd=31,spe=31},
  evs={atk=0,def=0,spa=0,spd=0,spe=0},
  attack=102, defense=103, spAtk=120, spDef=120, speed=100,
}
local otherMon = { species=3, hp=155, defense=103 }
local player = { mon=mon, species=3, side="player", item=stone,
                 ability="OVERGROW", type1=12, type2=3 }
local foe = { mon=otherMon, species=3, side="enemy", ability="OVERGROW" }
local st = { player=player, enemy=foe }
local art = {
  hasSprite=function(s) return s == "mega_venusaur" end,
  picture=function(_, side, shiny)
    return {image="mega_" .. side .. tostring(shiny)}
  end,
}
local eligible=function(_, b)
  return b.item == stone and b.mon and b.mon.species == 3 and "mega_venusaur" or nil
end
local game=Venusaur.new(Selection.new(), eligible, art)
local calls={}
local Ui={
  _st=st, _active=0, _mode="moves",
  waitingForCommand=function() return true end,
  handleInput=function() calls.vanillaInput=(calls.vanillaInput or 0)+1; return false end,
  takeCommand=function() return nil end,
  sidePic=function() calls.vanillaPicture=(calls.vanillaPicture or 0)+1; return {image="g9-base"} end,
}
Ui.takeCommand=function() local cmd=Ui.command; Ui.command=nil; return cmd end
local Damage={
  base=function(a,d,m,opts)
    calls.seenAttack=a.mon.attack
    calls.seenDefense=d.mon.defense
    calls.seenAbility=d.ability
    return a.mon.attack + d.mon.defense
  end,
}
local Engine={
  resolveMove=function(user, target, move, slot, adapter, state)
    calls.moves=(calls.moves or 0)+1
    return Damage.base(user,target,{power=90,type=12},{})
  end,
}
local Battle={
  _active=true, _st=st,
  start=function() calls.starts=(calls.starts or 0)+1; return true end,
  reset=function() calls.resets=(calls.resets or 0)+1; return true end,
}
local original={uiInput=Ui.handleInput, uiCommand=Ui.takeCommand, uiPic=Ui.sidePic,
                resolver=Engine.resolveMove, base=Damage.base,
                start=Battle.start, reset=Battle.reset}
local mod={enabled=true}
local bridge, err=Bridge.install(mod,game,{Ui=Ui,Damage=Damage,Engine=Engine,Battle=Battle})
assert(bridge, tostring(err))
local key=function(name)
  return {wasPressed=function(_, value) return value==name end}
end
assert(Ui.handleInput(key("start")))
assert(game.status(st,player)=="MEGA READY")
Ui.command={kind="move",move="RAZOR_LEAF",slot=1,battler=0}
local chosen=Ui.takeCommand()
assert(chosen.megaEvolution and chosen.megaEvolution.mon==mon)
assert(mon.attack==102 and mon.defense==103)
-- This call is the stock Engine.resolveMove(user, target, move, slot, ...);
-- there is no custom hook or Mega field in its argument list.
assert(Engine.resolveMove(player,foe,"RAZOR_LEAF",1,nil,st)==223)
assert(calls.seenAttack==120 and calls.seenDefense==103)
assert(player.ability=="THICK_FAT")
assert(mon.attack==102 and mon.defense==103)
assert(game.activeForm(mon)=="mega_venusaur")
assert(Ui.sidePic(true,false,3,0,false,0,mon).image=="mega_backfalse")
assert(Ui.sidePic(false,false,3,0,true,0,mon).image=="mega_fronttrue")
assert(Ui.sidePic(true,false,3,0,false,0,otherMon).image=="g9-base")
-- The same battler is a target, so Mega Defense is used without touching
-- permanent party stats.
Engine.resolveMove(foe,player,"RAZOR_LEAF",1,nil,st)
assert(calls.seenDefense==143)
assert(mon.defense==103)
-- Already used: the next eligible Pokémon cannot toggle.
local another={mon={species=3},species=3,side="player",item=stone}
Ui._st.player=another
assert(not Ui.handleInput(key("start")))
Ui._st.player=player
assert(Ui.handleInput(key("b"))==false)
assert(game.activeForm(mon)=="mega_venusaur")
Battle.reset()
assert(game.activeForm(mon)==nil and player.ability=="OVERGROW")
-- A new battle returns the key usage, and a changed move does not Mega.
Battle.start()
assert(Ui.handleInput(key("start")))
Ui.command={kind="move",move="RAZOR_LEAF",slot=1,battler=0}
Ui.takeCommand()
Engine.resolveMove(player,foe,"SLUDGE_BOMB",2,nil,st)
assert(player.ability=="OVERGROW" and not game.activeForm(mon))
-- Disabling a mod leaves wrappers behaving exactly like their predecessors.
mod.enabled=false
assert(Ui.sidePic(true,false,3,0,false,0,mon).image=="g9-base")
-- An unrelated later wrapper is not accidentally replaced on uninstall.
local wrappedSidePic=Ui.sidePic
Ui.sidePic=function(...) return wrappedSidePic(...) end
bridge.uninstall()
assert(Ui.sidePic~=original.uiPic)
assert(Ui.handleInput==original.uiInput)
assert(Ui.takeCommand==original.uiCommand)
assert(Engine.resolveMove==original.resolver)
assert(Damage.base==original.base)
assert(Battle.start==original.start and Battle.reset==original.reset)
print("PASS: standalone battle integration, G9 delegation, battle-only stats, copied commands, reset and uninstall")
