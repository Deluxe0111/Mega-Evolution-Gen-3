-- First playable, battle-only Mega form. No Pokemon record or species slot edits.
-- Uses Gen 3 opt-in battle hooks from the matching engine PR.
local Venusaur = {}

local BASE = { attack = 100, defense = 123, spAtk = 122, spDef = 120, speed = 80 }
local IV_KEY = { attack = "atk", defense = "def", spAtk = "spa", spDef = "spd", speed = "spe" }
local NATURE_KEYS = { "attack", "defense", "speed", "spAtk", "spDef" }
-- Gen III nature index = personality % 25. Neutral indices have no modifiers.
local NATURE = {
  [1] = { 1, 2 }, [2] = { 1, 3 }, [3] = { 1, 4 }, [4] = { 1, 5 },
  [5] = { 2, 1 }, [7] = { 2, 3 }, [8] = { 2, 4 }, [9] = { 2, 5 },
  [10] = { 3, 1 }, [11] = { 3, 2 }, [13] = { 3, 4 }, [14] = { 3, 5 },
  [15] = { 4, 1 }, [16] = { 4, 2 }, [17] = { 4, 3 }, [19] = { 4, 5 },
  [20] = { 5, 1 }, [21] = { 5, 2 }, [22] = { 5, 3 }, [23] = { 5, 4 },
}

local function megaStats(mon)
  if type(mon) ~= "table" then return nil end
  local level = tonumber(mon.level)
  if not level or level < 1 or level > 100 then return nil end
  local nature = NATURE[(tonumber(mon.personality) or 0) % 25]
  local iv, ev = mon.ivs or {}, mon.evs or {}
  local out = {}
  for _, key in ipairs(NATURE_KEYS) do
    local index = IV_KEY[key]
    local b = BASE[key]
    local effort = math.floor((tonumber(ev[index]) or 0) / 4)
    local raw = math.floor(((2 * b + (tonumber(iv[index]) or 0) + effort) * level) / 100) + 5
    local boost = 1
    if nature then
      if NATURE_KEYS[nature[1]] == key then boost = 1.1 end
      if NATURE_KEYS[nature[2]] == key then boost = 0.9 end
    end
    out[key] = math.floor(raw * boost)
  end
  return out
end
Venusaur.megaStats = megaStats

function Venusaur.new(selection, eligibility, art)
  assert(selection and type(eligibility) == "function" and art)
  local battle
  local changes = {}
  local calculated = {}

  local function restore()
    for battler, old in pairs(changes) do
      battler.ability, battler.type1, battler.type2 = old.ability, old.type1, old.type2
    end
    changes, calculated = {}, {}
  end

  local self = {}
  function self.begin(st)
    if not st then return false end
    if st ~= battle then
      restore()
      battle = st
      selection.beginBattle()
    end
    return true
  end

  local function attach(battler)
    local mon = battler and battler.mon
    if not mon or selection.activeForm(mon) ~= "mega_venusaur" then return end
    if not changes[battler] then
      changes[battler] = {
        ability = battler.ability, type1 = battler.type1, type2 = battler.type2,
      }
    end
    -- Both forms are Grass/Poison. The existing types remain authoritative.
    battler.ability = "THICK_FAT"
  end

  function self.input(st, battler, input)
    if not self.begin(st) or type(battler) ~= "table" or not battler.mon then
      return false
    end
    if input:wasPressed("b") then
      selection.cancel("player", battler.mon)
      return false -- let vanilla back-navigation proceed
    end
    if not input:wasPressed("start") then return false end
    local status = selection.status("player", battler.mon)
    if status and (status.used or status.pending) then return false end
    local form = eligibility(st, battler)
    if form ~= "mega_venusaur" then return false end
    if not art.hasSprite(form, "back") or not art.hasSprite(form, "front") then return false end
    selection.toggle("player", battler.mon, form, true)
    return true
  end

  function self.command(st, battler, action)
    if not self.begin(st) or type(action) ~= "table" then return action end
    if action.kind == "cancel_partner" then
      selection.cancel("player")
      return action
    end
    if action.kind ~= "move" or not battler or not battler.mon then return action end
    local selected, ok = selection.commit("player", battler.mon, action)
    return ok and selected or action
  end

  function self.beforeMove(st, action, battler)
    if not self.begin(st) or type(action) ~= "table" or action.kind ~= "move"
        or not battler or not battler.mon or battler.side ~= "player" then return false end
    local mon = battler.mon
    local request = action.megaEvolution
    if not request or request.form ~= "mega_venusaur" or request.mon ~= mon then
      attach(battler) -- preserve existing Mega ability on later turns/switch-ins
      return false
    end
    local status = selection.status("player", mon)
    if not status or status.used or not status.pending or battler.fainted then return false end
    if eligibility(st, battler) ~= "mega_venusaur" then return false end
    local stats = megaStats(mon)
    if not stats or not art.hasSprite("mega_venusaur", "back") then return false end
    local activated = selection.activatePlanned("player", mon, action, true)
    if activated ~= "mega_venusaur" then return false end
    calculated[mon] = stats
    attach(battler)
    return true
  end

  function self.switchedIn(battler)
    -- Re-attach the temporary ability when State.makeBattler constructs
    -- a new live battler for the same already-Mega party mon.
    attach(battler)
  end

  function self.stat(battler, key, vanilla)
    local mon = battler and battler.mon
    if not mon or selection.activeForm(mon) ~= "mega_venusaur" then return vanilla end
    attach(battler)
    return (calculated[mon] and calculated[mon][key]) or vanilla
  end

  function self.picture(battler, back, shiny, fallback)
    local mon = battler and battler.mon
    if not mon or selection.activeForm(mon) ~= "mega_venusaur" then return fallback end
    attach(battler)
    local pic = art.picture("mega_venusaur", back and "back" or "front", shiny)
    return pic or fallback
  end

  function self.status(st, battler)
    if not self.begin(st) or not battler or not battler.mon then return nil end
    local state = selection.status("player", battler.mon)
    if not state or state.used or state.pending then return nil end
    if eligibility(st, battler) ~= "mega_venusaur" then return nil end
    return state.armed and "MEGA READY" or "START: MEGA"
  end

  function self.turnEnded()
    -- Unexecuted decisions (cancelled targets, battle interruptions) never
    -- spend the single Mega allowance or leak into the next turn.
    selection.cancel("player")
  end

  function self.fainted(mon)
    if not mon then return end
    selection.faint(mon)
    calculated[mon] = nil
    for b, _ in pairs(changes) do
      if b.mon == mon then
        local old = changes[b]
        b.ability, b.type1, b.type2 = old.ability, old.type1, old.type2
        changes[b] = nil
      end
    end
  end

  function self.finish()
    restore()
    selection.finishBattle()
    battle = nil
  end
  function self.activeForm(mon) return selection.activeForm(mon) end
  return self
end

return Venusaur
