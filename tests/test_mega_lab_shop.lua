-- Professor lab Mega Stone fundraiser: item prices, native shop stock,
-- runtime NPC placement and dialogue, duplicated map entries and fallthrough.
local Items = dofile("src/mega_items.lua")
local catalog = dofile("data/mega_items.lua")
local definitions = {}
local rMod = { content = { items = {
  register=function(_,id,record)
    assert(not definitions[id], "duplicate registered item")
    definitions[id] = record
  end,
} } }
local registered,errors = Items.register(rMod,catalog)
assert(#errors==0 and #registered==#catalog)
assert(definitions.KEY_STONE.price==10000)
assert(definitions.KEY_STONE.pocket=="KEY_ITEMS")
assert(definitions.KEY_STONE.importance==1)
assert(definitions.BLASTOISINITE.price==5000)
assert(definitions.VENUSAURITE.price==5000)
for _,row in ipairs(catalog) do
  assert(definitions[row.id].price==(row.id=="KEY_STONE" and 10000 or 5000),
    "incorrect lab price for "..row.id)
end

local Shop = dofile("src/mega_lab_shop.lua")
assert(Shop.labFor("FR_OAKS_LAB").professor=="OAK")
assert(Shop.labFor("EM_LITTLEROOT_TOWN_PROFESSOR_BIRCHS_LAB").professor=="BIRCH")
assert(Shop.labFor("ROUTE_101")==nil)
local current="FR_OAKS_LAB"
local npcs={}
local eventHandlers,hooks={},{}
local collisions = { ["10:10"]=true }
local Collision = {isWalkable=function(x,y)
  return not collisions[x..":"..y]
end}
local Objects = {at=function()return nil end}
local session={bag={},money=45000}
local shown,closed,greeting,openShop=0,0,nil,nil
local Message={
  isOpen=function()return greeting~=nil end,
  show=function(s,cb) greeting={s=s,cb=cb}; shown=shown+1 end,
  close=function() greeting=nil; closed=closed+1 end,
}
local NativeShop={
  isOpen=function()return openShop~=nil end,
  show=function(opts) openShop=opts end,
}
local Bag={
  has=function(bag,item,qty)
    assert(item==definitions.KEY_STONE.index and qty==1)
    return bag.hasKeyStone or false
  end,
}
local Runtime={getSession=function()return session end}
local world={}
function world:current() return {mapId=current} end
function world:spawnNpc(mapId,def)
  assert(mapId==current)
  assert(def.name=="MEGA_LAB_FUNDRAISER")
  local id=mapId.."_obj_"..tostring((#npcs)+1)
  local original={}
  for k,v in pairs(def) do original[k]=v end
  original.owner="mega-evolution-gen3"
  original.runtime=true
  original.mapId=mapId
  npcs[#npcs+1]={id=id,def=original,originMapId=mapId}
  return id
end
function world:npc(mapId,id)
  for _,row in ipairs(npcs) do
    if row.id==id and row.originMapId==mapId then return row end
  end
  return nil
end
local mod = {
  id="mega-evolution-gen3",
  world=nil, -- verify the mod can install before the native game exists
  hooks={wrap=function(_,name,cb)hooks[name]=cb end},
  events={on=function(_,name,cb) eventHandlers[name]=cb end},
  log={info=function()end,warn=function(_,fmt,...)error(string.format(fmt,...))end},
}
local shop=assert(Shop.install(mod,catalog,registered,{
  ["src.ui.game3.message"]=Message,
  ["src.ui.game3.shop_menu"]=NativeShop,
  ["src.core.game3.bag"]=Bag,
  ["src.core.game3.runtime"]=Runtime,
  ["src.core.game3.collision"]=Collision,
  ["src.core.game3.objects"]=Objects,
}))
assert(eventHandlers["map.entered"] and eventHandlers["world.stepped"]
  and hooks["world.talk"])
mod.world=world -- game.ready: lazy WorldAPI becomes available
-- World not in a lab means no accidental NPC.
eventHandlers["map.entered"]({mapId="FR_ROUTE1"})
assert(#npcs==0)
eventHandlers["map.entered"]({mapId=current})
assert(#npcs==1 and npcs[1].def.graphicsId==55)
assert(npcs[1].def.x==9 and npcs[1].def.y==10,
  "blocked placement should use the next clear coordinate")
eventHandlers["map.entered"]({mapId=current})
eventHandlers["world.stepped"]()
assert(#npcs==1,"lab aide must not duplicate after a map event")
-- Other NPCs still get their original conversation.
local forwarded=0
local function nextTalk()
  forwarded=forwarded+1
  return "base-talk"
end
assert(hooks["world.talk"](nextTalk,{},{
  def={runtime=true,owner="other-mod",name="MEGA_LAB_FUNDRAISER"}
})=="base-talk" and forwarded==1)
-- Talk to OUR NPC, show a lab-funding message, then the native shop.
local aid=npcs[1]
assert(hooks["world.talk"](nextTalk,{},aid)==true)
assert(greeting and greeting.s:find("OAK",1,true)
  and greeting.s:find("FUNDS",1,true))
assert(forwarded==1 and shown==1)
greeting.cb()
assert(openShop and openShop.session==session)
assert(openShop.items[1]==definitions.KEY_STONE.index)
assert(#openShop.items==#catalog)
assert(openShop.items[2]==definitions.ABOMASITE.index)
assert(openShop.items[#openShop.items]==definitions.ZYGARDITE.index)
assert(closed==1 and shop.diagnostics().shops==1)
-- When re-entering, the Key Stone is hidden if already owned.
session.bag.hasKeyStone=true
greeting=nil;openShop=nil
assert(hooks["world.talk"](nextTalk,{},aid)==true)
greeting.cb()
assert(openShop.items[1]==definitions.ABOMASITE.index
  and #openShop.items==#catalog-1)
assert(shop.diagnostics().talks==2)
-- Emerald gets a second lab location with its own native scientist gfx.
current="EM_LITTLEROOT_TOWN_PROFESSOR_BIRCHS_LAB"
openShop=nil
eventHandlers["map.entered"]({mapId=current})
assert(#npcs==2 and npcs[2].def.graphicsId==46)
assert(npcs[2].def.x==9 and npcs[2].def.y==10)
assert(hooks["world.talk"](nextTalk,{},npcs[2])==true)
assert(greeting.s:find("BIRCH",1,true))
assert(shop.diagnostics().spawned==2)
print("PASS: lab fundraisers, 93 safe item prices, correct native shop stock, no duplicate NPCs, Oak/Birch and Key Stone ownership")
