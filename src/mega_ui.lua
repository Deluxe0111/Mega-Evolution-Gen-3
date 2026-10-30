-- Battle-only Mega presentation in the stock party/summary UI.
-- No persistent saved-mon mutations, no replacement of G9 frontPic/icon hooks,
-- and no use of battle-sized images outside battle.
local Ui = {}
local function copy(t)
  local c={}
  for k,v in pairs(t or {}) do c[k]=v end
  return c
end

function Ui.install(mod, game, art, modules)
  if not game or not game.view then return nil, "missing battle form view" end
  local req=modules and modules.require or require
  local function optional(path)
    local ok,value=pcall(req,path)
    return ok and type(value)=="table" and value or nil
  end
  local Pokemon=modules and modules.Pokemon or optional("src.core.game3.pokemon")
  local SummaryData=modules and modules.SummaryData or optional("src.core.game3.summary_data")
  local Summary=modules and modules.Summary or optional("src.ui.game3.summary_menu")
  local RS=modules and modules.RS or optional("src.ui.game3.rs.summary_menu")
  local RSE=modules and modules.RSE or optional("src.ui.game3.rse.summary_menu")
  local PartyMenu=modules and modules.PartyMenu or optional("src.ui.game3.party_menu")
  local Oam=modules and modules.Oam or optional("src.core.game3.oam")
  if not Pokemon or not art or not art.picture then
    return nil,"Pokemon or Mega image provider not available"
  end
  local replacements={}
  local diagnostics={
    partySlotOverrides=0, megaIconAttempts=0, megaIconSuccess=0,
    megaIconFailures=0, lastIcon=nil, lastFailure=nil,
    partyDraws=0, lastPartySlot=nil,
    nativePartyFlushes=0, nativeMegaOverrides=0,
    lastNativeSlot=nil, lastNativeSlug=nil, overlayError=nil,
  }
  local warned={}
  local function warnOnce(slug,why)
    local key=tostring(slug)..":"..tostring(why)
    if warned[key] then return end
    warned[key]=true
    if mod and mod.log and mod.log.warn then
      mod.log:warn("Mega party icon %s: %s",tostring(slug),tostring(why))
    end
  end
  local function wrap(holder,key,callback)
    if not holder or type(holder[key])~="function" then return end
    local original=holder[key]
    local wrapped=function(...) return callback(original,...) end
    holder[key]=wrapped
    replacements[#replacements+1]={holder=holder,key=key,old=original,ours=wrapped}
  end
  local function viewOf(mon)
    if type(mon)~="table" then return nil end
    return mon.__megaUiView or game.view(mon)
  end
  local function shiny(mon)
    if Pokemon.isShiny then
      local ok,result=pcall(Pokemon.isShiny,mon)
      if ok then return result==true end
    end
    return mon and mon.shiny==true
  end

  -- Read-only per-mon presentation seams: never touch the global species
  -- picture / icon functions owned by G9. Inactive Pokémon pass through.
  wrap(Pokemon,"monFrontPic",function(next,mon,form,kind)
    local v=viewOf(mon)
    if v then
      local pic=art.picture(v.slug,"front",shiny(mon),nil,false)
      if pic then return pic end
    end
    return next(mon,form,kind)
  end)
  local function female(mon)
    if not mon then return false end
    if mon.gender == "F" or mon.gender == "female" then return true end
    if mon.gender == "M" or mon.gender == "male" then return false end
    if type(Pokemon.gender) == "function" then
      local species = type(Pokemon.speciesOf) == "function"
        and Pokemon.speciesOf(mon) or mon.species
      local ok, value = pcall(Pokemon.gender, species, mon.personality)
      if ok then return value == "F" or value == "female" end
    end
    return false
  end

  local function iconFor(v,mon)
    if not v or not art.icon then return nil end
    diagnostics.megaIconAttempts=diagnostics.megaIconAttempts+1
    diagnostics.lastIcon=v.slug
    local ok,icon=pcall(art.icon,v.slug,shiny(mon),female(mon))
    if ok and icon and icon.image and icon.quads and icon.quads[0]
        and icon.quads[1] then
      diagnostics.megaIconSuccess=diagnostics.megaIconSuccess+1
      diagnostics.lastIconSource=icon.source or "unknown"
      return icon
    end
    diagnostics.megaIconFailures=diagnostics.megaIconFailures+1
    diagnostics.lastFailure=ok and "missing/invalid two-frame Mega artwork"
      or tostring(icon)
    warnOnce(v.slug,diagnostics.lastFailure)
    return nil
  end
  wrap(Pokemon,"monIcon",function(next,mon)
    local icon=iconFor(viewOf(mon),mon)
    return icon or next(mon)
  end)

  -- FireRed paints native party sprites via Oam.flushOne after its icon
  -- lookup. A later G9 icon wrapper can bypass Pokemon.monIcon altogether.
  -- Override only Mega Pokémon OAM sprites at this final render boundary.
  -- _order converts the visible battle-switch row to its original party slot.
  -- No party arrays, saved Pokémon or battle stats are mutated here.
  if PartyMenu and Oam and type(Oam.flushOne)=="function"
      and type(Oam.get)=="function" and type(game.partyView)=="function" then
    wrap(Oam,"flushOne",function(next,sprite,...)
      if PartyMenu.open and PartyMenu._battle
          and type(PartyMenu._party)=="table" and PartyMenu._oam then
        for i,record in pairs(PartyMenu._oam) do
          if type(i)=="number" and record and record.mon
              and Oam.get(record.mon)==sprite then
            diagnostics.nativePartyFlushes=diagnostics.nativePartyFlushes+1
            local slot=PartyMenu._order and PartyMenu._order[i] or i
            local ok,v=pcall(game.partyView,slot)
            if ok and v then
              local mon=PartyMenu._party[i]
              local icon=iconFor(v,mon)
              if icon then
                local frame=tonumber(sprite.data and sprite.data[2]) or 0
                frame=math.floor(frame)%2
                sprite.image=icon.image
                sprite._quads=icon.quads
                sprite.quad=icon.quads[frame] or icon.quads[0]
                diagnostics.nativeMegaOverrides=diagnostics.nativeMegaOverrides+1
                diagnostics.lastNativeSlot=slot
                diagnostics.lastNativeSlug=v.slug
              end
            end
            break
          end
        end
      end
      return next(sprite,...)
    end)
  end

  -- Battle-switch roster can contain COPIES and a reordered view of the
  -- original player party. Patch only its synchronous draw, replacing
  -- references with temporary Mega-marked display copies. The actual
  -- saved party, battle state and menu array are restored after EVERY draw.
  -- Both FRLG OAM and RSE Chrome call Pokemon.monIcon on these copies.
  local drawingParty=false
  local function diagnosticsVisible()
    if mod and mod.developer==true then return true end
    local options=mod and mod.options
    if options and type(options.get)=="function" then
      local ok,on=pcall(options.get,options,"mega_tuner_enabled")
      return ok and on==true
    end
    return false
  end
  local tinyFont
  local function drawPartyDebug()
    if not diagnosticsVisible() then return end
    local G=love and love.graphics
    if not G or not G.push or not G.rectangle or not G.print then return end
    local pushed=false
    local ok,err=pcall(function()
      G.push("all")
      pushed=true
      if G.origin then G.origin() end
      if G.setShader then G.setShader() end
      G.setColor(0.04,0.09,0.15,0.94)
      G.rectangle("fill",0,132,240,28)
      G.setColor(1,1,1,1)
      -- An unavailable font must not suppress the entire diagnostic.
      if not tinyFont and G.newFont then
        local fontOk,font=pcall(G.newFont,7)
        if fontOk then tinyFont=font end
      end
      if tinyFont and G.setFont then G.setFont(tinyFont) end
      local slot=diagnostics.lastPartySlot or "-"
      local slug=diagnostics.lastIcon or "NO MEGA STATE"
      local info=diagnostics.megaIconSuccess>0
        and ("ICON OK / "..tostring(diagnostics.lastIconSource or "?"))
        or (diagnostics.megaIconFailures>0 and "ICON FAILED"
          or "ICON NOT REQUESTED")
      G.print("MEGA SLOT "..tostring(slot)..": "..tostring(slug),4,134)
      G.print(info.." / OAM "..tostring(diagnostics.nativeMegaOverrides)
        .."/"..tostring(diagnostics.nativePartyFlushes),4,145)
      G.pop()
      pushed=false
    end)
    if not ok then
      if pushed then pcall(G.pop) end
      diagnostics.overlayError=tostring(err)
      warnOnce("diagnostic overlay",err)
    end
  end
  if PartyMenu and type(PartyMenu.draw)=="function"
      and type(game.partyView)=="function" then
    wrap(PartyMenu,"draw",function(next,...)
      if drawingParty or not PartyMenu.open or not PartyMenu._battle
          or type(PartyMenu._party)~="table" then return next(...) end
      diagnostics.partyDraws=diagnostics.partyDraws+1
      local party=PartyMenu._party
      local replacements={}
      for i,mon in ipairs(party) do
        local sourceSlot=PartyMenu._order and PartyMenu._order[i] or i
        local ok,v=pcall(game.partyView,sourceSlot)
        if ok and v and type(mon)=="table" then
          local mirror=copy(mon)
          mirror.__megaUiView=v
          party[i]=mirror
          replacements[#replacements+1]={index=i,original=mon}
          diagnostics.partySlotOverrides=diagnostics.partySlotOverrides+1
          diagnostics.lastPartySlot=sourceSlot
          if diagnostics.partySlotOverrides==1 and mod and mod.log
              and type(mod.log.info)=="function" then
            mod.log:info("Mega party menu resolved %s in original slot %s",
              tostring(v.slug),tostring(sourceSlot))
          end
        end
      end
      if #replacements==0 then
        local function packed(...)return {n=select("#",...),...}end
        local result=packed(pcall(next,...))
        drawPartyDebug()
        if not result[1] then error(result[2],0) end
        return (table.unpack or unpack)(result,2,result.n)
      end
      drawingParty=true
      local function packed(...)return {n=select("#",...),...}end
      local result=packed(pcall(next,...))
      for i=#replacements,1,-1 do
        local record=replacements[i]
        party[record.index]=record.original
      end
      drawingParty=false
      drawPartyDebug()
      if not result[1] then error(result[2],0) end
      return (table.unpack or unpack)(result,2,result.n)
    end)
  end

  -- Summary menus read stats and ability directly from a saved party-mon.
  -- Temporarily replace ONLY its party-array reference with a view copy for
  -- the synchronous draw, restoring the original pointer even on errors.
  local inDraw=false
  local function summaryDraw(next,menu,...)
    if inDraw or not menu or not menu._party then return next(...) end
    local party=menu._party
    local idx=tonumber(menu._cursor)
    local original=idx and party[idx]
    local v=viewOf(original)
    if not v then return next(...) end
    local mirror=copy(original)
    for k,value in pairs(v.stats or {}) do mirror[k]=value end
    -- Native ability identity is held only on the live battler; the mirror
    -- displays that identity without altering saved ability IDs.
    if v.ability and v.ability~="" then
      mirror.ability=v.ability
      mirror.abilityId=nil
      mirror.abilityName=v.ability:gsub("_"," ")
    end
    mirror.__megaUiView=v
    party[idx]=mirror
    local oldLoaded=menu._loaded
    if oldLoaded then menu._loaded=mirror end
    inDraw=true
    local oldAbilityName=Pokemon.abilityName
    local oldAbilityDesc=SummaryData and SummaryData.abilityDescription
    -- Emerald/Ruby/Sapphire menus resolve an ability's numeric species ID
    -- even if mon.ability is a string. Limit the display override to draw().
    if v.ability and v.ability~="" then
      if type(oldAbilityName)=="function" then
        Pokemon.abilityName=function(id)
          return mirror.abilityName
        end
      end
      if SummaryData and type(oldAbilityDesc)=="function" then
        SummaryData.abilityDescription=function()
          return "Mega Evolution ability"
        end
      end
    end
    local function packed(...) return {n=select("#",...),...} end
    local result=packed(pcall(next,...))
    if Pokemon.abilityName~=oldAbilityName then Pokemon.abilityName=oldAbilityName end
    if SummaryData and SummaryData.abilityDescription~=oldAbilityDesc then
      SummaryData.abilityDescription=oldAbilityDesc
    end
    party[idx]=original
    if oldLoaded then menu._loaded=oldLoaded end
    inDraw=false
    if not result[1] then error(result[2],0) end
    return (table.unpack or unpack)(result,2,result.n)
  end
  local function patchSummary(menu)
    if not menu or type(menu.draw)~="function" then return end
    wrap(menu,"draw",function(next,...)
      return summaryDraw(next,menu,...)
    end)
  end
  patchSummary(Summary)
  patchSummary(RS)
  -- RSE draws through the Summary bridge's party. If installed on its own,
  -- use the passed bridge as its context.
  if RSE and type(RSE.draw)=="function" then
    wrap(RSE,"draw",function(next,bridge)
      return summaryDraw(function()
        return next(bridge)
      end,bridge or Summary)
    end)
  end

  -- Emerald's mon animation can request another frame by species, so return
  -- the selected Mega frame only during an active Mega summary redraw.
  local MonAnim=modules and modules.MonAnim or optional("src.core.game3.mon_anim")
  if MonAnim and type(MonAnim.framePic)=="function" then
    wrap(MonAnim,"framePic",function(next,species,frame,isShiny,...)
      if inDraw then
        local menu=Summary
        local current=menu and menu._party and menu._party[menu._cursor]
        local v=viewOf(current)
        if v then
          local pic=art.picture(v.slug,"front",isShiny,frame,false)
          if pic then return pic end
        end
      end
      return next(species,frame,isShiny,...)
    end)
  end

  if mod and mod.log and type(mod.log.info)=="function" then
    mod.log:info("Mega UI OAM diagnostic hooks: party=%s oam=%s",
      tostring(PartyMenu and type(PartyMenu.draw)=="function"),
      tostring(Oam and type(Oam.flushOne)=="function"))
  end

  local bridge={}
  function bridge.diagnostics()
    local result={}
    for k,v in pairs(diagnostics) do result[k]=v end
    return result
  end
  function bridge.uninstall()
    for i=#replacements,1,-1 do
      local w=replacements[i]
      if w.holder[w.key]==w.ours then w.holder[w.key]=w.old end
    end
  end
  return bridge
end
return Ui
