local Visual = dofile("src/mega_battle_ui.lua")
local clock = 10
local enabled,armed,active = true,false,false
local mon={}
local b={mon=mon,side="player"}
local st={player=b, enemy={mon={},side="enemy"}}
local calls={toggle=0}
local game={
  activeForm=function(m) return active and m == mon and "mega_venusaur" or nil end,
  status=function(s,battler)
    if battler~=b or not enabled or active then return nil,false end
    return armed and "MEGA READY" or "START: MEGA",true
  end,
  input=function(s,battler,input)
    assert(s==st and battler==b and input:wasPressed("start"))
    armed=not armed
    calls.toggle=calls.toggle+1
    return true
  end,
}
local drawn,quads,files={}, {}, {}
local G={}
local dimensions={button={88,44},badge={26,34},flash={30,30}}
G.newImage=function(file)
  local key=file:find("megaButton.png",1,true) and "button"
    or file:find("symMega.png",1,true) and "badge"
    or file:find("mega_sym.png",1,true) and "flash"
  assert(key,"unexpected EBDX path "..file)
  files[key]=file
  local wh=dimensions[key]
  return {key=key,getDimensions=function()return wh[1],wh[2] end,
    setFilter=function(_,x,y)assert(x=="nearest" and y=="nearest")end}
end
G.newQuad=function(x,y,w,h,iw,ih)
  local q={x=x,y=y,w=w,h=h,iw=iw,ih=ih}
  quads[#quads+1]=q
  return q
end
G.draw=function(img,...)
  drawn[#drawn+1]={img=img,params={...}}
end
G.push=function()end
G.pop=function()end
G.setColor=function()end
G.rectangle=function()end
local mod={path="mods/mega",enabled=true}
local visual=Visual.new(mod,game,{graphics=G,time=function() return clock end})
local ui={_mode="moves",_swap=nil,_moveIndex=1,_active=0,
  moveGridNavigation=function()return true end}
local function pressed(name)
  return {wasPressed=function(_,other)return other==name end}
end
assert(visual:hit(0,89) and visual:hit(21.9,110.9))
assert(not visual:hit(22,89) and not visual:hit(0,111))
assert(visual:drawButton(st,ui))
assert(drawn[#drawn].img.key=="button")
assert(quads[#quads].x==0 and quads[#quads].w==44 and quads[#quads].h==44)
assert(drawn[#drawn].params[5]==0.5 and drawn[#drawn].params[6]==0.5)
-- Selecting LEFT on first move focuses the new button; A toggles it.
assert(visual:handleInput(ui,st,b,pressed("left")))
assert(visual.focused)
assert(visual:handleInput(ui,st,b,pressed("a")))
assert(armed and calls.toggle==1)
visual:drawButton(st,ui)
assert(quads[#quads].x==44,"active half of 88x44 button")
assert(visual:handleInput(ui,st,b,pressed("right")))
assert(not visual.focused)
-- START remains usable through the existing battle input handler; clicking
-- the new hotspot shares the same commit/toggle path.
assert(visual:toggle(st,b))
assert(not armed and calls.toggle==2)
enabled=false
assert(not visual:toggle(st,b) and not visual:drawButton(st,ui))
enabled=true
ui._mode="menu"
assert(not visual:drawButton(st,ui))
ui._mode="moves"
local Health={center=function(_,id)
    if id%2==0 then return {x=158,y=88}end
    return {x=44,y=30}
  end, draw=function()return "vanilla-box" end}
local original=Health.draw
local anim={stage=function()return {healthbox={}}end}
assert(visual:installHealthbox({Healthbox=Health,Anim=anim}))
assert(Health.draw("player",b,{st=st})=="vanilla-box")
assert(#drawn>=1 and drawn[#drawn].img.key=="button",
  "base Pokémon must not receive Mega badge")
active=true
assert(Health.draw("player",b,{st=st})=="vanilla-box")
local hit=drawn[#drawn]
assert(hit.img.key=="badge" and hit.params[1]==146 and hit.params[2]==83)
local enemy={mon=mon,side="enemy"}
assert(Health.draw("enemy",enemy,{st=st})=="vanilla-box")
hit=drawn[#drawn]
assert(hit.img.key=="badge" and hit.params[1]==24 and hit.params[2]==25)
-- Native double-battle positions and stage animation offsets are resolved,
-- not hardcoded to single-battle locations.
st.double=true
local doubles={center=function(_,id) return {x=171,y=100}end,
  draw=function()return true end}
local visual2=Visual.new(mod,game,{graphics=G,time=function()return clock end})
assert(visual2:drawHealthBadge(2,b,{st=st,ox=5,oy=-3},
  {Healthbox=doubles,Anim={stage=function()return {healthbox={[2]={ox=2,oy=4}}}end}}))
hit=drawn[#drawn]
assert(hit.params[1]==166 and hit.params[2]==96)
-- Transformation flourish uses the dedicated 30x30 symbol, then expires.
visual:onMegaEvolved(b)
clock=10.3
visual:drawOverlay(st,ui)
assert(drawn[#drawn].img.key=="flash")
clock=10.9
visual:drawOverlay(st,ui)
assert(visual.lastFlash==nil)
visual:uninstall()
assert(Health.draw==original)
assert(files.button:find("megaButton.png",1,true))
assert(files.badge:find("symMega.png",1,true))
assert(files.flash:find("mega_sym.png",1,true))
print("PASS: EBDX two-state button, D-pad/A & mouse/START toggles, healthbox badge, cosmetic transform flash")
