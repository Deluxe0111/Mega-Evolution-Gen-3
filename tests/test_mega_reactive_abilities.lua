-- Reactive Mega abilities: action-level integration, no ROM or save edits.
local Reactive=dofile("src/mega_reactive_abilities.lua")
local Bridge=dofile("src/mega_standalone.lua")
local active={}
local game={
  view=function(mon)return active[mon] end,
  stat=function()return nil end,
  finish=function()end,
}
local attacker={mon={hp=100,maxHp=100},id=1,side="enemy"}
local target={mon={hp=120,maxHp=120},id=0,side="player",stages={spAtk=0}}
local function makeMega(b,ability)active[b.mon]={ability=ability} end
local function clearMega(b)active[b.mon]=nil end

-- Magic Bounce only applies to native Magic Coat reflectable status moves,
-- and cannot recursively reflect the same bounced move.
makeMega(target,"MAGIC_BOUNCE")
local flag=function(move,bit)
  return math.floor((move.flags or 0)/bit)%2==1
end
local move={id="TOXIC",power=0,flags=4}
local M={user=attacker,target=target,move=move,opts={},anim={}}
local calls=0
local function nativeBounce(ctx)
  calls=calls+1
  if ctx.target.expMagicCoat and flag(ctx.move,4)
      and not ctx.opts.bounced then
    ctx.target.expMagicCoat=nil
    ctx.user,ctx.target=ctx.target,ctx.user
    ctx.opts.bounced=true
    return "reflected"
  end
  return "normal"
end
assert(Reactive.withMagicBounce(game,M,nativeBounce,flag)=="reflected")
assert(M.user==target and M.target==attacker and M.opts.bounced==true)
assert(target.expMagicCoat==nil and calls==1,
  "native guard must not remain armed after action")
assert(Reactive.withMagicBounce(game,M,nativeBounce,flag)=="normal")
assert(calls==2 and target.expMagicCoat==nil)
M={user=attacker,target=target,move={id="SURF",power=90,flags=4},opts={}}
assert(Reactive.withMagicBounce(game,M,nativeBounce,flag)=="normal")
M={user=attacker,target=target,move={id="SWORDS_DANCE",power=0,flags=0},opts={}}
assert(Reactive.withMagicBounce(game,M,nativeBounce,flag)=="normal")
target.expMagicCoat=false
M={user=attacker,target=target,move=move,opts={}}
local ok,err=pcall(function()
  return Reactive.withMagicBounce(game,M,function()error("synthetic failure")end,flag)
end)
assert(not ok and tostring(err):find("synthetic failure",1,true))
assert(target.expMagicCoat==false,"exceptions must restore the original Magic Coat state")
target.expMagicCoat=nil
clearMega(target)
assert(Reactive.withMagicBounce(game,M,nativeBounce,flag)=="normal",
  "normal Pokémon must retain stock reflection behaviour")

