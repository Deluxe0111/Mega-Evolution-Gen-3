-- Batch 4: Defiant, Infiltrator, Prankster, Protean.
-- Native Lua boundary simulations; no engine installation or saved party edits.
local Tactical=dofile("src/mega_tactical_abilities.lua")
local Bridge=dofile("src/mega_standalone.lua")
local Reactive=dofile("src/mega_reactive_abilities.lua")
local MegaAbilities=dofile("src/mega_abilities.lua")
local views={}
local game={
  view=function(mon)return views[mon] end,
  stat=function()return nil end,
  finish=function()end,
  beforeResolved=function()return false end,
}
local attacker={mon={hp=100,maxHp=100},side="player",id=0,
  type1=0,type2=12,stages={attack=0,defense=0}}
local defender={mon={hp=100,maxHp=100},side="enemy",id=1,
  type1=7,type2=17,stages={attack=0,defense=0}}
local function set(b,ab)views[b.mon]=ab and {ability=ab} or nil end
local moves={
  GROWL={id="GROWL",type=0,power=0,flags=4},
  TAUNT={id="TAUNT",type=17,power=0,flags=4},
  WATER_PULSE={id="WATER_PULSE",type=11,power=60,flags=2},
  QUICK_ATTACK={id="QUICK_ATTACK",type=0,power=40,flags=1},
  PROTECT={id="PROTECT",type=0,power=0,flags=0},
  TACKLE={id="TACKLE",type=0,power=40,flags=1},
  STRUGGLE={id="STRUGGLE",type=0,power=50,flags=1},
}
local priority={PROTECT=4,QUICK_ATTACK=1}
local Moves={
  get=function(ref)
    local key=type(ref)=="table" and (ref.id or ref.numId) or ref
    assert(moves[key],"unknown move "..tostring(key))
    return moves[key]
  end,
  priority=function(ref)
    local key=type(ref)=="table" and ref.id or ref
    return priority[key] or 0
  end,
}
local calls={}
local Secondary={
  changeStat=function(ad,b,stat,delta,flags)
    calls[#calls+1]={b=b,stat=stat,delta=delta,flags=flags}
    if delta<0 and ((b.stages[stat] or 0)<=-6) then return "blocked" end
    if delta>0 and ((b.stages[stat] or 0)>=6) then return "blocked" end
    local n=(b.stages[stat] or 0)+delta
    b.stages[stat]=math.min(6,math.max(-6,n))
    return "worked"
  end,
}
-- Defiant fires after a real opponent-induced stat drop, not self-inflicted
-- drops or a failed/blocked stat change. Uses native +2 attack stage.
set(defender,"DEFIANT")
local original=Secondary.changeStat
local result=original(nil,defender,"defense",-1,{allowPtr=true})
assert(Tactical.afterStatChange(game,Secondary,nil,defender,"defense",-1,
  {allowPtr=true},result))
assert(defender.stages.attack==2 and defender.stages.defense==-1)
assert(not Tactical.afterStatChange(game,Secondary,nil,defender,"attack",-1,
  {user=true},"worked"))
assert(not Tactical.afterStatChange(game,Secondary,nil,defender,"attack",-1,
  {},"blocked"))
defender.stages.attack=6
assert(not Tactical.afterStatChange(game,Secondary,nil,defender,"defense",-1,
  {},"worked"))
defender.stages.attack=0
set(defender,nil)
assert(not Tactical.afterStatChange(game,Secondary,nil,defender,"defense",-1,
  {},"worked"))

-- Infiltrator bypasses Reflect/Light Screen without changing caller opts.
set(attacker,"INFILTRATOR")
local originalOpts={reflect=true,lightScreen=true,power=90}
local opts=Tactical.damageOptions(game,attacker,originalOpts)
assert(opts~=originalOpts and opts.reflect==false and opts.lightScreen==false)
assert(originalOpts.reflect and originalOpts.lightScreen)
set(attacker,nil)
assert(Tactical.damageOptions(game,attacker,originalOpts)==originalOpts)
set(attacker,"INFILTRATOR")
local side={expSafeguardTurns=4}
local adapter={ownSide=function(_,b)assert(b==defender);return side end}
defender.substituteHP=23
local M={user=attacker,target=defender,adapter=adapter,move=moves.GROWL,opts={}}
local checked=false
assert(Tactical.withInfiltrator(game,M,function(ctx)
  assert(ctx.target.substituteHP==nil and side.expSafeguardTurns==nil)
  checked=true
  return "bypass"
end)=="bypass")
assert(checked and defender.substituteHP==23 and side.expSafeguardTurns==4)
local ok,err=pcall(Tactical.withInfiltrator,game,M,function()
  error("synthetic action failure")
end)
assert(not ok and tostring(err):find("synthetic action failure",1,true))
assert(defender.substituteHP==23 and side.expSafeguardTurns==4,
  "Infiltrator action failure must restore defensive fields")
set(attacker,nil)
assert(Tactical.withInfiltrator(game,M,function(ctx)
  assert(ctx.target.substituteHP==23 and side.expSafeguardTurns==4)
  return "native"
end)=="native")
defender.substituteHP=nil

-- Priority: only status moves get +1 for an active Mega Prankster; native
-- ties and higher priority attacks retain vanilla/speed ordering.
set(attacker,"PRANKSTER")
assert(Tactical.turnOrder(game,Moves,attacker,moves.GROWL,
  defender,moves.TACKLE,false)==true)
assert(Tactical.turnOrder(game,Moves,attacker,moves.GROWL,
  defender,moves.QUICK_ATTACK,false)==false,
  "equal modified priority retains native result")
assert(Tactical.turnOrder(game,Moves,attacker,moves.TACKLE,
  defender,moves.GROWL,false)==false)
assert(Tactical.turnOrder(game,Moves,attacker,moves.GROWL,
  defender,moves.PROTECT,false)==false)
set(attacker,nil)
assert(Tactical.turnOrder(game,Moves,attacker,moves.GROWL,
  defender,moves.TACKLE,false)==false)
set(defender,"PRANKSTER")
assert(Tactical.turnOrder(game,Moves,attacker,moves.TACKLE,
  defender,moves.GROWL,true)==false)
set(defender,nil)

-- Protean: change battle battler types, never original mon records; every
-- chosen move can retype (pre-Gen IX behaviour). Struggle is exempt.
set(attacker,"PROTEAN")
local party={type1=0,type2=12}
assert(Tactical.beforeMove(game,Moves,attacker,"WATER_PULSE"))
assert(attacker.type1==11 and attacker.type2==nil and party.type1==0)
assert(not Tactical.beforeMove(game,Moves,attacker,"WATER_PULSE"))
assert(Tactical.beforeMove(game,Moves,attacker,"GROWL"))
assert(attacker.type1==0 and attacker.type2==nil)
assert(not Tactical.beforeMove(game,Moves,attacker,"STRUGGLE"))
set(attacker,nil)
assert(not Tactical.beforeMove(game,Moves,attacker,"WATER_PULSE"))

-- Integrated native bridge: hooks should affect only active Mega views,
-- survive normal errors, and cleanly uninstall.
local st={battlers={[0]=attacker,[1]=defender}}
local Ui={_st=st,handleInput=function()return false end,
  takeCommand=function()return nil end,sidePic=function()return {} end}
local Battle={_st=st,start=function()end,reset=function()end}
local Engine={
  resolveMove=function(user,_,move)
    return {typeDuringMove=user.type1,move=move}
  end,
  forEachTarget=function(ctx,body)return body(ctx)end,
  hasFlag=function()return false end,
}
local Damage={
  base=function()return 20 end,
  calc=function(a,b,move,opts)
    return opts and (opts.reflect or opts.lightScreen) and 10 or 20,
      {effectiveness=1,stab=1}
  end,
}
local hooks={}
local mod={enabled=true,hooks={wrap=function(_,name,fn)
  hooks[name]=fn
  return function()hooks[name]=nil end
end}}
local bridge=assert(Bridge.install(mod,game,{
  Ui=Ui,Battle=Battle,Engine=Engine,Damage=Damage,
  Secondary=Secondary,Moves=Moves,
  MegaTactical=Tactical,MegaReactive=Reactive,
  MegaAbilities=MegaAbilities,
}))
local originalFinal={change=original}
set(defender,"DEFIANT")
defender.stages.attack=0
Secondary.changeStat(nil,defender,"defense",-1,{})
assert(defender.stages.attack==2)
Secondary.changeStat(nil,defender,"defense",-1,{user=true})
assert(defender.stages.attack==2)
set(defender,nil)
set(attacker,"INFILTRATOR")
assert(Damage.calc(attacker,defender,moves.TACKLE,originalOpts)==20)
assert(originalOpts.reflect and originalOpts.lightScreen)
defender.substituteHP=18;side.expSafeguardTurns=5
local result=Engine.forEachTarget({
  user=attacker,target=defender,adapter=adapter,
  move=moves.GROWL,opts={}
},function(ctx)
  assert(ctx.target.substituteHP==nil and side.expSafeguardTurns==nil)
  return "infiltrated"
end)
assert(result=="infiltrated" and defender.substituteHP==18
  and side.expSafeguardTurns==5)
set(attacker,nil)
set(attacker,"PROTEAN")
attacker.type1,attacker.type2=12,3
local action=Engine.resolveMove(attacker,defender,"WATER_PULSE",1,nil,st)
assert(action.typeDuringMove==11 and attacker.type1==11 and attacker.type2==nil)
set(attacker,nil)
set(attacker,"PRANKSTER")
assert(hooks["battle.turn_order"],"turn order hook must be active")
local ordered=hooks["battle.turn_order"](function()return false end,
  {id=0},moves.GROWL,{id=1},moves.TACKLE,{battle=st})
assert(ordered==true)
local tied=hooks["battle.turn_order"](function()return false end,
  {id=0},moves.GROWL,{id=1},moves.QUICK_ATTACK,{battle=st})
assert(tied==false)
mod.enabled=false
assert(hooks["battle.turn_order"](function()return false end,
  {id=0},moves.GROWL,{id=1},moves.TACKLE,{battle=st})==false)
mod.enabled=true
bridge.uninstall()
assert(Secondary.changeStat==originalFinal.change)
assert(hooks["battle.turn_order"]==nil and hooks["battle.accuracy"]==nil)
assert(Engine.resolveMove~=nil)
print("PASS: Mega Defiant, Infiltrator, Prankster, Protean, native hooks and cleanup")
