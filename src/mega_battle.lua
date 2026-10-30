-- Data-driven, battle-only Mega forms for the entire imported EBDX roster.
-- No saved-mon mutation, custom engine hooks or permanent species slots.
local Mega = {}
local IV_KEY={attack="atk", defense="def", spAtk="spa", spDef="spd", speed="spe"}
local NATURE_KEYS={"attack","defense","speed","spAtk","spDef"}
local NATURE={
  [1]={1,2},[2]={1,3},[3]={1,4},[4]={1,5},
  [5]={2,1},[7]={2,3},[8]={2,4},[9]={2,5},
  [10]={3,1},[11]={3,2},[13]={3,4},[14]={3,5},
  [15]={4,1},[16]={4,2},[17]={4,3},[19]={4,5},
  [20]={5,1},[21]={5,2},[22]={5,3},[23]={5,4},
}

local function makeStats(mon, row)
  if type(mon)~="table" or not row or not row.stats then return nil end
  local level=tonumber(mon.level)
  if not level or level<1 or level>100 then return nil end
  local nature=NATURE[(tonumber(mon.personality) or 0)%25]
  local iv,ev=mon.ivs or {},mon.evs or {}
  local output={}
  for _,key in ipairs(NATURE_KEYS) do
    local stat=row.stats[key]
    if not tonumber(stat) then return nil end
    local id=IV_KEY[key]
    local raw=math.floor(((2*stat+(tonumber(iv[id]) or 0)
      +math.floor((tonumber(ev[id]) or 0)/4))*level)/100)+5
    local mul=1
    if nature and NATURE_KEYS[nature[1]]==key then mul=1.1 end
    if nature and NATURE_KEYS[nature[2]]==key then mul=0.9 end
    output[key]=math.floor(raw*mul)
  end
  -- Official Mega mechanics do not recalculate max HP mid-battle, even
  -- if newer fan forms have altered HP entries.
  return output
end
Mega.megaStats=makeStats

