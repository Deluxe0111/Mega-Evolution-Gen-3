-- Approved Gym, Elite Four, Champion and story-boss Mega selections.
-- Resolve named approvals to real IDs and parties from the current ROM's
-- Gen3 trainer extract. Never rely on guessed numeric trainer IDs.
local Boss={}

local function norm(v)
  if type(v)~="string" then return nil end
  return v:upper():gsub("[^A-Z0-9]","")
end
local function copy(t)
  local o={}
  for k,v in pairs(t or {}) do o[k]=v end
  return o
end
local function region(gameId)
  if gameId=="firered" or gameId=="leafgreen" then return "firered" end
  if gameId=="ruby" or gameId=="sapphire" or gameId=="emerald" then
    return "hoenn"
  end
end
local function allowedGame(entry,gameId)
  if not entry.games then return true end
  for _,g in ipairs(entry.games) do if g==gameId then return true end end
  return false
end
local function matchesName(entry,name)
  local key=norm(name)
  if entry.name=="*" then return true end
  if key==norm(entry.name) then return true end
  for _,alt in ipairs(entry.aliases or {}) do
    if key==norm(alt) then return true end
  end
  return false
end
local function matchesClass(entry,className)
  for _,c in ipairs(entry.classes or {}) do
    if norm(className)==norm(c) then return true end
  end
  return false
end
local function idListed(ids,id)
  id=tonumber(id)
  for _,allowed in ipairs(ids or {}) do
    if tonumber(allowed)==id then return true end
  end
  return false
end

