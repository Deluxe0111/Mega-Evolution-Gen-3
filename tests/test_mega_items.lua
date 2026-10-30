local items = dofile("data/mega_items.lua")
local forms = dofile("data/mega_forms.lua")
local ItemReg = dofile("src/mega_items.lua")
local Eligibility = dofile("src/mega_eligibility.lua")

assert(#forms == 98 and #items == 93)
local rows, ids, slots = {}, {}, {}
local mod = { content = { items = {register = function(_, id, row)
  assert(type(id) == "string" and not ids[id], "duplicate id")
  assert(not slots[row.index], "duplicate numeric item ID")
  assert(row.fieldUse == "none", "Mega Stones must not be consumable evolution items")
  ids[id], slots[row.index], rows[id] = true, true, row
end}}}
local registered, errors = ItemReg.register(mod, items)
assert(#registered == 93 and #errors == 0)
assert(rows.KEY_STONE.index == 1599 and rows.KEY_STONE.pocket == "KEY_ITEMS")
assert(rows.VENUSAURITE and rows.VENUSAURITE.index >= 1500)
assert(rows.CHARIZARDITEX and rows.CHARIZARDITEY
  and rows.CHARIZARDITEX.index ~= rows.CHARIZARDITEY.index)
assert(rows.VENUSAURITE.price == 5000 and rows.KEY_STONE.price == 10000)
-- Fail safely when registry is not available: no guessing of IDs or inventory writes.
local noItems, noErrors = ItemReg.register({}, items)
assert(#noItems == 0 and #noErrors == 1)

local checker = Eligibility.new(forms, items)
local venus = { species = 3, side = "player", item = rows.VENUSAURITE.index,
                mon = {species = 3, hp = 100} }
local function context(overrides)
  local c = {battler=venus, species="VENUSAUR", side="player", keyStone=true}
  for key, value in pairs(overrides or {}) do c[key] = value end
  return c
end
local slug, reason = checker.check(context())
assert(slug == "mega_venusaur" and reason == nil)
slug = checker.check(context({species="  Venusaur! "}))
assert(slug == "mega_venusaur")
slug, reason = checker.check(context({keyStone=false}))
assert(slug == nil and reason == "key_stone_required")
slug, reason = checker.check(context({disabled=true}))
assert(slug == nil and reason == "battle_restricted")
slug, reason = checker.check(context({alreadyUsed=true}))
assert(slug == nil and reason == "already_mega_evolved")
slug, reason = checker.check(context({species="CHARIZARD"}))
assert(slug == nil and reason == "wrong_mega_stone")
slug, reason = checker.check(context({battler={side="player", item=0, mon={item=rows.VENUSAURITE.index, hp=100}}}))
assert(slug == nil and reason == "mega_stone_required",
  "Knock Off must not resurrect original party item")
slug, reason = checker.check(context({battler={side="player", item=rows.VENUSAURITE.index, mon={hp=100}, transformed=true}}))
assert(slug == nil and reason == "transformed_pokemon")
slug, reason = checker.check(context({battler={side="player", item=rows.VENUSAURITE.index, mon={hp=0}}}))
assert(slug == nil and reason == "cannot_mega_evolve")
slug, reason = checker.check(context({battler={side="player", item=rows.CHARIZARDITEX.index, mon={hp=100}}, species="CHARIZARD"}))
assert(slug == "mega_charizard_x" and reason == nil)
slug = checker.check(context({battler={side="player", item=rows.CHARIZARDITEY.index, mon={hp=100}}, species="CHARIZARD"}))
assert(slug == "mega_charizard_y")

-- All art forms are in the data catalog; no special no-Stone form is accidentally
-- enabled without its mechanics (Rayquaza requires Dragon Ascent).
local missing = 0
for _, form in ipairs(forms) do
  if form.stone ~= "" then
    assert(rows[form.stone], "Stone not registered: "..form.stone)
    local resolved, err = checker.resolve(form.species, rows[form.stone].index)
    if not resolved then
      assert(err == "ambiguous_mega_form", form.slug .. " unexpectedly rejected: "..tostring(err))
    else
      assert(resolved == form.slug, form.slug.." maps to "..tostring(resolved))
    end
  else
    missing = missing + 1
    assert(form.slug == "mega_rayquaza")
  end
end
assert(missing == 1)
slug, reason = checker.resolve("RAYQUAZA", nil)
assert(slug == nil and reason == "mega_stone_required")
print("PASS: 93 registered Mega items, 98 form definitions, Key Stone gating and strict per-battler eligibility")
