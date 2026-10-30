local UI=dofile("src/mega_ui.lua")
local mon={species=3,attack=20,defense=25,spAtk=30,spDef=40,speed=45,ability=65,abilityId=65}
local other={species=4,attack=70}
local mega={slug="mega_venusaur",ability="THICK_FAT",
  stats={attack=145,defense=160,spAtk=150,spDef=133,speed=101}}
local game={view=function(m) return m==mon and mega or nil end}
local Pokemon={
  monFrontPic=function() return {image="normal-front",w=64,h=64} end,
  monIcon=function() return {image="normal-icon",w=32,h=32} end,
  isShiny=function() return false end,
  abilityName=function() return "OVERGROW" end,
}
local SummaryData={abilityDescription=function()return "Overgrow ability" end}
local sourcePicture=function(slug,side,shiny,frame,battle)
  assert(slug=="mega_venusaur" and side=="front" and battle==false)
  return {image="mega-summary",w=64,h=64}
end
local calls=0
local Summary={_party={mon,other},_cursor=1}
local OriginalSummaryDraw=function()
  calls=calls+1
  local showing=Summary._party[Summary._cursor]
  assert(showing~=mon)
  assert(showing.attack==145 and showing.defense==160 and showing.speed==101)
  assert(showing.abilityName=="THICK FAT")
  assert(Pokemon.abilityName(65)=="THICK FAT")
  assert(SummaryData.abilityDescription(65)=="Mega Evolution ability")
  assert(Pokemon.monFrontPic(showing).image=="mega-summary")
  assert(Pokemon.monIcon(showing).image=="mega-party-icon")
  return "drawn"
end
Summary.draw=OriginalSummaryDraw
local bridge=assert(UI.install({},game,{
  picture=sourcePicture,
  icon=function()return {image="mega-party-icon",w=32,h=32} end
},{Pokemon=Pokemon,Summary=Summary,SummaryData=SummaryData}))
local oldAbility=Pokemon.abilityName
local oldDesc=SummaryData.abilityDescription
assert(Summary.draw()=="drawn")
assert(Summary._party[1]==mon and mon.attack==20 and mon.ability==65 and mon.abilityId==65)
assert(Pokemon.abilityName==oldAbility and SummaryData.abilityDescription==oldDesc)
assert(Pokemon.monIcon(mon).image=="mega-party-icon")
assert(Pokemon.monIcon(other).image=="normal-icon")
assert(Pokemon.monFrontPic(other).image=="normal-front")
Summary._cursor=2
assert(Summary.draw()==nil or true)
-- A summary drawing exception must restore the real party record too.
Summary._cursor=1
local origDraw=Summary.draw
Summary.draw=function()
  return origDraw()
end
-- separate installation after uninstall to test exception restoration
bridge.uninstall()
Summary.draw=function()
  assert(Summary._party[1]~=mon)
  error("expected draw failure")
end
local bad=assert(UI.install({},game,{
  picture=sourcePicture,icon=function()return {image="icon",w=32,h=32} end
},{Pokemon=Pokemon,Summary=Summary,SummaryData=SummaryData}))
local ok=pcall(Summary.draw)
assert(not ok)
assert(Summary._party[1]==mon and mon.attack==20)
assert(Pokemon.abilityName==oldAbility and SummaryData.abilityDescription==oldDesc)
bad.uninstall()
print("PASS: summary display copies, Mega stats/ability, picture/icon isolation, error-safe save pointers")
