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

-- Prefer the cartridge's crisp Gen 3 small font. Fractional scaling the
-- default LÖVE font made the earlier HUD badly blurred/unreadable.
local function drawText(g, nativeFont, str, x, y)
  str = tostring(str)
  if nativeFont and type(nativeFont.draw) == "function" then
    local opts = { small = true, maxWidth = 232,
      colors = nativeFont.COLOR and nativeFont.COLOR.WHITE }
    local ok = pcall(nativeFont.draw, str, x, y, opts)
    if ok then return end
  end
  -- Fallback keeps integer pixels even if the ROM font is unavailable.
  g.setColor(1, 1, 1, 1)
  g.print(str, x, y)
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
  local font = opts.font or tryModule("src.ui.game3.frlg_font")
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
      isMenu = true, isOpaque = true,
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
    local input = self.game and self.game.input
    if not (input and input.wasPressed) then return end
    local m = self.model
    local function pressed(k) return input:wasPressed(k) end
    local heldB = type(input.isDown) == "function" and input:isDown("b")

    if pressed("start") then
      local ok, err = export(self.game, m)
      if ok then
        -- Start saves the COMPLETE table then leaves the screen. A failed
        -- write keeps it open so unexported edits aren't lost.
        m.saved = true
        if self.game and self.game.stack then self.game.stack:pop() end
      else
        self.message = "SAVE FAILED - TRY AGAIN"
        self.messageTimer = 7
        if mod.log then mod.log:warn("Mega tuner export failed: %s", tostring(err)) end
      end
      return
    end
    -- GBA shoulder buttons L/R browse; d-pad never changes species.
    if pressed("l") then m:moveForm(-1); return end
    if pressed("r") then m:moveForm(1); return end
    if pressed("a") then m:toggleSide(); return end
    if pressed("select") then m:toggleShiny(); return end

    -- B is a held modifier. B+Up/Down scales, otherwise D-pad moves.
    -- Consuming B alone does not exit the calibration session.
    if heldB then
      if pressed("up") then m:scale(1)
      elseif pressed("down") then m:scale(-1) end
    else
      if pressed("left") then m:move(-1, 0)
      elseif pressed("right") then m:move(1, 0)
      elseif pressed("up") then m:move(0, -1)
      elseif pressed("down") then m:move(0, 1) end
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

    -- Integer-aligned, high-contrast HUD with the native Gen 3 pixel
    -- font. Never scale text fractionally or print over the animation.
    G.setColor(0.065, 0.11, 0.20, 0.98)
    G.rectangle("fill", 0, 0, 240, 31)
    G.rectangle("fill", 0, 116, 240, 44)
    G.setColor(0.92, 0.77, 0.30, 1)
    G.rectangle("fill", 0, 30, 240, 2)
    G.rectangle("fill", 0, 114, 240, 2)
    local selected = sides[m.side .. (m.shiny and "_shiny" or "")] or sides[m.side]
    drawText(G, font, ("%02d/%02d  %s"):format(m.index,#m.forms,label(slug)), 4, 0)
    drawText(G, font, ("%s  %s  X:%+d Y:%+d  Z:%.2f"):format(
      m.side:upper(),m.shiny and "SHINY" or "NORMAL",
      tonumber(selected.dx) or 0,tonumber(selected.dy) or 0,
      tonumber(selected.scale) or 1), 4, 15)
    drawText(G, font, "L/R: POKEMON     A: SWITCH SIDE", 4, 116)
    drawText(G, font, "D-PAD: MOVE      B+UP/DN: SCALE", 4, 130)
    drawText(G, font, "SELECT: SHINY      START: SAVE", 4, 144)
    if self.messageTimer > 0 then
      G.setColor(0.24, 0.07, 0.07, 0.99)
      G.rectangle("fill", 0, 96, 240, 18)
      drawText(G, font, self.message, 4, 96)
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
