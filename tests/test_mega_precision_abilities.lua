-- Batch 7: Parental Bond, Unseen Fist, Stalwart, Steadfast.
-- Exercise direct mechanics and live exported Gen3 wrapper boundaries.
local P=dofile("src/mega_precision_abilities.lua")
local Bridge=dofile("src/mega_standalone.lua")
local A=dofile("src/mega_abilities.lua")
local Reactive=dofile("src/mega_reactive_abilities.lua")
local Tactical=dofile("src/mega_tactical_abilities.lua")
local Special=dofile("src/mega_specialized_abilities.lua")
local view={}
local game={
  view=function(mon)return view[mon] end,
  stat=function()return nil end,
  finish=function()end,
  beforeResolved=function()return false end,
}
local hero={id=0,side="player",mon={hp=100,maxHp=100},stages={speed=0}}
local foe={id=1,side="enemy",mon={hp=100,maxHp=100},stages={speed=0}}
local ally={id=3,side="enemy",mon={hp=100,maxHp=100}}
local function set(b,name)view[b.mon]=name and {ability=name} or nil end
local E={HIT=0,MULTI_HIT=29,DOUBLE_HIT=44,TWINEEDLE=77,
  DRAGON_RAGE=41,SONICBOOM=89,LEVEL_DAMAGE=88,
  EXPLOSION=7,COUNTER=90,MIRROR_COAT=145,OHKO=38}
local tackle={id="TACKLE",power=80,type=0,flags=3,target=0,effect=0}
local ranged={id="AURA_SPHERE",power=80,type=1,flags=2,target=0,effect=0}
local spread={id="SURF",power=90,type=11,flags=2,target=8,effect=0}
local multi={id="FURY_ATTACK",power=15,type=0,flags=3,target=0,effect=29}
local fixed={id="DRAGON_RAGE",power=40,type=16,flags=2,target=0,effect=41}
local status={id="GROWL",power=0,flags=2,target=0,effect=0}

-- Unseen Fist bypasses a protected target only for contact attacks.
local protected={user=hero,target=foe,move=tackle,isProtected=function()return true end}
local originalProtected=protected.isProtected
set(hero,"UNSEEN_FIST")
assert(P.withUnseenFist(game,protected,function(ctx)
  assert(ctx:isProtected()==false)
  assert(ctx.target.expProtected==nil)
  return "landed"
end)=="landed")
assert(protected.isProtected==originalProtected and protected:isProtected())
protected.move=ranged
assert(P.withUnseenFist(game,protected,function(ctx)
  assert(ctx:isProtected()==true)
  return "blocked"
end)=="blocked")
protected.move=tackle
local ok,err=pcall(P.withUnseenFist,game,protected,function()error("test protect error")end)
assert(not ok and tostring(err):find("test protect error",1,true))
assert(protected.isProtected==originalProtected)
set(hero,nil)
assert(P.withUnseenFist(game,protected,function(ctx)
  return ctx:isProtected()
end)==true)

-- Stalwart ignores redirection temporarily in doubles, but doesn't erase
-- real Follow Me, Lightning Rod or target assignment on the opponent side.
local side={expFollowMeId=3,expFollowMe=ally}
local st={double=true,battlers={[0]=hero,[1]=foe,[3]=ally}}
foe.ability="LIGHTNING_ROD"
local adapter={
  foeSide=function(_,b) assert(b==hero);return side end,
  abilityOf=function(_,b)return b.ability end,
}
local nativeAbility=adapter.abilityOf
set(hero,"STALWART")
assert(P.withStalwart(game,st,adapter,hero,"THUNDERBOLT",function()
  assert(side.expFollowMeId==nil and side.expFollowMe==nil)
  assert(adapter:abilityOf(foe)==nil)
  return 1
end)==1)
assert(side.expFollowMeId==3 and side.expFollowMe==ally
  and adapter.abilityOf==nativeAbility)
ok,err=pcall(P.withStalwart,game,st,adapter,hero,"THUNDERBOLT",
  function()error("test redirection error")end)
assert(not ok and tostring(err):find("test redirection error",1,true))
assert(side.expFollowMeId==3 and adapter.abilityOf==nativeAbility)
st.double=false
assert(P.withStalwart(game,st,adapter,hero,"THUNDERBOLT",
  function()return side.expFollowMeId end)==3)
st.double=true
set(hero,nil)
assert(P.withStalwart(game,st,adapter,hero,"THUNDERBOLT",
  function()return side.expFollowMeId end)==3)

-- Parental Bond creates a cloned move row solely for one Hit.run call,
-- never makes status/spread/fixed/natural multi-hit attacks double strike.
set(hero,"PARENTAL_BOND")
local m={user=hero,target=foe,move=tackle,effect=0,hitsLanded=0}
assert(P.parentalEligible(game,m,E))
for _,move in ipairs({spread,multi,fixed,status}) do
  local other={user=hero,target=foe,move=move,effect=move.effect}
  assert(not P.parentalEligible(game,other,E),move.id)
end
assert(P.withParentalBond(game,m,function(ctx)
  assert(ctx._megaParentalBond==true and ctx.move.hits==2)
  assert(ctx.move~=tackle and tackle.hits==nil)
  local result=P.parentalDamage(game,ctx,hero,foe,80,{effectiveness=1})
  assert(result==80)
  ctx.hitsLanded=1
  result=P.parentalDamage(game,ctx,hero,foe,80,{effectiveness=1})
  assert(result==20)
  assert(P.parentalDamage(game,ctx,hero,foe,80,{fixed=true})==80)
  return "two hits"
end,E)=="two hits")
assert(m._megaParentalBond==nil and m.move==tackle and tackle.hits==nil)
m.hitsLanded=0
ok,err=pcall(P.withParentalBond,game,m,
  function()error("test second hit failure")end,E)
