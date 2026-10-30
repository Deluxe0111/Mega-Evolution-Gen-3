-- A professor's lab aide who funds research by selling Mega Stones.
-- Uses the Gen 3 runtime NPC and native shop UI, without editing story maps,
-- starter scripts, saved Pokemon, or the shared engine's shop implementation.
local Shop = {}

local LABS = {
  FR_OAKS_LAB = {
    professor = "OAK", graphicsId = 55,
    positions = { {10,10}, {9,10}, {10,9}, {9,9} },
  },
  EM_LITTLEROOT_TOWN_PROFESSOR_BIRCHS_LAB = {
    professor = "BIRCH", graphicsId = 46,
    positions = { {9,10}, {10,10}, {9,9}, {10,9} },
  },
}
-- The same layouts have distinct engine prefixes in other Gen 3 versions.
local function configFor(mapId)
  if type(mapId) ~= "string" then return nil end
  if mapId == "FR_OAKS_LAB" or mapId == "LG_OAKS_LAB" then
    return LABS.FR_OAKS_LAB
  end
  if mapId == "EM_LITTLEROOT_TOWN_PROFESSOR_BIRCHS_LAB"
      or mapId == "RU_LITTLEROOT_TOWN_PROFESSOR_BIRCHS_LAB"
      or mapId == "SA_LITTLEROOT_TOWN_PROFESSOR_BIRCHS_LAB" then
    return LABS.EM_LITTLEROOT_TOWN_PROFESSOR_BIRCHS_LAB
  end
  return nil
end
Shop.labFor = configFor

