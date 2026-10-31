-- Four battle interaction regressions, including integrated native hooks.
local Edge=dofile("src/mega_ability_edge_cases.lua")
local Bridge=dofile("src/mega_standalone.lua")
local Precision=dofile("src/mega_precision_abilities.lua")
local MegaAbilities=dofile("src/mega_abilities.lua")
local active={}
local game={view=function(mon)return active[mon] end,
  stat=function()return nil end,finish=function()end,
  beforeResolved=function()return false end}
local hero={id=0,side="player",type1=0,type2=0,
  mon={hp=100,maxHp=100},stages={}}
local foe={id=1,side="enemy",type1=17,type2=17,
  mon={hp=100,maxHp=100},stages={}}
local function set(b,ab)active[b.mon]=ab and {ability=ab} or nil end
local Types={ID={NORMAL=0,DARK=17}}
local dangerous={id="TOXIC",type=3,power=0,flags=4}
local blast={id="RETURN",type=0,power=80,target=0,flags=3,
  effect=0}
local secondaryMove={id="BITE",type=17,power=60,target=0,flags=3,
  effect=31,secondaryChance=30}
local Effects={SECONDARY={
  [31]={eff="FLINCH",certain=false,user=false},
}}
-- No Guard must reach semi-invulnerable targets during the ONE resolved
-- action and restore their Fly/Dig/Dive state, also after exceptions.
for _,semi in ipairs({"ON_AIR","UNDERGROUND","UNDERWATER"}) do
  foe.semiInvulnerable=semi
  set(hero,"NO_GUARD")
  assert(Edge.withNoGuard(game,{user=hero,target=foe},function()
    assert(foe.semiInvulnerable==nil)
    return semi
  end)==semi)
  assert(foe.semiInvulnerable==semi)
  local ok,err=pcall(Edge.withNoGuard,game,
    {user=hero,target=foe},function()error("synthetic accuracy failure")end)
  assert(not ok and tostring(err):find("synthetic accuracy failure",1,true))
  assert(foe.semiInvulnerable==semi)
  set(hero,nil)
  set(foe,"NO_GUARD")
  assert(Edge.withNoGuard(game,{user=hero,target=foe},
    function()return foe.semiInvulnerable end)==nil)
  assert(foe.semiInvulnerable==semi)
  set(foe,nil)
  assert(Edge.withNoGuard(game,{user=hero,target=foe},
    function()return foe.semiInvulnerable end)==semi)
end
foe.semiInvulnerable=nil

