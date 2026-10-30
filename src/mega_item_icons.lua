-- Register EBDX stone icons against both native Gen 3 Bag renderers.
-- No engine source/ROM changes. Ordinary items always use previous icon code.
local Icons = {}

local function numeric(id)
  return tonumber(id) or (type(id) == "table" and tonumber(id.index)) or nil
end

function Icons.install(mod, rows, opts)
  local req = opts and opts.require or require
  local graphics = opts and opts.graphics or (love and love.graphics)
  if not graphics or type(graphics.newImage) ~= "function"
      or type(graphics.draw) ~= "function" then
    return nil, "Love graphics not ready"
  end
  local byNumber = {}
  for _, row in ipairs(rows or {}) do
    if type(row.index) == "number" or tonumber(row.index) then
      byNumber[tonumber(row.index)] = row
    end
  end
  local loaded = {}
  local warned = {}
  local function icon(id)
    local row = byNumber[numeric(id)]
    if not row then return nil, false end
    local key = row.id
    if loaded[key] ~= nil then return loaded[key] or nil, true end
    local file = (key == "KEY_STONE")
      and "assets/source/ebdx/ui_reference/MEGARING.png"
      or ("assets/source/ebdx/mega_stones/" .. key .. ".png")
    local ok, image = pcall(graphics.newImage, mod.path .. "/" .. file)
    if ok and image then
      if image.setFilter then image:setFilter("nearest", "nearest") end
      loaded[key] = image
    else
      loaded[key] = false
      if mod.log and not warned[key] then
        warned[key] = true
        mod.log:warn("Mega icon not found for %s (%s)", key, file)
      end
    end
    return loaded[key] or nil, true
  end

  local installs = {}
  local function attach(path)
    local ok, chrome = pcall(req, path)
    if not ok or type(chrome) ~= "table"
        or type(chrome.drawItemIcon) ~= "function" then return false end
    local prior = chrome.drawItemIcon
    local wrapped
    if path == "src.ui.game3.rse.bag_chrome" then
      wrapped = function(id, x, y, rotation, ox, oy)
        local image = icon(id)
        if not image then return prior(id, x, y, rotation, ox, oy) end
        local w, h = image:getDimensions()
        if not w or not h or w <= 0 or h <= 0 then return prior(id, x, y, rotation, ox, oy) end
        graphics.setColor(1, 1, 1, 1)
        graphics.draw(image, x or 0, y or 0, rotation or 0,
          24 / w, 24 / h, (ox or 0) * w / 24, (oy or 0) * h / 24)
        return true
      end
    else
      wrapped = function(id, x, y, scale)
        local image = icon(id)
        if not image then return prior(id, x, y, scale) end
        local w, h = image:getDimensions()
        if not w or not h or w <= 0 or h <= 0 then return prior(id, x, y, scale) end
        local mul = tonumber(scale) or 1
        graphics.setColor(1, 1, 1, 1)
        graphics.draw(image, x or 0, y or 0, 0, mul * 24 / w, mul * 24 / h)
        return true
      end
    end
    chrome.drawItemIcon = wrapped
    installs[#installs + 1] = { holder = chrome, wrapper = wrapped, original = prior }
    return true
  end

  local ok1 = attach("src.ui.game3.bag_chrome")
  local ok2 = attach("src.ui.game3.rse.bag_chrome")
  if not ok1 and not ok2 then return nil, "no Gen 3 Bag icon renderer available" end
  return { uninstall = function()
    for i = #installs, 1, -1 do
      local irow = installs[i]
      if irow.holder.drawItemIcon == irow.wrapper then
        irow.holder.drawItemIcon = irow.original
      end
    end
  end }
end

return Icons
