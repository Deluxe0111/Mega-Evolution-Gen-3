local F=dofile("src/mega_field_abilities.lua")
local Bridge=dofile("src/mega_standalone.lua")
local A=dofile("src/mega_abilities.lua")
local C=dofile("src/mega_champions_abilities.lua")
local active={}
local game={view=function(mon)return active[mon] end,
  stat=function()return nil end,
  finish=function()end,beforeResolved=function()return false end}
local hero={id=0,side="player",type1=13,type2=13,
  mon={hp=120,maxHp=120,attack=140,defense=100,spAtk=110,spDef=90,speed=80},
  stages={attack=0,spAtk=0}}
local foe={id=1,side="enemy",type1=12,type2=3,
  mon={hp=100,maxHp=100,attack=100,defense=100,spAtk=120,spDef=95,speed=80},
  stages={attack=0,spAtk=0}}
local floette={id=3,side="enemy",type1=25,
  mon={hp=90,maxHp=90},stages={}}
local function set(b,ab,slug,stats)
  active[b.mon]=ab and {ability=ab,slug=slug,stats=stats} or nil
end
local st={battlers={[0]=hero,[1]=foe,[3]=floette}}
local adapter={_st=st,
  activeBattlers=function()return {hero,foe,floette} end,
  abilityOf=function(_,b)return b.ability end,
  hp=function(_,b)return b.mon.hp end,
  maxHp=function(_,b)return b.mon.maxHp end,
  isFainted=function(_,b)return b.mon.hp<=0 end,
  applyHpLoss=function(_,b,damage)
    b.mon.hp=math.max(0,b.mon.hp-damage)
  end,
  canApplyStatus=function(_,b,s)
    return b.mon.hp>0 and not b.status and s=="BRN"
  end,
}
local originalAbility=adapter.abilityOf
local originalBurn=adapter.canApplyStatus
local secondaryCalls={}
local Secondary={
  changeStat=function(_,b,stat,delta)
    secondaryCalls[#secondaryCalls+1]={b=b,stat=stat,delta=delta}
    b.stages[stat]=math.min(6,math.max(-6,(b.stages[stat] or 0)+delta))
    return "worked"
  end,
}
local Types={ID={GROUND=4,FIRE=10,FAIRY=25,NORMAL=0},
 isPhysical=function(t)return t<=8 end}
local prior=package.loaded["src.core.game3.progression"]
package.loaded["src.core.game3.progression"]={
  typeIndexFor=function(name)
    if name=="FAIRY" then return 25 end
  end}
local fairyMove={id="MOONBLAST",type=25,power=80}
local normalMove={id="SLASH",type=0,power=80,flags=1}
local fireMove={id="FLAMETHROWER",type=10,power=90,flags=2}
-- Fairy Aura buffs both sides, never boosts non-Fairy and never stacks.
set(floette,"FAIRY_AURA")
local opts={power=80,moveType=25}
local buff=F.fairyPower(game,st,adapter,fairyMove,opts,Types)
assert(buff.power==106 and buff~=opts and opts.power==80)
assert(F.fairyPower(game,st,adapter,normalMove,{power=80,moveType=0},Types).power==80)
set(hero,"FAIRY_AURA")
assert(F.fairyPower(game,st,adapter,fairyMove,opts,Types).power==106)
hero.ability=nil
foe.ability="AURA_BREAK"
assert(F.fairyPower(game,st,adapter,fairyMove,opts,Types).power==60)
foe.ability=nil
set(hero,nil);set(floette,nil)
assert(F.fairyPower(game,st,adapter,fairyMove,opts,Types)==opts)
set(floette,"FAIRY_AURA")
floette.mon.hp=0
assert(F.fairyPower(game,st,adapter,fairyMove,opts,Types)==opts)
floette.mon.hp=90

-- Eelevate behaves like Levitate during native hazards/hit checks and
-- boosts the holder's highest real Mega stat once per defeated opponent.
set(hero,"EELEVATE","mega_eelektross",
  {attack=155,defense=80,spAtk=135,spDef=90,speed=80})
assert(F.withEelevate(game,adapter,function()
  assert(adapter:abilityOf(hero)=="LEVITATE")
  assert(adapter:abilityOf(foe)==nil)
  return "native"
end)=="native")
assert(adapter.abilityOf==originalAbility)
local ok,err=pcall(F.withEelevate,game,adapter,function()
  error("synthetic immunity failure")
end)
assert(not ok and tostring(err):find("synthetic immunity failure",1,true)
  and adapter.abilityOf==originalAbility)
local ko={user=hero,target=foe,adapter=adapter}
foe.mon.hp=0
assert(F.eelevateKO(game,ko,Secondary))
assert(hero.stages.attack==1 and #secondaryCalls==1)
assert(not F.eelevateKO(game,ko,Secondary),"same KO cannot boost twice")
foe.mon.hp=100
set(hero,nil)
assert(not F.eelevateKO(game,ko,Secondary))
-- Non-grounded during Gravity or Smack Down: native Levitate disabled.
set(hero,"EELEVATE")
hero.expSmackDown=true
assert(F.withEelevate(game,adapter,function()
  return adapter:abilityOf(hero) end)==nil)
hero.expSmackDown=nil
st.gravityTurns=3
assert(F.withEelevate(game,adapter,function()
  return adapter:abilityOf(hero) end)==nil)
st.gravityTurns=nil
set(hero,nil)

-- Thermal Exchange blocks burn while abilities are active and boosts
-- Attack after genuine Fire damage, not behind Substitute or on fainting.
set(foe,"THERMAL_EXCHANGE")
assert(F.withBurnImmunity(game,adapter,function()
  return adapter:canApplyStatus(foe,"BRN")
end)==false)
assert(adapter.canApplyStatus==originalBurn)
assert(F.withBurnImmunity(game,adapter,function()
  return adapter:canApplyStatus(hero,"BRN")
end)==true)
local tm={user=hero,target=foe,adapter=adapter,move=fireMove}
foe.mon.hp=100
local n=#secondaryCalls
assert(F.thermalDamage(game,tm,30,false,10,Types,Secondary))
assert(foe.stages.attack==1 and #secondaryCalls==n+1)
assert(not F.thermalDamage(game,tm,30,false,11,Types,Secondary))
assert(not F.thermalDamage(game,tm,30,true,10,Types,Secondary))
foe.mon.hp=0
assert(not F.thermalDamage(game,tm,20,false,10,Types,Secondary))
foe.mon.hp=100
set(foe,nil)

-- Innards Out knocks out an attacker only on opposing attack KO, for the
-- HP left before final blow. Reject substitute, own attacks, repeated hits.
set(foe,"INNARDS_OUT")
local announce=0
local inn={user=hero,target=foe,adapter=adapter,move=normalMove,
  tryFaintUser=function()announce=announce+1 end}
hero.mon.hp=120;foe.mon.hp=0
assert(F.innardsOut(game,inn,42,0,false))
assert(hero.mon.hp==78 and announce==1)
assert(not F.innardsOut(game,inn,42,0,false))
assert(not F.innardsOut(game,{user=hero,target=foe,adapter=adapter},
  40,0,true))
assert(not F.innardsOut(game,{user=foe,target=foe,adapter=adapter},
  40,0,false))
set(foe,nil)

-- Both Mega Zygarde source rows already have Complete (216 base HP).
local zygarde={id=2,side="player",mon={hp=120,maxHp=420}}
set(zygarde,"POWER_CONSTRUCT","mega_zygarde",{hp=216})
assert(F.powerConstructAlreadyComplete(game,zygarde))
set(zygarde,"POWER_CONSTRUCT","mega_zygarde_form_5",{hp=216})
assert(F.powerConstructAlreadyComplete(game,zygarde))
assert(zygarde.mon.maxHp==420,"no double HP transform")
set(zygarde,nil)
assert(not F.powerConstructAlreadyComplete(game,zygarde))

-- Hook integration with mock native engine; all added handlers leave the
-- original function tables untouched after uninstall.
local Engine={
  resolveMove=function(_,_,_,_,ad)
    return ad:canApplyStatus(foe,"BRN") end,
  switchInEffects=function(_,ad,b,opts)
    return opts and opts.spikes and ad:abilityOf(b)~="LEVITATE"
  end,
  forEachTarget=function(M,body)return body(M)end,
  hasFlag=function()return false end,
}
local Hit={
  run=function(M)
    return M.adapter:abilityOf(M.target)=="LEVITATE"
  end,
  dealDamage=function(M,damage,info)
    local before=M.target.mon.hp
    M.target.mon.hp=math.max(0,before-damage)
    return before-M.target.mon.hp
  end,
}
local Damage={
  base=function(_,_,move,options)
    return options and options.power or move.power
  end,
  calc=function(a,b,move,options)
    return Damage.base(a,b,move,{power=move.power,moveType=move.type,
      adapter=options and options.adapter}),
      {moveType=move.type,effectiveness=1,stab=1}
  end,
}
local Ui={_st=st,handleInput=function()return false end,
  takeCommand=function()end,sidePic=function()return nil end}
local Battle={_st=st,start=function()end,reset=function()end}
local original={run=Hit.run,damage=Hit.dealDamage,
  switchIn=Engine.switchInEffects,resolve=Engine.resolveMove,
  base=Damage.base}
local bridge=assert(Bridge.install({enabled=true},game,{
  Ui=Ui,Battle=Battle,Engine=Engine,Hit=Hit,Damage=Damage,
  Secondary=Secondary,Types=Types,MegaAbilities=A,
  MegaChampions=C,MegaField=F,
}))
set(hero,"EELEVATE")
assert(Hit.run({user=foe,target=hero,adapter=adapter,move=normalMove}))
assert(Engine.switchInEffects(st,adapter,hero,{spikes=true})==false)
assert(adapter.abilityOf==originalAbility)
set(hero,nil)
assert(Engine.switchInEffects(st,adapter,hero,{spikes=true})==true)
set(foe,"THERMAL_EXCHANGE")
assert(Engine.resolveMove(hero,foe,"WILL_O_WISP",1,adapter,st)==false)
assert(adapter.canApplyStatus==originalBurn)
set(foe,nil)
assert(Engine.resolveMove(hero,foe,"WILL_O_WISP",1,adapter,st)==true)
set(foe,"INNARDS_OUT")
hero.mon.hp=100;foe.mon.hp=21
local ctx={user=hero,target=foe,adapter=adapter,move=normalMove,
  tryFaintUser=function()end}
assert(Hit.dealDamage(ctx,30,{moveType=0})==21)
assert(hero.mon.hp==79)
set(foe,nil)
set(floette,"FAIRY_AURA")
assert(Damage.base(hero,foe,fairyMove,{adapter=adapter,moveType=25,
  power=80})==106)
bridge.uninstall()
assert(Hit.run==original.run and Hit.dealDamage==original.damage
  and Engine.switchInEffects==original.switchIn
  and Engine.resolveMove==original.resolve and Damage.base==original.base)
package.loaded["src.core.game3.progression"]=prior
print("PASS: Eelevate, Fairy Aura, Thermal Exchange, Innards Out, Power Construct and native hooks")
