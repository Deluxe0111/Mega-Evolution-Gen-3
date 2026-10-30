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
  local battleForms = loadSibling(mod, "data/mega_battle_forms.lua")
  local ItemRegistry = loadSibling(mod, "src/mega_items.lua")
  local Eligibility = loadSibling(mod, "src/mega_eligibility.lua")
  local checker = Eligibility and formCatalog and itemCatalog
    and Eligibility.new(formCatalog, itemCatalog) or nil
  local registered, itemErrors = {}, {}
  if ItemRegistry and itemCatalog then
    registered, itemErrors = ItemRegistry.register(mod, itemCatalog)
  end
  if mod.log then
    mod.log:info("registered %d Mega items; full-roster battle integration loading", #registered)
    for i = 1, math.min(#itemErrors, 4) do
      mod.log:warn("Mega item registration issue: %s", itemErrors[i])
    end
  end
  local presentation = loadSibling(mod, "data/mega_presentation.lua")
  -- Opt-in development tool; stays out of ordinary player menus by default.
  if mod.options and type(mod.options.define) == "function" then
    mod.options:define({
      { key = "mega_tuner_enabled", label = "MEGA TUNER", type = "toggle",
        default = false },
    })
  end
  local registeredById = {}
  for _, row in ipairs(registered) do registeredById[row.id] = row.index end

  -- Research aide offers the native Poké Mart interface inside Oak/Birch labs.
  -- The Key Stone is ₽10,000; all registered Mega Stones are ₽5,000.
  local LabShop=loadSibling(mod,"src/mega_lab_shop.lua")
  local labShop,labShopError
  if LabShop and type(LabShop.install)=="function" then
    local ok,shop,err=pcall(LabShop.install,mod,itemCatalog,registered)
    if ok then labShop,labShopError=shop,err
    else labShopError=tostring(shop) end
  else
    labShopError="lab shop module unavailable"
  end
  if not labShop and mod.log then
    mod.log:warn("Mega lab fundraising shop unavailable: %s",tostring(labShopError))
  end
  exports.labShopDiagnostics = function()
    return labShop and labShop.diagnostics and labShop.diagnostics()
      or { error=labShopError }
  end

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
    local knowsMegaMove = false
    if species == "RAYQUAZA" and battler.mon and type(battler.mon.moves) == "table" then
      local okMoves, Moves = pcall(require, "src.core.game3.battle.moves")
      if okMoves and Moves and type(Moves.normalizeId) == "function" then
        for _, move in pairs(battler.mon.moves) do
          local okMove, moveName = pcall(Moves.normalizeId, move)
          if okMove and moveName and moveName:gsub("[^A-Z0-9]", "") == "DRAGONASCENT" then
            knowsMegaMove = true
            break
          end
        end
      end
    end
    return checker.check({
      battler = battler, species = species, side = side,
      baseForm = battler.mon and (battler.mon.form or battler.mon.formId) or 0,
      knowsMegaMove = knowsMegaMove,
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
  exports.megaIcon = function(slug, shiny, female)
    local p = getProvider()
    return p and p.icon and p.icon(slug, shiny, female) or nil
  end
  exports.cacheStats = function()
    local p = getProvider()
    return p and p.stats() or nil
  end

  -- Battle form state is entirely temporary. These are Gen 3-specific,
  -- cooperative hooks; on older engines registration fails closed.
  local Selection = loadSibling(mod, "src/mega_selection.lua")
  local MegaBattle = loadSibling(mod, "src/mega_battle.lua")
  local typeIds = {}
  local okTypes, Types = pcall(require, "src.core.game3.battle.types")
  if okTypes and Types and type(Types.ID) == "table" then
    for key, value in pairs(Types.ID) do typeIds[key] = value end
  end
  local game = Selection and MegaBattle and battleForms
    and MegaBattle.new(Selection.new(),
      function(st, b) return exports.checkMegaEligibility(st, b) end,
      { hasSprite = exports.hasSprite, picture = exports.picture,
        withBattleDraw = function(drawFn, ...)
          local p = getProvider()
          if p and p.withBattleDraw then
            return p.withBattleDraw(drawFn, ...)
          end
          return drawFn(...)
        end }, battleForms, typeIds) or nil

  local BattleVisual = loadSibling(mod, "src/mega_battle_ui.lua")
  local battleVisual = game and BattleVisual and BattleVisual.new(mod,game) or nil
  local Standalone = loadSibling(mod, "src/mega_standalone.lua")
  local MegaAbilities = loadSibling(mod, "src/mega_abilities.lua")
  local MegaReactive = loadSibling(mod, "src/mega_reactive_abilities.lua")
  local MegaTactical = loadSibling(mod, "src/mega_tactical_abilities.lua")
  local ItemIcons = loadSibling(mod, "src/mega_item_icons.lua")
  local MegaUI = loadSibling(mod, "src/mega_ui.lua")
  local uiBridge, uiError
  local bridge, bridgeError
  local iconBridge, iconError
  local failedBridgeMessage
  local function tryInstall()
    if bridge then return true end
    if not (game and Standalone and type(Standalone.install) == "function") then
      bridgeError = "Mega battle module not loaded"
      return false
    end
    local ok, installed, err = pcall(Standalone.install, mod, game,
      { MegaAbilities=MegaAbilities, MegaReactive=MegaReactive,
        MegaTactical=MegaTactical }, battleVisual)
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
  local function tryUi()
    if uiBridge or not (bridge and MegaUI and MegaUI.install and game) then return end
    local ok, installed, err = pcall(MegaUI.install,mod,game,{
      picture=exports.picture,
      icon=exports.megaIcon,
    })
    if ok and installed then uiBridge,uiError=installed,nil
    else uiError=ok and err or tostring(installed) end
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
  tryUi()
  if battleVisual then battleVisual:installHealthbox() end

  if mod.hooks and type(mod.hooks.wrap) == "function" then
    -- Proper EBDX two-state Mega button; frame 0=unarmed, frame 1=armed.
    -- The visual overlay never modifies G9's global sprite renderer.
    mod.hooks:wrap("battle.overlay", function(next, st)
      next(st)
      if not (bridge and battleVisual and st) then return end
      local okUi, Ui = pcall(require, "src.core.game3.battle.ui")
      if not okUi or not Ui then return end
      battleVisual:drawOverlay(st,Ui)
    end)

    -- Pointer events are viewport-local: use native GBA coordinates and
    -- the same 0,89,22,22 hotspot occupied by the actual Mega button.
    mod.hooks:wrap("input.pointer", function(next, host, ev)
      if not (bridge and battleVisual and ev and ev.phase == "pressed"
          and ev.insideGame) then return next(host, ev) end
      local okUi, Ui = pcall(require, "src.core.game3.battle.ui")
      if not okUi or not Ui or Ui._mode ~= "moves" or Ui._swap then
        return next(host, ev)
      end
      local okDisplay, Display = pcall(require, "src.core.game3.display")
      local okViewport, Viewport = pcall(require, "src.render.GameViewport")
      if not (okDisplay and Display and Display.fit and okViewport and Viewport) then
        return next(host, ev)
      end
      local w,h = Viewport.dimensions()
      local sx,ox,oy,_,_,sy = Display.fit(w,h)
      if not sx or not sy or sx <= 0 or sy <= 0 then return next(host, ev) end
      local x,y = (ev.gameX - ox)/sx,(ev.gameY - oy)/sy
      if battleVisual:hit(x,y) then
        local st = Ui._st
        local id = tonumber(Ui._active) or 0
        local b = st and (st.battlers and st.battlers[id]
          or (id == 0 and st.player) or (id == 1 and st.enemy))
        if b and battleVisual:toggle(st,b) then return true end
      end
      return next(host, ev)
    end)
  end

  if mod.events and mod.events.on then
    mod.events:on("game.ready", function()
      tryInstall()
      tryIcons()
      tryUi()
      if battleVisual then battleVisual:installHealthbox() end
      getProvider()
    end, 0)
    mod.events:on("battle.started", function()
      tryInstall()
      tryIcons()
      tryUi()
      if battleVisual then battleVisual:installHealthbox() end
    end)
    mod.events:on("battle.turn_ended", function() if bridge then game.turnEnded() end end)
    mod.events:on("battle.ended", function()
      if bridge then game.finish() end
      if battleVisual and battleVisual.resetTransform then
        battleVisual:resetTransform()
      end
    end)
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
      menus = uiBridge and "installed" or ("offline: " .. tostring(uiError)),
      partyIcons = uiBridge and uiBridge.diagnostics and uiBridge.diagnostics() or nil,
      megaButton = battleVisual and "EBDX artwork installed" or "unavailable",
      supportedForms = battleForms and #battleForms or 0,
      keyStoneItem = registeredById.KEY_STONE,
      venusauriteItem = registeredById.VENUSAURITE,
    }
  end

  -- Register a standalone battle-stage preview; it never begins a real fight
  -- or changes game.save/party Pokémon. Adjustments are exported as a complete
  -- Lua presentation file for manual review before importing into the mod.
  local TunerModel = loadSibling(mod, "src/mega_tuner_model.lua")
  local Tuner = loadSibling(mod, "src/mega_calibrator.lua")
  if Tuner and TunerModel and presentation and formCatalog then
    local ok, tuner, err = pcall(Tuner.install, mod, TunerModel, formCatalog,
      presentation, {
        frame = function(slug, kind, frame)
          local p = getProvider()
          return p and p.frame(slug, kind, frame) or nil
        end,
      }, {
        isVisible = function()
          return mod.developer == true or (mod.options
            and type(mod.options.get) == "function"
            and mod.options:get("mega_tuner_enabled") == true)
        end,
      })
    if ok and tuner then
      exports.openMegaTuner = tuner.open
      exports.exportMegaTuning = tuner.export
      exports.megaTuningText = tuner.text
      if mod.log then mod.log:info("Mega battle calibration screen registered") end
    elseif mod.log then
      mod.log:warn("Mega battle calibrator unavailable: %s",
        tostring(ok and err or tuner))
    end
  end

  exports.megaFormOf = function(mon) return gameplayReady and game.activeForm(mon) or nil end
end
