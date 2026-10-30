local Atlas = dofile("src/mega_atlas.lua")
local idx={schema=1,forms={mega_venusaur={variants={}}}}
for _,kind in ipairs({"icon","icon_shiny"}) do
  idx.forms.mega_venusaur.variants[kind]={
    frames=2,fps=2,segments={{first=0,frames=2,cols=2,fs=64,
      fw=58,fh=54,cx=3,cy=5,sheet=0,ox=2,oy=2,stepX=62,stepY=58}}
  }
end
local draws,filter,canvases={}, {}, {}
local femaleFiles=true
local sourceFiles=true
local G={}
G.newImage=function(path)
  if path:find("/mega_venusaur/",1,true) then
    if not sourceFiles or (not femaleFiles and path:find("female",1,true)) then
      error("optional EBDX source absent: "..path)
    end
    return {path=path,getDimensions=function()return 128,64 end,
      setFilter=function(_,a,b)assert(a=="nearest" and b=="nearest")end}
  end
  assert(path:find("battle_icon",1,true),path)
  return {path=path,getDimensions=function()return 2048,1024 end,
    setFilter=function(_,a,b)assert(a=="nearest" and b=="nearest")end}
end
G.newQuad=function(x,y,w,h,iw,ih)
  return {x=x,y=y,w=w,h=h,iw=iw,ih=ih}
end
G.newCanvas=function(w,h)
  local out={w=w,h=h,setFilter=function(_,a,b)
    filter[#filter+1]={a,b}
  end}
  canvases[#canvases+1]=out
  return out
end
G.push=function()end
G.pop=function()end
G.origin=function()end
G.setScissor=function()end
G.setShader=function()end
G.setColor=function()end
G.setCanvas=function()end
G.clear=function()end
G.draw=function(image,quad,x,y,rot,sx,sy)
  draws[#draws+1]={image=image,quad=quad,x=x,y=y,scaleX=sx,scaleY=sy}
end
local provider=assert(Atlas.new({path="mods/mega"},idx,G,function()return 0 end))
local normal=assert(provider.icon("mega_venusaur",false,false))
assert(normal.w==32 and normal.h==32 and normal.frames==2)
assert(normal.image.w==32 and normal.image.h==64)
assert(normal.quads[0].y==0 and normal.quads[1].y==32)
assert(#draws==2 and draws[1].image.path:find("/mega_venusaur/icon.png",1,true),
  "must read source EBDX icon rather than large battle_icon atlas")
assert(draws[1].quad.x==0 and draws[2].quad.x==64)
assert(draws[1].x==0 and draws[1].y==0)
assert(draws[2].y==32)
assert(normal.source=="ebdx" and normal.sheetH==64)
assert(draws[1].scaleX==.5 and draws[1].scaleY==.5)
assert(provider.icon("mega_venusaur",false,false)==normal)
local shiny=assert(provider.icon("mega_venusaur",true,false))
assert(shiny~=normal and draws[4].image.path:find("/mega_venusaur/icon_shiny.png",1,true))
local female=assert(provider.icon("mega_venusaur",false,true))
assert(female~=normal and draws[5].image.path:find("icon_female.png",1,true))
assert(draws[5].quad.x==0 and draws[6].quad.x==64)
local shinyFemale=assert(provider.icon("mega_venusaur",true,true))
assert(shinyFemale~=female and draws[7].image.path:find("icon_female_shiny.png",1,true))
assert(#filter==4 and filter[4][1]=="nearest")
-- When source lacks a gender-specific file, fall back to regular shiny
-- while retaining 2 native animation frames and the correct 32x32 quads.
femaleFiles=false
local fallback=assert(Atlas.new({path="mods/mega"},idx,G,function()return 0 end))
local fallbackShiny=assert(fallback.icon("mega_venusaur",true,true))
assert(fallbackShiny.quads[0] and fallbackShiny.quads[1])
assert(draws[#draws].image.path:find("icon_shiny.png",1,true),
  "female icon fallback must retain shiny artwork")
-- If original EBDX PNGs are missing, the packed atlas remains a fallback.
sourceFiles=false
local fallbackAtlas=assert(Atlas.new({path="mods/mega"},idx,G,function()return 0 end))
local atlasIcon=assert(fallbackAtlas.icon("mega_venusaur",false,false))
assert(atlasIcon.quads[0] and atlasIcon.quads[1])
assert(draws[#draws].image.path:find("battle_icon_0.png",1,true))
print("PASS: native source Mega party PNG strips at 32px, male/female shiny variants, packed atlas fallback")
