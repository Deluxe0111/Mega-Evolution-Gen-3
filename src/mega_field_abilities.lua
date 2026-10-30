-- Batch 9: Fairy Aura, Eelevate, Thermal Exchange, Innards Out and
-- Power Construct compatibility. Only live Mega forms; no save/ROM edits.
local Field={}
local function view(game,b)
  return type(game)=="table" and type(game.view)=="function"
    and type(b)=="table" and b.mon and game.view(b.mon) or nil
end
local function ability(game,b)
  local v=view(game,b)
  return v and v.ability or nil
end
Field.activeAbility=ability
local function living(b)
  return b and b.mon and (tonumber(b.mon.hp) or 0)>0 and not b.fainted
end
local function activeBattlers(adapter)
  if not (adapter and type(adapter.activeBattlers)=="function") then return {} end
  return adapter:activeBattlers() or {}
end
local function typeId(key,types)
  local ok,P=pcall(require,"src.core.game3.progression")
  if ok and P and type(P.typeIndexFor)=="function" then
    local success,num=pcall(P.typeIndexFor,key)
    if success and num~=nil then return num end
  end
  return types and types.ID and types.ID[key] or nil
end

-- Fairy Aura applies to EVERY combatant's Fairy attacks as long as any
-- living Mega Floette has the aura. Never add multiple aura boosts.
function Field.fairyPower(game,st,adapter,move,opts,types)
  local t=tonumber(opts and opts.moveType)
    or (type(move)=="table" and tonumber(move.type))
  local fairy=typeId("FAIRY",types)
  if fairy==nil or fairy~=t then return opts end
  local power=tonumber(opts and opts.power)
    or (type(move)=="table" and tonumber(move.power)) or 0
  if power<=0 then return opts end
  local aura,breakAura=false,false
  for _,b in ipairs(activeBattlers(adapter)) do
    if living(b) then
      if ability(game,b)=="FAIRY_AURA" then aura=true end
      local ab=adapter.abilityOf and adapter:abilityOf(b)
      if ab=="AURA_BREAK" then breakAura=true end
    end
  end
  if not aura then return opts end
  local copy={}
  for k,v in pairs(opts or {}) do copy[k]=v end
  -- Exact Fairy Aura factor is 5448/4096; Aura Break reverses it.
  copy.power=math.max(1,math.floor(power*(breakAura and 3072 or 5448)/4096))
  return copy
end

-- Eelevate combines Levitate with Beast Boost. Reusing native LEVITATE
-- lookup also preserves Ground immunity and Gen3 Spikes immunity without
-- rewriting the type chart or editing battler ability IDs.
function Field.withEelevate(game,adapter,body)
  if type(body)~="function" then return nil end
  if not (adapter and type(adapter.abilityOf)=="function") then
    return body()
  end
  local original=adapter.abilityOf
  adapter.abilityOf=function(self,b,...)
    if ability(game,b)=="EELEVATE"
        and not b.expSmackDown and not b.expIngrain
        and not (self._st and self._st.gravityTurns and self._st.gravityTurns>0) then
      return "LEVITATE"
    end
    return original(self,b,...)
  end
  local result={pcall(body)}
  adapter.abilityOf=original
  if not result[1] then error(result[2],0) end
  return (table.unpack or unpack)(result,2,#result)
end

local STATS={"attack","defense","spAtk","spDef","speed"}
function Field.eelevateKO(game,M,Secondary)
  local user,target=M and M.user,M and M.target
  local ad=M and M.adapter
  if not (user and target and user~=target and user.side~=target.side
    and living(user) and ability(game,user)=="EELEVATE"
    and ad and type(ad.hp)=="function" and ad:hp(target)<=0
    and Secondary and type(Secondary.changeStat)=="function") then return false end
  M._megaEelevateKOs=M._megaEelevateKOs or {}
  if M._megaEelevateKOs[target] then return false end
  M._megaEelevateKOs[target]=true
  local v=view(game,user)
  local stats=(v and v.stats) or user.mon or {}
  local best,highest=nil,-math.huge
  for _,stat in ipairs(STATS) do
    local n=tonumber(stats[stat]) or -math.huge
    if n>highest then highest,best=n,stat end
  end
  if not best or highest<0 then return false end
  return Secondary.changeStat(ad,user,best,1,{user=true})=="worked"
end

-- After real Fire-type HP damage, Thermal Exchange gives +1 Attack.
-- Invulnerability from burn applies to native status application guard.
function Field.thermalDamage(game,M,dealt,hadSub,moveType,types,Secondary)
  local b=M and M.target
  if not (b and M.user and b~=M.user and living(b)
      and ability(game,b)=="THERMAL_EXCHANGE" and not hadSub
      and not M.hitSubstitute and (tonumber(dealt) or 0)>0
      and moveType==typeId("FIRE",types)
      and Secondary and type(Secondary.changeStat)=="function") then
    return false
  end
  return Secondary.changeStat(M.adapter,b,"attack",1,{user=true})=="worked"
end
function Field.withBurnImmunity(game,ad,body)
  if type(body)~="function" then return nil end
  if not (ad and type(ad.canApplyStatus)=="function") then return body() end
  local old=ad.canApplyStatus
  ad.canApplyStatus=function(self,b,status,...)
    if ability(game,b)=="THERMAL_EXCHANGE"
        and (status=="BRN" or status=="BURN") then
      return false,"thermal_exchange"
    end
    return old(self,b,status,...)
  end
  local res={pcall(body)}
  ad.canApplyStatus=old
  if not res[1] then error(res[2],0) end
  return (table.unpack or unpack)(res,2,#res)
end

-- Innards Out activates only if an opposing attack knocked out the holder,
-- and retaliates for the target's REMAINING HP immediately before that hit.
-- Already-announced fainting and multi-hit attacks are guarded by context.
function Field.innardsOut(game,M,before,after,hadSub)
  local b=M and M.target
  local user=M and M.user
  local ad=M and M.adapter
  if not (b and user and b~=user and b.side~=user.side
      and ability(game,b)=="INNARDS_OUT"
      and not hadSub and not M.hitSubstitute
      and tonumber(before) and tonumber(before)>0
      and tonumber(after) and tonumber(after)<=0
      and ad and type(ad.applyHpLoss)=="function") then return false end
  M._megaInnardsOut=M._megaInnardsOut or {}
  if M._megaInnardsOut[b] then return false end
  M._megaInnardsOut[b]=true
  ad:applyHpLoss(user,math.floor(before))
  if type(M.tryFaintUser)=="function" then M:tryFaintUser() end
  return true
end

-- Mega Zygarde forms already enter as Complete Forme (216 base HP).
-- Power Construct must NOT perform a second transformation at half HP.
function Field.powerConstructAlreadyComplete(game,b)
  local v=view(game,b)
  if not (v and v.ability=="POWER_CONSTRUCT") then return false end
  return v.slug=="mega_zygarde" or v.slug=="mega_zygarde_form_5"
end

return Field
