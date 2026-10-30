-- Pokémon Champions Mega abilities, scoped to active Gen3 battle forms.
-- Live battler state only: never alter ROM move rows, global type data,
-- saved Pokémon, weather, or another mod's ability registry.
local Champions={}

local function ability(game,b)
  if type(game)~="table" or type(game.view)~="function"
      or type(b)~="table" or type(b.mon)~="table" then return nil end
  local v=game.view(b.mon)
  return v and v.ability or nil
end
Champions.activeAbility=ability

local function bit(flags,index)
  return math.floor((tonumber(flags) or 0)/index)%2==1
end

local function typeId(name,Types)
  if Types and Types.ID and Types.ID[name]~=nil then
    return Types.ID[name]
  end
  local ok,Progression=pcall(require,"src.core.game3.progression")
  if ok and Progression and type(Progression.typeIndexFor)=="function" then
    local success,id=pcall(Progression.typeIndexFor,name)
    if success then return id end
  end
  return nil
end

-- Fire Mane: stronger Fire moves, regardless of physical/special category.
-- Called inside Damage.base after Damage.calc has already resolved type.
function Champions.powerOptions(game,b,move,opts,Types)
  if ability(game,b)~="FIRE_MANE" then return opts end
  local power=tonumber(opts and opts.power)
    or (type(move)=="table" and tonumber(move.power)) or 0
  local t=tonumber(opts and opts.moveType)
    or (type(move)=="table" and tonumber(move.type))
  local fire=typeId("FIRE",Types)
  if power<=0 or not fire or t~=fire then return opts end
  local copy={}
  for k,v in pairs(opts or {}) do copy[k]=v end
  copy.power=math.max(1,math.floor(power*3/2))
  return copy
end

-- Aura Guard: only contact-based attacks deal half damage.
-- The other form's defence changes remain in the normal Mega stat view.
function Champions.defensiveDamage(game,attacker,defender,move,amount,info)
  if ability(game,defender)~="AURA_GUARD"
      or not (type(move)=="table" and bit(move.flags,1))
      or type(amount)~="number" or amount<=0
      or (info and (info.status or info.fixed or info.setDamage
        or info.failed or (info.typeFlags and info.typeFlags.immune))) then
    return amount,info
  end
  return math.max(1,math.floor(amount/2)),info
end

-- Mega Sol affects the holder's moves, NEVER the ambient battle weather.
-- Existing damage calculation handles Sun-boosted Fire, weakened Water,
-- Weather Ball's type/power and Solar Beam's charging penalty.
function Champions.weatherOptions(game,b,opts)
  if ability(game,b)~="MEGA_SOL" then return opts end
  local copy={}
  for k,v in pairs(opts or {}) do copy[k]=v end
  copy.weatherKind="SUN"
  return copy
end

function Champions.noSolarCharge(game,ctx)
  if not ctx or ability(game,ctx.user)~="MEGA_SOL" then
    return false
  end
  local mv=ctx.move
  local name=type(mv)=="table"
    and (mv.id or mv.name or mv.moveId) or mv
  if type(name)~="string" then return false end
  name=name:upper():gsub("[^A-Z0-9]+","_")
  return name=="SOLAR_BEAM" or name=="SOLAR_BLADE"
end

-- Piercing Drill (Champions) and updated Unseen Fist both allow contact
-- moves through Protect/Detect, but only one-quarter of the regular damage.
-- Temporarily override the single move's protected check; no global flags
-- or protections are disabled. Magic Coat and other filters remain native.
function Champions.withPiercingProtect(game,M,body)
  if type(body)~="function" then return nil end
  local user,target=M and M.user,M and M.target
  local move=M and M.move
  local ab=ability(game,user)
  local qualified=(ab=="PIERCING_DRILL" or ab=="UNSEEN_FIST")
    and target and target~=user and type(move)=="table"
    and bit(move.flags,1) and bit(move.flags,2)
    and type(M.isProtected)=="function" and M:isProtected()
  if not qualified then return body(M) end
  -- Native contexts inherit isProtected from their metatable. Restore
  -- the original *raw* field so the temporary override leaves no residue.
  local old=rawget(M,"isProtected")
  local oldMarker=rawget(M,"_megaQuarterProtect")
  M.isProtected=function()return false end
  M._megaQuarterProtect=true
  local result={pcall(body,M)}
  M.isProtected=old
  M._megaQuarterProtect=oldMarker
  if not result[1] then error(result[2],0) end
  return (table.unpack or unpack)(result,2,#result)
end

function Champions.piercingDamage(game,M,attacker,defender,amount,info)
  if not (M and M._megaQuarterProtect and attacker and defender
      and (attacker==M.user or
        (attacker.mon and M.user and attacker.mon==M.user.mon))
      and (defender==M.target or
        (defender.mon and M.target and defender.mon==M.target.mon))
      and type(amount)=="number" and amount>0
      and not (info and (info.status or info.fixed or info.setDamage
        or info.failed or (info.typeFlags and info.typeFlags.immune)))) then
    return amount,info
  end
  return math.max(1,math.floor(amount/4)),info
end

-- Spicy Spray: a genuinely damaging hit to the Mega Scovillain's HP
-- burns the attacker. Native applyStatus rejects Fire types, existing
-- statuses, Safeguard and protective abilities. Substitute damage does
-- NOT count; recoil/environmental damage is not a damaging attack.
function Champions.afterDamage(game,M,dealt,hadSub)
  local ad=M and M.adapter
  local user,target=M and M.user,M and M.target
  if not (ad and user and target and user~=target
      and ability(game,target)=="SPICY_SPRAY"
      and type(M.move)=="table"
      and (tonumber(M.move.power) or 0)>0
      and (tonumber(dealt) or 0)>0
      and not hadSub and not M.hitSubstitute
      and type(ad.applyStatus)=="function") then return false end
  local applied=ad:applyStatus(user,"BRN",target)
  if applied and type(ad.statusAnim)=="function" then
    ad:statusAnim(user,"BRN")
  end
  return applied==true
end

return Champions
