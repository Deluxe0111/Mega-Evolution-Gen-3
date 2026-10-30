-- Specialised abilities used by the Mega form roster.
-- Scoped to active Mega battlers; never edit ROM move records or saved mons.
local Special={}

local IGNORABLE={
  LEVITATE=true,WONDER_GUARD=true,FLASH_FIRE=true,WATER_ABSORB=true,
  VOLT_ABSORB=true,LIGHTNING_ROD=true,STURDY=true,SOUNDPROOF=true,
  FILTER=true,MULTISCALE=true,MAGIC_BOUNCE=true,BULLETPROOF=true,
  SHELL_ARMOR=true,BATTLE_ARMOR=true,THICK_FAT=true,
  INSOMNIA=true,VITAL_SPIRIT=true,IMMUNITY=true,LIMBER=true,
  WATER_VEIL=true,MAGMA_ARMOR=true,CLEAR_BODY=true,WHITE_SMOKE=true,
  HYPER_CUTTER=true,KEEN_EYE=true,OWN_TEMPO=true,INNER_FOCUS=true,
  SHIELD_DUST=true,SAND_VEIL=true,
}
local FORCE_EFFECT={
  POISON=true,BURN=true,FREEZE=true,PARALYSIS=true,
  FLINCH=true,CONFUSION=true,TOXIC=true,TRI_ATTACK=true,
  ATK_MINUS_1=true,DEF_MINUS_1=true,SPD_MINUS_1=true,
  SP_ATK_MINUS_1=true,SP_DEF_MINUS_1=true,ACC_MINUS_1=true,
  EVA_MINUS_1=true,SP_ATK_TWO_DOWN=true,
}
local function active(game,b)
  if type(game)~="table" or type(game.view)~="function"
      or type(b)~="table" or type(b.mon)~="table" then return nil end
  local view=game.view(b.mon)
  return view and view.ability or nil
end
Special.activeAbility=active

function Special.sheerForceQualifies(game,b,move,effectIds)
  if active(game,b)~="SHEER_FORCE" or type(move)~="table"
      or (tonumber(move.power) or 0)<=0
      or not effectIds then return false end
  local effect=tonumber(move.effect)
  local spec=effect and effectIds.SECONDARY and effectIds.SECONDARY[effect]
  if effect==effectIds.SECRET_POWER then return true end
  return spec and not spec.user and FORCE_EFFECT[spec.eff]==true or false
end

function Special.baseOptions(game,b,move,opts,effectIds)
  if not Special.sheerForceQualifies(game,b,move,effectIds) then return opts end
  local power=tonumber(opts and opts.power) or tonumber(move.power)
  if not power or power<=0 then return opts end
  local copy={}
  for k,v in pairs(opts or {}) do copy[k]=v end
  copy.power=math.max(1,math.floor(power*13/10))
  return copy
end

function Special.suppressSecondary(game,M,effectIds)
  return M and Special.sheerForceQualifies(game,M.user,M.move,effectIds)
end

-- Mold Breaker ignores the named target's suppressible defensive abilities,
-- not unrelated allies or contact-response effects such as Rough Skin.
-- Temporarily mark the target for Mega custom defences, and intercept native
-- adapter:abilityOf lookups. Restore both fields if an attack raises.
function Special.withMoldBreaker(game,M,body)
  if type(body)~="function" then return nil end
  local target=M and M.target
  local user=M and M.user
  local ad=M and M.adapter
  if not (target and user and target~=user and ad
      and type(ad.abilityOf)=="function"
      and active(game,user)=="MOLD_BREAKER") then return body(M) end
  local old=ad.abilityOf
  local oldFlag=target._megaIgnoreDefensiveAbility
  target._megaIgnoreDefensiveAbility=true
  ad.abilityOf=function(self,b,...)
    local ability=old(self,b,...)
    if b==target and IGNORABLE[ability] then return nil end
    return ability
  end
  local result=table.pack and table.pack(pcall(body,M))
    or {pcall(body,M)}
  ad.abilityOf=old
  target._megaIgnoreDefensiveAbility=oldFlag
  if not result[1] then error(result[2],0) end
  return (table.unpack or unpack)(result,2,result.n or #result)
end

-- Invert stat changes at native Secondary.changeStat. A positive change
-- becomes a loss and vice versa, using native caps/animations/messages.
function Special.contraryDelta(game,b,delta)
  local n=tonumber(delta)
  if n and n~=0 and active(game,b)=="CONTRARY" then return -n end
  return delta
end

-- Gen3's MULTI_HIT roll is two rng(0,3) calls for a possible 2..5 hits.
-- Only intercept these two calls while running a qualifying Skill Link move.
-- Fixed two-hit attacks are not changed, and unrelated rng ranges pass on.
function Special.withSkillLink(game,M,body,effectIds)
  if type(body)~="function" then return nil end
  local move=M and M.move
  local ad=M and M.adapter
  local variable=move and effectIds and
    (tonumber(M.effect)==tonumber(effectIds.MULTI_HIT)
      or type(move.hits)=="table")
  if not (variable and ad and type(ad.roll)=="function"
      and active(game,M.user)=="SKILL_LINK") then return body(M) end
  local old=ad.roll
  local remaining=2
  ad.roll=function(self,lo,hi,...)
    if remaining>0 and tonumber(lo)==0 and tonumber(hi)==3 then
      local answer=remaining==2 and 2 or 3
      remaining=remaining-1
      return answer
    end
    return old(self,lo,hi,...)
  end
  local result=table.pack and table.pack(pcall(body,M))
    or {pcall(body,M)}
  ad.roll=old
  if not result[1] then error(result[2],0) end
  return (table.unpack or unpack)(result,2,result.n or #result)
end

return Special
