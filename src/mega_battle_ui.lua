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
-- Display-only timeline: battle calculation still transforms immediately.
-- Keep the original Pokémon visible while its silhouette whitens; swap to
-- an entirely white Mega silhouette, then restore the Mega's colours.
local TRANSFORM = { white = 0.48, swap = 0.72, finish = 1.36 }
local WHITE_SHADER = [[
extern float whiten;
vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screenCoords) {
  vec4 pixel = Texel(texture, uv);
  vec3 original = pixel.rgb * color.rgb;
  return vec4(mix(original, vec3(1.0), whiten), pixel.a * color.a);
}
]]

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
  local whiteShader, whiteShaderFailed
  local pendingImage, pendingWhite
  local function loadAsset(key)
    if images[key] then return images[key] end
    if tried[key] then return nil end
    if not (G and type(G.newImage) == "function") then return nil end
    tried[key] = true
    local file = (mod.path or "") .. "/" .. ASSETS[key]
    local ok, img = pcall(G.newImage, file)
    if ok and img then
      -- Keep the original EBDX pixel artwork sharp. In particular, linear
      -- minification on symMega blurred individual sprite pixels.
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

  local function transformAge(mon)
    local fx = self.lastFlash
    if not fx or fx.mon ~= mon then return nil end
    local age = clock() - fx.started
    if age < 0 or age >= TRANSFORM.finish then return nil end
    return age
  end

  function self:onMegaEvolved(battler)
    if not battler or not battler.mon then return end
    self.lastFlash = {started=clock(),mon=battler.mon}
    self.focused = false
  end

  -- Only presentation is delayed. Engine.resolveMove already installed the
  -- temporary Mega form and continues its damage/ability/turn logic normally.
  -- Because Ui.sidePic supplies both old and Mega pictures, keep the real
  -- original image while it whitens and reveal the Mega entirely white.
  function self:choosePicture(mon,back,ordinary,mega)
    if not back or not mon or not mega then return mega or ordinary end
    local age = transformAge(mon)
    if age == nil then return mega end
    local picture,white
    if age < TRANSFORM.swap then
      picture = ordinary or mega
      white = math.min(1, age / TRANSFORM.white)
    else
      picture = mega
      white = math.max(0, (TRANSFORM.finish-age) /
        (TRANSFORM.finish-TRANSFORM.swap))
    end
    -- Ui.sidePic is called inside the battle draw. The temporary render hook
    -- recognises only this exact image; it never whitens the battle backdrop,
    -- HP bar, other battlers, or the expanding Mega emblem.
    pendingImage = picture and picture.image
    pendingWhite = white
    return picture
  end

  local function getWhiteShader()
    if whiteShader then return whiteShader end
    if whiteShaderFailed or not G or not G.newShader then return nil end
    local ok,result = pcall(G.newShader,WHITE_SHADER)
    if not ok or not result then
      whiteShaderFailed = true
      if mod.log and mod.log.warn then
        mod.log:warn("Mega silhouette shader unavailable: %s", tostring(result))
      end
      return nil
    end
    whiteShader = result
    return result
  end

  -- Scope the whitening to a single Ui.draw call, only while transforming.
  -- This composes with Mega atlas' already-scoped pivot correction, and puts
  -- the exact previous graphics.draw and shader back even on an error.
  function self:withTransitionDraw(drawFn,...)
    pendingImage,pendingWhite = nil,nil
    local flash = self.lastFlash
    if not flash or transformAge(flash.mon) == nil or not G
       or type(G.draw) ~= "function"
       or type(G.setShader) ~= "function" or type(G.getShader) ~= "function"
       or not getWhiteShader() then
      return drawFn(...)
    end
    local previous = G.draw
    local busy = false
    local function scoped(image,...)
      if busy or image ~= pendingImage or not pendingWhite or pendingWhite <= 0 then
        return previous(image,...)
      end
      busy = true
      local before = G.getShader()
      local strength = math.max(0,math.min(1,pendingWhite))
      local function packed(...) return {n=select("#",...),...} end
      local result = packed(pcall(function(...)
        whiteShader:send("whiten",strength)
        G.setShader(whiteShader)
        return previous(image,...)
      end,...))
      G.setShader(before)
      busy = false
      if not result[1] then error(result[2],0) end
      return (table.unpack or unpack)(result,2,result.n)
    end
    local replaced = pcall(function() G.draw=scoped end)
    if not replaced then return drawFn(...) end
    local function packed(...) return {n=select("#",...),...} end
    local result = packed(pcall(drawFn,...))
    if G.draw==scoped then G.draw=previous end
    pendingImage,pendingWhite=nil,nil
    if not result[1] then error(result[2],0) end
    return (table.unpack or unpack)(result,2,result.n)
  end

  function self:drawFlash(st)
    local flash = self.lastFlash
    if not flash or not G then return end
    local age = clock() - flash.started
    if age < 0 or age >= TRANSFORM.finish then
      self.lastFlash = nil
      return
    end
    -- Retain the user's favourite expanding Mega symbol, with a longer
    -- easing curve and a more gradual fade while the silhouette changes.
    local img = loadAsset("flash")
    if not img then return end
    local k = math.max(0,math.min(1,age/TRANSFORM.finish))
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
    local age = transformAge(battler.mon)
    if age and age < TRANSFORM.swap then return false end
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
    -- The EBDX source is 26x34. Use exact 1/2 scale on both axes:
    -- a crisp 13x17 badge, not an independently stretched 18x24 one.
    -- Keep its full height BELOW the HP box's name/gender row, in the
    -- lower-left area to the left of the HP bar (single & double battles).
    local s=0.5
    local x=math.floor(barX-18)
    local y=math.floor(barY-2)
    G.push("all")
    G.setColor(1,1,1,1)
    G.draw(img,x,y,0,s,s)
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
  function self:resetTransform()
    self.lastFlash=nil
    pendingImage,pendingWhite=nil,nil
  end
  function self:uninstall()
    self:resetTransform()
    if hbModule and hbModule.draw==wrappedDraw then
      hbModule.draw=originalDraw
    end
  end
  return self
end
return MegaUI