-- Bulletproof uses the exact ball/bomb move set. No false positives on
-- cannons; a blocked attack consumes normal PP and applies no damage.
makeMega(target,"BULLETPROOF")
local function mockMove(name)
  local ctx={user=attacker,target=target,move={id=name,power=80},opts={},
    anim={},events={}}
  function ctx:attackString()self.events[#self.events+1]="name"end
  function ctx:ppReduce()self.events[#self.events+1]="pp"end
  function ctx:sayId(msg) self.events[#self.events+1]=msg end
  return ctx
end
for _,name in ipairs({"SHADOW_BALL","SLUDGE_BOMB","AURA_SPHERE",
  "BULLET_SEED","ROCK_BLAST","ZAP_CANNON","ACID_SPRAY","WEATHER_BALL"}) do
  local ctx=mockMove(name)
  assert(Reactive.blockBulletproof(game,ctx),name)
  assert(ctx.noEffect and ctx.anim.missed and ctx.anim.statusOnly
    and #ctx.events==3 and ctx.events[2]=="pp",name)
end
for _,name in ipairs({"FLAMETHROWER","HYDRO_CANNON","FLASH_CANNON",
  "FLAME_BURST","POWER_GEM"}) do
  assert(not Reactive.blockBulletproof(game,mockMove(name)),name)
end
local savedMove=mockMove("SHADOW_BALL").move
assert(savedMove.id=="SHADOW_BALL","ROM move rows must stay unchanged")
clearMega(target)
assert(not Reactive.blockBulletproof(game,mockMove("SHADOW_BALL")))

-- Regenerator heals at switch, not while fainted or at maximum HP.
makeMega(target,"REGENERATOR")
local st={battlers={[0]=target,[1]=attacker}}
local healed=0
local adapter={
  hp=function(_,b)return b.mon.hp end,
  maxHp=function(_,b)return b.mon.maxHp end,
  heal=function(_,b,amount)
    healed=healed+1
    local before=b.mon.hp
    b.mon.hp=math.min(b.mon.maxHp,b.mon.hp+amount)
    return b.mon.hp-before
  end,
}
target.mon.hp=50
assert(Reactive.onSwitchOut(game,adapter,target) and target.mon.hp==90)
assert(healed==1)
target.mon.hp=120
assert(not Reactive.onSwitchOut(game,adapter,target))
target.mon.hp=0;target.fainted=true
assert(not Reactive.onSwitchOut(game,adapter,target))
target.fainted=nil;target.mon.hp=30
clearMega(target)
assert(not Reactive.onSwitchOut(game,adapter,target) and target.mon.hp==30)

-- Berserk triggers only for actual direct damage crossing the half-HP
-- threshold, even if the move deals multiple hits. No activation on faint,
-- substitute, already-under-half hits, or when already at +6 Sp. Atk.
makeMega(target,"BERSERK")
target.mon.hp=120;target.stages.spAtk=0
local increases=0
local Secondary={
  changeStat=function(_,b,stat,delta,flags)
    assert(stat=="spAtk" and delta==1 and flags.user==true)
    increases=increases+1
    b.stages.spAtk=math.min(6,b.stages.spAtk+delta)
    return "worked"
  end,
}
local ctx={user=attacker,target=target,adapter=adapter}
assert(Reactive.onDamaged(game,ctx,65,58,Secondary))
assert(target.stages.spAtk==1 and increases==1)
assert(not Reactive.onDamaged(game,ctx,58,45,Secondary))
assert(not Reactive.onDamaged(game,ctx,65,0,Secondary))
assert(not Reactive.onDamaged(game,ctx,65,65,Secondary))
target.stages.spAtk=6
assert(not Reactive.onDamaged(game,ctx,65,58,Secondary))
clearMega(target)
target.stages.spAtk=0
assert(not Reactive.onDamaged(game,ctx,65,58,Secondary))

-- Whole bridge: native Engine.forEachTarget, Hit.run, Hit.dealDamage,
-- and switchOutEffects; ensure disabled and uninstall restore stock paths.
local Engine={
  resolveMove=function()return "move"end,
  hasFlag=flag,
  forEachTarget=function(M,body)return body(M)end,
  switchOutEffects=function()return false end,
}
local Ui={
  _st=st,handleInput=function()return false end,
  takeCommand=function()return nil end,
  sidePic=function()return {} end,
}
local Battle={_st=st,start=function()end,reset=function()end}
local Damage={base=function()return 1 end}
local Hit={
  run=function(M)M.nativeRun=true;return "original hit" end,
  dealDamage=function(M,amt)
    local before=M.target.mon.hp
    M.target.mon.hp=math.max(0,before-amt)
    return before-M.target.mon.hp
  end,
}
local originals={forEachTarget=Engine.forEachTarget,
  switchOutEffects=Engine.switchOutEffects,
  hitRun=Hit.run,hitDamage=Hit.dealDamage}
local mod={enabled=true}
local bridge=assert(Bridge.install(mod,game,{
  Engine=Engine,Ui=Ui,Battle=Battle,Damage=Damage,Hit=Hit,
  Secondary=Secondary,MegaReactive=Reactive,
}))
makeMega(target,"MAGIC_BOUNCE")
local bounced={user=attacker,target=target,move=move,opts={}}
assert(Engine.forEachTarget(bounced,nativeBounce)=="reflected")
assert(target.expMagicCoat==nil)
makeMega(target,"BULLETPROOF")
local shot=mockMove("SHADOW_BALL")
assert(Hit.run(shot)==nil and shot.noEffect and not shot.nativeRun)
local normal=mockMove("FLAMETHROWER")
assert(Hit.run(normal)=="original hit" and normal.nativeRun)
makeMega(target,"REGENERATOR")
target.mon.hp=30
assert(Engine.switchOutEffects(st,adapter,target)==true and target.mon.hp==70)
makeMega(target,"BERSERK")
target.mon.hp=65;target.stages.spAtk=0
assert(Hit.dealDamage(ctx,7)==7 and target.mon.hp==58 and target.stages.spAtk==1)
assert(Hit.dealDamage(ctx,3)==3 and target.stages.spAtk==1)
-- Remaining wrappers must preserve native behaviour when disabled.
mod.enabled=false
makeMega(target,"BULLETPROOF")
local disabled=mockMove("SHADOW_BALL")
assert(Hit.run(disabled)=="original hit" and disabled.nativeRun)
mod.enabled=true
bridge.uninstall()
assert(Engine.forEachTarget==originals.forEachTarget)
assert(Engine.switchOutEffects==originals.switchOutEffects)
assert(Hit.run==originals.hitRun and Hit.dealDamage==originals.hitDamage)
print("PASS: Mega Magic Bounce, Bulletproof, Regenerator, Berserk and native hook isolation")
