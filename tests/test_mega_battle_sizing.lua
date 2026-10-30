-- Mega battle sizing must match G9's large, feet-anchored back sprites.
-- Normal provider images remain fitted 64x64; battle images may be wider.
local Atlas = dofile("src/mega_atlas.lua")
local presentation = dofile("data/mega_presentation.lua")
local spec = presentation.mega_venusaur
assert(spec.back.scale == 0.80 and spec.front.scale == 0.74)
local idx = {schema=1,forms={mega_venusaur={variants={
  back={frames=1,fps=8,segments={{first=0,frames=1,cols=2,fs=121,ox=0,oy=0,sheet=0}}},
  front={frames=1,fps=8,segments={{first=0,frames=1,cols=2,fs=117,ox=0,oy=0,sheet=0}}},
}}}}
local created, drawCalls, draws, tagged = {}, {}, {}, {}
local G = {
  newImage=function(path)
    return {path=path,getDimensions=function() return 1024,512 end,
      setFilter=function() end}
  end,
  newQuad=function(x,y,w,h) return {x=x,y=y,w=w,h=h} end,
  newCanvas=function(w,h,opts)
    local c={w=w,h=h,dpi=opts.dpiscale,setFilter=function() end}
    created[#created+1]=c
    return c
  end,
  push=function() end, pop=function() end,
  origin=function() end, setScissor=function() end,
  setShader=function() end, setBlendMode=function() end,
  setColor=function() end, setCanvas=function() end, clear=function() end,
  draw=function(...)
    drawCalls[#drawCalls+1]={...}
  end,
}
local originalDraw=G.draw
local mod = {path="mods/mega",find=function() return nil end}
local a=assert(Atlas.new(mod,idx,G,function() return 0 end,presentation))
local public=assert(a.picture("mega_venusaur","back",false,0))
assert(public.image.w==64 and public.image.h==64 and public.image.dpi==4)
local wide=assert(a.picture("mega_venusaur","back",false,0,true))
assert(wide.image.w>64 and wide.image.h>64 and wide.image.dpi==2)
assert(wide~=public)
assert(a.picture("mega_venusaur","back",false,0,true)==wide)
local s=spec.back.scale
local ox=(64-121*s)/2
local oy=spec.back.baseline-spec.back.feet*s
local xmin=math.floor(ox)
local ymin=math.floor(oy)
local wantPivotX=32-xmin
local wantPivotY=32-ymin
G.draw(wide.image,52,48,0,1,1,32,32)
local call=drawCalls[#drawCalls]
assert(call[7]==wantPivotX and call[8]==wantPivotY,
  "G9-wide canvas pivot should keep Mega Venusaur on its feet")
G.draw(public.image,52,48,0,1,1,32,32)
call=drawCalls[#drawCalls]
assert(call[7]==32 and call[8]==32,"ordinary art untouched")
local front=assert(a.picture("mega_venusaur","front",false,0,true))
assert(front.image.w>64,"enemy Mega fronts are wide as well")
-- An installed HD module should receive the atlas SOURCE (not a 64px crop),
-- and should use the same scale and feet anchor in full-resolution passes.
local hd = {tag=function(img,options) tagged[#tagged+1]={image=img,spec=options} end,
  enabled=function(pass) return pass=="battle" end}
mod.find=function() return {exports=hd} end
local full=assert(a.picture("mega_venusaur","back",false,0,true))
assert(full.image.w==64 and full.image.dpi==4)
assert(#tagged==1)
local tag=tagged[1].spec
assert(tag.texture and tag.quad and tag.quad.w==121)
assert(tag.scale==0.80 and tag.side=="player")
assert(tag.pivot[1]==60.5 and tag.pivot[2]==111)
assert(tag.lowPivot[1]==32 and tag.lowPivot[2]==57)
assert(a.picture("mega_venusaur","back",false,0,true)==full)
print("PASS: fitted public art, large G9-style back/front, feet pivot, and full-res HD sprite tag")
