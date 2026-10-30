-- Mega Evolution Gen 3: artwork provider, not battle mechanics.
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
    mod.log:info("registered %d Mega items; battle transformation not yet enabled", #registered)
    for i = 1, math.min(#itemErrors, 4) do
      mod.log:warn("Mega item registration issue: %s", itemErrors[i])
    end
  end
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
  exports.isActive = function() return false end

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
    local value, err = engine.new(mod, index, graphics, timer)
    if not value then
      if not failed and mod.log then mod.log:warn("Mega atlas is invalid: %s", tostring(err)) end
      failed = true
      return nil
    end
    provider = value
    if mod.log then mod.log:info("Mega art provider ready; battle mechanics not installed") end
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
  exports.picture = function(slug, side, shiny, frame)
    local p = getProvider()
    return p and p.picture(slug, side, shiny, frame) or nil
  end
  exports.cacheStats = function()
    local p = getProvider()
    return p and p.stats() or nil
  end

  -- No Pokemon mutation and no graphics function hooks. A later battle
  -- adapter will consume the explicit provider once ownership is resolved.
  if mod.events and mod.events.on then
    mod.events:on("game.ready", function() getProvider() end, 0)
  end
end
