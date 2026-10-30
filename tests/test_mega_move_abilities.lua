local Ability=dofile("src/mega_abilities.lua")
local Standalone=dofile("src/mega_standalone.lua")
local active={}
local game={view=function(mon)return active[mon] end,stat=function()return nil end,
  finish=function()end}
local m1={hp=100,maxHp=100}
local m2={hp=100,maxHp=100}
local hero={mon=m1,id=0,side="player"}
local enemy={mon=m2,id=1,side="enemy"}
local function use(ab)active[m1]={ability=ab} end
local function foe(ab)active[m2]={ability=ab} end
local normal={id="HYPER_VOICE",type=0,power=90,flags=0}
local status={id="GROWL",type=0,power=0}
local water={id="SURF",type=11,power=90}
-- Introduce a synthetic Fairy expansion provider. The Mega mod may only
-- consume the existing provider ID; it must never invent one.
local prior=package.loaded["src.core.game3.progression"]
package.loaded["src.core.game3.progression"]={
  typeIndexFor=function(key)
    if key=="FAIRY" then return 24 end
    if key=="ICE" then return 15 end
    if key=="FLYING" then return 2 end
  end,
}
local function expect(ab,move,expectedType,expectedPower)
  use(ab)
  local opts=Ability.moveOptions(game,hero,move,{})
  assert(opts and opts.moveType==expectedType,
    ab.." type "..tostring(opts and opts.moveType))
  local baseOpts={power=move.power,moveType=opts.moveType}
  local adjusted=Ability.baseOptions(game,hero,move,baseOpts)
  assert(adjusted.power==expectedPower,
    ab.." power "..tostring(adjusted.power))
  assert(move.type==0 and move.power==90,"ROM move data mutated")
end
expect("PIXILATE",normal,24,108)
expect("AERILATE",normal,2,108)
expect("REFRIGERATE",normal,15,108)
use("PIXILATE")
local untouched={}
assert(Ability.moveOptions(game,hero,status,untouched)==untouched,
  "status moves cannot convert")
assert(Ability.moveOptions(game,hero,water,untouched)==untouched,
  "only normal types convert")
assert(Ability.baseOptions(game,hero,water,{power=90,moveType=11}).power==90)
-- Missing Fairy provider must leave the original move unmodified.
package.loaded["src.core.game3.progression"]={
  typeIndexFor=function()return nil end,
}
package.loaded["src.core.game3.battle.types"]={ID={NORMAL=0,ICE=15,FLYING=2}}
local withoutProvider={}
assert(Ability.moveOptions(game,hero,normal,withoutProvider)==withoutProvider)
assert(Ability.baseOptions(game,hero,normal,{power=90,moveType=0}).power==90)
package.loaded["src.core.game3.progression"]={
  typeIndexFor=function(key)if key=="FAIRY" then return 24 end end,
}
use("SCRAPPY")
local fighting={id="KARATE_CHOP",type=1,power=50}
local original={power=90}
local scrappy=Ability.moveOptions(game,hero,normal,original)
assert(scrappy.foresight==true and scrappy.power==90 and original.foresight==nil)
local scrappyFight=Ability.moveOptions(game,hero,fighting,{})
assert(scrappyFight.foresight==true)
local scrappyUnchanged={}
assert(Ability.moveOptions(game,hero,water,scrappyUnchanged)==scrappyUnchanged)
assert(Ability.moveOptions(game,hero,status,scrappyUnchanged)==scrappyUnchanged)
use("NO_GUARD")
assert(Ability.accuracy(game,{user={id=0},target={id=1}},function(pub)
  return pub.id==0 and hero or enemy end))
use("TOUGH_CLAWS")
foe("NO_GUARD")
assert(Ability.accuracy(game,{user={id=0},target={id=1}},function(pub)
  return pub.id==0 and hero or enemy end),"defending No Guard should also apply")
active[m1]=nil;active[m2]=nil
assert(not Ability.accuracy(game,{user={id=0},target={id=1}},function(pub)
  return pub.id==0 and hero or enemy end))

-- Integration: same native Damage.calc / Damage.base call chain, and
-- mod.hooks:wrap('battle.accuracy') invoked after engine protection checks.
local st={battlers={[0]=hero,[1]=enemy}}
local Ui={_st=st,handleInput=function()return false end,
  takeCommand=function()return nil end,sidePic=function()return nil end}
local Engine={resolveMove=function()return "vanilla" end}
local Battle={_st=st,start=function()end,reset=function()end}
local Damage={}
local seen={}
Damage.base=function(a,d,move,opts)
  seen.type=opts.moveType
  seen.power=opts.power
  return opts.power
end
Damage.calc=function(a,d,move,opts)
  opts=opts or {}
  local optsBase={moveType=opts.moveType or move.type,power=opts.power or move.power}
  local amount=Damage.base(a,d,move,optsBase)
  -- Model a Ghost target: only Normal/Fighting need Scrappy/Foresight.
  local isGhostImmune=(optsBase.moveType==0 or optsBase.moveType==1)
  local eff=isGhostImmune and (opts.foresight and 1 or 0) or 1
  return amount*eff,{stab=1,effectiveness=eff,moveType=optsBase.moveType}
end
local oldBase,oldCalc=Damage.base,Damage.calc
local hooks={}
local mod={enabled=true,hooks={wrap=function(_,name,fn)
  assert(name=="battle.accuracy")
  hooks.accuracy=fn
  return function()hooks.accuracy=nil end
end}}
local bridge=assert(Standalone.install(mod,game,{
  Ui=Ui,Engine=Engine,Damage=Damage,Battle=Battle,MegaAbilities=Ability,
}))
use("PIXILATE")
local amount,info=Damage.calc(hero,enemy,normal,{})
assert(amount==108 and seen.type==24 and info.moveType==24,"Pixilate must drive native damage type")
use("AERILATE")
assert(Damage.calc(hero,enemy,normal,{})==108 and seen.type==2)
use("REFRIGERATE")
assert(Damage.calc(hero,enemy,normal,{})==108 and seen.type==15)
use("SCRAPPY")
assert(Damage.calc(hero,enemy,normal,{})==90,
  "Scrappy must clear native Ghost immunity via Foresight")
assert(Damage.calc(hero,enemy,fighting,{})==50,
  "Scrappy must also support Fighting moves")
active[m1]=nil
assert(Damage.calc(hero,enemy,normal,{})==0 and seen.type==0)
use("NO_GUARD")
local rolled=0
local function accuracyNext(ctx)
  rolled=rolled+1
  return ctx.accuracy>=100
end
assert(hooks.accuracy(accuracyNext,{user={id=0},target={id=1},
  accuracy=13,battle=st}))
assert(rolled==1)
active[m1]=nil
assert(not hooks.accuracy(accuracyNext,{user={id=0},target={id=1},
  accuracy=13,battle=st}))
mod.enabled=false
use("PIXILATE")
assert(Damage.calc(hero,enemy,normal,{})==0,
  "disabled mods cannot affect damage calculation")
mod.enabled=true
bridge.uninstall()
assert(hooks.accuracy==nil and Damage.base==oldBase and Damage.calc==oldCalc)
package.loaded["src.core.game3.progression"]=prior
print("PASS: type-conversion trio, Scrappy, No Guard roll, live Fairy provider, native Damage chain and cleanup")
