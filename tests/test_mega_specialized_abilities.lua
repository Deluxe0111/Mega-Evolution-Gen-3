local S=dofile("src/mega_specialized_abilities.lua")
local A=dofile("src/mega_abilities.lua")
local Reactive=dofile("src/mega_reactive_abilities.lua")
local Bridge=dofile("src/mega_standalone.lua")
local active={}
local game={view=function(mon)return active[mon] end,
  stat=function()return nil end,finish=function()end,
  beforeResolved=function()return false end}
local hero={mon={hp=100,maxHp=100,attack=90,spAtk=90},
  side="player",id=0,stages={attack=0,defense=0}}
local foe={mon={hp=100,maxHp=100,attack=80,spAtk=80},
  side="enemy",id=1,stages={attack=0,defense=0}}
local byAbility=function(b,name)active[b.mon]=name and {ability=name} or nil end
local E={MULTI_HIT=29,SECRET_POWER=197,SECONDARY={
  [31]={eff="FLINCH"},[2]={eff="POISON"},
  [36]={eff="TRI_ATTACK"},[48]={eff="RECOIL_25",user=true,certain=true},
  [138]={eff="DEF_PLUS_1",user=true},[76]={eff="CONFUSION"},
  [68]={eff="ATK_MINUS_1"},
}}
local flinch={id="BITE",power=60,effect=31,secondaryChance=30}
local poison={id="POISON_STING",power=15,effect=2,secondaryChance=30}
local recoil={id="TAKE_DOWN",power=90,effect=48,secondaryChance=0}
local selfBoost={id="STEEL_WING",power=70,effect=138,secondaryChance=10}
local plain={id="TACKLE",power=35,effect=0}
local status={id="GROWL",power=0,effect=31}
byAbility(hero,"SHEER_FORCE")
for _,move in ipairs({flinch,poison,
  {id="TRI_ATTACK",power=80,effect=36},
  {id="SECRET_POWER",power=70,effect=197}}) do
  assert(S.sheerForceQualifies(game,hero,move,E),move.id)
end
for _,move in ipairs({recoil,selfBoost,plain,status}) do
  assert(not S.sheerForceQualifies(game,hero,move,E),move.id)
end
local opts={power=60}
local changed=S.baseOptions(game,hero,flinch,opts,E)
assert(changed~=opts and changed.power==78 and opts.power==60
  and flinch.power==60,"Sheer Force must not mutate ROM move or opts")
assert(S.baseOptions(game,hero,recoil,opts,E)==opts)
assert(S.suppressSecondary(game,{user=hero,move=flinch},E))
assert(not S.suppressSecondary(game,{user=hero,move=recoil},E))
byAbility(hero,nil)
assert(S.baseOptions(game,hero,flinch,opts,E)==opts)

-- Defender-only temporary ability suppression must not interfere with
-- attacker or third party ability lookups or leak if the move raises.
byAbility(hero,"MOLD_BREAKER")
byAbility(foe,"FILTER")
foe.ability="LEVITATE"
local third={mon={hp=100},ability="WONDER_GUARD"}
local adapter={
  abilityOf=function(_,b)
    return b.ability
  end,
  roll=function(_,lo,hi)return lo end,
}
local oldLookup=adapter.abilityOf
local ctx={user=hero,target=foe,adapter=adapter}
assert(S.withMoldBreaker(game,ctx,function(M)
  assert(adapter:abilityOf(foe)==nil)
  assert(adapter:abilityOf(third)=="WONDER_GUARD")
  assert(foe._megaIgnoreDefensiveAbility)
  assert(A.activeAbility(game,foe)==nil)
  return "bypassed"
end)=="bypassed")
assert(adapter.abilityOf==oldLookup and foe._megaIgnoreDefensiveAbility==nil)
assert(A.activeAbility(game,foe)=="FILTER")
local worked,err=pcall(S.withMoldBreaker,game,ctx,function()
  error("synthetic hit failure")
end)
assert(not worked and tostring(err):find("synthetic hit failure",1,true))
assert(adapter.abilityOf==oldLookup and foe._megaIgnoreDefensiveAbility==nil)
foe.ability="ROUGH_SKIN"
assert(S.withMoldBreaker(game,ctx,function()
  return adapter:abilityOf(foe)
end)=="ROUGH_SKIN","Mold Breaker must not suppress contact reactions")
byAbility(hero,nil)
foe.ability="LEVITATE"
assert(S.withMoldBreaker(game,ctx,function()
  return adapter:abilityOf(foe)
end)=="LEVITATE","normal Pokémon leave defender abilities alone")
byAbility(foe,"BULLETPROOF")
byAbility(hero,"MOLD_BREAKER")
local bm={user=hero,target=foe,adapter=adapter,move={id="SHADOW_BALL",power=80}}
function bm:attackString()end
function bm:ppReduce()end
function bm:sayId()end
bm.anim={}
assert(S.withMoldBreaker(game,bm,function(M)
  assert(not Reactive.bulletproofBlocks(game,M))
end)==nil)
assert(Reactive.bulletproofBlocks(game,bm))
byAbility(foe,nil)