-- Prankster: a Dark-type enemy blocks ONLY status moves from a Mega
-- Prankster, with one PP cost and no effect. Allied Dark unaffected.
set(hero,"PRANKSTER")
local M={user=hero,target=foe,move=dangerous,anim={},events={}}
function M:attackString()self.events[#self.events+1]="attack"end
function M:ppReduce()self.events[#self.events+1]="pp"end
function M:sayId(s)self.events[#self.events+1]=s end
assert(Edge.pranksterBlocks(game,M,Types))
assert(Edge.blockPrankster(game,M,Types))
assert(M.noEffect and M.anim.missed and M.anim.statusOnly
  and #M.events==3 and M.events[2]=="pp")
M.move=blast
assert(not Edge.pranksterBlocks(game,M,Types))
M.move=dangerous
foe.type1,foe.type2=1,1
assert(not Edge.pranksterBlocks(game,M,Types))
foe.type1,foe.type2=17,17
local ally={side="player",type1=17,type2=17,mon={hp=100}}
M.target=ally
assert(not Edge.pranksterBlocks(game,M,Types))
M.target=foe;set(hero,nil)
assert(not Edge.pranksterBlocks(game,M,Types))

-- Per-hit secondary events: two distinct procs for two damaging hits;
-- native end-of-move extra roll suppressed. Status KO and substitute cases.
set(hero,"PARENTAL_BOND")
local calls=0
local Secondary={
  withChance=function(M,eff)
    assert(eff=="FLINCH")
    calls=calls+1
    return true
  end,
}
local bond={user=hero,target=foe,adapter={
  isFainted=function(_,b)return b.mon.hp<=0 end
},move=secondaryMove,effect=31,_megaParentalBond=true}
assert(Edge.parentalHitSecondary(game,bond,60,Secondary,Effects))
assert(Edge.parentalHitSecondary(game,bond,15,Secondary,Effects))
assert(calls==2 and bond._megaParentalSecondaryApplied)
assert(Edge.skipPostParentalSecondary(game,bond,"FLINCH",Effects))
assert(not Edge.skipPostParentalSecondary(game,bond,"BURN",Effects))
bond.hitSubstitute=true
assert(not Edge.parentalHitSecondary(game,bond,15,Secondary,Effects))
assert(calls==2)
bond.hitSubstitute=nil
foe.mon.hp=0
assert(not Edge.parentalHitSecondary(game,bond,15,Secondary,Effects))
foe.mon.hp=100
bond._megaParentalDuringHit=true
assert(not Edge.skipPostParentalSecondary(game,bond,"FLINCH",Effects))
bond._megaParentalDuringHit=nil
set(hero,nil)
assert(not Edge.parentalHitSecondary(game,bond,15,Secondary,Effects))

-- Electric Terrain blocks initial Yawn and suppresses delayed Yawn
-- only if still active after the end-turn weather countdown.
local Weather={
  grounded=function(b)return b.type1~=2 and b.type2~=2 and b.mon.hp>0 end,
  terrainBlocksSleep=function(st,b)
    return (st.megaElectricTerrainTurns or 0)>0
      and b.type1~=2 and b.type2~=2 end,
}
local st={megaElectricTerrainTurns=3,battlers={[0]=hero,[1]=foe}}
local messages={}
local ad={_st=st,activeBattlers=function()return {hero,foe}end,
  sayText=function(_,msg)messages[#messages+1]=msg end}
local yawnCtx={user=hero,target=foe,adapter=ad}
assert(Edge.blockTerrainYawn(Weather,yawnCtx))
assert(#messages==1)
foe.expYawnTurns=1;foe.yawnTurns=1
local slept=false
local function residual()
  st.megaElectricTerrainTurns=st.megaElectricTerrainTurns-1
  if foe.expYawnTurns==1 then slept=true end
  return "finished"
end
assert(Edge.suppressDueYawn(Weather,ad,residual)=="finished")
assert(not slept and foe.expYawnTurns==nil)
-- One remaining terrain turn expires first; Yawn should still work.
st.megaElectricTerrainTurns=1;foe.expYawnTurns=1;foe.yawnTurns=1
assert(Edge.suppressDueYawn(Weather,ad,residual)=="finished")
assert(slept and foe.expYawnTurns==1)
foe.expYawnTurns=nil;foe.yawnTurns=nil
st.megaElectricTerrainTurns=3
foe.type1=2
assert(not Edge.blockTerrainYawn(Weather,yawnCtx))
foe.type1=17
foe.expYawnTurns=1;foe.yawnTurns=1
local ok,err=pcall(Edge.suppressDueYawn,Weather,ad,function()
  error("synthetic turn failure")
end)
assert(not ok and tostring(err):find("synthetic turn failure",1,true))
assert(foe.expYawnTurns==1 and foe.yawnTurns==1)
foe.expYawnTurns=nil;foe.yawnTurns=nil

-- Integrated native entrypoints, including Parental Bond and suppression.
local Damage={
  base=function()return 80 end,
  calc=function()return 80,{moveType=0,effectiveness=1,stab=1}end,
}
local nativeRolls=0
Secondary.withChance=function(M,eff)
  nativeRolls=nativeRolls+1
  return true
end
local hitCount=0
local Hit={}
Hit.dealDamage=function(M,amount)
    local before=M.target.mon.hp
    M.target.mon.hp=math.max(0,before-amount)
    return before-M.target.mon.hp
  end
Hit.run=function(M)
    local count=tonumber(M.move.hits) or 1
    for i=1,count do
      local amount=Damage.calc(M.user,M.target,M.move,{})
      Hit.dealDamage(M,amount)
      hitCount=hitCount+1
    end
    Secondary.withChance(M,"FLINCH",false,false)
    return count
  end
local Engine={
  resolveMove=function()return "normal"end,
  hasFlag=function()return false end,
  forEachTarget=function(M,fn)return fn(M)end,
}
local Status={
  yawn=function(ctx)ctx.target.expYawnTurns=2;return "yawn"end,
  cantMakeAsleep=function()return false end,
}
local Residuals={
  collectEvents=function(adapter)
    local b=foe
    if b.expYawnTurns==1 then
      b.status="SLP"
      b.expYawnTurns=nil
    end
    return "residual"
  end,
}
local Battle={_st=st,start=function()end,reset=function()end}
local Ui={_st=st,handleInput=function()return false end,
  takeCommand=function()return nil end,sidePic=function()end}
local hooks={}
local mod={enabled=true,hooks={wrap=function(_,name,fn)
  hooks[name]=fn
  return function()hooks[name]=nil end
end}}
local originals={target=Engine.forEachTarget,hit=Hit.dealDamage,
  chance=Secondary.withChance,run=Hit.run,collect=Residuals.collectEvents,
  yawn=Status.yawn}
local bridge=assert(Bridge.install(mod,game,{
  Engine=Engine,Ui=Ui,Battle=Battle,Damage=Damage,Hit=Hit,
  Secondary=Secondary,Status=Status,Residuals=Residuals,
  MegaAbilities=MegaAbilities,MegaPrecision=Precision,MegaEdge=Edge,
  MegaWeather=Weather,EffectIds=Effects,Types=Types,
}))
set(hero,"NO_GUARD")
foe.semiInvulnerable="ON_AIR"
assert(Engine.forEachTarget({user=hero,target=foe,move=blast},
  function()return foe.semiInvulnerable end)==nil)
assert(foe.semiInvulnerable=="ON_AIR")
foe.semiInvulnerable=nil
set(hero,"PRANKSTER")
local blocked={user=hero,target=foe,move=dangerous,anim={},
  attackString=function()end,ppReduce=function()end,sayId=function()end}
assert(Engine.forEachTarget(blocked,function()
  error("Dark-type status effect should not execute")
end)==nil and blocked.noEffect)
set(hero,"PARENTAL_BOND")
foe.mon.hp=240
local attack={user=hero,target=foe,move=secondaryMove,effect=31,
  adapter={hp=function(_,b)return b.mon.hp end,
    isFainted=function(_,b)return b.mon.hp<=0 end},
  anim={},hitsLanded=0}
nativeRolls=0
assert(Hit.run(attack)==2)
assert(nativeRolls==2,"two hits must independently roll the secondary effect")
assert(secondaryMove.hits==nil)
set(hero,nil)
foe.mon.hp=240;nativeRolls=0
local normal={user=hero,target=foe,move=secondaryMove,effect=31,
  adapter=attack.adapter,anim={}}
assert(Hit.run(normal)==1 and nativeRolls==1)

st.megaElectricTerrainTurns=3
assert(Status.yawn(yawnCtx)==nil and foe.expYawnTurns==nil)
foe.expYawnTurns=1;foe.yawnTurns=1
assert(Residuals.collectEvents(ad)=="residual")
assert(foe.status==nil and foe.expYawnTurns==nil)
mod.enabled=false
assert(Status.yawn(yawnCtx)=="yawn")
mod.enabled=true
bridge.uninstall()
assert(Engine.forEachTarget==originals.target
  and Hit.dealDamage==originals.hit and Hit.run==originals.run
  and Secondary.withChance==originals.chance
  and Status.yawn==originals.yawn and Residuals.collectEvents==originals.collect)
print("PASS: No Guard airborne, Prankster Dark, Parental Bond secondary per hit and Electric Terrain Yawn")
