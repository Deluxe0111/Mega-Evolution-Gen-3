-- Mega ability interaction repairs: Gen3 Intimidate directly changes
-- stages without Secondary.changeStat, and Healer does not exist in stock G3.
-- Use native battle action boundaries; never mutate saved Pokemon records.
local Interaction={}

local function activeAbility(game,b)
  if type(game)~="table" or type(game.view)~="function"
      or type(b)~="table" or type(b.mon)~="table" then return nil end
  local view=game.view(b.mon)
  return view and view.ability or nil
end

local function packed(...)
  return {n=select("#",...),...}
end
local function unpacked(values,start)
  return (table.unpack or unpack)(values,start or 1,values.n)
end

local function intimidator(ad)
  if not (ad and type(ad.activeBattlers)=="function"
      and type(ad.abilityOf)=="function") then return nil end
  for _,b in ipairs(ad:activeBattlers() or {}) do
    if b and b.expIntimidatePending and ad:abilityOf(b)=="INTIMIDATE" then
      return b
    end
  end
  return nil
end

-- Native runIntimidate directly writes foe.stages.attack (not the public
-- Secondary.changeStat entrypoint). Invert the stage only during this
-- ONE native invocation, so all normal lower-stage checks (Mist, substitute,
-- Intimidate abilities, stage caps) remain authoritative. Restore even on
-- error and trigger Defiant once for an actual opposing Attack drop.
function Interaction.withIntimidate(game,ad,Secondary,callNative)
  if type(callNative)~="function" then return nil end
  local src=intimidator(ad)
  if not src then return callNative() end
  local foes={}
  if ad._st and ad._st.double and type(ad.foesOf)=="function" then
    foes=ad:foesOf(src) or {}
  elseif type(ad.foeOf)=="function" then
    local foe=ad:foeOf(src)
    if foe then foes={foe} end
  end
  local seen={}
  local watched={}
  for _,b in ipairs(foes) do
    if b and b~=src and b.side~=src.side
        and type(b.stages)=="table" and not seen[b] then
      seen[b]=true
      local ab=activeAbility(game,b)
      if ab=="CONTRARY" or ab=="DEFIANT" then
        local before=tonumber(b.stages.attack) or 0
        watched[#watched+1]={b=b,before=before,ability=ab}
        if ab=="CONTRARY" then b.stages.attack=-before end
      end
    end
  end
  local result=packed(pcall(callNative))
  -- Always restore the real-stage basis (including errors).
  for _,entry in ipairs(watched) do
    if entry.ability=="CONTRARY" then
      entry.b.stages.attack=-(tonumber(entry.b.stages.attack) or 0)
    end
  end
  if not result[1] then error(result[2],0) end
  if result[2] then
    for _,entry in ipairs(watched) do
      if entry.ability=="DEFIANT" and
          (tonumber(entry.b.stages.attack) or 0)<entry.before
          and Secondary and type(Secondary.changeStat)=="function" then
        Secondary.changeStat(ad,entry.b,"attack",2,{user=true})
      end
    end
  end
  return unpacked(result,2)
end

-- Healer is a Gen5+ ability, absent from native Gen3. In doubles, each
-- active Mega Audino has an independent 30% chance to cure the adjacent
-- allied Pokemon's nonvolatile status at its normal ability end-turn slot.
-- Never cure the holder itself, a fainted ally or an opposing Pokemon.
function Interaction.healerEndTurn(game,ad,b)
  if activeAbility(game,b)~="HEALER"
      or not (ad and ad._st and ad._st.double)
      or not (type(ad.hp)=="function" and type(ad.activeBattlers)=="function"
        and type(ad.status)=="function" and type(ad.clearStatus)=="function"
        and type(ad.roll)=="function")
      or (tonumber(ad:hp(b)) or 0)<=0 then return false end
  for _,ally in ipairs(ad:activeBattlers() or {}) do
    if ally and ally~=b and ally.side==b.side
        and (tonumber(ad:hp(ally)) or 0)>0
        and ad:status(ally) then
      local r=tonumber(ad:roll(0,99))
      if r and r>=0 and r<30 then
        ad:clearStatus(ally)
        return true
      end
    end
  end
  return false
end

return Interaction
