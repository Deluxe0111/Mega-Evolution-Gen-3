-- Every playable Mega must have explicit, independently editable battle sizing.
-- Validate against the real normalized animation union, not just a mock atlas.
local presentation = dofile("data/mega_presentation.lua")
local forms = dofile("data/mega_forms.lua")
local index = dofile("assets/runtime/mega_atlas_index.lua")
local n = 0
local seen = {}
for _, form in ipairs(forms) do
  local slug = form.slug
  assert(not seen[slug], "duplicate form: " .. slug)
  seen[slug] = true
  local config = assert(presentation[slug], "missing presentation for " .. slug)
  local art = assert(index.forms[slug], "missing atlas form: " .. slug)
  for _, side in ipairs({"back", "front"}) do
    local spec = assert(config[side], slug .. ": missing " .. side)
    assert(spec.scale == 1, slug .. ":" .. side .. " must start at 1x")
    assert(spec.baseline == (side == "back" and 57 or 62))
    assert(spec.dx == 0 and type(spec.dy) == "number")
    for _, suffix in ipairs({"", "_shiny"}) do
      local kind = side .. suffix
      local cell = assert(art.variants[kind], slug .. ": no " .. kind .. " art")
      local seg = assert(cell.segments[1], slug .. ": no " .. kind .. " segment")
      local differs = false
      local plain = art.variants[side].segments[1]
      for _, field in ipairs({"fs", "cx", "cy", "fw", "fh"}) do
        if seg[field] ~= plain[field] then differs = true end
      end
      local chosen = suffix ~= "" and config[kind] or nil
      if differs then
        assert(chosen, slug .. ": separate " .. kind .. " frame size needs its own anchor")
      else
        assert(not chosen, slug .. ": redundant " .. kind .. " override")
      end
      chosen = chosen or spec
      assert(chosen.scale == 1 and chosen.baseline == spec.baseline)
      assert(chosen.dx == 0 and type(chosen.dy) == "number")
      local bottom = (tonumber(seg.cy) or 0) + (tonumber(seg.fh) or tonumber(seg.fs))
      assert(chosen.feet >= bottom, slug .. ":" .. kind .. " below visible animation")
      assert(chosen.feet <= seg.fs, slug .. ":" .. kind .. " beyond frame")
      assert(chosen.feet - bottom <= 6, slug .. ":" .. kind .. " excessive hovering")
    end
  end
  n = n + 1
end
for slug in pairs(presentation) do
  assert(seen[slug], "unknown presentation entry " .. slug)
end
assert(n == 98, "expected 98 Mega forms, found " .. n)
assert(presentation.mega_venusaur.back.feet == 100)
assert(presentation.mega_venusaur.front.feet == 98)
assert(presentation.mega_mewtwo_x.back.feet == 86)
assert(presentation.mega_mewtwo_x.back.dy == 4)
assert(presentation.mega_pyroar.front_shiny.feet == 92)
assert(presentation.mega_zygarde_form_5.back_shiny.feet == 124)
print("PASS: 98 complete front/back 1x Mega presentations + geometry-specific shiny anchors")
