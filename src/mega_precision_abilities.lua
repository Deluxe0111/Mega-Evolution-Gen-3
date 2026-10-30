-- Standard modern abilities on active Mega forms. Keep all move,
-- target and battle contexts local: no shared engine or ROM mutation.
local Precision={}

local function ability(game,b)
  if type(game)~="table" or type(game.view)~="function"
      or type(b)~="table" or type(b.mon)~="table" then return nil end
  local v=game.view(b.mon)
  return v and v.ability or nil
end
Precision.activeAbility=ability

local function pack(f,...)
  local r={pcall(f,...)}
  if not r[1] then error(r[2],0) end
  return (table.unpack or unpack)(r,2,#r)
end

local function withFields(fields,body)
  local old={}
  for _,entry in ipairs(fields) do
    old[#old+1]={object=entry.object,key=entry.key,value=entry.object[entry.key]}
    entry.object[entry.key]=entry.value
  end
  local res={pcall(body)}
  for i=#old,1,-1 do
    local e=old[i]
    e.object[e.key]=e.value
  end
  if not res[1] then error(res[2],0) end
  return (table.unpack or unpack)(res,2,#res)
end

-- Unseen Fist bypasses Protect/Detect only on contact moves. Let the
-- context's own isProtected() continue to handle every other move, including
-- status/noncontact moves. Do not erase the target's protect state.
function Precision.withUnseenFist(game,M,body)
  if type(body)~="function" then return nil end
  local move=M and M.move
  local flags=tonumber(move and move.flags) or 0
  local contact=flags%2==1
  local protectable=math.floor(flags/2)%2==1
  if not (M and M.target and M.user and M.target~=M.user
      and contact and protectable and type(M.isProtected)=="function"
      and ability(game,M.user)=="UNSEEN_FIST") then return body(M) end
  return withFields({
    {object=M,key="isProtected",value=function()return false end},
  },function()return body(M)end)
end

-- Stalwart ignores redirection such as Follow Me and Lightning Rod in doubles.
-- Use native getMoveTarget()/resolveTarget(), but with the opponent side's
-- redirection fields temporarily absent and its redirecting ability hidden.
-- Existing selected target IDs, fallback targeting and native RNG are kept.
function Precision.withStalwart(game,st,adapter,attacker,move,body)
  if type(body)~="function" then return nil end
  if not (st and st.double and type(adapter)=="table"
      and attacker and ability(game,attacker)=="STALWART"
      and type(adapter.foeSide)=="function") then return body() end
  local side=adapter:foeSide(attacker)
  if type(side)~="table" then return body() end
  local entries={
    {object=side,key="expFollowMeId",value=nil},
    {object=side,key="expFollowMe",value=nil},
  }
  if type(adapter.abilityOf)=="function" then
    local original=adapter.abilityOf
    entries[#entries+1]={object=adapter,key="abilityOf",value=function(self,b,...)
      local ab=original(self,b,...)
      if b~=attacker and (ab=="LIGHTNING_ROD" or ab=="STORM_DRAIN") then
        return nil
      end
      return ab
    end}
  end
  return withFields(entries,body)
end

-- Parental Bond's native hit loop already provides PP, accuracy, substitute,
-- faint, Endure, target and animation semantics. Temporarily use a copy of
-- the single-hit move with hits=2. Only damage on hit two is quartered,
-- via the existing Damage.calc wrapper (before animation/Endure adjustment).
-- Never trigger it for status, spread, fixed damage or natural multihit moves.
local EXCLUDE={
  MULTI_HIT=true,DOUBLE_HIT=true,TWINEEDLE=true,
  DRAGON_RAGE=true,SONICBOOM=true,LEVEL_DAMAGE=true,
  SUPER_FANG=true,ENDEAVOR=true,PSYWAVE=true,
  COUNTER=true,MIRROR_COAT=true,OHKO=true,
  EXPLOSION=true,TRIPLE_KICK=true,BEAT_UP=true,
}
function Precision.parentalEligible(game,M,effects)
  local move=M and M.move
  if not (move and M.target and M.user and M.target~=M.user
      and ability(game,M.user)=="PARENTAL_BOND") then return false end
  local power=tonumber(move.power) or 0
  local target=tonumber(move.target) or 0
  if power<=0 or (target~=0 and target~=1 and target~=2 and target~=4)
      or (tonumber(move.hits) or 1)>1
      or type(move.hits)=="table" then return false end
  if type(effects)=="table" then
    for key in pairs(EXCLUDE) do
      if effects[key]~=nil and tonumber(M.effect)==tonumber(effects[key]) then
        return false
      end
    end
  end
  return true
end

function Precision.withParentalBond(game,M,body,effects)
  if type(body)~="function" then return nil end
  if not Precision.parentalEligible(game,M,effects) then return body(M) end
  local cloned={}
  for k,v in pairs(M.move) do cloned[k]=v end
  cloned.hits=2
  return withFields({
    {object=M,key="move",value=cloned},
    {object=M,key="_megaParentalBond",value=true},
  },function()return body(M)end)
end

function Precision.parentalDamage(game,ctx,attacker,defender,damage,info)
  if not (ctx and ctx._megaParentalBond
      and (tonumber(ctx.hitsLanded) or 0)>=1
      and ability(game,ctx.user)=="PARENTAL_BOND"
      and type(damage)=="number" and damage>0
      and not (info and (info.status or info.fixed or info.setDamage or
        info.failed or (info.typeFlags and info.typeFlags.immune)))) then
    return damage,info
  end
  -- Damage.calc receives either the live battler or a temporary stat clone.
  if not (attacker and defender
      and (attacker==ctx.user
        or (attacker.mon and attacker.mon==ctx.user.mon))
      and (defender==ctx.target
        or (defender.mon and defender.mon==ctx.target.mon))) then
    return damage,info
  end
  return math.max(1,math.floor(damage/4)),info
end

-- Steadfast activates when the native engine actually consumes flinch and
-- cancels the move, not just when a flinch flag was set earlier in the turn.
function Precision.afterMove(game,b,hadFlinch,Secondary,adapter)
  if not (hadFlinch and b and not b.flinched and b.expUnableToMove
      and ability(game,b)=="STEADFAST" and Secondary
      and type(Secondary.changeStat)=="function" and adapter) then
    return false
  end
  return Secondary.changeStat(adapter,b,"speed",1,{user=true})=="worked"
end

return Precision
