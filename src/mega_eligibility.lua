-- Strict, side-effect-free Mega eligibility. The caller supplies the live
-- battler, Key Stone ownership, and species name. Fail closed on uncertainty.
-- No saved species mutation, no fake item ownership and no item grants.
local Eligibility = {}

local function normalize(value)
  if type(value) ~= "string" then return nil end
  return value:upper():gsub("[^A-Z0-9]", "")
end

function Eligibility.new(forms, items)
  assert(type(forms) == "table" and type(items) == "table")
  local byItem, bySpecies = {}, {}
  for _, row in ipairs(items) do
    byItem[normalize(row.id)] = row.id
    byItem[tonumber(row.index)] = row.id
  end
  local candidates = {}
  for _, row in ipairs(forms) do
    candidates[row.species] = candidates[row.species] or {}
    candidates[row.species][#candidates[row.species] + 1] = row
  end
  for sp, list in pairs(candidates) do
    bySpecies[normalize(sp)] = list
  end

  local function resolve(species, held)
    local formsForSpecies = bySpecies[normalize(species)]
    if not formsForSpecies then return nil, "species_not_supported" end
    local stone = byItem[held] or byItem[normalize(held)]
    if not stone or stone == "KEY_STONE" then return nil, "mega_stone_required" end
    local chosen
    for _, form in ipairs(formsForSpecies) do
      if form.stone ~= "" and form.stone == stone then
        if chosen then return nil, "ambiguous_mega_form" end
        chosen = form
      end
    end
    if chosen then return chosen.slug, nil end
    return nil, "wrong_mega_stone"
  end

  function Eligibility.resolve(species, held)
    return resolve(species, held)
  end

  -- Context shape:
  --   species: real base species ID/name (typically Pokemon.keyName(b.species))
  --   battler: live State.makeBattler table, not a saved party Pokemon
  --   keyStone: verified Bag.has(session.bag, 1599) for player
  --   side: "player" or "enemy"; disabled: safari/tutorial/link etc.
  --   alreadyUsed: selection.used for the same trainer, if true
  function Eligibility.check(ctx)
    if type(ctx) ~= "table" or type(ctx.battler) ~= "table" then
      return nil, "no_battler"
    end
    if ctx.side ~= "player" and ctx.side ~= "enemy" then return nil, "invalid_side" end
    if ctx.disabled then return nil, "battle_restricted" end
    if ctx.alreadyUsed then return nil, "already_mega_evolved" end
    local battler = ctx.battler
    if battler.zeroed or battler.fainted or (battler.mon and tonumber(battler.mon.hp) == 0) then
      return nil, "cannot_mega_evolve"
    end
    if battler.transformed or (battler.mon and battler.mon.transformed) then
      return nil, "transformed_pokemon"
    end
    if ctx.keyStone ~= true then return nil, "key_stone_required" end
    -- The current battler's held item is authoritative (Knock Off etc.).
    -- A supplied battle item 0 is not replaced by the original party item.
    local held = battler.item
    if held == nil and battler.mon then held = battler.mon.item or battler.mon.heldItem end
    if not held or held == 0 or held == "0" then return nil, "mega_stone_required" end
    if ctx.species == nil then return nil, "unknown_species" end
    return resolve(ctx.species, held)
  end

  return Eligibility
end

return Eligibility