-- Contrary flips up and down while preserving native ±6 caps. Non-Mega
-- battlers and blocked move effects remain unchanged.
byAbility(hero,"CONTRARY")
assert(S.contraryDelta(game,hero,-2)==2)
assert(S.contraryDelta(game,hero,1)==-1)
assert(S.contraryDelta(game,hero,0)==0)
byAbility(hero,nil)
assert(S.contraryDelta(game,hero,-1)==-1)

-- Skill Link requests max hits without editing the ROM move.
byAbility(hero,"SKILL_LINK")
local draws=0
adapter.roll=function(_,lo,hi)draws=draws+1;return 0 end
local naturalRoll=adapter.roll
local multi={user=hero,target=foe,adapter=adapter,
  move={id="FURY_ATTACK",power=15,effect=29},effect=29}
local n=S.withSkillLink(game,multi,function()
  local r1=adapter:roll(0,3)
  local r2=adapter:roll(0,3)
  assert(adapter:roll(1,100)==0,"unrelated rng must pass to native")
  return r2%4+2,r1
end,E)
assert(n==5 and draws==1 and adapter.roll==naturalRoll)
worked=pcall(S.withSkillLink,game,multi,function()
  assert(adapter:roll(0,3)==2)
  error("synthetic multi-hit error")
end,E)
assert(not worked and adapter.roll==naturalRoll)
local fixed={user=hero,target=foe,adapter=adapter,
  move={id="DOUBLE_KICK",power=30,hits=2,effect=44},effect=44}
assert(S.withSkillLink(game,fixed,function()
  return adapter:roll(0,3)
end,E)==0)
byAbility(hero,nil)
assert(S.withSkillLink(game,multi,function()
  return adapter:roll(0,3)
end,E)==0)

-- Integration through the exact tables exported by the stock engine.
local state={player=hero,enemy=foe,battlers={[0]=hero,[1]=foe}}
local Battle={_st=state,start=function()end,reset=function()end}
local Ui={_st=state,handleInput=function()return false end,
  takeCommand=function()return nil end,sidePic=function()return {} end}
local Engine={
  resolveMove=function()return "vanilla" end,
  forEachTarget=function(M,body)return body(M)end,
  hasFlag=function()return false end,
}
local Damage={
  base=function(a,b,move,opts)return tonumber(opts and opts.power) or move.power end,
  calc=function(a,b,move,opts)
    return Damage.base(a,b,move,opts),
      {stab=1,effectiveness=1,moveType=0,typeFlags={immune=false}}
  end,
}
local secondaryCalls=0
local Secondary={
  withChance=function()secondaryCalls=secondaryCalls+1;return true end,
  changeStat=function(ad,b,stat,delta)
    local before=b.stages[stat] or 0
    local after=math.min(6,math.max(-6,before+delta))
    b.stages[stat]=after
    return before~=after and "worked" or "blocked"
  end,
}
local Hit={
  run=function(M)
    if M.effect==29 then
      local r1=M.adapter:roll(0,3)
      local r2=M.adapter:roll(0,3)
      return r2%4+2,r1
    end
    if M.move.effect==31 then
      Secondary.withChance(M,"FLINCH",false,false)
    end
    return "hit"
  end,
  dealDamage=function()return 0 end,
}
local orig={forEach=Engine.forEachTarget,base=Damage.base,
  chance=Secondary.withChance,stage=Secondary.changeStat,hit=Hit.run}
local mod={enabled=true}
local bridge=assert(Bridge.install(mod,game,{
  Ui=Ui,Battle=Battle,Engine=Engine,Damage=Damage,
  Hit=Hit,Secondary=Secondary,EffectIds=E,
  MegaAbilities=A,MegaReactive=Reactive,MegaSpecialized=S,
}))
byAbility(hero,"SHEER_FORCE")
local buffOpts={power=60}
local powered=Damage.base(hero,foe,flinch,buffOpts)
assert(powered==78 and buffOpts.power==60)
local M={user=hero,target=foe,adapter=adapter,move=flinch,
  effect=31,opts={},anim={}}
assert(Hit.run(M)=="hit" and secondaryCalls==0)
byAbility(hero,nil)
assert(Hit.run(M)=="hit" and secondaryCalls==1)

byAbility(hero,"CONTRARY")
hero.stages.attack=0
Secondary.changeStat(nil,hero,"attack",-2,{})
assert(hero.stages.attack==2)
Secondary.changeStat(nil,hero,"attack",1,{})
assert(hero.stages.attack==1)
byAbility(hero,nil)
Secondary.changeStat(nil,hero,"attack",-1,{})
assert(hero.stages.attack==0)

byAbility(hero,"MOLD_BREAKER")
foe.ability="LEVITATE"
assert(Engine.forEachTarget({user=hero,target=foe,adapter=adapter},
  function()return adapter:abilityOf(foe)end)==nil)
assert(adapter:abilityOf(foe)=="LEVITATE")
byAbility(hero,"SKILL_LINK")
assert(Hit.run(multi)==5)
mod.enabled=false
local unmodified=Damage.base(hero,foe,flinch,buffOpts)
assert(unmodified==60)
mod.enabled=true
bridge.uninstall()
assert(Engine.forEachTarget==orig.forEach
  and Damage.base==orig.base
  and Secondary.withChance==orig.chance
  and Secondary.changeStat==orig.stage and Hit.run==orig.hit)
print("PASS: Sheer Force Mold Breaker Contrary Skill Link and native integration")
