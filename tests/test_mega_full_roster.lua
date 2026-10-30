-- Every imported EBDX form must be selectable, transform and keep save data intact.
local Forms=dofile("data/mega_battle_forms.lua")
local FormKeys=dofile("data/mega_forms.lua")
local Items=dofile("data/mega_items.lua")
local Eligibility=dofile("src/mega_eligibility.lua")
local Selection=dofile("src/mega_selection.lua")
local Mega=dofile("src/mega_battle.lua")
local typeIds={
  NORMAL=0,FIGHTING=1,FLYING=2,POISON=3,GROUND=4,ROCK=5,BUG=6,
  GHOST=7,STEEL=8,FIRE=10,WATER=11,GRASS=12,ELECTRIC=13,
  PSYCHIC=14,ICE=15,DRAGON=16,DARK=17
}
local byStone={}
for _,row in ipairs(Items) do byStone[row.id]=row.index end
assert(#Forms==98 and #FormKeys==98)
local bySlug={}
for _,row in ipairs(Forms) do
  assert(not bySlug[row.slug],row.slug)
  bySlug[row.slug]=row
  assert(type(row.stats)=="table" and row.stats.attack>0
    and row.stats.defense>0 and row.stats.spAtk>0 and row.stats.spDef>0
    and row.stats.speed>0,row.slug)
  if row.stone~="" then assert(byStone[row.stone],row.slug) end
end
local checker=Eligibility.new(FormKeys,Items)
local art={
  hasSprite=function(slug,kind) return bySlug[slug]~=nil end,
  picture=function(slug,side,shiny,frame,battle)
    return {image=slug..":"..side..":"..tostring(shiny)..":"..tostring(battle)}
  end
}
local function key(name)
  return {wasPressed=function(_,x)return x==name end}
end
for _,row in ipairs(Forms) do
  local species=row.species
  local stone=row.stone=="" and 0 or byStone[row.stone]
  local mon={
    species=3,level=50,personality=0,form=row.baseForm,
    hp=155,maxHp=155,attack=102,defense=103,spAtk=120,spDef=120,speed=100,
    ivs={atk=31,def=31,spa=31,spd=31,spe=31},
    evs={atk=0,def=0,spa=0,spd=0,spe=0},
    moves={"RAZOR_LEAF"},pp={10},
  }
  local b={mon=mon,side="player",species=3,item=stone,
    ability="OVERGROW",type1=12,type2=3}
  local function elig(_, battler)
    return checker.check({
      battler=battler,species=species,baseForm=battler.mon.form,
      side=battler.side,keyStone=true,knowsMegaMove=row.move~=""
    })
  end
  local game=Mega.new(Selection.new(),elig,art,Forms,typeIds)
  local st={}
  assert(game.status(st,b)=="START: MEGA",row.slug)
  assert(game.input(st,b,key("start")),row.slug)
  assert(game.status(st,b)=="MEGA READY")
  local action=game.command(st,b,{kind="move",move="RAZOR_LEAF",slot=1,battler=0})
  assert(action.megaEvolution and action.megaEvolution.form==row.slug,row.slug)
  assert(game.beforeResolved(st,b,"RAZOR_LEAF",1),row.slug)
  assert(game.activeForm(mon)==row.slug,row.slug)
  local stats=Mega.megaStats(mon,bySlug[row.slug])
  for _,k in ipairs({"attack","defense","spAtk","spDef","speed"}) do
    assert(game.stat(b,k,0)==stats[k],row.slug..":"..k)
  end
  assert(game.monPicture(st,mon,true,false,nil).image:find(row.slug,1,true))
  assert(game.monPicture(st,mon,false,true,nil).image:find("front",1,true))
  assert(b.ability==(bySlug[row.slug].ability~="" and bySlug[row.slug].ability or "OVERGROW"))
  if #bySlug[row.slug].types>0 then
    local ts=bySlug[row.slug].types
    if typeIds[ts[1]] and (not ts[2] or typeIds[ts[2]]) then
      assert(b.type1==typeIds[ts[1]] and b.type2==typeIds[ts[2]])
    else
      assert(b.type1==12 and b.type2==3,"Fairy fallback must retain types")
    end
  end
  assert(mon.attack==102 and mon.defense==103 and mon.speed==100)
  assert(mon.hp==155 and mon.maxHp==155 and mon.form==row.baseForm)
  local replacement={mon=mon,side="player",species=3,ability="OVERGROW",item=stone}
  game.switchedIn(replacement)
  assert(game.activeForm(mon)==row.slug)
  assert(game.stat(replacement,"speed",0)==stats.speed)
  local anotherMon={species=3,level=50}
  assert(not game.input(st,{mon=anotherMon,side="player",item=stone},key("start")),
    "single Mega allowance was not enforced: "..row.slug)
  game.fainted(mon)
  assert(game.activeForm(mon)==nil and b.ability=="OVERGROW" and replacement.ability=="OVERGROW")
  game.finish()
  assert(mon.attack==102 and mon.defense==103 and mon.speed==100)
end
-- Forms sharing a Mega Stone must resolve ONLY to their original species form.
for _,pair in ipairs({
  {"MEOWSTIC", "MEOWSTICITE",0,1},
  {"ZYGARDE", "ZYGARDITE",2,3},
  {"MAGEARNA", "MAGEARNITE",0,1},
  {"TATSUGIRI", "TATSUGIRINITE",0,1}
}) do
  local a=assert(checker.resolve(pair[1],byStone[pair[2]],pair[3]))
  local b=assert(checker.resolve(pair[1],byStone[pair[2]],pair[4]))
  assert(a~=b,"same-stone variants must be different")
  local slug,reason=checker.resolve(pair[1],byStone[pair[2]],99)
  assert(slug==nil and reason=="wrong_base_form")
end
assert(checker.resolve("RAYQUAZA",0,0,true)=="mega_rayquaza")
assert(checker.resolve("RAYQUAZA",0,0,false)==nil)
-- Super-effective Fairy type cannot be fabricated in the stock Gen III chart.
assert(typeIds.FAIRY==nil)
print("PASS: 98 Mega forms, stat calculations, exact stones/forms, Rayquaza, per-mon art and save isolation")
