-- Reactive Mega abilities. Only live, active Mega forms qualify.
-- Use native engine action boundaries so the normal battle/save pipeline
-- remains authoritative. No global Ability IDs or ROM edits.
local Reactive = {}

local function megaAbility(game,b)
  if type(game)~="table" or type(game.view)~="function"
      or type(b)~="table" or type(b.mon)~="table" then return nil end
  local view=game.view(b.mon)
  return view and view.ability or nil
end
Reactive.activeAbility=megaAbility

local BALL_MOVES = {
  ACID_SPRAY=true, AURA_SPHERE=true, BARRAGE=true, BEAK_BLAST=true,
  BULLET_SEED=true, EGG_BOMB=true, ELECTRO_BALL=true, ENERGY_BALL=true,
  FOCUS_BLAST=true, GYRO_BALL=true, ICE_BALL=true, MAGNET_BOMB=true,
  MIST_BALL=true, MUD_BOMB=true, OCTAZOOKA=true, POLLEN_PUFF=true,
  PYRO_BALL=true, ROCK_BLAST=true, ROCK_WRECKER=true,
  SEARING_SHOT=true, SEED_BOMB=true, SHADOW_BALL=true, SLUDGE_BOMB=true,
  SYRUP_BOMB=true, WEATHER_BALL=true, ZAP_CANNON=true,
}
local function moveName(move)
  local name=type(move)=="table" and (move.id or move.name) or move
  if type(name)~="string" then return nil end
  return name:upper():gsub("[^A-Z0-9]+","_"):gsub("^_+",""):gsub("_+$","")
end

function Reactive.bulletproofBlocks(game,M)
  if type(M)~="table" or not M.target or M.target==M.user
      or not M.move then return false end
  if megaAbility(game,M.target)~="BULLETPROOF" then return false end
  return BALL_MOVES[moveName(M.move)]==true
end

-- Hit.run runs after the move has been legally chosen (and after Magic
-- Coat's reflection), but before attacks, HP reduction and secondary effects.
-- We must not silently consume PP from the party/save; native M methods do it.
function Reactive.blockBulletproof(game,M)
  if not Reactive.bulletproofBlocks(game,M) then return false end
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

-- Native Engine.forEachTarget calls its body after targeting and immediately
-- before try_bounce(). Setting the *existing* Magic Coat guard for the exact
-- action reuses the full native reflection logic, including Magic-Coat flags,
-- PP handling and the bounced-once guard. Restore the target's original field
-- whether that action succeeds, fails, or raises an error.
function Reactive.withMagicBounce(game,M,body,hasFlag)
  if type(body)~="function" then return nil end
  local target=M and M.target
  local eligible=target and M.user and target~=M.user
    and megaAbility(game,target)=="MAGIC_BOUNCE"
    and M.move and type(hasFlag)=="function"
    and hasFlag(M.move,4)
    and type(M.opts)=="table" and not M.opts.bounced
    and (tonumber(M.move.power) or 0)==0
  if not eligible then return body(M) end
  local original=target.expMagicCoat
  target.expMagicCoat=true
  local results={pcall(body,M)}
  local n=#results
  target.expMagicCoat=original
  if not results[1] then error(results[2],0) end
  return (table.unpack or unpack)(results,2,n)
end

-- Called by Engine.switchOutEffects BEFORE State.syncBattlerToParty. Heal
-- the original live battler; the native sync persists the restored HP.
-- No healing when fainted, and never change the max HP or saved species.
function Reactive.onSwitchOut(game,adapter,b)
  if megaAbility(game,b)~="REGENERATOR" or type(adapter)~="table"
      or type(adapter.hp)~="function" or type(adapter.maxHp)~="function"
      or type(adapter.heal)~="function" then return false end
  local hp,maxHp=tonumber(adapter:hp(b)),tonumber(adapter:maxHp(b))
  if not hp or not maxHp or hp<=0 or maxHp<=0 or hp>=maxHp
      or b.fainted then return false end
  return (tonumber(adapter:heal(b,math.max(1,math.floor(maxHp/3)))) or 0)>0
end

-- Called after actual direct-attack HP damage. Fires when HP crosses from
-- above half to <= half, only if still alive; substitute/blocked/missed moves
-- don't change the true HP and cannot trigger it. Can trigger again only
-- after HP is restored above half and another attack crosses that threshold.
function Reactive.onDamaged(game,M,before,after,Secondary)
  if type(M)~="table" or not M.target or M.target==M.user
      or megaAbility(game,M.target)~="BERSERK"
      or not (Secondary and type(Secondary.changeStat)=="function")
      or not (M.adapter and type(M.adapter.maxHp)=="function") then return false end
  before,after=tonumber(before),tonumber(after)
  local maxHp=tonumber(M.adapter:maxHp(M.target))
  if not before or not after or not maxHp or maxHp<=0 or after<=0
      or before<=math.floor(maxHp/2) or after>math.floor(maxHp/2)
      or after>=before then return false end
  local stages=M.target.stages
  if type(stages)~="table" or (tonumber(stages.spAtk) or 0)>=6 then return false end
  return Secondary.changeStat(M.adapter,M.target,"spAtk",1,
    {user=true})=="worked"
end

return Reactive
