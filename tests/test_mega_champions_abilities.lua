-- Pokémon Champions Mega abilities, standard/edge cases and native hooks.
local C=dofile("src/mega_champions_abilities.lua")
local A=dofile("src/mega_abilities.lua")
local Bridge=dofile("src/mega_standalone.lua")
local Precision=dofile("src/mega_precision_abilities.lua")
local active={}
local game={view=function(mon)return active[mon] end,
  stat=function()return nil end,
  finish=function()end,
  beforeResolved=function()return false end}
local p={id=0,side="player",type1=11,type2=11,
  mon={hp=120,maxHp=120,spAtk=100},stages={}}
local foe={id=1,side="enemy",type1=0,type2=0,
  mon={hp=150,maxHp=150,spAtk=100},stages={}}
local function set(b,ab)active[b.mon]=ab and {ability=ab} or nil end
local Types={ID={NORMAL=0,FIRE=10,DRAGON=16,FAIRY=17,GROUND=4},
  isPhysical=function(t)return t<=8 end}
local priorTypes=package.loaded["src.core.game3.battle.types"]
package.loaded["src.core.game3.battle.types"]=Types

local normal={id="RETURN",power=100,type=0,flags=3,effect=0,target=0}
local fire={id="FLAMETHROWER",power=90,type=10,flags=2,effect=0,target=0}
local water={id="SURF",power=90,type=11,flags=2,effect=0,target=8}
local contact={id="SLASH",power=80,type=0,flags=3,effect=0,target=0}
local noContact={id="SHADOW_BALL",power=80,type=7,flags=2,effect=0,target=0}

-- Dragonize uses the existing dynamic type registry and -ate multipliers.
set(p,"DRAGONIZE")
local opts=A.moveOptions(game,p,normal,{}, {DRAGON=16})
assert(opts.moveType==16 and normal.type==0)
assert(A.baseOptions(game,p,normal,{moveType=16,power=100}).power==120)
assert(A.moveOptions(game,p,fire,{})==nil or
  A.moveOptions(game,p,fire,{}).moveType==nil)
set(p,nil)

-- Fire Mane acts on Fire power only and does not modify a ROM move row.
set(p,"FIRE_MANE")
local input={power=90,moveType=10,crit=true}
local changed=C.powerOptions(game,p,fire,input,Types)
assert(changed~=input and changed.power==135
  and input.power==90 and changed.crit==true)
assert(C.powerOptions(game,p,water,{power=90,moveType=11},Types).power==90)
set(p,nil)
assert(C.powerOptions(game,p,fire,input,Types)==input)

-- Aura Guard halves only contact damage from opposing moves.
set(foe,"AURA_GUARD")
assert(C.defensiveDamage(game,p,foe,contact,101,{effectiveness=1})==50)
assert(C.defensiveDamage(game,p,foe,noContact,101,{effectiveness=1})==101)
assert(C.defensiveDamage(game,p,foe,contact,101,{fixed=true})==101)
set(foe,nil)

-- Mega Sol sets only the holder's effective move weather.
set(p,"MEGA_SOL")
local weatherIn={weatherKind="RAIN",reflect=true}
local weatherOut=C.weatherOptions(game,p,weatherIn)
assert(weatherOut~=weatherIn and weatherOut.weatherKind=="SUN"
  and weatherOut.reflect and weatherIn.weatherKind=="RAIN")
assert(C.noSolarCharge(game,{user=p,move={id="SOLAR_BEAM"}}))
assert(C.noSolarCharge(game,{user=p,move={id="SOLAR_BLADE"}}))
assert(not C.noSolarCharge(game,{user=p,move={id="THUNDER"}}))
set(p,nil)
assert(C.weatherOptions(game,p,weatherIn)==weatherIn)
assert(not C.noSolarCharge(game,{user=p,move={id="SOLAR_BEAM"}}))

