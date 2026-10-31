-- Gen3 Mega ability edge cases. Battle-local wrappers, native state restored
-- even when the target action raises. Never change ROM moves or type IDs.
local Edge={}

local function ability(game,b)
  if not (type(game)=="table" and type(game.view)=="function"
    and type(b)=="table" and type(b.mon)=="table") then return nil end
  local v=game.view(b.mon)
  return v and v.ability or nil
end
local function pack(...)
  return {n=select("#",...),...}
end
local function invoke(body,...)
  local r=pack(pcall(body,...))
  if not r[1] then error(r[2],0) end
  return (table.unpack or unpack)(r,2,r.n)
end

-- The stock Ctx:accuracyCheck rejects ON_AIR/UNDERGROUND/UNDERWATER
-- before the public accuracy hook. Clear ONLY the targeted battler's
-- transient semi-invulnerability during this one target action. Protect,
-- immunity and the move's own charging state remain native.
function Edge.withNoGuard(game,M,body)
  if type(body)~="function" then return nil end
  local target=M and M.target
  if not (target and M.user and target~=M.user
      and target.semiInvulnerable
      and (ability(game,M.user)=="NO_GUARD"
        or ability(game,target)=="NO_GUARD")) then
    return body(M)
  end
  local semi=target.semiInvulnerable
  target.semiInvulnerable=nil
  local result=pack(pcall(body,M))
  target.semiInvulnerable=semi
  if not result[1] then error(result[2],0) end
  return (table.unpack or unpack)(result,2,result.n)
end

-- Modern Prankster: opponent Dark-type battlers cannot be targeted by
-- status moves whose priority is increased by the user's Prankster.
-- Do not block allies, self-targets or ordinary damaging moves.
function Edge.pranksterBlocks(game,M,Types)
  local user,target=M and M.user,M and M.target
  local move=M and M.move
  if not (user and target and target~=user and user.side~=target.side
      and ability(game,user)=="PRANKSTER" and type(move)=="table"
      and (tonumber(move.power) or 0)==0) then return false end
  local dark=Types and Types.ID and Types.ID.DARK or 17
  return target.type1==dark or target.type2==dark
end

function Edge.blockPrankster(game,M,Types)
  if not Edge.pranksterBlocks(game,M,Types) then return false end
  if type(M.attackString)~="function" or type(M.ppReduce)~="function"
      or type(M.sayId)~="function" then return false end
  M:attackString()
  M:ppReduce()
  M:sayId("STRINGID_ITDOESNTAFFECT",{def=M.target})
  M.noEffect=true
  if type(M.anim)=="table" then
    M.anim.missed=true
    M.anim.statusOnly=true
  end
  return true
end

-- The native Gen3 multi-hit loop calls Secondary.withChance ONCE after
-- all hits. Parental Bond's cloned two-hit move should instead roll the
-- qualifying non-self secondary separately after each damaging hit.
function Edge.parentalHitSecondary(game,M,dealt,Secondary,EffectIds)
  if not (M and M._megaParentalBond
      and ability(game,M.user)=="PARENTAL_BOND"
      and M.target and M.user~=M.target
      and type(Secondary)=="table"
      and type(Secondary.withChance)=="function"
      and EffectIds and type(EffectIds.SECONDARY)=="table") then
    return false
  end
  local spec=EffectIds.SECONDARY[M.effect]
  if not (spec and spec.eff and not spec.user) then return false end
  if (tonumber(dealt) or 0)<=0 or M.hitSubstitute then return false end
  -- The native post-loop roll must be skipped even if this hit KO'd
  -- its target (in which case no secondary can be inflicted).
  M._megaParentalSecondaryApplied=true
  local ad=M.adapter
  if ad and type(ad.isFainted)=="function" and ad:isFainted(M.target) then
    return false
  end
  M._megaParentalDuringHit=true
  local r=pack(pcall(Secondary.withChance,M,spec.eff,spec.certain,spec.user))
  M._megaParentalDuringHit=nil
  if not r[1] then error(r[2],0) end
  return true
end

function Edge.skipPostParentalSecondary(game,M,eff,EffectIds)
  if not (M and M._megaParentalBond and M._megaParentalSecondaryApplied
      and not M._megaParentalDuringHit
      and ability(game,M.user)=="PARENTAL_BOND"
      and EffectIds and EffectIds.SECONDARY) then return false end
  local spec=EffectIds.SECONDARY[M.effect]
  return spec and not spec.user and spec.eff==eff or false
end

-- Yawn is special: the native Gen3 end-turn handler uses
-- applyStatus(...,force=true) and always prints a sleep message. Block
-- initial Yawn against a grounded terrain-protected target; if Yawn was
-- already queued before Electric Terrain, silently expire it on its
-- due turn. Only suppress if terrain will still be active AFTER the
-- weather-continuation phase decrements the terrain timer.
function Edge.blockTerrainYawn(Weather,ctx)
  if not (Weather and Weather.terrainBlocksSleep
      and ctx and ctx.adapter and ctx.target
      and Weather.terrainBlocksSleep(ctx.adapter._st,ctx.target,ctx.adapter)) then
    return false
  end
  if ctx.adapter.sayText then
    ctx.adapter:sayText("STRINGID_ITDOESNTAFFECT",{def=ctx.target})
  end
  return true
end

function Edge.suppressDueYawn(Weather,adapter,body)
  if type(body)~="function" then return nil end
  local st=adapter and adapter._st
  local timer=tonumber(st and st.megaElectricTerrainTurns) or 0
  if timer<=1 or not (Weather and Weather.grounded)
      or type(adapter.activeBattlers)~="function" then
    return body(adapter)
  end
  local cancelled={}
  for _,b in ipairs(adapter:activeBattlers() or {}) do
    if b and (tonumber(b.expYawnTurns) or 0)==1
        and Weather.grounded(b,adapter) then
      -- Native Yawn would set both to nil on resolution; do that now
      -- rather than let it force sleep and incorrectly announce success.
      cancelled[#cancelled+1]={b=b,turns=b.expYawnTurns,yawn=b.yawnTurns}
      b.expYawnTurns=nil
      b.yawnTurns=nil
    end
  end
  local r=pack(pcall(body,adapter))
  if not r[1] then
    for _,v in ipairs(cancelled) do
      v.b.expYawnTurns=v.turns
      v.b.yawnTurns=v.yawn
    end
    error(r[2],0)
  end
  return (table.unpack or unpack)(r,2,r.n)
end

return Edge
