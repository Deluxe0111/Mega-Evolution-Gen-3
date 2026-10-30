-- Battlefield/weather mechanics for active Mega forms only. The Gen3
-- engine remains owner of native rain/sun/sand/hail, weather residuals,
-- stats, turn order and type charts. No new global type or ability IDs.
local Weather={}

local function ability(game,b)
  if not (type(game)=="table" and type(game.view)=="function"
      and type(b)=="table" and type(b.mon)=="table") then return nil end
  local v=game.view(b.mon)
  return v and v.ability or nil
end
Weather.ability=ability

local function alive(b)
  return b and b.mon and (tonumber(b.mon.hp) or 0)>0 and not b.fainted
end

local function grounded(b,adapter)
  if not alive(b) then return false end
  if b.onAir or b.magnetRise or (tonumber(b.expMagnetRiseTurns) or 0)>0 then
    return false
  end
  if tonumber(b.type1)==2 or tonumber(b.type2)==2 then return false end
  if adapter and type(adapter.abilityOf)=="function"
      and adapter:abilityOf(b)=="LEVITATE" then return false end
  return true
end
Weather.grounded=grounded

local function strongWindsPresent(game,ad,excluding)
  if not ad or type(ad.activeBattlers)~="function" then return false end
  for _,b in ipairs(ad:activeBattlers()) do
    if b~=excluding and alive(b)
        and ability(game,b)=="DELTA_STREAM" then return true end
  end
  return false
end

function Weather.blockNativeWeather(game,adapter,b)
  local st=adapter and adapter._st
  if not (st and st.weather=="STRONG_WINDS"
      and strongWindsPresent(game,adapter)) then return false end
  local ab=adapter and adapter.abilityOf and adapter:abilityOf(b)
  return ab=="DRIZZLE" or ab=="DROUGHT" or ab=="SAND_STREAM"
end

function Weather.cleanStrongWinds(game,st,adapter,excluding)
  if not (st and st.weather=="STRONG_WINDS") then return false end
  if strongWindsPresent(game,adapter,excluding) then return false end
  st.weather,st.weatherTurns=nil,0
  return true
end

-- Trigger at actual Mega transformation (and on switch-in of an already
-- transformed battler). Never make up native ability numeric IDs.
function Weather.activate(game,st,b,adapter)
  if not (st and alive(b)) then return false end
  local ab=ability(game,b)
  if ab=="SNOW_WARNING" then
    if st.weather=="STRONG_WINDS"
        and strongWindsPresent(game,adapter) then return false end
    st.weather,st.weatherTurns="HAIL",5
    if adapter and adapter.playAnim then
      adapter:playAnim("general","HAIL_CONTINUES",nil,nil)
    end
    return true
  elseif ab=="ELECTRIC_SURGE" then
    st.megaElectricTerrainTurns=5
    return true
  elseif ab=="DELTA_STREAM" then
    st.weather,st.weatherTurns="STRONG_WINDS",0
    return true
  end
  return false
end

-- Weather continues through existing Gen3 rules. Electric Terrain has its
-- own turn counter instead of rewriting st.terrain (that is the overworld
-- terrain index used by Nature Power).
function Weather.onSwitchOut(game,st,b,adapter)
  if ability(game,b)~="DELTA_STREAM" then return false end
  return Weather.cleanStrongWinds(game,st,adapter,b)
end

function Weather.tick(game,st,adapter)
  if not st then return false end
  local turns=tonumber(st.megaElectricTerrainTurns) or 0
  if turns>0 then
    turns=turns-1
    st.megaElectricTerrainTurns=turns>0 and turns or nil
  end
  return Weather.cleanStrongWinds(game,st,adapter)
end

function Weather.terrainBlocksSleep(st,b,adapter)
  return (tonumber(st and st.megaElectricTerrainTurns) or 0)>0
    and grounded(b,adapter)
end