function Shop.install(mod, catalog, registered, deps)
  deps = deps or {}
  if not (mod and mod.world and type(mod.world.spawnNpc) == "function"
      and mod.events and type(mod.events.on) == "function"
      and mod.hooks and type(mod.hooks.wrap) == "function") then
    return nil, "Gen 3 runtime NPC/shop services unavailable"
  end
  local function optional(path)
    if deps[path] then return deps[path] end
    local ok, value = pcall(require,path)
    return ok and value or nil
  end
  local Message=optional("src.ui.game3.message")
  local NativeShop=optional("src.ui.game3.shop_menu")
  local Bag=optional("src.core.game3.bag")
  local Runtime=optional("src.core.game3.runtime")
  if not (Message and type(Message.show)=="function"
      and type(Message.close)=="function"
      and NativeShop and type(NativeShop.show)=="function"
      and Bag and type(Bag.has)=="function" and Runtime
      and type(Runtime.getSession)=="function") then
    return nil, "native Gen 3 shop, message, bag or session unavailable"
  end

  -- Only actually registered numeric item IDs go into the mart. Fixed IDs
  -- are used by the engine and saves, never catalog array positions.
  local byId={}
  for _, row in ipairs(registered or {}) do
    if type(row.id)=="string" and type(row.index)=="number" then
      byId[row.id]=row.index
    end
  end
  local stones,seen={},{}
  for _, row in ipairs(catalog or {}) do
    if row.id~="KEY_STONE" and byId[row.id] and not seen[row.id] then
      seen[row.id]=true
      stones[#stones+1]=byId[row.id]
    end
  end
  local keyStone=byId.KEY_STONE
  if not keyStone or #stones==0 then
    return nil, "Key Stone or registered Mega Stones missing"
  end

  local diagnostics={spawned=0, talks=0, shops=0, lastMap=nil, lastError=nil}
  local idsByMap={}
  local function logFailure(label,err)
    diagnostics.lastError=tostring(label)..": "..tostring(err)
    if mod.log and type(mod.log.warn)=="function" then
      mod.log:warn("Mega lab aide %s",diagnostics.lastError)
    end
  end

  local function stockFor(session)
    local stock={}
    if not (session and session.bag and Bag.has(session.bag,keyStone,1)) then
      stock[1]=keyStone
    end
    for _,id in ipairs(stones) do stock[#stock+1]=id end
    return stock
  end

  local function findPosition(mapId, cfg)
    local Collision=optional("src.core.game3.collision")
    local Objects=optional("src.core.game3.objects")
    for _,xy in ipairs(cfg.positions) do
      local x,y=xy[1],xy[2]
      local walkable=not (Collision and type(Collision.isWalkable)=="function")
        or Collision.isWalkable(x,y)
      local empty=not (Objects and type(Objects.at)=="function")
        or Objects.at(x,y)==nil
      if walkable and empty then return x,y end
    end
    return nil,nil
  end

  local function spawnFor(mapId)
    local cfg=configFor(mapId)
    if not cfg then return false end
    if not mod.world.current then return false end
    local current=mod.world:current()
    if not (current and current.mapId==mapId) then return false end
    local old=idsByMap[mapId]
    if old and mod.world.npc and mod.world:npc(mapId,old) then return true end
    local x,y=findPosition(mapId,cfg)
    if not x then
      logFailure("placement","no free lab position: "..mapId)
      return false
    end
    local id,err=mod.world:spawnNpc(mapId,{
      name="MEGA_LAB_FUNDRAISER", x=x,y=y,
      graphicsId=cfg.graphicsId, elevation=3,
      movement="STAY", facing="down", range="DOWN",
      text="MEGA_LAB_FUNDRAISER",
    })
    if not id then logFailure("spawn",err); return false end
    idsByMap[mapId]=id
    diagnostics.spawned=diagnostics.spawned+1
    diagnostics.lastMap=mapId
    if mod.log and type(mod.log.info)=="function" then
      mod.log:info("Mega lab aide at %s (%d,%d), NPC %s",mapId,x,y,tostring(id))
    end
    return true
  end

  local function isOurNpc(target)
    local def=target and target.def
    if not (def and def.runtime and def.owner==mod.id
        and def.name=="MEGA_LAB_FUNDRAISER") then return false end
    return configFor(def.mapId or target.originMapId)~=nil
  end

  mod.hooks:wrap("world.talk",function(next,game,target)
    if not isOurNpc(target) then return next(game,target) end
    local session=Runtime.getSession()
    if not session then return next(game,target) end
    if NativeShop.isOpen and NativeShop.isOpen() then return true end
    if Message.isOpen and Message.isOpen() then return true end
    local mapId=target.def.mapId or target.originMapId
    local cfg=configFor(mapId)
    if not cfg then return next(game,target) end
    diagnostics.talks=diagnostics.talks+1
    local msg="PROF. "..cfg.professor.."'S LAB NEEDS FUNDS!\nSPECIAL STONES FOR SALE!"
    Message.show(msg,function()
      Message.close()
      local stock=stockFor(session)
      if #stock==0 then return end
      NativeShop.show({items=stock,session=session})
      diagnostics.shops=diagnostics.shops+1
    end)
    return true
  end)

  mod.events:on("map.entered",function(ev)
    if ev and ev.mapId then spawnFor(ev.mapId) end
  end)
  mod.events:on("map.reloaded",function(ev)
    if ev and ev.mapId then spawnFor(ev.mapId) end
  end)
  mod.events:on("game.ready",function()
    local current=mod.world.current and mod.world:current()
    if current then spawnFor(current.mapId) end
  end)
  -- Some versions announce an entered map before Field.running becomes
  -- available. Retry on movement; never spawn a second copy in the same map.
  mod.events:on("world.stepped",function(ev)
    local current=mod.world.current and mod.world:current()
    if current and configFor(current.mapId) and not idsByMap[current.mapId] then
      spawnFor(current.mapId)
    end
  end)

  return {
    stockFor=stockFor, spawnFor=spawnFor,
    diagnostics=function()
      local result={}
      for k,v in pairs(diagnostics) do result[k]=v end
      return result
    end,
  }
end

return Shop
