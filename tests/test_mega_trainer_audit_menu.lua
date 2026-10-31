local Model=dofile("src/mega_trainer_audit_model.lua")
local Screen=dofile("src/mega_trainer_audit_screen.lua")
local Boss=dofile("src/mega_boss_roster.lua")
local Forms=dofile("data/mega_forms.lua")
local Approvals=dofile("data/mega_boss_selections.lua")
local calls=0
local audit=function()
  calls=calls+1
  return {
    {key="brock",name="BROCK",className="LEADER",
      trainerId=109,slug="mega_aerodactyl",status="add",
      slot=3,level=14,party={{name="GEODUDE",level=12},
        {name="ONIX",level=14}}},
    {key="misty",name="MISTY",className="LEADER",
      trainerId=110,slug="mega_starmie",status="existing",
      slot=2,party={{name="STARYU",level=18},
        {name="STARMIE",level=21}}},
    {key="giovanni",name="GIOVANNI",className="LEADER",
      trainerId=111,slug="mega_kangaskhan",
      status="full_party_needs_approval",party={
        {name="RHYHORN",level=45}
      }},
    {key="roxanne",slug="mega_glimmora",
      status="trainer_identity_not_found"},
    {key="giovanni_rocket",name="GIOVANNI",className="BOSS",
      trainerId=348,status="disabled_by_choice",
      party={{name="KANGASKHAN",level=29}}},
  }
end
local model=Model.new(audit)
assert(not model.loaded)
model:refresh()
local counts=model:counts()
assert(counts.total==5 and counts.ready==2 and counts.review==2
  and counts.skipped==1)
assert(model:selected().trainerId==109)
model:move(1)
assert(model:selected().trainerId==110)
model:filterMove(1)
assert(model:filterName()=="READY" and #model:list()==2)
model:filterMove(1)
assert(model:filterName()=="NEEDS REVIEW" and #model:list()==2)
assert(model:selected().status=="full_party_needs_approval")
model:move(300)
assert(model:selected().status=="trainer_identity_not_found")
assert(model:exportText():find("109 | mega_aerodactyl",1,true))
assert(model:exportText():find("ONIX Lv.14",1,true))
assert(model:exportText():find("ACTION: replacement decision",1,true))
assert(model:exportText():find("RULE: no Mega Evolution",1,true))
model:filterMove(1)
assert(model:filterName()=="ALL" and model:selected().trainerId==109)

local swapModel=Model.new(function() return {{
  key="juan",trainerId=800,name="JUAN",className="LEADER",
  slug="mega_tatsugiri_curly",status="replace",
  slot=5,replacedName="CRAWDAUNT",level=58,
  party={{name="CRAWDAUNT",level=58}}
}} end)
swapModel:refresh()
assert(swapModel:counts().ready==1 and swapModel:counts().review==0)
assert(swapModel:exportText():find(
  "PROPOSE: replace slot 5 (CRAWDAUNT) with mega_tatsugiri_curly at Lv.58",
  1,true))
local registerKey,screenSpec,startHook,exportFile,exportBody
local G=setmetatable({},{
  __index=function(_,name)
    return function()end
  end,
})
local mod={
 content={screens={register=function(_,key,spec)
   registerKey,screenSpec=key,spec
 end}},
 ui={insertBefore=function(items,_,row)
   items[#items+1]=row
   return items
 end},
 hooks={wrap=function(_,name,fn)
   assert(name=="ui.start_menu.items")
   startHook=fn
 end},
 cache={write=function(_,path,body)
   exportFile,exportBody=path,body
   return true
 end},
}
local pushes={}
local facade=assert(Screen.install(mod,Model,audit,{
 screenBridge={push=function(game,name)
   pushes[#pushes+1]=name
   return true
 end},
 graphics=G,
 font={draw=function()end,COLOR={WHITE=1}},
}))
assert(registerKey=="MegaTrainerAudit" and type(screenSpec.new)=="function")
local items=startHook(function(_,rows)return rows end,{},{{label="SAVE"}})
assert(#items==2 and items[2].label=="MEGA AUDIT")
items[2].onSelect()
assert(pushes[1]=="MegaTrainerAudit")
local keys={}
local stackPops=0
local game={
 input={wasPressed=function(_,key)return keys[key]==true end},
 stack={pop=function()stackPops=stackPops+1 end},
}
local screen=screenSpec.new(game)
assert(screen.model.loaded and calls>=2)
local function press(k)
 keys={[k]=true}
 screen:update(1/60)
 keys={}
end
screen:draw()
press("down")
assert(screen.model:selected().trainerId==110)
press("r")
assert(screen.model:filterName()=="READY")
press("r")
assert(screen.model:filterName()=="NEEDS REVIEW")
press("a")
assert(screen.model.detail)
screen:draw()
press("b")
assert(not screen.model.detail and stackPops==0)
press("start")
assert(screen.model.index==1 and calls>=3)
press("select")
assert(exportFile=="exports/mega_trainer_audit.txt")
assert(exportBody:find("STARMIE Lv.21",1,true))
assert(type(facade.report())=="string")
assert(facade.export())
press("b")
assert(stackPops==1)
facade.open(game)
assert(#pushes==2)
-- Native raw ROM pack may have NO className; Trainers.get must supply
-- the resolved class name from the indexed class-name table.
local party={{species=142,level=14}}
local pokemon={
 keyName=function(id)return id==142 and "AERODACTYL" end,
 speciesFromName=function(name)
   return name=="AERODACTYL" and 142 or nil
 end,
}
local romRows={[123]={id=123,name="BROCK",class=84,party=party}}
local trainers={
 pack=function()return {trainers=romRows,classNames={[84]="LEADER"}}end,
 get=function(id)
   local raw=romRows[id]
   if not raw then return nil end
   return {id=id,name=raw.name,className="LEADER",party=raw.party}
 end,
}
local b=Boss.new(Approvals,Forms,{pokemon=pokemon,trainers=trainers})
local rows=assert(b.audit("firered"))
local found
for _,row in ipairs(rows) do if row.key=="brock" then found=row end end
assert(found and found.trainerId==123 and found.status=="existing")
assert(found.party[1].name=="AERODACTYL" and found.party[1].level==14)
print("PASS: ROM trainer audit model, raw class resolution, menu inputs, filters, details, text export")
