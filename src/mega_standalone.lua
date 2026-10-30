-- Standalone Gen 3 bridge. No Gen1Recomp patch or custom engine hook needed.
-- We wrap existing exported Lua entrypoints, retain the original chains, and
-- never replace Pokemon.frontPic/backPic (owned by G9 Battle Sprites).
local Standalone = {}

local function current(st, id)
  if not st then return nil end
  id = tonumber(id) or 0
  if st.battlers then return st.battlers[id] end
  return (id == 0 and st.player) or (id == 1 and st.enemy) or nil
end

local function cloneBattler(b, game)
  if type(b) ~= "table" or type(b.mon) ~= "table" then return b end
  local values, modified = {}, false
  for _, key in ipairs({ "attack", "defense", "spAtk", "spDef" }) do
    local stat = game.stat(b, key, nil)
    if stat ~= nil then values[key], modified = stat, true end
  end
  if not modified then return b end
  -- Copy just the view used by Damage.base: no party Pokémon/save mutation,
  -- including while exceptions or other mods are computing damage.
  local copy, mon = {}, {}
  for k, v in pairs(b) do copy[k] = v end
  for k, v in pairs(b.mon) do mon[k] = v end
  for k, v in pairs(values) do mon[k] = v end
  copy.mon = mon
  return copy
end

function Standalone.install(mod, game, modules)
  if type(game) ~= "table" then return nil, "missing Mega controller" end
  local req = modules and modules.require or require
  local function required(name)
    local ok, value = pcall(req, name)
    if not ok or type(value) ~= "table" then return nil end
    return value
  end
  local Ui = modules and modules.Ui or required("src.core.game3.battle.ui")
  local Engine = modules and modules.Engine or required("src.core.game3.battle.engine")
  local Damage = modules and modules.Damage or required("src.core.game3.battle.damage")
  local Battle = modules and modules.Battle or required("src.core.game3.battle")
  if not (Ui and Engine and Damage and Battle
      and type(Ui.handleInput) == "function"
      and type(Ui.takeCommand) == "function"
      and type(Ui.sidePic) == "function"
      and type(Engine.resolveMove) == "function"
      and type(Damage.base) == "function"
      and type(Battle.start) == "function"
      and type(Battle.reset) == "function") then
    return nil, "expected Gen 3 battle entrypoints unavailable"
  end

  local active = true
  local wrapped = {}
  local function enabled()
    if active and mod.enabled == false then
      game.finish()
      return false
    end
    return active
  end
  local function wrap(holder, key, body)
    local prev = holder[key]
    local func = function(...) return body(prev, ...) end
    holder[key] = func
    wrapped[#wrapped + 1] = { holder = holder, key = key, ours = func, old = prev }
  end

  wrap(Ui, "handleInput", function(next, input)
    if enabled() and Ui._mode == "moves" and Ui.waitingForCommand
        and Ui.waitingForCommand() and not Ui._swap then
      local st = Ui._st
      local b = current(st, Ui._active or 0)
      if b and game.input(st, b, input) then return true end
    end
    return next(input)
  end)

  wrap(Ui, "takeCommand", function(next)
    local action = next()
    if not enabled() or not action then return action end
    local st = Ui._st
    local id = type(action) == "table" and action.battler or Ui._active
    local b = current(st, id or 0)
    return game.command(st, b, action)
  end)

  wrap(Engine, "resolveMove", function(next, user, target, move, slot, adapter, st, out, opts)
    if enabled() and st and not st.link and not st.spectate then
      local battler = type(user) == "table" and user or current(st, user)
      -- The turn planner may force Encore/Choice/etc. Recheck the exact
      -- *resolved* move and slot, never spend the Mega on a changed move.
      if battler then game.beforeResolved(st, battler, move, slot) end
    end
    return next(user, target, move, slot, adapter, st, out, opts)
  end)

  wrap(Damage, "base", function(next, attacker, defender, move, opts)
    if not enabled() then return next(attacker, defender, move, opts) end
    return next(cloneBattler(attacker, game), cloneBattler(defender, game), move, opts)
  end)

  wrap(Ui, "sidePic", function(next, back, ignoreDeoxys, picSp, form, shiny, personality, mon)
    local ordinary = next(back, ignoreDeoxys, picSp, form, shiny, personality, mon)
    if not enabled() or not mon then return ordinary end
    local st = Ui._st
    if not (st and Battle._active and Battle._st == st) then return ordinary end
    -- The existing Ui.sidePic already receives the real mon pointer. The
    -- original provider is evaluated FIRST (including G9's wrappers), and
    -- non-Mega battlers always keep its result untouched.
    return game.monPicture(st, mon, back, shiny, ordinary)
  end)

  wrap(Battle, "start", function(next, opts)
    if enabled() then game.finish() end
    return next(opts)
  end)

  wrap(Battle, "reset", function(next, ...)
    if enabled() then game.finish() end
    return next(...)
  end)

  local bridge = {}
  function bridge.uninstall()
    if not active then return end
    active = false
    game.finish()
    -- Undo only if our wrapper is still on top; later mods must keep the
    -- chain they installed. Otherwise our closure remains a pass-through.
    for i = #wrapped, 1, -1 do
      local w = wrapped[i]
      if w.holder[w.key] == w.ours then w.holder[w.key] = w.old end
    end
  end
  return bridge
end

return Standalone