-- Piercing Drill / updated Champions Unseen Fist: 25% through Protect,
-- without modifying the target's Protect field. Noncontact stays blocked.
local M={user=p,target=foe,move=contact}
foe.expProtected=true
M.isProtected=function(self)return self.target.expProtected==true end
local originalProtected=M.isProtected
for _,ab in ipairs({"PIERCING_DRILL","UNSEEN_FIST"}) do
  set(p,ab)
  local result=C.withPiercingProtect(game,M,function(ctx)
    assert(ctx:isProtected()==false and ctx._megaQuarterProtect==true)
    return C.piercingDamage(game,ctx,p,foe,100,{stab=1})
  end)
  assert(result==25,ab)
  assert(M.isProtected==originalProtected and M._megaQuarterProtect==nil
    and foe.expProtected==true,ab.." must not clear Protect")
end
M.move=noContact
set(p,"PIERCING_DRILL")
assert(C.withPiercingProtect(game,M,function(ctx)
  assert(ctx:isProtected()==true)
  return "blocked"
end)=="blocked")
M.move=contact
local ok,err=pcall(C.withPiercingProtect,game,M,function()
  error("synthetic guarded hit error")
end)
assert(not ok and tostring(err):find("synthetic guarded hit error",1,true))
assert(M.isProtected==originalProtected and M._megaQuarterProtect==nil)
foe.expProtected=nil
assert(C.withPiercingProtect(game,M,function(ctx)
  assert(not ctx._megaQuarterProtect)
  return "unprotected"
end)=="unprotected")
set(p,nil)

-- Spicy Spray triggers after HP damage to Mega Scovillain, never on a
-- substitute, on zero damage or when burn is rejected by the native adapter.
set(foe,"SPICY_SPRAY")
local statuses={}
local applies=0
local animated=0
local adapter={
  applyStatus=function(_,who,status,source)
    applies=applies+1
    assert(who==p and status=="BRN" and source==foe)
    if statuses[who] or who.type1==10 then return false end
    statuses[who]=status
    return true
  end,
  statusAnim=function(_,who,status)
    assert(who==p and status=="BRN")
    animated=animated+1
  end,
  hp=function(_,b)return b.mon.hp end,
}
local hit={user=p,target=foe,move=contact,adapter=adapter}
assert(C.afterDamage(game,hit,15,false))
assert(statuses[p]=="BRN" and animated==1 and applies==1)
assert(not C.afterDamage(game,hit,15,true))
hit.hitSubstitute=true
assert(not C.afterDamage(game,hit,10,false))
hit.hitSubstitute=nil
assert(not C.afterDamage(game,hit,0,false))
statuses[p]=nil;p.type1=10
assert(not C.afterDamage(game,hit,20,false))
p.type1=11
set(foe,nil)
assert(not C.afterDamage(game,hit,15,false))
set(foe,"SPICY_SPRAY")

-- Native integration with Damage.base/Calc, forEachTarget, Hit.dealDamage
-- and the existing battle.charge_required callback.
local nativeBaseCall=0
local nativeDamage={}
nativeDamage.base=function(attacker,defender,move,opts)
  nativeBaseCall=nativeBaseCall+1
  return tonumber(opts and opts.power) or move.power
end
nativeDamage.calc=function(attacker,defender,move,opts)
  opts=opts or {}
  local amount=nativeDamage.base(attacker,defender,move,
    {power=opts.power or move.power,moveType=opts.moveType or move.type})
  return amount,{moveType=opts.moveType or move.type,
    weatherKind=opts.weatherKind,stab=1,effectiveness=1}
end
local Hit={
  run=function(ctx)
    return nativeDamage.calc(ctx.user,ctx.target,ctx.move,{})
  end,
  dealDamage=function(ctx,amount)
    local old=ctx.target.mon.hp
    ctx.target.mon.hp=math.max(0,old-amount)
    return old-ctx.target.mon.hp
  end,
}
local Engine={
  resolveMove=function()return "move"end,
  hasFlag=function()return false end,
  forEachTarget=function(M,body)return body(M)end,
}
local Battle={_st={battlers={[0]=p,[1]=foe}},start=function()end,
  reset=function()end}
