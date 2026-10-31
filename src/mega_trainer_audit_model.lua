-- Pure, read-only navigation and text export for the imported-ROM audit.
local Audit={}
local FILTERS={"ALL","READY","NEEDS REVIEW"}
local READY={existing=true,add=true}
local SKIPPED={disabled_by_choice=true}
function Audit.new(loader)
  local self={rows={},error=nil,filter=1,index=1,detail=false,
    loaded=false}
  local function visible()
    local items={}
    for _,row in ipairs(self.rows) do
      local ready=READY[row.status]==true
      local skipped=SKIPPED[row.status]==true
      if self.filter==1 or (self.filter==2 and ready)
          or (self.filter==3 and not ready and not skipped) then
        items[#items+1]=row
      end
    end
    return items
  end
  function self:refresh()
    local ok,rows,err=pcall(loader)
    if ok and type(rows)=="table" then
      self.rows,self.error=rows,nil
    else
      self.rows={}
      self.error=tostring((ok and err) or rows or "audit unavailable")
    end
    self.loaded=true
    self.index=1
    self.detail=false
  end
  function self:filterName()return FILTERS[self.filter]end
  function self:list()return visible()end
  function self:selected()
    return visible()[self.index]
  end
  function self:move(delta)
    local n=#visible()
    self.index=math.min(math.max(1,self.index+(delta or 0)),math.max(1,n))
  end
  function self:filterMove(delta)
    self.filter=(self.filter-1+(delta or 0))%#FILTERS+1
    self.index=1
    self.detail=false
  end
  function self:counts()
    local ready,review,skipped=0,0,0
    for _,row in ipairs(self.rows) do
      if READY[row.status] then ready=ready+1
      elseif SKIPPED[row.status] then skipped=skipped+1
      else review=review+1 end
    end
    return {total=#self.rows,ready=ready,review=review,skipped=skipped}
  end
  function self:exportText()
    local out={"MEGA TRAINER AUDIT","READ ONLY / IMPORTED ROM",
      "Total: "..tostring(#self.rows),""}
    if self.error then out[#out+1]="ERROR: "..self.error end
    for _,row in ipairs(self.rows) do
      local id=row.trainerId and tostring(row.trainerId) or "UNMATCHED"
      out[#out+1]=string.format(
        "%s | %s | %s | #%s | %s | %s",
        tostring(row.key or "?"),tostring(row.name or "?"),
        tostring(row.className or "?"),id,
        tostring(row.slug or "?"),tostring(row.status or "?"))
      for i,mon in ipairs(row.party or {}) do
        out[#out+1]=string.format("  %d. %s Lv.%d",
          i,tostring(mon.name or mon.species or "?"),
          tonumber(mon.level) or 0)
      end
      if row.status=="add" then
        out[#out+1]="  PROPOSE: add "..tostring(row.slug)
          .." in slot "..tostring(row.slot)
          .." at Lv."..tostring(row.level)
      elseif row.status=="full_party_needs_approval" then
        out[#out+1]="  ACTION: replacement decision required; no swap made"
      elseif row.status=="disabled_by_choice" then
        out[#out+1]="  RULE: no Mega Evolution for this encounter"
      end
    end
    return table.concat(out,"\n").."\n"
  end
  return self
end
return Audit
