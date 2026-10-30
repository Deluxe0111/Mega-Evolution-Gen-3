-- Non-combat battle-view calibrator. Uses the *actual* normalized Mega
-- animation quads and native Gen 3 battlefield background. No SAVE/battler
-- manipulation, fake NPCs, captures, money or battle rule side effects.
local Calibrator = {}
local SCREEN = "MegaBattleCalibrator"
local OUTPUT = "mega_presentation_export.lua"

local function label(slug)
  return tostring(slug):gsub("^mega_", ""):gsub("_", " "):upper()
end

local function tryModule(path)
  local ok, result = pcall(require, path)
  return ok and result or nil
end

local function drawText(g, str, x, y, sx)
  g.setColor(0.94, 0.98, 1, 1)
  g.print(tostring(str), x, y, 0, sx or 1, sx or 1)
end

function Calibrator.install(mod, modelModule, forms, presentation, atlas, opts)
  if not (mod and mod.content and mod.content.screens
      and mod.hooks and mod.ui and modelModule and atlas and #forms > 0) then
    return nil, "Gen 3 tool screen services unavailable"
  end
  opts = opts or {}
  local exportName = opts.exportName or OUTPUT
  local bg = opts.background or tryModule("src.core.game3.battle.bg")
  local G = opts.graphics or (love and love.graphics)
  -- API2's generic mod.ui.push targets old Gen1 Screens; the existing
  -- Gen3 bridge is explicitly required for a Gen3 registered screen.
  local screenBridge = opts.screenBridge or tryModule("src.ui.game3.mod_ui")
  local pushScreen = opts.pushScreen or (screenBridge and screenBridge.push)
  if type(pushScreen) ~= "function" then
    return nil, "Gen 3 custom screen bridge not available"
  end
  local lastExport
  local lastModel
  local function export(game, model)
    local body = model:exportLua()
    lastExport = body
    local stored, detail = false, nil
    -- Primary safe persistent installation-wide export, independent of a
    -- particular save slot and never touching the user's Pokémon SAVE.
    if mod.cache and type(mod.cache.write) == "function" then
      local ok, a, b = pcall(mod.cache.write, mod.cache, "exports/" .. exportName, body)
      stored = ok and a == true
      detail = not stored and (ok and b or a) or nil
    end
    -- A second shareable .lua file in the mod's compatibility directory.
    -- Sandboxed LegacyCompat redirects this path to mod_compat/<mod-id>/;
    -- it cannot overwrite the packaged data/mega_presentation.lua.
    local direct = false
    if opts.writeFile then
      local ok, a = pcall(opts.writeFile, exportName, body)
      direct = ok and a == true
    elseif love and love.filesystem and love.filesystem.write then
      local ok, a = pcall(love.filesystem.write, exportName, body)
      direct = ok and a == true
    end
    return stored or direct, detail, body
  end

  local Screen = {}
  Screen.__index = Screen

  function Screen.new(game)
    local self = setmetatable({
      game = game,
      gbaCanvas = true, kind = "mega_calibrator",
      isMenu = true, isOpaque = true, mode = "browse",
      model = modelModule.new(forms, presentation),
      seconds = 0, message = "", messageTimer = 0,
    }, Screen)
    lastModel = self.model
    return self
  end
  function Screen:exit() end
  function Screen:update(dt)
    self.seconds = self.seconds + math.max(0, dt or 1/60)
    if self.messageTimer > 0 then self.messageTimer = self.messageTimer - (dt or 1/60) end
    local key = self.game and self.game.input
    if not (key and key.wasPressed) then return end
    local m = self.model
    local function pressed(k) return key:wasPressed(k) end

    if pressed("start") then
      local ok, err = export(self.game, m)
      self.message = ok and ("EXPORTED: " .. exportName)
        or ("EXPORT FAILED: " .. tostring(err or "storage unavailable"))
      self.messageTimer = 7
      return
    end
    if pressed("select") then m:toggleSide(); return end
    if m.mode == "browse" then
      if pressed("left") then m:moveForm(-1)
      elseif pressed("right") then m:moveForm(1)
      elseif pressed("up") then m:moveForm(-10)
      elseif pressed("down") then m:moveForm(10)
      elseif pressed("a") then m.mode = "tune"
      elseif pressed("b") and self.game and self.game.stack then
        self.game.stack:pop()
      end
    else
      if pressed("up") then m:nextField(-1)
      elseif pressed("down") then m:nextField(1)
      elseif pressed("left") then m:adjust(-1)
      elseif pressed("right") then m:adjust(1)
      elseif pressed("a") then m:toggleShiny()
      elseif pressed("b") then m.mode = "browse"
      end
    end
  end

  local function drawFrame(slug, side, shiny, index, seconds, row)
    local kind = side .. (shiny and "_shiny" or "")
    local sprite = atlas.frame(slug, kind, math.floor(seconds * 8))
    if not (sprite and sprite.image and sprite.quad) then return false end
    local scale = tonumber(row.scale) or 1
    local feet = tonumber(row.feet) or sprite.h or 64
    local baseline = tonumber(row.baseline) or (side == "back" and 57 or 62)
    local cx, cy = side == "back" and 72 or 176, side == "back" and 76 or 40
    -- Exactly the same source-space calculation as Atlas.battleLayout:
    -- 64px standard battle pic has a (32,32) pivot. The crop offset
    -- restores its original position without re-grounding any animation.
    local x = cx - sprite.w * scale / 2 + (tonumber(row.dx) or 0)
      + (tonumber(sprite.cropX) or 0) * scale
    local y = cy - 32 + baseline - feet * scale + (tonumber(row.dy) or 0)
      + (tonumber(sprite.cropY) or 0) * scale
    G.setColor(1, 1, 1, 1)
    G.draw(sprite.image, sprite.quad, x, y, 0, scale, scale)
    return true
  end

  function Screen:draw()
    if not G then return end
    local m = self.model
    G.push("all")
    if G.origin then G.origin() end
    if G.setScissor then G.setScissor() end
    G.setColor(0.91, 0.97, 0.87, 1)
    G.rectangle("fill", 0, 0, 240, 160)
    -- Real native FRLG/RSE battle background if available; preview remains
    -- usable before battle assets finish loading.
    if bg and bg.draw then
      local ok, drew = pcall(bg.draw, nil, 0, 0, 0)
      if not ok or drew == false then
        G.setColor(.59,.84,.54,1)
        G.ellipse("fill",176,64,51,13)
        G.ellipse("fill",72,100,55,16)
      end
    else
      G.setColor(.59,.84,.54,1)
      G.ellipse("fill",176,64,51,13)
      G.ellipse("fill",72,100,55,16)
    end

    local slug = m:slug()
    local sides = m.edits[slug]
    for _, side in ipairs({"front","back"}) do
      local kind = side .. (m.shiny and "_shiny" or "")
      local row = sides[kind] or sides[side]
      drawFrame(slug, side, m.shiny, m.index, self.seconds, row)
    end

    -- Native-sized battle playfield + developer controls overlay.
    G.setColor(0.07, 0.13, 0.23, .94)
    G.rectangle("fill", 0, 0, 240, 25)
    G.rectangle("fill", 0, 112, 240, 48)
    G.setColor(.96,.83,.36,1)
    G.rectangle("line", 0.5, 0.5, 239, 24)
    G.rectangle("line", 0.5, 112.5, 239, 47)
    drawText(G, ("%02d/%02d  %s"):format(m.index,#m.forms,label(slug)), 5, 3, .8)
    local selected = sides[m.side .. (m.shiny and "_shiny" or "")] or sides[m.side]
    drawText(G, ("EDIT %s %s  %s"):format(m.side:upper(),
      m.shiny and "SHINY" or "NORMAL",m.mode:upper()), 5, 15, .68)
    if m.mode == "browse" then
      drawText(G, "D-PAD: CHOOSE MEGA   A: ADJUST", 6, 115, .72)
      drawText(G, "SELECT: SIDE   START: EXPORT", 6, 128, .72)
      drawText(G, "B: EXIT       MODIFIED: " .. m:countChanged(), 6, 141, .72)
    else
      local field = m:fieldName()
      drawText(G, field:upper() .. " = " .. tostring(selected[field]), 6, 115, .86)
      drawText(G, "UP/DOWN FIELD  LEFT/RIGHT +/-", 6, 128, .69)
      drawText(G, "A SHINY  SELECT SIDE  START SAVE", 6, 141, .65)
    end
    if self.messageTimer > 0 then
      G.setColor(.1,.2,.13,.98)
      G.rectangle("fill",4,91,232,19)
      drawText(G,self.message,7,95,.69)
    end
    G.pop()
  end

  local ok, err = pcall(mod.content.screens.register, mod.content.screens,
    SCREEN, {new = function(game) return Screen.new(game) end})
  if not ok then return nil, tostring(err) end

  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" then return out end
    if opts.isVisible and not opts.isVisible() then return out end
    local row = { label = "MEGA TUNER",
      onSelect = function()
        pushScreen(game, SCREEN)
      end }
    if mod.ui.insertBefore then
      return mod.ui.insertBefore(out, "SAVE", row)
    end
    out[#out + 1] = row
    return out
  end)

  local facade = {}
  function facade.export(game)
    return export(game, lastModel or modelModule.new(forms, presentation))
  end
  function facade.text()
    return lastExport or (lastModel and lastModel:exportLua()) or nil
  end
  function facade.open(game)
    return pushScreen(game, SCREEN)
  end
  return facade
end

return Calibrator