local Ui={_st=Battle._st,handleInput=function()return false end,
  takeCommand=function()return nil end,sidePic=function()return {}end}
local calls={}
local mod={enabled=true,hooks={wrap=function(_,name,callback)
  calls[name]=callback
  return function()calls[name]=nil end
end}}
local original={base=nativeDamage.base,calc=nativeDamage.calc,
  target=Engine.forEachTarget,hit=Hit.dealDamage}
local bridge=assert(Bridge.install(mod,game,{
  Damage=nativeDamage,Hit=Hit,Engine=Engine,Battle=Battle,Ui=Ui,
  MegaAbilities=A,MegaChampions=C,MegaPrecision=Precision,Types=Types,
}))
set(p,"FIRE_MANE")
assert(nativeDamage.base(p,foe,fire,{power=90,moveType=10})==135)
set(p,"DRAGONIZE")
local converted,convertedInfo=nativeDamage.calc(p,foe,normal,{})
assert(converted==120 and convertedInfo.moveType==16,
  "native damage must see Dragonize conversion & boost")
set(p,"MEGA_SOL")
local effective,effectiveInfo=nativeDamage.calc(p,foe,water,
  {weatherKind="RAIN"})
assert(effectiveInfo.weatherKind=="SUN"
  and nativeDamage.calc(p,foe,normal,{weatherKind="RAIN"})~=nil)
assert(calls["battle.charge_required"])
assert(calls["battle.charge_required"](function()return true end,
  {user=p,move={id="SOLAR_BEAM"}})==false)
set(p,nil)
assert(calls["battle.charge_required"](function()return true end,
  {user=p,move={id="SOLAR_BEAM"}})==true)

set(foe,"AURA_GUARD")
assert(nativeDamage.calc(p,foe,contact,{})==40)
assert(nativeDamage.calc(p,foe,noContact,{})==80)
set(foe,nil)
foe.expProtected=true
for _,ab in ipairs({"PIERCING_DRILL","UNSEEN_FIST"}) do
  set(p,ab)
  local inCtx={user=p,target=foe,move=contact,
    isProtected=function(self)return self.target.expProtected end}
  local amount=Engine.forEachTarget(inCtx,function(ctx)
    assert(not ctx:isProtected())
    return nativeDamage.calc(p,foe,contact,{})
  end)
  assert(amount==20,"protected "..ab.." must deal 25% damage")
  assert(foe.expProtected and inCtx.isProtected(inCtx))
end
foe.expProtected=nil
set(p,nil)

set(foe,"SPICY_SPRAY")
statuses[p]=nil
foe.mon.hp=150
local reaction={user=p,target=foe,move=contact,adapter=adapter}
assert(Hit.dealDamage(reaction,15)==15)
assert(statuses[p]=="BRN")
statuses[p]=nil
foe.substituteHP=10
assert(Hit.dealDamage(reaction,2)==2)
assert(statuses[p]==nil,"substitute damage does not trigger Spicy Spray")
foe.substituteHP=nil

mod.enabled=false
set(p,"FIRE_MANE")
assert(nativeDamage.base(p,foe,fire,{power=90,moveType=10})==90)
mod.enabled=true
bridge.uninstall()
assert(nativeDamage.base==original.base and nativeDamage.calc==original.calc
  and Engine.forEachTarget==original.target
  and Hit.dealDamage==original.hit
  and calls["battle.charge_required"]==nil)
package.loaded["src.core.game3.battle.types"]=priorTypes
print("PASS: Champions Dragonize, Fire Mane, Aura Guard, Mega Sol, Piercing Drill, Spicy Spray and corrected Unseen Fist")