function Mega.new(selection, eligibility, art, catalogue, typeIds)
  assert(selection and type(eligibility)=="function" and art
    and type(catalogue)=="table")
  local forms={}
  for _,row in ipairs(catalogue) do
    assert(type(row.slug)=="string" and not forms[row.slug])
    forms[row.slug]=row
  end
  typeIds=type(typeIds)=="table" and typeIds or {}
  local battle
  local changes,calculated={},{}
  local function restoreOne(b)
    local old=changes[b]
    if not old then return end
    b.ability,b.type1,b.type2=old.ability,old.type1,old.type2
    changes[b]=nil
  end
  local function restore()
    for b in pairs(changes) do restoreOne(b) end
    calculated={}
  end
  local self={}
  function self.begin(st)
    if not st then return false end
    if st~=battle then
      restore()
      battle=st
      selection.beginBattle()
    end
    return true
  end
  local function attach(b)
    local mon=b and b.mon
    local slug=mon and selection.activeForm(mon)
    local row=slug and forms[slug]
    if not row then return end
    if not changes[b] then
      changes[b]={ability=b.ability,type1=b.type1,type2=b.type2}
    end
    local old=changes[b]
    b.ability=row.ability~="" and row.ability or old.ability
    if #row.types>0 then
      local primary=typeIds[row.types[1]]
      local secondary=row.types[2] and typeIds[row.types[2]]
      -- Stock Gen 3 has no Fairy type. Never inject an unknown type ID:
      -- the unsupported type remains the original until a type-expansion
      -- provider is available. Don't partially change dual types.
      if primary~=nil and (not row.types[2] or secondary~=nil) then
        b.type1=primary
        b.type2=secondary -- nil means mono-type Mega
      else
        b.type1,b.type2=old.type1,old.type2
      end
    end
  end
  local function validForm(st,b)
    local slug=eligibility(st,b)
    return slug and forms[slug] and slug or nil
  end
  function self.input(st,b,input)
    if not self.begin(st) or not b or not b.mon then return false end
    if input:wasPressed("b") then selection.cancel("player",b.mon); return false end
    if not input:wasPressed("start") then return false end
    local status=selection.status("player",b.mon)
    if status and (status.used or status.pending) then return false end
    local slug=validForm(st,b)
    if not slug or not art.hasSprite(slug,"back")
        or not art.hasSprite(slug,"front") then return false end
    selection.toggle("player",b.mon,slug,true)
    return true
  end
  function self.command(st,b,action)
    if not self.begin(st) or type(action)~="table" then return action end
    if action.kind=="cancel_partner" then selection.cancel("player"); return action end
    if action.kind~="move" or not b or not b.mon then return action end
    local chosen,ok=selection.commit("player",b.mon,action)
    return ok and chosen or action
  end
  function self.beforeMove(st,action,b)
    if not self.begin(st) or type(action)~="table" or action.kind~="move"
        or not b or not b.mon or b.side~="player" then return false end
    local mon=b.mon
    local tag=action.megaEvolution
    if not tag or tag.mon~=mon or not forms[tag.form] then
      attach(b)
      return false
    end
    local s=selection.status("player",mon)
    if not s or s.used or not s.pending or b.fainted then return false end
    if eligibility(st,b)~=tag.form then return false end
    local row=forms[tag.form]
    local stats=makeStats(mon,row)
    if not stats or not art.hasSprite(tag.form,"back") then return false end
    local active=selection.activatePlanned("player",mon,action,true)
    if active~=tag.form then return false end
    calculated[mon]=stats
    attach(b)
    return true
  end
  function self.beforeResolved(st,b,move,slot)
    if not self.begin(st) or not b or not b.mon then return false end
    local chosen=selection.pendingAction("player",b.mon)
    if not chosen or chosen.kind~="move" or chosen.move~=move
        or chosen.slot~=slot then return false end
    return self.beforeMove(st,{
      kind="move",move=move,slot=slot,megaEvolution=chosen.megaEvolution
    },b)
  end
  function self.withBattleDraw(drawFn,...)
    if art.withBattleDraw then return art.withBattleDraw(drawFn,...) end
    return drawFn(...)
  end
  function self.monPicture(st,mon,back,shiny,fallback)
    if st~=battle or not mon then return fallback end
    local slug=selection.activeForm(mon)
    if not slug then return fallback end
    return art.picture(slug,back and "back" or "front",shiny,nil,true) or fallback
  end
  function self.switchedIn(b) attach(b) end
  function self.stat(b,key,vanilla)
    local mon=b and b.mon
    local slug=mon and selection.activeForm(mon)
    if not slug then return vanilla end
    attach(b)
    return calculated[mon] and calculated[mon][key] or vanilla
  end
  function self.picture(b,back,shiny,fallback)
    local mon=b and b.mon
    local slug=mon and selection.activeForm(mon)
    if not slug then return fallback end
    attach(b)
    return art.picture(slug,back and "back" or "front",shiny,nil,true) or fallback
  end
  function self.status(st,b)
    if not self.begin(st) or not b or not b.mon or b.side~="player" then return nil end
    local s=selection.status("player",b.mon)
    if not s or s.used or s.pending then return nil end
    local slug,reason=eligibility(st,b)
    if not slug then
      if reason=="species_not_supported" then return nil end
      if reason=="key_stone_required" then return "KEY STONE NEEDED",false end
      if reason=="mega_stone_required" then return "MEGA STONE NEEDED",false end
      if reason=="wrong_base_form" or reason=="ambiguous_mega_form" then
        return "MEGA FORM UNAVAILABLE",false
      end
      return nil
    end
    if not forms[slug] then return nil end
    if not art.hasSprite(slug,"back") or not art.hasSprite(slug,"front") then
      return "MEGA ART MISSING",false
    end
    return s.armed and "MEGA READY" or "START: MEGA",true
  end
  function self.turnEnded() selection.cancel("player") end
  function self.fainted(mon)
    if not mon then return end
    selection.faint(mon)
    calculated[mon]=nil
    for b in pairs(changes) do if b.mon==mon then restoreOne(b) end end
  end
  function self.finish()
    restore()
    selection.finishBattle()
    battle=nil
  end
  function self.activeForm(mon) return selection.activeForm(mon) end
  function self.formData(slug) return forms[slug] end
  return self
end

return Mega