assert(not ok and tostring(err):find("test second hit failure",1,true))
assert(m.move==tackle and m._megaParentalBond==nil)
set(hero,nil)
assert(not P.parentalEligible(game,m,E))

-- Steadfast is a native flinch consumed by the engine, not a mere flinch
-- flag. Apply ordinary +1 Speed with the native stage function.
local increases=0
local Secondary={
  changeStat=function(_,b,key,delta,flags)
    assert(key=="speed" and delta==1 and flags.user)
    if b.stages.speed>=6 then return "blocked" end
    b.stages.speed=b.stages.speed+delta
    increases=increases+1
    return "worked"
  end,
}
set(hero,"STEADFAST")
hero.flinched=true;hero.expUnableToMove=nil
assert(not P.afterMove(game,hero,true,Secondary,adapter))
hero.flinched=nil;hero.expUnableToMove=true
assert(P.afterMove(game,hero,true,Secondary,adapter))
assert(hero.stages.speed==1 and increases==1)
assert(not P.afterMove(game,hero,false,Secondary,adapter))
hero.stages.speed=6
assert(not P.afterMove(game,hero,true,Secondary,adapter))
set(hero,nil)
hero.stages.speed=0
assert(not P.afterMove(game,hero,true,Secondary,adapter))

-- Native bridge integration: original function tables, one PP for two
-- strikes, damage 80+20, contact-protect bypass, Follow Me redirection,
-- and Steadfast on an actual flinch consumed inside resolveMove.
local current={}
local nativeHitCount=0
local Damage={
  base=function()return 80 end,
  calc=function(a,b,move,opts)
    return 80,{moveType=0,effectiveness=1,stab=1,typeFlags={immune=false}}
  end,
}
local Hit={
  run=function(ctx)
    ctx.ppUses=(ctx.ppUses or 0)+1
    local amount=0
    for i=1,(ctx.move.hits or 1) do
      local hit=Damage.calc(ctx.user,ctx.target,ctx.move,{})
      amount=amount+hit
      ctx.hitsLanded=(ctx.hitsLanded or 0)+1
      nativeHitCount=nativeHitCount+1
    end
    return amount
  end,
  dealDamage=function()return 0 end,
}
local Engine={
  hasFlag=function()return false end,
  forEachTarget=function(M,body)return body(M)end,
  getMoveTarget=function(st,ad,attacker,moveId)
    return ad:foeSide(attacker).expFollowMeId or 1
  end,
  resolveTarget=function(st,ad,attacker,moveId,chosenId)
    return ad:foeSide(attacker).expFollowMeId or chosenId
  end,
  resolveMove=function(user,target,move,slot,ad,st)
    if user.flinched then
      user.flinched=nil
      user.expUnableToMove=true
      return "flinched"
    end
    return "moved"
  end,
}
local orig={
  hit=Hit.run,damage=Damage.calc,move=Engine.resolveMove,
  target=Engine.resolveTarget,getTarget=Engine.getMoveTarget,
  forEach=Engine.forEachTarget,stats=Secondary.changeStat,
}
local Battle={_st=st,start=function()end,reset=function()end}
local Ui={_st=st,handleInput=function()return false end,
  takeCommand=function()return nil end,sidePic=function()return {} end}
local mod={enabled=true}
local bridge=assert(Bridge.install(mod,game,{
  Ui=Ui,Battle=Battle,Engine=Engine,Damage=Damage,Hit=Hit,
  Secondary=Secondary,EffectIds=E,
  MegaAbilities=A,MegaReactive=Reactive,
  MegaTactical=Tactical,MegaSpecialized=Special,
  MegaPrecision=P,
}))
set(hero,"PARENTAL_BOND")
local test={user=hero,target=foe,move=tackle,effect=0,hitsLanded=0,
  ppUses=0}
assert(Hit.run(test)==100 and test.ppUses==1
  and nativeHitCount==2)
assert(test.move==tackle and tackle.hits==nil)
set(hero,nil)
local noMega={user=hero,target=foe,move=tackle,effect=0,hitsLanded=0}
assert(Hit.run(noMega)==80)
set(hero,"UNSEEN_FIST")
protected.move=tackle
assert(Engine.forEachTarget(protected,function(ctx)
  return ctx:isProtected() end)==false)
set(hero,"STALWART")
assert(Engine.getMoveTarget(st,adapter,hero,"THUNDERBOLT")==1)
assert(Engine.resolveTarget(st,adapter,hero,"THUNDERBOLT",1)==1)
assert(side.expFollowMeId==3 and adapter.abilityOf==nativeAbility)
set(hero,nil)
assert(Engine.getMoveTarget(st,adapter,hero,"THUNDERBOLT")==3)
assert(Engine.resolveTarget(st,adapter,hero,"THUNDERBOLT",1)==3)
set(hero,"STEADFAST")
hero.flinched=true;hero.expUnableToMove=nil;hero.stages.speed=0
assert(Engine.resolveMove(hero,foe,"TACKLE",1,adapter,st)=="flinched")
assert(hero.stages.speed==1 and hero.expUnableToMove)
mod.enabled=false
set(hero,"PARENTAL_BOND")
local disabled={user=hero,target=foe,move=tackle,effect=0,hitsLanded=0}
assert(Hit.run(disabled)==80)
mod.enabled=true
bridge.uninstall()
assert(Hit.run==orig.hit and Damage.calc==orig.damage
  and Engine.resolveMove==orig.move and Engine.forEachTarget==orig.forEach
  and Engine.resolveTarget==orig.target
  and Engine.getMoveTarget==orig.getTarget
  and Secondary.changeStat==orig.stats)
print("PASS: Parental Bond, Unseen Fist, Stalwart and Steadfast with native hooks")
