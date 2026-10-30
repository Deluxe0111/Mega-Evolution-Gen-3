-- Reproduce the real Gen1Recomp State.ensureBattleMoves identity mismatch:
-- the battler uses a proxy with private move/PP slots; the party menu gets
-- the original session.party mon. Both must report the SAME active Mega form.
local Selection=dofile("src/mega_selection.lua")
local Mega=dofile("src/mega_battle.lua")
local catalog=dofile("data/mega_battle_forms.lua")
local bySlug={}
for _,row in ipairs(catalog) do bySlug[row.slug]=row end
local expected=assert(bySlug.mega_blastoise)
local base={
  species=9,level=50,personality=0,form=0,hp=155,maxHp=155,
  attack=100,defense=110,spAtk=100,spDef=115,speed=78,
  ivs={atk=20,def=20,spa=20,spd=20,spe=20},
  evs={atk=0,def=0,spa=0,spd=0,spe=0},
  moves={"SURF"},pp={15},
}
local before={species=base.species,attack=base.attack,form=base.form}
local b={mon=base,side="player",species=9,item=100,ability="TORRENT",type1=11}
local st={player=b,playerParty={base}}
local art={
  hasSprite=function(slug,side) return slug=="mega_blastoise" end,
  picture=function(slug,side,shiny)
    return {image=slug..":"..side..":"..tostring(shiny)}
  end
}
local game=Mega.new(Selection.new(),function(_, battler)
  return battler and battler.mon and battler.mon.species==9
    and "mega_blastoise" or nil
end,art,catalog,{WATER=11})
local key=function(name)
  return {wasPressed=function(_,button)return button==name end}
end
local function proxy()
  -- This is the same shape as src/core/game3/battle/state.lua
  -- State.ensureBattleMoves(): proxy has its own moves, and __index=base.
  b._partyMon=base
  b.mon=setmetatable({moves={"SURF"},pp={15}},
    {__index=base,__newindex=base})
  return b.mon
end

-- Path 1: the engine creates its proxy BEFORE move selection.
local p=proxy()
assert(game.input(st,b,key("start")))
local cmd=game.command(st,b,{kind="move",move="SURF",slot=1})
assert(cmd.megaEvolution and cmd.megaEvolution.mon==base,
  "queued Mega should be associated with original party identity")
assert(game.beforeResolved(st,b,"SURF",1))
assert(game.activeForm(p)=="mega_blastoise","battle proxy lost its Mega")
assert(game.activeForm(base)=="mega_blastoise","party menu did not see Mega")
local view=assert(game.view(base),"party menu must receive active Mega view")
assert(view.slug=="mega_blastoise" and view.ability==expected.ability)
assert(game.view(p).slug==view.slug)
-- Exercise the actual Mega UI -> Pokemon.monIcon hook consumed by FireRed's
-- OAM party roster. This must work for the ORIGINAL save-party record.
local UI=dofile("src/mega_ui.lua")
local Pokemon={
  monIcon=function() return {image="vanilla-icon",quads={[0]=1,[1]=2}} end,
  monFrontPic=function() return {image="normal-front"} end,
  isShiny=function() return false end,
  gender=function() return "M" end,
  speciesOf=function(m) return m.species end,
}
local seen
local bridge=assert(UI.install({},game,{
  picture=function(slug,side) return {image=slug..":"..side} end,
  icon=function(slug,shiny,female)
    seen={slug,shiny,female}
    return {image="mega-blastoise-icon",w=32,h=32,
      quads={[0]={frame=0},[1]={frame=1}}}
  end,
},{Pokemon=Pokemon}))
local icon=Pokemon.monIcon(st.playerParty[1])
assert(icon.image=="mega-blastoise-icon" and icon.quads[0] and icon.quads[1],
  "FireRed PartyMenu cannot resolve the Mega Blastoise animation")
assert(seen[1]=="mega_blastoise" and seen[2]==false)
assert(Pokemon.monIcon({species=1}).image=="vanilla-icon")
bridge.uninstall()
assert(Pokemon.monIcon(base).image=="vanilla-icon")
assert(game.monPicture(st,p,true,false).image=="mega_blastoise:back:false")
assert(game.stat(b,"speed",0)>0)
assert(base.species==before.species and base.attack==before.attack and base.form==before.form)
local switched={mon=base,side="player",species=9,ability="TORRENT",type1=11}
game.switchedIn(switched)
assert(game.activeForm(switched.mon)=="mega_blastoise")
assert(game.view(switched.mon).slug=="mega_blastoise")
assert(game.stat(switched,"speed",0)>0)
game.fainted(p)
assert(game.activeForm(base)==nil and game.activeForm(p)==nil)
assert(game.view(base)==nil and switched.ability=="TORRENT")
game.finish()
assert(game.activeForm(base)==nil)

-- Path 2: action was selected before State.ensureBattleMoves creates proxy.
b.mon=base
b._partyMon=nil
st={player=b,playerParty={base}}
assert(game.input(st,b,key("start")))
local queued=game.command(st,b,{kind="move",move="SURF",slot=1})
assert(queued.megaEvolution.mon==base)
local afterQueue=proxy()
assert(game.beforeResolved(st,b,"SURF",1),
  "proxy creation after move commitment must preserve Mega selection")
assert(game.activeForm(base)=="mega_blastoise")
assert(game.activeForm(afterQueue)=="mega_blastoise")
assert(game.view(base).slug=="mega_blastoise")
game.finish()
assert(game.activeForm(base)==nil and game.view(base)==nil)
assert(base.species==9 and base.form==0 and base.attack==100)
print("PASS: FireRed Blastoise party/switch icon uses original party identity across live move proxies, battle switch, faint and reset")
