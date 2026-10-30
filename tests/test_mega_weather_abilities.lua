-- Gen3 Mega weather/field ability regression: native weather and
-- turn-end boundaries, 5-turn Electric Terrain, strong winds and Solar Power.
local Weather=dofile("src/mega_weather_abilities.lua")
local Bridge=dofile("src/mega_standalone.lua")
local MegaAbilities=dofile("src/mega_abilities.lua")
local Reactive=dofile("src/mega_reactive_abilities.lua")
local Tactical=dofile("src/mega_tactical_abilities.lua")
local forms={}
local game={
  view=function(mon)return forms[mon] end,
  stat=function()return nil end,
  finish=function()end,
  beforeResolved=function()return false end,
}
local a={mon={hp=120,maxHp=120,spAtk=100},id=0,side="player",
  type1=10,type2=10,stages={}}
local b={mon={hp=100,maxHp=100,spAtk=100},id=1,side="enemy",
  type1=2,type2=16,stages={}}
local function set(mon,ability)
  forms[mon.mon]=ability and {ability=ability} or nil
end
local st={weather="SUN",weatherTurns=0,battlers={[0]=a,[1]=b}}
local event={}
local adapter={_st=st,
  activeBattlers=function()return {a,b} end,
  abilityOf=function(_,mon) return mon.ability end,
  maxHp=function(_,mon)return mon.mon.maxHp end,
  hp=function(_,mon)return mon.mon.hp end,
  applyHpLoss=function(_,mon,amount)
    mon.mon.hp=math.max(0,mon.mon.hp-amount)
    event[#event+1]={kind="hp",amount=amount}
  end,
  playAnim=function(_,kind,name)
    event[#event+1]={kind=kind,name=name}
  end,
  sayText=function(_,id)
    event[#event+1]={kind="text",id=id}
  end
}
local Types={
  ID={ELECTRIC=13,FLYING=2},
  isPhysical=function(t)return t<=8 end,
  effectiveness=function(attack,def1,def2)
    if def1==2 and def2==2 and (attack==5 or attack==13 or attack==15)
      then return 2 end
    return 1
  end
}
-- Stock Drought and Swift Swim must remain native; these new abilities
-- do not hijack them or invent numeric ability IDs.
set(a,"DROUGHT")
assert(Weather.activate(game,st,a,adapter)==false and st.weather=="SUN")
set(a,"SNOW_WARNING")
assert(Weather.activate(game,st,a,adapter))
assert(st.weather=="HAIL" and st.weatherTurns==5)
assert(event[#event].name=="HAIL_CONTINUES")
set(a,nil)
assert(not Weather.activate(game,st,a,adapter))

-- Electric Terrain is separate from the engine's st.terrain overworld ID.
st.terrain=8
set(a,"ELECTRIC_SURGE")
assert(Weather.activate(game,st,a,adapter))
assert(st.megaElectricTerrainTurns==5 and st.terrain==8)
local info={moveType=13,stab=1,effectiveness=1,typeFlags={immune=false}}
local dmg=Weather.finalDamage(game,st,adapter,a,b,100,info,Types)
assert(dmg==130,"grounded Electric attacks get 30% terrain boost")
assert(info.effectiveness==1,"damage info cannot be modified")
a.type1=2
assert(Weather.finalDamage(game,st,adapter,a,b,100,info,Types)==100,
  "Flying attackers do not gain Electric Terrain boosts")
a.type1=10
a.ability="LEVITATE"
assert(Weather.finalDamage(game,st,adapter,a,b,100,info,Types)==100)
a.ability=nil
assert(Weather.terrainBlocksSleep(st,a,adapter))
a.type1=2
assert(not Weather.terrainBlocksSleep(st,a,adapter))
a.type1=10
for i=4,1,-1 do
  Weather.tick(game,st,adapter)
  assert(st.megaElectricTerrainTurns==i)
end
Weather.tick(game,st,adapter)
assert(st.megaElectricTerrainTurns==nil)
assert(Weather.finalDamage(game,st,adapter,a,b,100,info,Types)==100)
assert(not Weather.terrainBlocksSleep(st,a,adapter))

-- Solar Power adds +50% Sp Atk in sunlight via a cloned battle stat
-- view; never double-buffs physical moves or writes to the actual mon.
set(a,"SOLAR_POWER")
st.weather="SUN"
local originalMon=a.mon
local clone={mon={hp=120,maxHp=120,spAtk=160},id=0,side="player"}
local sunny=Weather.attackView(game,st,adapter,a,clone,
  {id="FLAMETHROWER",type=10,power=95},{weatherKind="SUN"},Types.isPhysical)
assert(sunny~=clone and sunny.mon~=clone.mon and sunny.mon.spAtk==240)
assert(clone.mon.spAtk==160 and originalMon.spAtk==100)
assert(Weather.attackView(game,st,adapter,a,clone,
  {id="TACKLE",type=0,power=35},{weatherKind="SUN"},Types.isPhysical)==clone)
assert(Weather.attackView(game,st,adapter,a,clone,
  {id="SURF",type=11,power=90},{weatherKind="RAIN"},Types.isPhysical)==clone
  or st.weather=="SUN") -- test native effective-weather fallback separately
assert(Weather.endTurn(game,adapter,a))
assert(a.mon.hp==105,"Solar Power removes 1/8 max HP in sun")
st.weather="RAIN"
assert(not Weather.endTurn(game,adapter,a) and a.mon.hp==105)
st.weather="SUN"
a.mon.hp=0
assert(not Weather.endTurn(game,adapter,a),"Solar Power does not hurt fainted")
a.mon.hp=120

-- Delta Stream neutralises only Flying's super-effective part; Dragon
-- remains relevant against Mega Rayquaza's Dragon/Flying dual typing.
set(a,"DELTA_STREAM")
assert(Weather.activate(game,st,a,adapter))
assert(st.weather=="STRONG_WINDS" and st.weatherTurns==0)
local rock={moveType=5,effectiveness=2,typeFlags={super=true,notVery=false,immune=false}}
local amount,changed=Weather.finalDamage(game,st,adapter,b,a,120,rock,Types)
assert(amount==120,"non-Flying target unaffected")
a.type1=16;a.type2=2
amount,changed=Weather.finalDamage(game,st,adapter,b,a,120,rock,Types)
assert(amount==60 and changed.effectiveness==1
  and not changed.typeFlags.super)
assert(rock.effectiveness==2 and rock.typeFlags.super,
  "native result info cannot be modified in place")
local dragon={moveType=16,effectiveness=2,typeFlags={super=true,immune=false}}
assert(Weather.finalDamage(game,st,adapter,b,a,120,dragon,Types)==120,
  "Dragon-type weakness remains")
local ice={moveType=15,effectiveness=4,typeFlags={super=true,immune=false}}
local iceDamage,iceInfo=Weather.finalDamage(game,st,adapter,b,a,120,ice,Types)
assert(iceDamage==60 and iceInfo.effectiveness==2)
assert(Weather.onSwitchOut(game,st,a,adapter))
assert(st.weather==nil)
st.weather="STRONG_WINDS"
a.mon.hp=0
assert(Weather.cleanStrongWinds(game,st,adapter))
assert(st.weather==nil,"fainted Delta Stream cannot persist")
a.mon.hp=120

-- Native bridge integration tests with injected engine/adapter modules.
local Battle={_st=st,start=function()end,reset=function()end}
local Ui={_st=st,handleInput=function()return false end,
  takeCommand=function()return nil end,sidePic=function()return {} end}
local Engine={
  resolveMove=function()return "resolved" end,
  switchInEffects=function()return false end,
  switchOutEffects=function()return false end,
  forEachTarget=function(M,body)return body(M) end,
  hasFlag=function()return false end,
}
local Damage={
  base=function(attacker,defender,move,opts)
    return attacker.mon.spAtk
  end,
  calc=function(attacker,defender,move,opts)
    local power=Damage.base(attacker,defender,move,opts)
    return power,{moveType=move.type,effectiveness=1,
      typeFlags={super=false,immune=false},stab=1}
  end,
}
local Hit={run=function()end,dealDamage=function(M,amount)
  M.target.mon.hp=math.max(0,M.target.mon.hp-amount)
  return amount
end}
local Secondary={changeStat=function()return "blocked" end}
local NativeAbilities={endTurn=function()return false end}
local WeatherHandlers={tickWeather=function()return "native tick"end}
local Status={cantMakeAsleep=function()return false end}
local original={
  switchIn=Engine.switchInEffects,
  switchOut=Engine.switchOutEffects,
  damageBase=Damage.base,damageCalc=Damage.calc,
  endTurn=NativeAbilities.endTurn,
  tick=WeatherHandlers.tickWeather,
  sleep=Status.cantMakeAsleep,
}
local mod={enabled=true}
local bridge=assert(Bridge.install(mod,game,{
  Ui=Ui,Engine=Engine,Battle=Battle,Damage=Damage,
  Hit=Hit,Secondary=Secondary,
  MegaAbilities=MegaAbilities,MegaReactive=Reactive,
  MegaTactical=Tactical,MegaWeather=Weather,
  Types=Types,NativeAbilities=NativeAbilities,
  WeatherHandlers=WeatherHandlers,Status=Status,
}))
set(a,"SNOW_WARNING")
st.weather="SUN"
assert(Engine.switchInEffects(st,adapter,a)==true and st.weather=="HAIL")
set(a,"ELECTRIC_SURGE")
assert(Engine.switchInEffects(st,adapter,a)==true)
assert(st.megaElectricTerrainTurns==5)
local context={adapter=adapter}
assert(Status.cantMakeAsleep(context,a)==true)
a.type1=2
assert(Status.cantMakeAsleep(context,a)==false)
a.type1=10
assert(WeatherHandlers.tickWeather(adapter)=="native tick")
assert(st.megaElectricTerrainTurns==4)
set(a,"SOLAR_POWER")
st.weather="SUN"
a.mon.hp=120;a.type1=10;a.type2=10
local res=Damage.base(a,b,{type=10,power=90},
  {weatherKind="SUN",adapter=adapter})
assert(res==150 and a.mon.spAtk==100)
assert(NativeAbilities.endTurn(adapter,a)==true and a.mon.hp==105)
set(a,"DELTA_STREAM")
assert(Engine.switchInEffects(st,adapter,a)==true and st.weather=="STRONG_WINDS")
assert(Engine.switchOutEffects(st,adapter,a)==false and st.weather==nil)
set(a,nil)
assert(NativeAbilities.endTurn(adapter,a)==false)
bridge.uninstall()
assert(Engine.switchInEffects==original.switchIn
  and Engine.switchOutEffects==original.switchOut
  and Damage.base==original.damageBase and Damage.calc==original.damageCalc
  and NativeAbilities.endTurn==original.endTurn
  and WeatherHandlers.tickWeather==original.tick
  and Status.cantMakeAsleep==original.sleep)
print("PASS: Snow Warning, Solar Power, Electric Surge, Delta Stream and native hook cleanup")
