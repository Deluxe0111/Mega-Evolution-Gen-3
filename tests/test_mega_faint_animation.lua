-- Regression: a Mega fainted event is NOT the end of the native faint
-- animation. Hold Mega art/stats/ability until Anim.faintMon completes.
local Selection=dofile("src/mega_selection.lua")
local Mega=dofile("src/mega_battle.lua")
local Policy=dofile("src/mega_trainer_policy.lua")
local Standalone=dofile("src/mega_standalone.lua")
local forms=dofile("data/mega_battle_forms.lua")
local bySlug={}
for _,r in ipairs(forms) do bySlug[r.slug]=r end
local mon={
  species=6,form=0,level=50,personality=1,
  hp=160,maxHp=160,attack=100,defense=90,spAtk=120,spDef=95,
  speed=105,moves={"FLAMETHROWER"},item=0
}
local b={id=1,side="enemy",mon=mon,species=6,partyIndex=1,
  ability="BLAZE",type1=10,type2=2,item=0}
local st={enemy=b,battlers={[1]=b},foeParty={mon},wild=false}
local policy=Policy.new(forms,{speciesName=function(id)
  return id==6 and "CHARIZARD" or nil
end})
local art={
  hasSprite=function()return true end,
  picture=function(slug,side)
    return {image=slug..":"..side}
  end
}
local game=Mega.new(Selection.new(),function()return nil end,art,forms,
  {FIRE=10,FLYING=2,DRAGON=16},policy)
assert(game.beforeResolved(st,b,"FLAMETHROWER",1))
assert(game.activeForm(mon)=="mega_charizard_x")
local megaAbility=assert(bySlug.mega_charizard_x.ability)
assert(b.ability==megaAbility)
assert(game.monPicture(st,mon,false,false,nil).image=="mega_charizard_x:front")
local pending
local completed=false
local Anim={
  idOf=function(key)
    assert(key=="enemy" or key==1)
    return 1
  end,
  faintMon=function(key,opts)
    pending=opts.onComplete
    return "animation-running"
  end,
}
local Battle={_st=st,_active=true,
  start=function()end,reset=function()end}
local Ui={_st=st,handleInput=function()end,
  takeCommand=function()end,sidePic=function()end}
local Engine={resolveMove=function()end}
local Damage={base=function()return 50 end}
local original=Anim.faintMon
local bridge=assert(Standalone.install({enabled=true},game,{
  Anim=Anim,Battle=Battle,Ui=Ui,Engine=Engine,Damage=Damage
}))
assert(bridge.faintAnimationHooked)
mon.hp=0
assert(game.faintPending(mon))
assert(game.faintPendingFor(mon))
assert(game.activeForm(mon)=="mega_charizard_x")
assert(b.ability==megaAbility)
local result=Anim.faintMon("enemy",{onComplete=function()
  completed=true
  assert(game.activeForm(mon)==nil)
  assert(b.ability=="BLAZE")
end})
assert(result=="animation-running" and type(pending)=="function")
-- All animation frames still display the Mega, even though HP is zero.
assert(game.monPicture(st,mon,false,false,nil).image=="mega_charizard_x:front")
assert(game.picture(b,false,false,nil).image=="mega_charizard_x:front")
assert(game.activeForm(mon)=="mega_charizard_x")
assert(b.ability==megaAbility)
pending()
assert(completed and not game.faintPendingFor(mon))
assert(game.activeForm(mon)==nil and b.ability=="BLAZE")
assert(game.monPicture(st,mon,false,false,nil)==nil)
assert(not game.beforeResolved(st,b,"FLAMETHROWER",1),
  "KO must not refund the opposing side's once-per-battle Mega")
bridge.uninstall()
assert(Anim.faintMon==original)
-- Battle exit and forced reset clean up a pending death even if the game
-- exits before the native sprite tween can call its completion callback.
mon.hp=160
game.finish()
assert(game.beforeResolved(st,b,"FLAMETHROWER",1))
mon.hp=0
assert(game.faintPending(mon))
game.finish()
assert(game.activeForm(mon)==nil and b.ability=="BLAZE")
print("PASS: Mega KO retains front sprite and ability until native faint animation ends")
