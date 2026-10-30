-- Mega battle sizing must match G9's large, feet-anchored back sprites.
-- Normal provider images remain fitted 64x64; battle images may be wider.
local Atlas = dofile("src/mega_atlas.lua")
local presentation = dofile("data/mega_presentation.lua")
local spec = presentation.mega_venusaur
assert(spec.back.scale == 1 and spec.front.scale == 1)
assert(spec.back.feet == 100 and spec.front.feet == 98)
local realIndex = dofile("assets/runtime/mega_atlas_index.lua")
local actual = realIndex.forms.mega_venusaur.variants
for _, variant in ipairs({"back", "back_shiny"}) do
  local seg = actual[variant].segments[1]
  -- Source feet alignment comes from the full animation's common alpha
  -- envelope, never a guessed square-frame edge or per-frame auto-ground.
  assert(seg.cy + seg.fh == spec.back.feet,
    "Mega back anchor does not match packed alpha envelope")
end
for _, variant in ipairs({"front", "front_shiny"}) do
  local seg = actual[variant].segments[1]
  assert(seg.cy + seg.fh == spec.front.feet,
    "Mega front anchor does not match packed alpha envelope")
end
local idx = {schema=1,forms={mega_venusaur={variants={
  back={frames=1,fps=8,segments={{first=0,frames=1,cols=2,fs=121,ox=0,oy=0,sheet=0}}},
  front={frames=1,fps=8,segments={{first=0,frames=1,cols=2,fs=117,ox=0,oy=0,sheet=0}}},
  icon={frames=1,fps=2,segments={{first=0,frames=1,cols=2,fs=64,ox=0,oy=0,sheet=0}}},
}}}}
local created, drawCalls, draws, tagged = {}, {}, {}, {}
local G = {
  newImage=function(path)
    return {path=path,getDimensions=function() return 1024,512 end,
      setFilter=function() end}
  end,
  newQuad=function(x,y,w,h) return {x=x,y=y,w=w,h=h} end,
  newCanvas=function(w,h,opts)
    local c={w=w,h=h,dpi=opts and opts.dpiscale or 1,setFilter=function() end}
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
local ox=(64-121*s)/2 + (spec.back.dx or 0)
local oy=spec.back.baseline-spec.back.feet*s + (spec.back.dy or 0)
local xmin=math.floor(ox)
local ymin=math.floor(oy)
local wantPivotX=32-xmin
local wantPivotY=32-ymin
assert(G.draw==originalDraw, "atlas must never install a global draw wrapper")
-- Simulate a G9/HD wrapper that inspects exact draw arguments; enemy sprites
-- MUST keep the exact call shape, with no extra padded nils or pivot changes.
local enemy = {path="g9/rockruff",getDimensions=function() return 64,64 end}
local enemyQuad = {type="quad"}
local seen = {}
G.draw = function(image, ...)
  seen[#seen+1]={image=image,n=select("#",...),args={...}}
  return originalDraw(image, ...)
end
local hdOrG9Draw = G.draw
local scopedRan = false
a.withBattleDraw(function()
  scopedRan = true
  assert(G.draw~=hdOrG9Draw)
  G.draw(enemy, 120, 34, 0, 1, 1, 32, 32)
  G.draw(enemy, enemyQuad, 120, 34, 0, 1, 1, 32, 32)
  G.draw(wide.image,52,48,0,1,1,32,32)
  G.draw(public.image,52,48,0,1,1,32,32)
end)
assert(scopedRan and G.draw==hdOrG9Draw,
  "original G9/HD draw wrapper must be restored after each frame")
assert(seen[1].image==enemy and seen[1].n==7,
  "opponent sprite should keep original argument count")
assert(seen[1].args[6]==32 and seen[1].args[7]==32)
assert(seen[2].image==enemy and seen[2].n==8,
  "opponent quad rendering must be forwarded with the same arguments")
assert(seen[2].args[7]==32 and seen[2].args[8]==32)
assert(seen[3].image==wide.image and seen[3].args[6]==wantPivotX
  and seen[3].args[7]==wantPivotY,
  "only Mega canvas must receive its feet-aligned pivot")
assert(seen[4].image==public.image and seen[4].args[6]==32
  and seen[4].args[7]==32, "ordinary picture remains unchanged")
local ok=pcall(function()
  a.withBattleDraw(function() G.draw(enemy,120,34); error("intentional draw error") end)
end)
assert(not ok and G.draw==hdOrG9Draw, "must restore G9 drawing even after an error")
G.draw=originalDraw
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
assert(tag.scale==1 and tag.side=="player")
assert(tag.pivot[1]==60.5 and tag.pivot[2]==100)
assert(tag.lowPivot[1]==17 and tag.lowPivot[2]==83)
assert(a.picture("mega_venusaur","back",false,0,true)==full)
-- HD must never run a temporary graphics.draw shim, even if a Mega is
-- visible and a battle picture is requested by the full-resolution provider.
local hdDraw = G.draw
a.withBattleDraw(function()
  assert(G.draw==hdDraw,"Mega shim must not interfere with HD Battle Fit")
end)
assert(G.draw==hdDraw)
-- Menu icons must be independently constrained to 32 logical pixels.
local icon=assert(a.icon("mega_venusaur"))
assert(icon.w==32 and icon.h==32 and icon.image.w==32 and icon.image.h==32)
assert(a.icon("mega_venusaur")==icon)
-- Two imported Mega animations use DIFFERENT source frame dimensions for
-- shiny art. Verify that the renderer uses the geometry-specific feet value
-- and offsets the HD quad's pivot by that animation's common crop origin.
local oddIndex = {schema=1, forms={mega_pyroar={variants={
  front={frames=1, segments={{first=0,frames=1,cols=1,fs=100,
    fw=93,fh=100,cx=3,cy=0,ox=0,oy=0,sheet=0}}},
  front_shiny={frames=1, segments={{first=0,frames=1,cols=1,fs=96,
    fw=86,fh=85,cx=7,cy=7,ox=0,oy=0,sheet=0}}},
}}}}
local odd=assert(Atlas.new(mod,oddIndex,G,function() return 0 end,presentation))
local plain=assert(odd.picture("mega_pyroar","front",false,0,true))
local ptag=tagged[#tagged].spec
assert(ptag.scale==1 and ptag.pivot[2]==100)
assert(ptag.lowPivot[2]==62)
local shining=assert(odd.picture("mega_pyroar","front",true,0,true))
local stag=tagged[#tagged].spec
assert(stag.scale==1 and stag.pivot[2]==85,
  "shiny pivot should use its own feet=92 and original cropY=7")
assert(stag.lowPivot[2]==62 and plain~=shining)
print("PASS: G9 enemy draw untouched, 1x Mega pivots, 32px icons, HD and shiny frame geometry")
