-- Opt-in artwork overlay for the existing stock-Gen3 Mega controller.
-- Exact EBDX assets, no global Pokémon picture hooks or engine modification.
local MegaUI = {}
local ROOT = "assets/source/ebdx/ui_reference/Graphics/EBDX/Pictures/"
local ASSETS = {
  button = ROOT .. "UI/megaButton.png", -- 88x44: 44x44 inactive | active
  badge = ROOT .. "UI/symMega.png",     -- 26x34 HP-bar badge
  flash = ROOT .. "mega_sym.png",        -- 30x30 transformation emblem
}
local BX, BY, BW, BH = 0, 89, 22, 22  -- flush left, above moves at y=111

local function resolve(st, id)
  if not st then return nil end
  id = tonumber(id) or 0
  if st.battlers then return st.battlers[id] end
  return id == 0 and st.player or id == 1 and st.enemy or nil
end

function MegaUI.new(mod, game, opts)
  assert(game and game.input and game.status and game.activeForm)
  opts = opts or {}
  local G = opts.graphics or (love and love.graphics)
  local clock = opts.time or function()
    return love and love.timer and love.timer.getTime and love.timer.getTime() or 0
  end
  local req = opts.require or require
  local images, tried = {}, {}
  local warn = {}
  local self = {focused = false, lastFlash = nil}
  local function loadAsset(key)
    if images[key] then return images[key] end
    if tried[key] then return nil end
    if not (G and type(G.newImage) == "function") then return nil end
    tried[key] = true
    local file = (mod.path or "") .. "/" .. ASSETS[key]
    local ok, img = pcall(G.newImage, file)
    if ok and img then
      if img.setFilter then img:setFilter("nearest", "nearest") end
      images[key] = img
      return img
    end
    if not warn[key] and mod.log and mod.log.warn then
      warn[key] = true
      mod.log:warn("Missing Mega %s: %s", key, file)
    end
    return nil
  end

  function self:available(st, battler)
    if not battler or not battler.mon or battler.side ~= "player" then
      return false, false
    end
    local label, canPress = game.status(st, battler)
    if canPress ~= true then return false, false end
    return true, label == "MEGA READY"
  end

  function self:hit(x, y)
    return type(x)=="number" and type(y)=="number"
      and x >= BX and x < BX + BW and y >= BY and y < BY + BH
  end

  function self:toggle(st, battler)
    local available = self:available(st, battler)
    if not available then return false end
    local consumed = game.input(st, battler, {
      wasPressed = function(_, name) return name == "start" end
    })
    return consumed == true
  end

  -- START remains the original binding. LEFT from a left-column move
  -- focuses the button, A toggles it, and RIGHT/B returns to move slots.
  -- This does not replace the game's native selection or target handling.
  function self:handleInput(ui, st, battler, input)
    if not (ui and ui._mode == "moves" and input and input.wasPressed) then
      self.focused = false
      return false
    end
    local available = self:available(st, battler)
    if not available then self.focused = false; return false end
    if self.focused then
      if input:wasPressed("a") then return self:toggle(st, battler) end
      if input:wasPressed("right") or input:wasPressed("b") then
        self.focused = false
        return true
      end
      -- A direction must not make the base move cursor select another row
      -- while the Mega button is keyboard-focused.
      if input:wasPressed("left") or input:wasPressed("up") or
         input:wasPressed("down") then return true end
      return false
    end
    local idx = tonumber(ui._moveIndex) or 1
    if input:wasPressed("left") and ui.moveGridNavigation
      and ui.moveGridNavigation() and idx % 2 == 1 then
      self.focused = true
      return true
    end
    return false
  end

  function self:drawButton(st, ui)
    if not G or not ui or ui._mode ~= "moves" or ui._swap then
      self.focused = false
      return false
    end
    local battler = resolve(st, ui._active or 0)
    local available, armed = self:available(st, battler)
    if not available then self.focused = false; return false end
    local img = loadAsset("button")
    if not img then return false end
    local w,h = img:getDimensions()
    if w < 2 or h < 1 or not G.newQuad then return false end
    local fw = math.floor(w / 2) -- 44px states for current 88x44 PNG
    local q = G.newQuad(armed and fw or 0, 0, fw, h, w, h)
    local sx,sy = BW/fw, BH/h
    G.push("all")
    G.setColor(1,1,1,1)
    G.draw(img, q, BX, BY, 0, sx, sy)
    if self.focused then
      G.setColor(1,1,1,1)
      G.rectangle("line",BX,BY,BW-1,BH-1)
      G.rectangle("line",BX+2,BY+2,BW-5,BH-5)
    end
    G.pop()
    return true
  end

  function self:onMegaEvolved(battler)
    if not battler or not battler.mon then return end
    self.lastFlash = {started=clock(),mon=battler.mon}
    self.focused = false
  end

  function self:drawFlash(st)
    local flash = self.lastFlash
    if not flash or not G then return end
    local age = clock() - flash.started
    if age < 0 or age > 0.7 then self.lastFlash = nil; return end
    -- The 30x30 EBDX Mega emblem briefly blooms over the player battler.
    local img = loadAsset("flash")
    if not img then return end
    local k = math.max(0, math.min(1,age/0.7))
    local scale = 0.6 + 0.9*k
    local alpha = 1-k
    local side = resolve(st,0)
    if not side or side.mon ~= flash.mon then return end
    local w,h = img:getDimensions()
    G.push("all")
    G.setColor(1,1,1,alpha)
    G.draw(img,72,68,0,scale,scale,w/2,h/2)
    G.pop()
  end

  function self:drawOverlay(st, ui)
    if not st or not G then return end
    self:drawButton(st,ui)
    self:drawFlash(st)
  end

  -- Overlay a small active-only symMega badge immediately LEFT of each
  -- native HP bar. Use Healthbox.center() and animation offsets instead of
  -- guessing absolute positions for Emerald, FireRed and double battles.
  function self:drawHealthBadge(side, battler, opts, modules)
    if not (battler and battler.mon and game.activeForm(battler.mon) and G)
      then return false end
    local img=loadAsset("badge")
    if not img then return false end
    local H=modules and modules.Healthbox
    if not H or type(H.center) ~= "function" then return false end
    local st=opts and opts.st
    local id=type(side)=="number" and side or (side=="enemy" and 1 or 0)
    local c=H.center(st,id)
    if not c then return false end
    local isPlayer=(id%2==0)
    local Anim=modules and modules.Anim
    local stage=Anim and Anim.stage and Anim.stage()
    local hb=stage and stage.healthbox and (stage.healthbox[side]
      or stage.healthbox[id]
      or stage.healthbox[isPlayer and "player" or "enemy"])
    if hb and hb.visible == false then return false end
    local ox=(hb and hb.ox or 0)+(opts and opts.ox or 0)
    local oy=(opts and opts.oy or 0)
    if st and st.double then oy=oy+(hb and hb.oy or 0) end
    -- Stock: player HP bar starts cx, enemy starts cx-8.
    local barX=c.x+ox+(isPlayer and 0 or -8)
    local barY=c.y+oy
    local w,h=img:getDimensions()
    local s=math.min(11/w,13/h)
    G.push("all")
    G.setColor(1,1,1,1)
    G.draw(img,math.floor(barX-12),math.floor(barY-5),0,s,s)
    G.pop()
    return true
  end

  local originalDraw, wrappedDraw, hbModule
  function self:installHealthbox(modules)
    if wrappedDraw then return true end
    local H = modules and modules.Healthbox
    if not H then
      local ok,v=pcall(req,"src.core.game3.battle.healthbox")
      H=ok and v or nil
    end
    if not H or type(H.draw) ~= "function" then return false end
    local Anim=modules and modules.Anim
    if not Anim then
      local ok,v=pcall(req,"src.core.game3.battle.anim")
      Anim=ok and v or nil
    end
    originalDraw = H.draw
    hbModule=H
    wrappedDraw=function(side,battler,opts)
      local result=originalDraw(side,battler,opts)
      if mod.enabled ~= false then
        self:drawHealthBadge(side,battler,opts,{Healthbox=H,Anim=Anim})
      end
      return result
    end
    H.draw=wrappedDraw
    return true
  end
  function self:uninstall()
    if hbModule and hbModule.draw==wrappedDraw then
      hbModule.draw=originalDraw
    end
  end
  return self
end
return MegaUI
