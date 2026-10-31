local Interactions=dofile("src/mega_ability_interactions.lua")
local Standalone=dofile("src/mega_standalone.lua")

local visible={}
local game={
  view=function(mon)return visible[mon] end,
  stat=function()return nil end,
  finish=function()end,
  beforeResolved=function()return false end,
}
local function assign(b,ab)
  visible[b.mon]=ab and {ability=ab} or nil
end
local source={
  id=1,side="enemy",mon={hp=90,maxHp=90},
  ability="INTIMIDATE",expIntimidatePending=true,stages={attack=0}
}
local contrary={
  id=0,side="player",mon={hp=90,maxHp=90},
  stages={attack=0}
}
local defiant={
  id=2,side="player",mon={hp=90,maxHp=90},
  stages={attack=0}
}
local ally={
  id=3,side="enemy",mon={hp=100,maxHp=100},
  stages={attack=0},status="PSN"
}
local st={double=true,enemySide={},playerSide={}}
local active={source,contrary,defiant,ally}
local mist=false
local changes=0
local stageFn=function(_,b,stat,delta,opts)
  assert(stat=="attack" and delta==2 and opts.user==true)
  changes=changes+1
  b.stages.attack=math.min(6,(b.stages.attack or 0)+delta)
  return "worked"
end
local Secondary={changeStat=stageFn}
local ad={
  _st=st,
  activeBattlers=function()return active end,
  abilityOf=function(_,b)return b.ability end,
  foesOf=function(_,b)
    return b==source and {contrary,defiant} or {source}
  end,
  foeOf=function(_,b)return b==source and contrary or source end,
  ownSide=function()return {expMistTurns=mist and 5 or 0} end,
  isFainted=function(_,b)return b.mon.hp<=0 end,
  hp=function(_,b)return b.mon.hp end,
  status=function(_,b)return b.status end,
  clearStatus=function(_,b)b.status=nil end,
  roll=function()return 0 end,
}
local nativeRuns=0
local nativeIntimidate=function(adapter)
  for _,b in ipairs(adapter:activeBattlers()) do
    if b.expIntimidatePending and adapter:abilityOf(b)=="INTIMIDATE" then
      b.expIntimidatePending=nil
      nativeRuns=nativeRuns+1
      local foes=adapter._st.double and adapter:foesOf(b)
        or {adapter:foeOf(b)}
      for _,target in ipairs(foes) do
        if target.mon.hp>0 and (target.substituteHP or 0)<=0
            and (adapter:ownSide(target).expMistTurns or 0)<=0
            and (target.stages.attack or 0)>-6
            and adapter:abilityOf(target)~="CLEAR_BODY" then
          target.stages.attack=target.stages.attack-1
        end
      end
      return true
    end
  end
  return false
end

local function runIntimidate()
  source.expIntimidatePending=true
  return Interactions.withIntimidate(game,ad,Secondary,
    function()return nativeIntimidate(ad)end)
end
assign(contrary,"CONTRARY")
assign(defiant,"DEFIANT")
assert(runIntimidate())
assert(contrary.stages.attack==1,"Contrary reverses native Intimidate")
assert(defiant.stages.attack==1,
  "Defiant ends +1 after -1 Intimidate and +2 reaction")
assert(changes==1)
-- Native failed-to-lower behaviour stays unchanged under Mist/Substitute.
mist=true
assert(runIntimidate())
assert(contrary.stages.attack==1 and defiant.stages.attack==1)
mist=false
contrary.substituteHP=10
defiant.substituteHP=10
assert(runIntimidate())
assert(contrary.stages.attack==1 and defiant.stages.attack==1)
contrary.substituteHP=nil
defiant.substituteHP=nil
-- Upper stage cap applies to Contrary, lower cap to default.
contrary.stages.attack=6
defiant.stages.attack=-6
assert(runIntimidate())
assert(contrary.stages.attack==6 and defiant.stages.attack==-6)
contrary.stages.attack=-6
defiant.stages.attack=5
assert(runIntimidate())
assert(contrary.stages.attack==-5 and defiant.stages.attack==6)
assert(changes==2)
-- When there is no Intimidate pending, nothing should be modified.
source.expIntimidatePending=nil
assert(Interactions.withIntimidate(game,ad,Secondary,
  function()return false end)==false)
assert(contrary.stages.attack==-5 and defiant.stages.attack==6)
-- Actual errors restore the genuine stage representation.
source.expIntimidatePending=true
local ok,err=pcall(Interactions.withIntimidate,game,ad,Secondary,
  function()error("synthetic Intimidate error")end)
assert(not ok and tostring(err):find("synthetic Intimidate error",1,true))
assert(contrary.stages.attack==-5 and defiant.stages.attack==6)
source.expIntimidatePending=nil
-- Without an active Mega form, both behave exactly like stock Gen3.
assign(contrary,nil)
assign(defiant,nil)
contrary.stages.attack=0
defiant.stages.attack=0
assert(runIntimidate())
assert(contrary.stages.attack==-1 and defiant.stages.attack==-1)
assert(nativeRuns==6)

-- Healer: singles, self status, partner fainted, and opponent excluded.
assign(contrary,"HEALER")
contrary.status="PAR"
defiant.status="BRN"
source.status="PSN"
st.double=false
assert(not Interactions.healerEndTurn(game,ad,contrary))
assert(defiant.status=="BRN" and contrary.status=="PAR")
st.double=true
local draw=29
ad.roll=function(_,lo,hi)
  assert(lo==0 and hi==99)
  return draw
end
assert(Interactions.healerEndTurn(game,ad,contrary))
assert(defiant.status==nil and contrary.status=="PAR"
  and source.status=="PSN")
defiant.status="TOX"
draw=30
assert(not Interactions.healerEndTurn(game,ad,contrary))
assert(defiant.status=="TOX")
draw=0
defiant.mon.hp=0
assert(not Interactions.healerEndTurn(game,ad,contrary))
defiant.mon.hp=90
assign(contrary,nil)
assert(not Interactions.healerEndTurn(game,ad,contrary))
-- Native hook integration: same handler references Gen3 residual sequence.
local native={runIntimidate=nativeIntimidate,
  endTurn=function()return false end}
local Ui={_st=st,handleInput=function()return false end,
  takeCommand=function()return nil end,sidePic=function()return nil end}
local Engine={resolveMove=function()return nil end}
local Battle={_st=st,start=function()end,reset=function()end}
local Damage={base=function()return 25 end}
local mod={enabled=true}
local bridge=assert(Standalone.install(mod,game,{
  Ui=Ui,Engine=Engine,Battle=Battle,Damage=Damage,
  NativeAbilities=native,Secondary=Secondary,
  MegaInteraction=Interactions,
}))
assign(contrary,"CONTRARY")
assign(defiant,"DEFIANT")
contrary.stages.attack=0
defiant.stages.attack=0
source.expIntimidatePending=true
assert(native.runIntimidate(ad))
assert(contrary.stages.attack==1 and defiant.stages.attack==1)
assign(contrary,"HEALER")
defiant.status="BRN"
assert(native.endTurn(ad,contrary))
assert(defiant.status==nil)
mod.enabled=false
defiant.status="BRN"
assert(not native.endTurn(ad,contrary))
assert(defiant.status=="BRN")
mod.enabled=true
bridge.uninstall()
assert(native.runIntimidate==nativeIntimidate)
assert(not native.endTurn(ad,contrary))
print("PASS: native Intimidate Contrary/Defiant, Mist/Substitute/stage caps, Healer doubles and hook restoration")
