-- Turn-selection bookkeeping for a future ORAS-style Mega Evolution button.
-- PURE STATE: no battle hooks, Pokemon mutations, sprite swaps or item grants.
-- The presentation layer MUST check true battle eligibility before calling arm().
local Selection = {}

local function sideKey(side)
  if side == "player" or side == "enemy" then return side end
  return nil
end

local function isMove(action)
  return type(action) == "table" and action.kind == "move"
end

function Selection.new()
  local self = {}
  local armed = {}      -- one uncommitted selection per side
  local committed = {}  -- side => action with queued Mega request
  local used = {}       -- one successfully activated Mega per side per battle
  local active = {}     -- battler identity => Mega slug (persists when switched out)

  function self.beginBattle()
    armed, committed, used, active = {}, {}, {}, {}
  end

  -- Called while the FIGHT/moves menu is open. A second press disarms.
  -- Eligibility must verify held stone/key stone, form, battle restrictions,
  -- and no Transform/Imposter; this module deliberately does not guess them.
  function self.toggle(side, monKey, slug, eligible)
    side = sideKey(side)
    if not side or monKey == nil or type(slug) ~= "string" or slug == "" then
      return false, "invalid_request"
    end
    if used[side] then return false, "already_mega_evolved" end
    if committed[side] then return false, "mega_move_already_selected" end
    if armed[side] and armed[side].mon == monKey
        and armed[side].slug == slug then
      armed[side] = nil
      return true, "disarmed"
    end
    if eligible ~= true then return false, "ineligible" end
    armed[side] = { mon = monKey, slug = slug }
    return true, "armed"
  end

  -- Only after a VALID move is finally selected (including double-battle target).
  -- Never convert the action into a Mega-only action: it remains kind="move".
  -- The chosen move action is copied so other mods' command objects are unchanged.
  function self.commit(side, monKey, action)
    side = sideKey(side)
    if not side or monKey == nil or not isMove(action) then
      return action, false, "not_a_move"
    end
    local pending = armed[side]
    if not pending or pending.mon ~= monKey then
      return action, false, "not_armed"
    end
    if used[side] or committed[side] then
      armed[side] = nil
      return action, false, "already_reserved"
    end
    local decorated = {}
    for k, value in pairs(action) do decorated[k] = value end
    decorated.megaEvolution = { form = pending.slug, mon = monKey, side = side }
    committed[side] = { action = decorated, mon = monKey, slug = pending.slug }
    armed[side] = nil
    return decorated, true, "committed"
  end

  -- When a turn's move is cancelled (partner backtracking, invalid target, etc.).
  -- A move selection that never reached activation must not spend the one-Mega limit.
  function self.cancel(side, monKey, action)
    side = sideKey(side)
    if not side then return false end
    local removed = false
    if armed[side] and (monKey == nil or armed[side].mon == monKey) then
      armed[side] = nil
      removed = true
    end
    local chosen = committed[side]
    if chosen and (monKey == nil or chosen.mon == monKey)
        and (action == nil or chosen.action == action) then
      committed[side] = nil
      removed = true
    end
    return removed
  end

  -- Called by the eventual battle engine adapter at the transformation point.
  -- Success must indicate that form, ability/stats and animation were safely
  -- applied; no battle resource is spent before that.
  function self.activate(side, monKey, action, success)
    side = sideKey(side)
    if not side or not isMove(action) then return nil, "not_a_move" end
    local chosen = committed[side]
    if not chosen or chosen.mon ~= monKey or chosen.action ~= action then
      return nil, "not_committed"
    end
    if used[side] then return nil, "already_mega_evolved" end
    if success ~= true then return nil, "transformation_not_completed" end
    used[side] = monKey
    active[monKey] = chosen.slug
    committed[side] = nil
    return chosen.slug, "activated"
  end

  -- Switching out preserves the active form. Fainting clears form but never
  -- refunds this side's single Mega Evolution for that battle.
  function self.faint(monKey)
    if monKey == nil then return false end
    local was = active[monKey] ~= nil
    active[monKey] = nil
    return was
  end

  function self.activeForm(monKey)
    return monKey ~= nil and active[monKey] or nil
  end

  function self.status(side, monKey)
    side = sideKey(side)
    if not side then return nil end
    local request = armed[side]
    local chosen = committed[side]
    return {
      used = used[side] ~= nil,
      active = monKey ~= nil and active[monKey] or nil,
      armed = request ~= nil and request.mon == monKey,
      pending = chosen ~= nil and chosen.mon == monKey,
      form = (request and request.mon == monKey and request.slug)
        or (chosen and chosen.mon == monKey and chosen.slug) or nil,
    }
  end

  self.finishBattle = self.beginBattle
  return self
end

return Selection
