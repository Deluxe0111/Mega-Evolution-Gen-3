-- Read-only native-resolution Gen3 screen for actual ROM trainer IDs,
-- parties, missing species, free slots, and replacement decisions.
local ScreenModule={}
local SCREEN="MegaTrainerAudit"
local OUTPUT="mega_trainer_audit.txt"
local function optional(path)
  local ok,result=pcall(require,path)
  return ok and result or nil
end
local function shorten(value,n)
  local s=tostring(value or "?")
  return #s>n and s:sub(1,n-1).."~" or s
end
local function displayName(row)
  return (row and (row.name or row.key) or "?"):upper()
end
function ScreenModule.install(mod,modelModule,audit,opts)
  opts=opts or {}
  if not (mod and mod.content and mod.content.screens
      and type(mod.content.screens.register)=="function"
      and mod.hooks and type(mod.hooks.wrap)=="function"
      and mod.ui and type(audit)=="function"
      and modelModule and type(modelModule.new)=="function") then
    return nil,"Gen3 screen registration or audit unavailable"
  end
  local bridge=opts.screenBridge or optional("src.ui.game3.mod_ui")
  local push=opts.pushScreen or (bridge and bridge.push)
  if type(push)~="function" then return nil,"Gen3 screen bridge unavailable" end
  local G=opts.graphics or (love and love.graphics)
  local Font=opts.font or optional("src.ui.game3.frlg_font")
  local lastModel
  local function text(s,x,y)
    s=tostring(s or "")
    if Font and type(Font.draw)=="function" then
      local ok=pcall(Font.draw,s,x,y,{small=true,maxWidth=236,
        colors=Font.COLOR and Font.COLOR.WHITE})
      if ok then return end
    end
    if G then G.setColor(1,1,1,1);G.print(s,x,y) end
  end
  local function writeReport(model)
    local body=model:exportText()
    local stored=false
    if mod.cache and type(mod.cache.write)=="function" then
      local ok,value=pcall(mod.cache.write,mod.cache,
        "exports/"..OUTPUT,body)
      stored=ok and value==true
    end
    if not stored and opts.writeFile then
      local ok,value=pcall(opts.writeFile,OUTPUT,body)
      stored=ok and value==true
    elseif not stored and love and love.filesystem and love.filesystem.write then
      local ok,value=pcall(love.filesystem.write,OUTPUT,body)
      stored=ok and value==true
    end
    return stored,body
  end
  local Screen={}
  Screen.__index=Screen
  function Screen.new(game)
    local self=setmetatable({
      game=game,gbaCanvas=true,kind="mega_trainer_audit",
      isMenu=true,isOpaque=true,
      model=modelModule.new(audit),message="",messageTimer=0
    },Screen)
    self.model:refresh()
    lastModel=self.model
    return self
  end
  function Screen:exit()end
  function Screen:update(dt)
    if self.messageTimer>0 then self.messageTimer=self.messageTimer-(dt or 0) end
    local input=self.game and self.game.input
    if not input or type(input.wasPressed)~="function" then return end
    local function key(k)return input:wasPressed(k)end
    local model=self.model
    if key("b") then
      if model.detail then model.detail=false
      elseif self.game and self.game.stack then self.game.stack:pop() end
      return
    end
    if key("select") then
      local ok=writeReport(model)
      self.message=ok and "AUDIT EXPORTED" or "EXPORT FAILED"
      self.messageTimer=3
      return
    end
    if key("start") then
      model:refresh()
      self.message="ROM AUDIT REFRESHED"
      self.messageTimer=2
      return
    end
    if model.detail then
      if key("a") then model.detail=false end
      return
    end
    if key("l") then model:filterMove(-1)
    elseif key("r") then model:filterMove(1)
    elseif key("up") then model:move(-1)
    elseif key("down") then model:move(1)
    elseif key("left") then model:move(-7)
    elseif key("right") then model:move(7)
    elseif key("a") and model:selected() then model.detail=true end
  end
  function Screen:draw()
    if not G then return end
    local m=self.model
    G.push("all")
    if G.origin then G.origin() end
    if G.setScissor then G.setScissor() end
    G.setColor(.055,.085,.16,1)
    G.rectangle("fill",0,0,240,160)
    G.setColor(.14,.23,.35,1)
    G.rectangle("fill",0,0,240,27)
    G.rectangle("fill",0,130,240,30)
    G.setColor(.9,.76,.35,1)
    G.rectangle("fill",0,25,240,2)
    local counts=m:counts()
    text("TRAINER MEGA AUDIT",4,1)
    text(string.format("%d TOTAL %d READY %d REVIEW %d OFF",
      counts.total,counts.ready,counts.review,counts.skipped or 0),4,14)
    if m.error then
      text("NO ROM TRAINER DATA",5,37)
      text(shorten(m.error,34),5,53)
      text("IMPORT THE ROM AND REOPEN",5,69)
    elseif m.detail then
      local row=m:selected()
      if row then
        text(shorten(displayName(row).."  #"..tostring(row.trainerId or "?"),35),4,29)
        text(shorten("MEGA: "..tostring(row.slug or "?"),36),4,42)
        text(shorten("STATUS: "..tostring(row.status or "?"),36),4,55)
        text("ORIGINAL PARTY:",4,68)
        for i,member in ipairs(row.party or {}) do
          if i<=5 then
            text(shorten(string.format("%d. %s Lv.%s",i,
              tostring(member.name or "?"),tostring(member.level or "?")),38),
              4,68+i*11)
          end
        end
        if #(row.party or {})>5 then
          text(shorten("6. "..tostring(row.party[6].name or "?")
            .." Lv."..tostring(row.party[6].level or "?"),38),4,121)
        end
      end
    else
      local rows=m:list()
      if #rows==0 then text("NO MATCHING TRAINERS",4,52) end
      local start=math.max(1,math.floor((m.index-1)/7)*7+1)
      for pos=start,math.min(#rows,start+6) do
        local row=rows[pos]
        local i=pos-start
        local y=29+i*14
        if pos==m.index then
          G.setColor(.24,.37,.52,1)
          G.rectangle("fill",2,y,236,14)
        end
        local flag=row.status=="existing" and "OK"
          or row.status=="add" and "ADD"
          or row.status=="disabled_by_choice" and "OFF" or "CHECK"
        text(shorten(string.format("%s  #%s %s",flag,
          tostring(row.trainerId or "?"),displayName(row)),36),5,y)
      end
      text(string.format("%d-%d / %d  [%s]",start,
        math.min(#rows,start+6),#rows,m:filterName()),4,118)
    end
    text(m.detail and "A/B BACK  START REFRESH" or
      "L/R FILTER  UP/DN MOVE  A DETAIL",4,132)
    text("SELECT EXPORT     B EXIT",4,145)
    if self.messageTimer>0 then
      G.setColor(.5,.22,.14,1)
      G.rectangle("fill",0,110,240,17)
      text(self.message,4,112)
    end
    G.pop()
  end

  local ok,err=pcall(mod.content.screens.register,mod.content.screens,
    SCREEN,{new=function(game)return Screen.new(game)end})
  if not ok then return nil,tostring(err) end
  mod.hooks:wrap("ui.start_menu.items",function(next,game,items)
    local out=next(game,items)
    if type(out)~="table" then return out end
    if opts.isVisible and not opts.isVisible() then return out end
    local item={label="MEGA AUDIT",
      onSelect=function()return push(game,SCREEN)end}
    if mod.ui.insertBefore then
      return mod.ui.insertBefore(out,"SAVE",item)
    end
    out[#out+1]=item
    return out
  end)

  local facade={}
  function facade.open(game)return push(game,SCREEN)end
  function facade.report()
    local model=lastModel or modelModule.new(audit)
    if not model.loaded then model:refresh() end
    return model:exportText()
  end
  function facade.export()
    local model=lastModel or modelModule.new(audit)
    if not model.loaded then model:refresh() end
    return writeReport(model)
  end
  return facade
end
return ScreenModule
