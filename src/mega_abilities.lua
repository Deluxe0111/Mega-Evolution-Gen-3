-- Battle-only mechanics for abilities on actively Mega-Evolved Pokémon.
-- Only data-local damage modifiers in this first batch. No global ability
-- IDs, move database edits, save mutation or type-chart replacement.
local Abilities = {}

local PUNCH = {
  COMET_PUNCH=true, MEGA_PUNCH=true, FIRE_PUNCH=true, ICE_PUNCH=true,
  THUNDER_PUNCH=true, MACH_PUNCH=true, DIZZY_PUNCH=true,
  DYNAMIC_PUNCH=true, DYNAMICPUNCH=true, FOCUS_PUNCH=true,
  SHADOW_PUNCH=true, SKY_UPPERCUT=true, HAMMER_ARM=true,
  BULLET_PUNCH=true, DRAIN_PUNCH=true, POWER_UP_PUNCH=true,
  METEOR_MASH=true, ICE_HAMMER=true, PLASMA_FISTS=true,
  DOUBLE_IRON_BASH=true,
}
local BITE = {
  BITE=true, CRUNCH=true, HYPER_FANG=true, FIRE_FANG=true,
  ICE_FANG=true, THUNDER_FANG=true, POISON_FANG=true,
  PSYCHIC_FANGS=true, JAW_LOCK=true, FISHIOUS_REND=true,
}
local PULSE = {
  WATER_PULSE=true, DARK_PULSE=true, DRAGON_PULSE=true,
  AURA_SPHERE=true, ORIGIN_PULSE=true, TERRAIN_PULSE=true,
}
local SLICING = {
  CUT=true, SLASH=true, RAZOR_LEAF=true, FURY_CUTTER=true,
  FALSE_SWIPE=true, AIR_CUTTER=true, LEAF_BLADE=true,
  NIGHT_SLASH=true, CROSS_POISON=true, AIR_SLASH=true,
  X_SCISSOR=true, PSYCHO_CUT=true, RAZOR_SHELL=true,
  SACRED_SWORD=true, SOLAR_BLADE=true, SMART_STRIKE=true,
  BEHEMOTH_BLADE=true, BITTER_BLADE=true, CEASELESS_EDGE=true,
  KOWTOW_CLEAVE=true, MIGHTY_CLEAVE=true, POPULATION_BOMB=false,
}

local function name(move)
  local s=type(move)=="table"
    and (move.id or move.name or move.moveId) or move
  if type(s)~="string" then return nil end
  return (s:upper():gsub("[^A-Z0-9]+","_"):gsub("^_+",""):gsub("_+$",""))
end

-- Avoid knowing or supplying new ability numeric IDs: the live Mega battle
-- view is authoritative and returns nil outside the current transformation.
local function activeAbility(game,b)
  if type(game)~="table" or type(game.view)~="function"
      or type(b)~="table" or type(b.mon)~="table" then return nil end
  local v=game.view(b.mon)
  return v and type(v.ability)=="string" and v.ability~="" and v.ability or nil
end
Abilities.activeAbility=activeAbility

local function effectivePower(move,opts)
  local explicit=opts and tonumber(opts.power)
  return explicit or (type(move)=="table" and tonumber(move.power)) or 0
end
local function isContact(move)
  local flags=type(move)=="table" and tonumber(move.flags)
  -- Gen3 move.flags bit 0 is makes-contact, as in native abilities.contact().
  return flags and flags%2==1 or false
end

-- Called by the existing Damage.base wrapper. It is also called during
-- Damage.calc's base invocation, AFTER variable-power effects were resolved.
-- Replace opts, never mutate the move ROM row or caller's options table.
function Abilities.baseOptions(game,attacker,move,opts)
  local ability=activeAbility(game,attacker)
  if not ability then return opts end
  local power=effectivePower(move,opts)
  if power<=0 or name(move)=="STRUGGLE" then return opts end
  local n,d=1,1
  local moveName=name(move)
  if ability=="TOUGH_CLAWS" and isContact(move) then n,d=13,10
  elseif ability=="TECHNICIAN" and power<=60 then n,d=3,2
  elseif ability=="IRON_FIST" and PUNCH[moveName] then n,d=6,5
  elseif ability=="STRONG_JAW" and BITE[moveName] then n,d=3,2
  elseif ability=="MEGA_LAUNCHER" and PULSE[moveName] then n,d=3,2
  elseif ability=="SHARPNESS" and SLICING[moveName] then n,d=3,2
  elseif ability=="SAND_FORCE"
      and opts and opts.weatherKind=="SAND"
      and ({[4]=true,[5]=true,[8]=true})[tonumber(opts.moveType)
        or (type(move)=="table" and tonumber(move.type))] then
    n,d=13,10
  end
  if n==d then return opts end
  local newOpts={}
  for k,v in pairs(opts or {}) do newOpts[k]=v end
  newOpts.power=math.max(1,math.floor(power*n/d))
  return newOpts
end

-- The Gen3 calculator applies STAB/type matchups AFTER Damage.base, so
-- Adaptability, Filter and Multiscale must run after Damage.calc. We adjust
-- the final result once (never the underlying ROM row or saved Pokemon).
-- This closely matches their multipliers; final rounding may differ by 1
-- from engines that combine modifiers before the last damage roll.
function Abilities.finalDamage(game,attacker,defender,damage,info)
  damage=tonumber(damage)
  if not damage or damage<=0 or type(info)~="table" or info.fixed
      or info.status or info.failed or info.setDamage or info.typeFlags
      and info.typeFlags.immune then return damage,info end
  local aAbility=activeAbility(game,attacker)
  local dAbility=activeAbility(game,defender)
  if aAbility=="ADAPTABILITY" and info.stab==1.5 then
    damage=math.max(1,math.floor(damage*4/3))
  end
  if dAbility=="FILTER" and (tonumber(info.effectiveness) or 1)>1 then
    damage=math.max(1,math.floor(damage*3/4))
  elseif dAbility=="MULTISCALE" then
    local mon=defender and defender.mon
    local hp=tonumber(mon and mon.hp or defender.hp)
    local maxHp=tonumber(mon and mon.maxHp or defender.maxHp)
    if hp and maxHp and maxHp>0 and hp>=maxHp then
      damage=math.max(1,math.floor(damage/2))
    end
  end
  return damage,info
end

return Abilities