function Boss.new(approved,formRows,opts)
  opts=opts or {}
  local forms={}
  for _,row in ipairs(formRows or {}) do
    if row.slug then forms[row.slug]=row end
  end
  local pokemon=opts.pokemon
  local trainers=opts.trainers
  local gameId=opts.gameId
  local function keyName(id)
    if type(id)=="string" then return norm(id) end
    if not (pokemon and type(pokemon.keyName)=="function") then return nil end
    local ok,name=pcall(pokemon.keyName,id)
    return ok and norm(name) or nil
  end
  local function speciesId(name)
    if not (pokemon and type(pokemon.speciesFromName)=="function") then return nil end
    local ok,id=pcall(pokemon.speciesFromName,name)
    if not ok or not tonumber(id) then return nil end
    if keyName(id)~=norm(name) then return nil end
    return id
  end
  local function match(entry,trainer,game,id)
    if not (entry and trainer and allowedGame(entry,game)
        and matchesName(entry,trainer.name)
        and matchesClass(entry,trainer.className)) then return nil end
    -- Names alone are not sufficient for the FRLG CHAMPION class:
    -- the ROM pack also contains a blank-name, single-Ekans #38 row.
    if entry.requireNamed and not norm(trainer.name) then return nil end
    if entry.minPartySize and #(trainer.party or {})<entry.minPartySize then
      return nil
    end
    if entry.requiresStarter then
      local containsStarter=false
      for _,m in ipairs(trainer.party or {}) do
        local name=keyName(m.species)
        if name=="CHARIZARD" or name=="BLASTOISE" or name=="VENUSAUR" then
          containsStarter=true
          break
        end
      end
      if not containsStarter then return nil end
    end
    -- These IDs come from the user's actual FireRed ROM audit.
    -- An early Giovanni is explicitly prevented from using a Mega;
    -- otherwise the generic trainer rule could select Kangaskhan.
    if entry.noMegaTrainerIds and idListed(entry.noMegaTrainerIds[game],id) then
      return "disabled_by_choice"
    end
    if entry.onlyTrainerIds and not idListed(entry.onlyTrainerIds[game],id) then
      return nil
    end
    return "approved"
  end
  local function findApproved(trainer,game,id)
    local g=region(game)
    if not g then return nil end
    local found,disposition
    for _,entry in ipairs(approved[g] or {}) do
      local verdict=match(entry,trainer,game,id)
      if verdict then
        if found then return nil,"ambiguous_boss_match" end
        found,disposition=entry,verdict
      end
    end
    return found,disposition
  end
  local function sameNativeParty(rom,party)
    if type(rom)~="table" or type(party)~="table"
        or #rom==0 or #party~=#rom then return false end
    for i,m in ipairs(rom) do
      local b=party[i]
      if not b or tonumber(m.species)~=tonumber(b.species)
          or tonumber(m.level)~=tonumber(b.level) then return false end
    end
    return true
  end
  local function target(entry,party)
    if entry.slug=="starter_x" then
      -- FRLG rival champion: use whichever fully evolved starter is
      -- ALREADY in the team. Charizard gets X rather than Y.
      for i=#party,1,-1 do
        local m=party[i]
        local name=keyName(m.species)
        local slug=name=="CHARIZARD" and "mega_charizard_x"
          or name=="BLASTOISE" and "mega_blastoise"
          or name=="VENUSAUR" and "mega_venusaur"
        if slug then return i,slug,true end
      end
      return nil,nil,true
    end
    local form=forms[entry.slug]
    if not form then return nil,nil,false end
    for i=#party,1,-1 do
      local m=party[i]
      if keyName(m.species)==norm(form.species)
          and (tonumber(m.form or m.formId) or 0)==
            (tonumber(form.base_form) or 0) then
        return i,entry.slug,true
      end
    end
    return nil,entry.slug,false
  end
  local self={}
  function self.assess(game,trainerId,actualParty,metadata)
    local id=tonumber(trainerId)
    if not id or not trainers or type(trainers.get)~="function" then
      return {status="no_rom_trainer"}
    end
    local row=metadata or trainers.get(id)
    if not row then return {status="no_rom_trainer",trainerId=id} end
    local entry,reason=findApproved(row,game,id)
    if not entry then
      return {status=reason or "not_approved",trainerId=id}
    end
    local report={key=entry.key,trainerId=id,name=row.name,
      className=row.className,slug=entry.slug,
      originalPartySize=#(row.party or {}),party={}}
    for i,m in ipairs(row.party or {}) do
      report.party[i]={
        slot=i, species=tonumber(m.species),
        name=keyName(m.species) or ("SPECIES "..tostring(m.species)),
        level=tonumber(m.level) or 0,
      }
    end
    if not sameNativeParty(row.party,actualParty) then
      report.status="rom_party_mismatch"
      return report
    end
    if reason=="disabled_by_choice" then
      report.status="disabled_by_choice"
      report.slug=nil
      return report
    end
    local slot,slug,present=target(entry,actualParty)
    report.slug=slug or entry.slug
    if slot then
      report.status="existing"
      report.slot=slot
      return report
    end
    if entry.noAdd then
      report.status="starter_not_present"
      return report
    end
    if entry.double then
      report.status="double_party_review"
      return report
    end
    if #actualParty>=6 then
      report.status="full_party_needs_approval"
      return report
    end
    local form=forms[entry.slug]
    if not form then
      report.status="form_not_installed"
      return report
    end
    if (tonumber(form.base_form) or 0)~=0 then
      report.status="alternate_base_form_needs_review"
      return report
    end
    local species=speciesId(form.species)
    if not species then
      report.status="species_not_registered"
      return report
    end
    report.status="add"
    report.slot=#actualParty+1
    report.species=species
    report.level=math.max(1,tonumber(actualParty[#actualParty].level) or 5)
    return report
  end

  -- Called BEFORE native Battle.start. This validates the exact ROM
  -- trainer ID *and* original party; it never mutates the supplied opts,
  -- original trainer cache, species, levels or held items.
  function self.prepare(opts,game)
    if type(opts)~="table" or opts.wild or opts.link or opts.spectate
        or opts.battleTower or opts.trainerTower or opts.eReader
        or opts.secretBase or opts.frontier or opts.pokedude
        or opts.oldManTutorial or opts.ghostBattle then
      return opts,nil
    end
    local foe=type(opts.foe)=="table" and opts.foe
    local party=foe and foe.party
    if not party or opts.foeParty then return opts,nil end
    local id=tonumber(opts.trainerId or foe.trainerId)
    local report=self.assess(game,id,party)
    if report.status~="existing" and report.status~="add" then
      return opts,report
    end
    local patched=copy(opts)
    if report.status=="add" then
      local amended=copy(foe)
      amended.party={}
      for i,mon in ipairs(party) do amended.party[i]=mon end
      local last=party[#party]
      -- Native foe_mon_from prepares stats and level-based moves from
      -- this generated foe entry. Do not award a held Mega Stone.
      amended.party[#amended.party+1]={
        species=report.species,level=report.level,
        rawIv=tonumber(last and last.rawIv) or 0,
        iv=tonumber(last and last.iv) or 0,
        nativeNpcTrainer=foe.nativeNpcTrainer
      }
      patched.foe=amended
    end
    return patched,report
  end

  -- ROM-derived audit API for all instances/rematches, including real IDs.
  -- The user can review returned rows without enabling mutations.
  function self.audit(game)
    local pack=trainers and trainers.pack and trainers.pack()
    local all=pack and pack.trainers
    if type(all)~="table" then return nil,"trainer_extract_not_loaded" end
    local rows={}
    local found={}
    for trainerId,raw in pairs(all) do
      -- The *raw* import often omits className: it is resolved from
      -- pack.classNames only by Trainers.get. Use the same native
      -- resolved identity as the live Battle.start hook.
      local row=trainers.get and trainers.get(trainerId) or raw
      local entry=findApproved(row,game,trainerId)
      if entry then
        local report=self.assess(game,trainerId,row.party,row)
        rows[#rows+1]=report
        found[entry.key]=true
      end
    end
    for _,entry in ipairs(approved[region(game) or ""] or {}) do
      if allowedGame(entry,game) and not found[entry.key] then
        rows[#rows+1]={key=entry.key,slug=entry.slug,
          status="trainer_identity_not_found"}
      end
    end
    table.sort(rows,function(a,b)
      if a.key==b.key then
        return (a.trainerId or 0)<(b.trainerId or 0)
      end
      return (a.key or "")<(b.key or "")
    end)
    return rows
  end
  return self
end
return Boss