local function weatherIsSun(st,adapter,opts)
  if opts and opts.weatherKind~=nil then
    return opts.weatherKind=="SUN"
  end
  if not st then return false end
  local ok,Rules=pcall(require,"src.core.game3.battle.rules")
  if ok and Rules and Rules.weather and Rules.weather.effective then
    return Rules.weather.effective(st,adapter)=="SUN"
  end
  return st.weather=="SUN"
end

-- Solar Power boosts Special Attack rather than just move power. Supply a
-- temporary battler+mon view to Damage.base after the Mega stat calculation.
function Weather.attackView(game,st,adapter,b,statView,move,opts,isPhysical)
  statView=statView or b
  if ability(game,b)~="SOLAR_POWER" or not weatherIsSun(st,adapter,opts)
      or not (statView and statView.mon) then return statView end
  local typ=tonumber(opts and opts.moveType)
    or tonumber(type(move)=="table" and move.type)
  if not typ or (type(isPhysical)=="function" and isPhysical(typ)) then
    return statView
  end
  local oldSpA=tonumber(statView.mon.spAtk)
  if not oldSpA then return statView end
  local newB,newMon={},{}
  for k,v in pairs(statView) do newB[k]=v end
  for k,v in pairs(statView.mon) do newMon[k]=v end
  newMon.spAtk=math.max(1,math.floor(oldSpA*3/2))
  newB.mon=newMon
  return newB
end

-- Electric Terrain: 1.3x Electric damage for grounded attacking Pokemon.
-- Delta Stream: only neutralise the SUPER-EFFECTIVE part of the target's
-- Flying typing. A dual-typed Dragon/Flying target still takes Dragon damage.
-- This intentionally runs AFTER native damage/type effectiveness and after
-- other ability bonuses; never mutate the source type chart or info table.
function Weather.finalDamage(game,st,adapter,a,d,amount,info,typeProvider)
  if type(amount)~="number" or amount<=0 or type(info)~="table"
      or info.fixed or info.failed or info.setDamage
      or (info.typeFlags and info.typeFlags.immune) then
    return amount,info
  end
  local ty=tonumber(info.moveType)
  local electric=typeProvider and typeProvider.ID and typeProvider.ID.ELECTRIC or 13
  local flying=typeProvider and typeProvider.ID and typeProvider.ID.FLYING or 2
  if (tonumber(st and st.megaElectricTerrainTurns) or 0)>0
      and ty==electric and grounded(a,adapter) then
    amount=math.max(1,math.floor(amount*13/10))
  end
  if st and st.weather=="STRONG_WINDS"
      and strongWindsPresent(game,adapter)
      and d and (d.type1==flying or d.type2==flying)
      and typeProvider and type(typeProvider.effectiveness)=="function"
      and ty then
    local flyingEffect=typeProvider.effectiveness(ty,flying,flying)
    if flyingEffect and flyingEffect>1 then
      amount=math.max(1,math.floor(amount/2))
      local copy={}
      for k,v in pairs(info) do copy[k]=v end
      copy.effectiveness=(tonumber(info.effectiveness) or 1)/2
      if type(info.typeFlags)=="table" then
        local flags={}
        for k,v in pairs(info.typeFlags) do flags[k]=v end
        flags.super=copy.effectiveness>1
        flags.notVery=copy.effectiveness<1
        copy.typeFlags=flags
      end
      info=copy
    end
  end
  return amount,info
end

-- Solar Power end-turn chip, only in effective sun and only while alive.
-- Native Abilities.endTurn/Residuals handle faint sequencing and HP events.
function Weather.endTurn(game,adapter,b)
  if not (adapter and alive(b) and ability(game,b)=="SOLAR_POWER"
      and weatherIsSun(adapter._st,adapter)
      and type(adapter.maxHp)=="function"
      and type(adapter.applyHpLoss)=="function") then return false end
  local maxHp=tonumber(adapter:maxHp(b))
  if not maxHp or maxHp<=0 then return false end
  adapter:applyHpLoss(b,math.max(1,math.floor(maxHp/8)))
  return true
end

return Weather
