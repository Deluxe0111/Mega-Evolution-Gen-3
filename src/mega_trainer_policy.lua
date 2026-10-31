-- Enemy Mega Evolution policy. A living NPC trainer may Mega Evolve
-- exactly one eligible Pokémon per battle, without editing ROM/save teams
-- or granting permanent items. Boss roster changes are a separate opt-in
-- authoring layer, deliberately empty until the choices are reviewed.
local TrainerMega={}

local function norm(value)
  if type(value)~="string" then return nil end
  return value:upper():gsub("[^A-Z0-9]","")
end

local function baseForm(mon)
  return tonumber(mon and (mon.form or mon.formId)) or 0
end

local function moveKnown(mon,moveName,normalizeMove)
  if not (mon and type(mon.moves)=="table") then return false end
  for _,move in pairs(mon.moves) do
    local name=normalizeMove and normalizeMove(move) or move
    if norm(name)==norm(moveName) then return true end
  end
  return false
end

-- opts.speciesName is the host Pokemon.keyName resolver. Later-generation
-- species remain eligible when the National Dex provider supplies a name.
function TrainerMega.new(catalog,opts)
  opts=opts or {}
  local bySpecies={}
  for _,row in ipairs(catalog or {}) do
    local species=norm(row.species)
    if species and row.slug then
      bySpecies[species]=bySpecies[species] or {}
      bySpecies[species][#bySpecies[species]+1]=row
    end
  end
  local speciesName=opts.speciesName
  local normalizeMove=opts.normalizeMove
  local selectionCache=setmetatable({},{__mode="k"})
  local function battleAllowed(st)
    return type(st)=="table" and not st.wild and not st.link
      and not st.spectate and not st.safari and not st.pokedude
      and not st.oldManTutorial and not st.ghostBattle
      and not st.battleTower and not st.trainerTower and not st.eReader
      and not st.secretBase and not st.frontierTrainer
      and type(st.foeParty)=="table"
  end
  local function candidateForMon(mon)
    if not (type(mon)=="table" and (tonumber(mon.hp) or 0)>0)
        or mon.transformed then return nil end
    local species=speciesName and speciesName(mon.species or mon.speciesId)
      or (type(mon.species)=="string" and mon.species)
    local forms=bySpecies[norm(species)] or {}
    local form=baseForm(mon)
    for _,row in ipairs(forms) do
      if (tonumber(row.baseForm or row.base_form) or 0)==form
          and (not row.move or row.move==""
            or moveKnown(mon,row.move,normalizeMove)) then
        return row.slug
      end
    end
    return nil
  end

  local self={}
  function self.candidateForMon(mon) return candidateForMon(mon) end
  function self.choose(st)
    if not battleAllowed(st) then return nil end
    -- Deterministic ace rule: last Pokémon in the party that can Mega.
    -- This respects the real trainer party without adding a replacement.
    local chosen
    for i,mon in ipairs(st.foeParty) do
      local slug=candidateForMon(mon)
      if slug then chosen={slot=i,slug=slug} end
    end
    return chosen
  end
  function self.selected(st)
    if not battleAllowed(st) then return nil end
    local existing=selectionCache[st]
    if not existing then
      existing=self.choose(st) or {none=true}
      selectionCache[st]=existing
    end
    return existing.none and nil or existing
  end
  function self.formFor(st,b)
    if not (b and b.side=="enemy" and b.mon
        and not b.fainted and (tonumber(b.mon.hp) or 0)>0) then
      return nil
    end
    local chosen=self.selected(st)
    if not chosen or b.partyIndex~=chosen.slot then return nil end
    -- Revalidate current identity/HP/form when the selected Pokémon
    -- actually attempts a move; never trust a pre-battle cached slug.
    if candidateForMon(b.mon)~=chosen.slug then return nil end
    return chosen.slug
  end
  function self.reset()
    selectionCache=setmetatable({},{__mode="k"})
  end
  return self
end
return TrainerMega
