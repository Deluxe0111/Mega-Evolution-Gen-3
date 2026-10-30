local Model = dofile("src/mega_tuner_model.lua")
local Screen = dofile("src/mega_calibrator.lua")
local forms={{slug="mega_venusaur"},{slug="mega_mewtwo_x"}}
local settings={
  mega_venusaur={
    back={scale=1,feet=100,baseline=57,dx=0,dy=0},
    front={scale=1,feet=98,baseline=62,dx=0,dy=0},
  },
  mega_mewtwo_x={
    back={scale=1,feet=86,baseline=57,dx=0,dy=4},
    front={scale=1,feet=71,baseline=62,dx=0,dy=0},
  }
}
local registry,hooks,cache,exported={}, {}, {}, {}
local G,drawn,texts={}, {}, {}
for _,fn in ipairs({"setColor","rectangle","ellipse","push","pop","print","origin","setScissor"}) do
  G[fn]=function()end
end
G.draw=function(img,quad,x,y,rot,sx,sy)
  drawn[#drawn+1]={image=img,quad=quad,x=x,y=y,sx=sx,sy=sy}
end
local font={
  COLOR={WHITE={fg={1,1,1,1},shadow={0,0,0,1}}},
  draw=function(str,x,y,opts)
    texts[#texts+1]={str=str,x=x,y=y,opts=opts}
  end
}
local mod={
  content={screens={register=function(_,name,rec)registry[name]=rec;return true end}},
  hooks={wrap=function(_,name,fn) hooks[name]=fn end},
  ui={insertBefore=function(items,anchor,row)items[#items+1]=row;return items end},
  cache={write=function(_,key,body)cache[key]=body;return true end}
}
local game={stack={pops=0,pop=function(self)self.pops=self.pops+1 end}}
mod.ui.push=function(game_,name)
  assert(registry[name] and game_==game)
  return registry[name].new(game)
end
local art={frame=function(_,side,frame)
  assert(side=="back" or side=="front" or side=="front_shiny" or side=="back_shiny")
  return {image={name=side},quad={name="quad"},w=121,h=121,cropX=5,cropY=21}
end}
local tool=assert(Screen.install(mod,Model,forms,settings,art,{
  graphics=G, font=font,
  background={draw=function()return false end},
  pushScreen=mod.ui.push, isVisible=function()return true end,
  writeFile=function(name,body)exported[name]=body;return true end
}))
local items=hooks["ui.start_menu.items"](function(_,orig)return orig end,game,{{label="SAVE"}})
assert(#items==2 and items[2].label=="MEGA TUNER")
local screen=tool.open(game)
assert(screen.gbaCanvas and screen.isOpaque and screen.kind=="mega_calibrator")
local function tap(name,heldB)
  game.input={
    wasPressed=function(_,button)return button==name end,
    isDown=function(_,button)return button=="b" and heldB==true end,
  }
  screen:update(1/60)
end
screen:draw()
assert(#drawn==2,"must draw both sides without starting a real battle")
assert(drawn[1].sx==1 and drawn[2].sx==1)
assert(drawn[2].x==72-121/2+5)
assert(drawn[2].y==76-32+57-100+21)
assert(#texts==5,"two top labels and three help lines expected")
for _,label in ipairs(texts) do
  assert(label.opts.small==true,"must use crisp native small font")
  assert(label.x==math.floor(label.x) and label.y==math.floor(label.y))
end
assert(texts[3].str:find("L/R:",1,true))
assert(texts[4].str:find("B+UP/DN:",1,true))
-- D-pad moves the selected BACK without browsing Megas.
tap("left");tap("up")
assert(screen.model:slug()=="mega_venusaur")
assert(screen.model:row().dx==-1 and screen.model:row().dy==-1)
-- Without B, vertical input must NEVER scale.
assert(screen.model:row().scale==1)
-- With B held, vertical input scales by 0.05 and does not move.
tap("up",true)
assert(screen.model:row().scale==1.05 and screen.model:row().dy==-1)
tap("down",true)
assert(screen.model:row().scale==1)
tap("b") -- B alone is a modifier, not back/exit
assert(game.stack.pops==0)
tap("a")
assert(screen.model.side=="front")
tap("right");tap("down")
assert(screen.model:row().dx==1 and screen.model:row().dy==1)
tap("select")
assert(screen.model.shiny)
tap("r")
assert(screen.model:slug()=="mega_mewtwo_x")
tap("l")
assert(screen.model:slug()=="mega_venusaur")
tap("start")
assert(game.stack.pops==1,"START should export and exit")
assert(cache["exports/mega_presentation_export.lua"])
assert(exported["mega_presentation_export.lua"]==cache["exports/mega_presentation_export.lua"])
local actual=assert(load(exported["mega_presentation_export.lua"]))()
assert(actual.mega_venusaur.back.dx==-1 and actual.mega_venusaur.back.dy==-1)
assert(actual.mega_venusaur.front.dx==1 and actual.mega_venusaur.front.dy==1)
assert(actual.mega_venusaur.back.scale==1)
assert(actual.mega_venusaur.back.feet==100 and actual.mega_venusaur.back.baseline==57)
assert(settings.mega_venusaur.back.dx==0,"save/game presentation must not mutate")
assert(type(tool.text())=="string")
-- Export failure must retain UI/unsaved edits rather than silently exit.
local failTool=assert(Screen.install({
  content={screens={register=function(_,name,rec)registry[name]=rec end}},
  hooks={wrap=function()end},
  ui=mod.ui,
},Model,forms,settings,art,{
  graphics=G,font=font,pushScreen=mod.ui.push,
  background={draw=function()return false end}
}))
local bad=failTool.open(game)
game.stack.pops=0
game.input={wasPressed=function(_,k)return k=="start" end,isDown=function()return false end}
bad:update(1/60)
assert(game.stack.pops==0 and bad.message:find("SAVE FAILED",1,true))
print("PASS: shoulder browse, D-pad offsets, B+Up/Down scale, A side, SELECT shiny, pixel font, Start save+exit")
