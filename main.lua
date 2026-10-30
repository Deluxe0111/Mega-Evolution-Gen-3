-- Mega Evolution Gen 3: standalone temporary battle forms + art provider.
-- G9 Battle Sprites owns Pokemon.frontPic/backPic/icon: we never wrap those here.
local function loadSibling(mod, path)
  local source = mod:read(path)
  if not source then return nil end
  local chunk, err = load(source, "@" .. mod.path .. "/" .. path)
  if not chunk then
    if mod.log then mod.log:warn("Mega source could not compile: %s (%s)", path, tostring(err)) end
    return nil
  end
  local ok, value = pcall(chunk)
  if ok then return value end
  if mod.log then mod.log:warn("Mega source could not load: %s (%s)", path, tostring(value)) end
  return nil
end

return function(mod)
  local exports = mod.exports
  exports.apiVersion = 1
  exports.supportedGames = { "gen3" }

  -- Register held Mega Stones through the same public item registry used by
  -- National Dex. Fixed numeric IDs persist in Gen 3 saves; never renumber.
  local itemCatalog = loadSibling(mod, "data/mega_items.lua")
  local formCatalog = loadSibling(mod, "data/mega_forms.lua")
  local ItemRegistry = loadSibling(mod, "src/mega_items.lua")
  local Eligibility = loadSibling(mod, "src/mega_eligibility.lua")
  local checker = Eligibility and formCatalog and itemCatalog
    and Eligibility.new(formCatalog, itemCatalog) or nil
  local registered, itemErrors = {}, {}
  if ItemRegistry and itemCatalog then
    registered, itemErrors = ItemRegistry.register(mod, itemCatalog)
  end
  if mod.log then
    mod.log:info("registered %d Mega items; standalone battle integration loading", #registered)
    for i = 1, math.min(#itemErrors, 4) do
      mod.log:warn("Mega item registration issue: %s", itemErrors[i])
    end
  end
  local presentation = loadSibling(mod, "data/mega_presentation.lua")
  local registeredById = {}
  for _, row in ipairs(registered) do registeredById[row.id] = row.index end

  exports.itemsRegistered = function() return #registered end
  exports.itemId = function(name) return registeredById[name] end
  exports.checkMegaEligibility = function(st, battler)
    if not checker or not st or type(battler) ~= "table" then return nil, "not_ready" end
    local side = battler.side
    if side ~= "player" and side ~= "enemy" then return nil, "invalid_side" end

    -- Trainer NPC items/Key Stones and execution hooks will be implemented
    -- together later; don't offer an enemy a misleading playable request.
    local ownsKeyStone = false
    if side == "player" and registeredById.KEY_STONE and st.session and st.session.bag then
      local okBag, Bag = pcall(require, "src.core.game3.bag")
      if okBag and Bag and type(Bag.has) == "function" then
        local okOwned, has = pcall(Bag.has, st.session.bag, registeredById.KEY_STONE, 1)
        ownsKeyStone = okOwned and has == true
      end
    end
    local species
    local okPokemon, Pokemon = pcall(require, "src.core.game3.pokemon")
    if okPokemon and Pokemon and type(Pokemon.keyName) == "function" then
      local okName, name = pcall(Pokemon.keyName, battler.species)
      if okName then species = name end
    end
    -- National Dex resolves newly registered species through the same engine
    -- Pokemon module, so the original mon's stored species is never rewritten.
    return checker.check({
      battler = battler, species = species, side = side,
      keyStone = ownsKeyStone,
      disabled = st.safari or st.oldManTutorial or st.pokedude or st.link or st.spectate,
    })
  end
  -- This flag means gameplay Mega Evolution is active. Artwork alone is NOT gameplay.
  local gameplayReady = false
  exports.isActive = function() return gameplayReady end

  local provider, failed = nil, false
  local function getProvider()
    if provider then return provider end
    local engine = loadSibling(mod, "src/mega_atlas.lua")
    local index = loadSibling(mod, "assets/runtime/mega_atlas_index.lua")
    if not (type(engine) == "table" and type(engine.new) == "function" and index) then
      if not failed and mod.log then
        mod.log:warn("Mega atlas provider not ready: missing runtime index or module")
        failed = true
      end
      return nil
    end
    local graphics = love and love.graphics
    local timer = function()
      return love and love.timer and love.timer.getTime and love.timer.getTime() or 0
    end
    local value, err = engine.new(mod, index, graphics, timer, presentation)
    if not value then
      if not failed and mod.log then mod.log:warn("Mega atlas is invalid: %s", tostring(err)) end
      failed = true
      return nil
    end
    provider = value
    if mod.log then mod.log:info("Mega art provider ready") end
    return provider
  end

  exports.artAvailable = function() return getProvider() ~= nil end
  exports.hasSprite = function(slug, variant)
    local p = getProvider()
    return p ~= nil and p.hasSprite(slug, variant or "front") or false
  end
  exports.formInfo = function(slug)
    local p = getProvider()
    return p and p.formInfo(slug) or nil
  end
  exports.frameLocation = function(slug, variant, frame)
    local p = getProvider()
    return p and p.locate(slug, variant, frame) or nil
  end
  -- Explicit opt-in image providers. The battle state system must select the
  -- right form for ONE battler; these do not alter regular Pokemon pictures.
  exports.frame = function(slug, variant, frame)
    local p = getProvider()
    return p and p.frame(slug, variant, frame) or nil
  end
  exports.picture = function(slug, side, shiny, frame, battle)
    local p = getProvider()
    return p and p.picture(slug, side, shiny, frame, battle) or nil
  end
  exports.cacheStats = function()
    local p = getProvider()
    return p and p.stats() or nil
  end

  -- Battle form state is entirely temporary. These are Gen 3-specific,
  -- cooperative hooks; on older engines registration fails closed.
  local Selection = loadSibling(mod, "src/mega_selection.lua")
  local Venusaur = loadSibling(mod, "src/mega_venusaur.lua")
  local game = Selection and Venusaur and Venusaur.new(Selection.new(),
    function(st, b) return exports.checkMegaEligibility(st, b) end,
    { hasSprite = exports.hasSprite, picture = exports.picture,
      withBattleDraw = function(drawFn, ...)
        local p = getProvider()
        if p and p.withBattleDraw then
          return p.withBattleDraw(drawFn, ...)
        end
        return drawFn(...)
      end }) or nil

  local Standalone = loadSibling(mod, "src/mega_standalone.lua")
  local ItemIcons = loadSibling(mod, "src/mega_item_icons.lua")
  local bridge, bridgeError
  local iconBridge, iconError
  local failedBridgeMessage
  local function tryInstall()
    if bridge then return true end
    if not (game and Standalone and type(Standalone.install) == "function") then
      bridgeError = "Mega battle module not loaded"
      return false
    end
    local ok, installed, err = pcall(Standalone.install, mod, game)
    if not ok then bridgeError = tostring(installed)
    elseif installed then bridge, bridgeError = installed, nil
    else bridgeError = err end
    gameplayReady = bridge ~= nil
    if bridge then
      if mod.log then mod.log:info("Mega battle bridge installed (stock Gen1Recomp)") end
      return true
    end
    if mod.log and failedBridgeMessage ~= bridgeError then
      failedBridgeMessage = bridgeError
      mod.log:warn("Mega battle bridge unavailable: %s", tostring(bridgeError))
    end
    return false
  end
  local function tryIcons()
    if iconBridge or not (ItemIcons and ItemIcons.install and itemCatalog) then return end
    local ok, installed, err = pcall(ItemIcons.install, mod, itemCatalog)
    if ok and installed then iconBridge, iconError = installed, nil
    else iconError = ok and err or tostring(installed) end
  end

  -- The normal mod entry executes before some game graphics and battle
  -- modules finish initialising. Retry at both game.ready and battle.started
  -- instead of permanently failing after the first early require().
  tryInstall()
  tryIcons()

  if mod.hooks and type(mod.hooks.wrap) == "function" then
    mod.hooks:wrap("battle.overlay", function(next, st)
      next(st)
      if not (st and love and love.graphics) then return end
      local ok, Ui = pcall(require, "src.core.game3.battle.ui")
      if not ok or not Ui or Ui._mode ~= "moves" or Ui._swap then return end
      local id = tonumber(Ui._active) or 0
      local b = st.battlers and st.battlers[id] or
        ((id == 0 and st.player) or (id == 1 and st.enemy))
      if not b then return end
      local label, selectable
      if bridge then
        label, selectable = game.status(st, b)
      elseif tonumber(b.species or (b.mon and b.mon.species)) == 3 then
        label, selectable = "MEGA BRIDGE OFFLINE", false
      else
        return
      end
      if not label then return end
      local g = love.graphics
      g.setColor(0.08, 0.13, 0.23, 0.96)
      g.rectangle("fill", 128, 99, 109, 20, 3, 3)
      g.setColor(selectable and 1 or 0.65, selectable and 0.86 or 0.64, 0.35, 1)
      g.rectangle("line", 128, 99, 109, 20, 3, 3)
      g.setColor(1, 1, 1, 1)
      -- Use a small font so the diagnostic labels fit within the panel.
      local font = g.getFont and g.getFont()
      local width = font and font.getWidth and font:getWidth(label) or 0
      local scale = width > 102 and 102 / width or 1
      g.print(label, 131, 105, 0, scale, scale)
    end)

    -- The visual Mega button is also clickable with mouse/touch. Convert the
    -- viewport-local pointer into the GBA's 240x160 UI coordinates; never
    -- swallow unrelated input or clicks on disabled diagnostic labels.
    mod.hooks:wrap("input.pointer", function(next, host, ev)
      if not bridge or not ev or ev.phase ~= "pressed" or not ev.insideGame then
        return next(host, ev)
      end
      local okUi, Ui = pcall(require, "src.core.game3.battle.ui")
      if not okUi or not Ui or Ui._mode ~= "moves" or Ui._swap then
        return next(host, ev)
      end
      local okDisplay, Display = pcall(require, "src.core.game3.display")
      local okViewport, Viewport = pcall(require, "src.render.GameViewport")
      if not (okDisplay and Display and Display.fit and okViewport and Viewport) then
        return next(host, ev)
      end
      local w, h = Viewport.dimensions()
      local sx, ox, oy, _, _, sy = Display.fit(w, h)
      if not sx or not sy or sx <= 0 or sy <= 0 then return next(host, ev) end
      local x, y = (ev.gameX - ox) / sx, (ev.gameY - oy) / sy
      if x < 128 or x > 237 or y < 99 or y > 119 then
        return next(host, ev)
      end
      local st = Ui._st
      local id = tonumber(Ui._active) or 0
      local b = st and (st.battlers and st.battlers[id]
        or (id == 0 and st.player) or (id == 1 and st.enemy))
      local selectable = false
      if b then
        local _label, canPress = game.status(st, b)
        selectable = canPress == true
      end
      if not selectable then return next(host, ev) end
      if game.input(st, b, { wasPressed = function(_, name) return name == "start" end }) then
        return true
      end
      return next(host, ev)
    end)
  end

  if mod.events and mod.events.on then
    mod.events:on("game.ready", function()
      tryInstall()
      tryIcons()
      getProvider()
    end, 0)
    mod.events:on("battle.started", function()
      tryInstall()
      tryIcons()
    end)
    mod.events:on("battle.turn_ended", function() if bridge then game.turnEnded() end end)
    mod.events:on("battle.ended", function() if bridge then game.finish() end end)
    mod.events:on("battle.battler_switched", function(ev)
      if not bridge then return end
      local ok, Battle = pcall(require, "src.core.game3.battle")
      local st = ok and Battle and Battle.getState and Battle.getState()
      local id = ev and tonumber(ev.battlerId)
      local b = st and id and (st.battlers and st.battlers[id]
        or (id == 0 and st.player) or (id == 1 and st.enemy))
      if b then game.switchedIn(b) end
    end)
    mod.events:on("battle.fainted", function(ev)
      if not bridge then return end
      local ok, Battle = pcall(require, "src.core.game3.battle")
      local st = ok and Battle and Battle.getState and Battle.getState()
      local id = ev and tonumber(ev.battlerId)
      local b = st and id and (st.battlers and st.battlers[id]
        or (id == 0 and st.player) or (id == 1 and st.enemy))
      if b and b.mon then game.fainted(b.mon) end
    end)
  end

  exports.megaDiagnostics = function()
    return {
      bridge = bridge and "installed" or ("offline: " .. tostring(bridgeError)),
      icons = iconBridge and "installed" or ("offline: " .. tostring(iconError)),
      supportedForm = "mega_venusaur",
      keyStoneItem = registeredById.KEY_STONE,
      venusauriteItem = registeredById.VENUSAURITE,
    }
  end

  exports.megaFormOf = function(mon) return gameplayReady and game.activeForm(mon) or nil end
end
