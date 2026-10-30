-- Pure calibration model: UI edits are isolated from live Mega battle state.
-- The export is a complete, deterministic replacement mega_presentation.lua.
local Tuner = {}

-- feet/baseline remain in each presentation record and in exports, but
-- the in-game controls change only screen-space dx/dy and scale.
local FIELDS = { "scale", "dx", "dy", "feet", "baseline" }

local function copy(source)
  local out = {}
  for slug, sides in pairs(source or {}) do
    out[slug] = {}
    for side, row in pairs(sides) do
      out[slug][side] = {}
      for k, v in pairs(row) do out[slug][side][k] = v end
    end
  end
  return out
end

function Tuner.new(forms, presentation)
  assert(type(forms) == "table" and type(presentation) == "table")
  local slugs = {}
  for _, form in ipairs(forms) do
    assert(presentation[form.slug], "missing presentation for " .. tostring(form.slug))
    slugs[#slugs + 1] = form.slug
  end
  assert(#slugs > 0, "empty Mega roster")
  local self = {
    forms = slugs, index = 1, side = "back", shiny = false,
    edits = copy(presentation), changed = {}, saved = false
  }

  function self:slug() return self.forms[self.index] end
  function self:row()
    local sides = self.edits[self:slug()]
    local kind = self.side .. (self.shiny and "_shiny" or "")
    return sides[kind] or sides[self.side]
  end
   function self:countChanged()
    local n = 0
    for _ in pairs(self.changed) do n = n + 1 end
    return n
  end
  function self:moveForm(direction)
    local n = #self.forms
    self.index = (self.index - 1 + direction) % n + 1
    return self:slug()
  end
  function self:toggleSide()
    self.side = self.side == "back" and "front" or "back"
  end
  function self:toggleShiny() self.shiny = not self.shiny end

  local function setValue(self, field, value)
    local row = self:row()
    if row[field] == value then return false end
    row[field] = value
    self.changed[self:slug()] = true
    self.saved = false
    return true
  end

  function self:move(dx, dy)
    assert(type(dx) == "number" and type(dy) == "number")
    local row = self:row()
    local x = math.max(-512, math.min(512, (tonumber(row.dx) or 0) + dx))
    local y = math.max(-512, math.min(512, (tonumber(row.dy) or 0) + dy))
    local changedX = setValue(self, "dx", x)
    local changedY = setValue(self, "dy", y)
    return changedX or changedY
  end

  function self:scale(direction)
    local row = self:row()
    local current = tonumber(row.scale) or 1
    local nextValue = math.floor((current + direction * 0.05) * 100 + 0.5) / 100
    return setValue(self, "scale", math.max(0.20, math.min(2.50, nextValue)))
  end
  function self:resetCurrent(original)
    local slug = self:slug()
    self.edits[slug] = copy({[slug] = original[slug]})[slug]
    self.changed[slug] = nil
    self.saved = false
  end
  function self:exportLua()
    local rows = {
      "-- Mega Evolution Gen 3 - in-game calibration export",
      "-- Complete replacement for data/mega_presentation.lua",
      "-- Edited in the non-combat battle-preview screen; source animation motion retained.",
      "-- All numbers are source-frame/world display coordinates, not save data.",
      "return {",
    }
    for _, slug in ipairs(self.forms) do
      rows[#rows + 1] = "  " .. slug .. " = {"
      local conf = self.edits[slug]
      for _, side in ipairs({ "back", "front", "back_shiny", "front_shiny" }) do
        local s = conf[side]
        if s then
          local values = {}
          for _, field in ipairs(FIELDS) do
            local v = tonumber(s[field]) or 0
            values[#values + 1] = field .. " = " .. string.format("%.2f", v):gsub("%.00$", "")
          end
          rows[#rows + 1] = "    " .. side .. " = { " .. table.concat(values, ", ") .. " },"
        end
      end
      rows[#rows + 1] = "  },"
    end
    rows[#rows + 1] = "}"
    rows[#rows + 1] = ""
    return table.concat(rows, "\n")
  end

  return self
end

return Tuner
