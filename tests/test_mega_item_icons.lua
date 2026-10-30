local Icons = dofile("src/mega_item_icons.lua")
local rows = dofile("data/mega_items.lua")
local ids = {}
for _, row in ipairs(rows) do ids[row.id] = row.index end
local calls = { paths={}, draw={}, frlg=0, rse=0 }
local graphics = {
  newImage=function(path)
    calls.paths[#calls.paths+1]=path
    return { getDimensions=function() return 32, 32 end, setFilter=function() end }
  end,
  setColor=function() end,
  draw=function(image,x,y,rot,sx,sy,ox,oy)
    calls.draw[#calls.draw+1]={x=x,y=y,sx=sx,sy=sy,ox=ox,oy=oy}
  end,
}
local frlg = {drawItemIcon=function() calls.frlg=calls.frlg+1; return false end}
local rse = {drawItemIcon=function() calls.rse=calls.rse+1 end}
local oldFRLG, oldRSE=frlg.drawItemIcon,rse.drawItemIcon
local module = {
  ["src.ui.game3.bag_chrome"]=frlg,
  ["src.ui.game3.rse.bag_chrome"]=rse,
}
local bridge,err=Icons.install({path="mods/mega"},
  rows,{graphics=graphics,require=function(p) return module[p] end})
assert(bridge, tostring(err))
assert(frlg.drawItemIcon(ids.VENUSAURITE,8,124))
assert(calls.paths[1]=="mods/mega/assets/source/ebdx/mega_stones/VENUSAURITE.png")
assert(#calls.draw==1 and calls.draw[1].sx==0.75)
assert(rse.drawItemIcon(ids.KEY_STONE,8,16)==true)
assert(calls.paths[2]=="mods/mega/assets/source/ebdx/ui_reference/Graphics/Items/MEGARING.png")
assert(calls.draw[2].x==8 and calls.draw[2].sx==0.75)
assert(frlg.drawItemIcon(5,8,124)==false and calls.frlg==1)
rse.drawItemIcon(5,8,16)
assert(calls.rse==1)
assert(#calls.paths==2)
bridge.uninstall()
assert(frlg.drawItemIcon==oldFRLG and rse.drawItemIcon==oldRSE)
print("PASS: FRLG/RSE Mega Stone icons, Key Stone icon, scaling, fallback and uninstall")
