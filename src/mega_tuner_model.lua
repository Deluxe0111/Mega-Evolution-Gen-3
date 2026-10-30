-- Pure calibration model: UI edits are isolated from live Mega battle state.
-- The export is a complete, deterministic replacement mega_presentation.lua.
local Tuner = {}

local SIDE = { "back", "front" }
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
    field = 1, mode = "browse", edits = copy(presentation),
    changed = {}, step = 0, saved = false
  }

  function self:slug() return self.forms[self.index] end
  function self:row()
    local sides = self.edits[self:slug()]
    local kind = self.side .. (self.shiny and "_shiny" or "")
    return sides[kind] or sides[self.side]
  end
  function self:fieldName() return FIELDS[self.field] end
  function self:countChanged()
    local n = 0
    for _ in pairs(self.changed) do n = n + 1 end
    return n
  end
  function self:moveForm(direction)
    local n = #self.forms
    self.index = (self.index - 1 + direction) % n + 1
    self.field = 1
    return self:slug()
  end
  function self:toggleSide()
    self.side = self.side == "back" and "front" or "back"
    self.field = 1
  end
  function self:toggleShiny() self.shiny = not self.shiny end
  function self:nextField(direction)
    self.field = (self.field - 1 + direction) % #FIELDS + 1
  end
  function self:adjust(direction)
    local row = self:row()
    local field = self:fieldName()
    local current = tonumber(row[field]) or 0
    local value
    if field == "scale" then
      -- 0.05 steps, numeric rounding prevents accumulated floating point drift
      value = math.floor((current + direction * 0.05) * 100 + 0.5) / 100
      value = math.max(0.20, math.min(2.50, value))
    else
      value = math.max(-512, math.min(512, math.floor(current + direction)))
      if field == "feet" then value = math.max(0, value) end
    end
    if current == value then return false end
    row[field] = value
    self.changed[self:slug()] = true
    self.saved = false
    return true
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
