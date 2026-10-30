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
local G={}
local drawn={}
for _,fn in ipairs({"setColor","rectangle","ellipse","push","pop","print","origin","setScissor"}) do
  G[fn]=function()end
end
G.draw=function(img,quad,x,y,rotation,scaleX,scaleY)
  drawn[#drawn+1]={image=img,quad=quad,x=x,y=y,sx=scaleX,sy=scaleY}
end
local mod={
  content={screens={register=function(_,name,record)registry[name]=record;return true end}},
  hooks={wrap=function(_,name,fn) hooks[name]=fn end},
  ui={insertBefore=function(_,items,anchor,row)
    items[#items+1]=row
    return items
  end},
  cache={write=function(_,key,body) cache[key]=body;return true end},
}
local game={stack={pops=0,pop=function(self) self.pops=self.pops+1 end}}
mod.ui.push=function(_,screen)
  assert(registry[screen],"registered screen required")
  return registry[screen].new(game)
end
local art={
  frame=function(_,side,frame)
    assert(side=="back" or side=="front" or side=="front_shiny" or side=="back_shiny")
    return {image={name=side},quad={name="quad"},
      w=121,h=121,cropX=5,cropY=21}
  end
}
local shared={}
local tool=assert(Screen.install(mod,Model,forms,settings,art,{
  graphics=G,background={draw=function()return false end},
  isVisible=function()return true end,
  writeFile=function(name,body) exported[name]=body;return true end,
}))
local items=hooks["ui.start_menu.items"](function(_game,orig)return orig end,game,{{label="SAVE"}})
assert(#items==2 and items[2].label=="MEGA TUNER")
local view=items[2].onSelect() -- onSelect currently does not return screen
assert(registry.MegaBattleCalibrator)
local screen=tool.open(game)
assert(screen and screen.gbaCanvas and screen.kind=="mega_calibrator")
local function tap(name)
  game.input={wasPressed=function(_,button)return button==name end}
  screen:update(1/60)
end
screen:draw()
assert(#drawn==2,"both sides must render without entering a real battle")
assert(drawn[1].sx==1 and drawn[2].sx==1)
-- Back preview must use the original source frame and shared alpha crop;
-- it must not be automatically centred every animation frame.
assert(drawn[2].x == 72 - 121/2 + 5)
assert(drawn[2].y == 76 - 32 + 57 - 100 + 21)
tap("a")
assert(screen.model.mode=="tune")
tap("left")
assert(screen.model:row().scale==0.95)
screen:draw()
assert(drawn[#drawn].sx==.95)
tap("select")
assert(screen.model.side=="front")
tap("down");tap("right")
assert(screen.model:row().dx==1)
tap("a")
assert(screen.model.shiny)
tap("start")
assert(cache["exports/mega_presentation_export.lua"])
assert(exported["mega_presentation_export.lua"]==cache["exports/mega_presentation_export.lua"])
local result=assert(load(exported["mega_presentation_export.lua"]))()
assert(result.mega_venusaur.back.scale==.95)
assert(result.mega_venusaur.front.dx==1)
assert(settings.mega_venusaur.back.scale==1)
tap("b")
assert(screen.model.mode=="browse")
tap("right")
assert(screen.model:slug()=="mega_mewtwo_x")
tap("b")
assert(game.stack.pops==1)
assert(type(tool.text())=="string")
print("PASS: menu screen, animated battle-stage previews, real coords, keyboard edits, export and save isolation")
