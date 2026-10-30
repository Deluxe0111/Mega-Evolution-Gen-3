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

  local function resolve(species, held, formId, knowsMegaMove)
    local formsForSpecies = bySpecies[normalize(species)]
    if not formsForSpecies then return nil, "species_not_supported" end
    local stone = byItem[held] or byItem[normalize(held)]
    local chosen = {}
    for _, form in ipairs(formsForSpecies) do
      local matches = (form.stone ~= "" and form.stone == stone)
        or (form.stone == "" and form.move ~= "" and knowsMegaMove == true
            and (not stone or stone == "KEY_STONE"))
      if matches then chosen[#chosen + 1] = form end
    end
    if #chosen == 0 then
      if not stone or stone == "KEY_STONE" then return nil, "mega_stone_required" end
      return nil, "wrong_mega_stone"
    end
    if #chosen == 1 then
      -- A form-specific Mega cannot be selected using a Pokémon in a different
      -- base form, even when only one stone target exists.
      local candidate = chosen[1]
      if formId ~= nil and candidate.base_form and tonumber(candidate.base_form) ~= tonumber(formId) then
        return nil, "wrong_base_form"
      end
      return candidate.slug, nil
    end
    if formId == nil then return nil, "ambiguous_mega_form" end
    local found
    for _, form in ipairs(chosen) do
      if tonumber(form.base_form or 0) == tonumber(formId) then
        if found then return nil, "ambiguous_mega_form" end
        found = form
      end
    end
    return found and found.slug or nil, found and nil or "wrong_base_form"
  end

  function Eligibility.resolve(species, held, formId, knowsMegaMove)
    return resolve(species, held, formId, knowsMegaMove)
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
    if ctx.species == nil then return nil, "unknown_species" end
    if not bySpecies[normalize(ctx.species)] then return nil, "species_not_supported" end
    if ctx.keyStone ~= true then return nil, "key_stone_required" end
    -- The current battler's held item is authoritative (Knock Off etc.).
    -- A supplied battle item 0 is not replaced by the original party item.
    local held = battler.item
    if held == nil and battler.mon then held = battler.mon.item or battler.mon.heldItem end
    if ctx.species == nil then return nil, "unknown_species" end
    -- Ordinary Mega Stones require the exact held item. Rayquaza is the
    -- one known exception: Dragon Ascent, and no competing held Mega Stone.
    local monForm = ctx.baseForm
    if monForm == nil and battler.mon then
      monForm = battler.mon.form or battler.mon.formId
    end
    return resolve(ctx.species, held, monForm, ctx.knowsMegaMove)
  end

  return Eligibility
end

return Eligibility
