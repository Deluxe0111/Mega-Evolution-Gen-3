-- NPC Mega Evolution uses the real opponent roster and only one form
-- per enemy side, without touching held items, saved party or AI moves.
local Policy=dofile("src/mega_trainer_policy.lua")
local Selection=dofile("src/mega_selection.lua")
local Mega=dofile("src/mega_battle.lua")
local Forms=dofile("data/mega_battle_forms.lua")
local bySlug={}
for _,r in ipairs(Forms) do bySlug[r.slug]=r end
local typeIds={NORMAL=0,FIGHTING=1,FLYING=2,POISON=3,GROUND=4,ROCK=5,
 BUG=6,GHOST=7,STEEL=8,FIRE=10,WATER=11,GRASS=12,ELECTRIC=13,
 PSYCHIC=14,ICE=15,DRAGON=16,DARK=17}
local function mon(species,form)
  return {species=species,form=form or 0,level=50,hp=120,maxHp=120,
    moves={"TACKLE"},item=0,attack=100,defense=100,spAtk=100,
    spDef=100,speed=100,personality=1}
end
local names={[3]="VENUSAUR",[6]="CHARIZARD",[130]="GYARADOS",
  [16]="PIDGEY",[384]="RAYQUAZA",[678]="MEOWSTIC"}
local policy=Policy.new(Forms,{speciesName=function(sp)return names[sp] end,
  normalizeMove=function(move)return move end})
local function makeState(party)
  local b={side="enemy",id=1,mon=party[1],species=party[1].species,
    partyIndex=1,ability="OVERGROW",type1=12,type2=3,item=0}
  return {foeParty=party,enemy=b,wild=false},b
end
local art={hasSprite=function(slug,kind)return bySlug[slug]~=nil end,
  picture=function(slug,side)return {image=slug..side}end}
local game=Mega.new(Selection.new(),function()return nil end,
  art,Forms,typeIds,policy)
-- No eligible Pokemon -> no Megas, no changed Pokémon or move.
local untouched={mon(16),mon(16)}
local st,b=makeState(untouched)
assert(policy.choose(st)==nil)
assert(not game.beforeResolved(st,b,"TACKLE",1))
assert(game.activeForm(untouched[1])==nil)
game.finish()
-- Wild, link and special battle types are excluded.
local party={mon(3),mon(16),mon(130)}
for _,flag in ipairs({"wild","link","spectate","safari","pokedude",
  "oldManTutorial","ghostBattle","battleTower","trainerTower",
  "eReader","secretBase","frontierTrainer"}) do
  local w={foeParty=party,[flag]=true}
  assert(policy.choose(w)==nil,flag)
end
-- Pick the LAST eligible Pokemon (ace), not the first one.
st,b=makeState(party)
local select=assert(policy.choose(st))
assert(select.slot==3 and select.slug=="mega_gyarados")
assert(policy.formFor(st,b)==nil)
local gyara={side="enemy",id=1,mon=party[3],species=130,
  partyIndex=3,ability="INTIMIDATE",type1=11,type2=2,item=0}
assert(policy.formFor(st,gyara)=="mega_gyarados")
assert(game.beforeResolved(st,gyara,"TACKLE",1))
assert(game.activeForm(party[3])=="mega_gyarados")
assert(gyara.ability==bySlug.mega_gyarados.ability
  or bySlug.mega_gyarados.ability=="")
assert(game.stat(gyara,"attack",0)~=0)
assert(party[3].item==0 and party[3].species==130
  and party[3].attack==100)
-- No second enemy Mega even when another eligible Pokémon enters.
local venus={side="enemy",id=1,mon=party[1],species=3,
  partyIndex=1,ability="OVERGROW",type1=12,type2=3,item=0}
assert(not game.beforeResolved(st,venus,"TACKLE",1))
assert(game.activeForm(party[1])==nil)
-- Re-entry preserves existing Mega.
local returnGyara={side="enemy",id=1,mon=party[3],species=130,
  partyIndex=3,ability="INTIMIDATE",type1=11,type2=2,item=0}
game.switchedIn(returnGyara)
assert(game.activeForm(party[3])=="mega_gyarados")
assert(game.stat(returnGyara,"speed",0)~=0)
game.fainted(party[3])
assert(game.activeForm(party[3])==nil)
assert(not game.beforeResolved(st,venus,"TACKLE",1))
game.finish()
assert(gyara.ability=="INTIMIDATE" and returnGyara.ability=="INTIMIDATE")
-- Deterministic variant fallback, no mystery base form substitution.
local charParty={mon(6)}
st,b=makeState(charParty)
assert(policy.choose(st).slug=="mega_charizard_x")
assert(game.beforeResolved(st,b,"TACKLE",1))
assert(game.activeForm(b.mon)=="mega_charizard_x")
game.finish()
-- Forms with alternate base_form must match.
local badMeowstic={mon(678,99)}
assert(policy.choose({foeParty=badMeowstic})==nil)
local m1={mon(678,1)}
assert(policy.choose({foeParty=m1}).slug=="mega_meowstic_form_3")
-- Rayquaza is only eligible if Dragon Ascent exists in its moveset.
local ray={mon(384)}
assert(policy.choose({foeParty=ray})==nil)
ray[1].moves={"DRAGON_ASCENT"}
assert(policy.choose({foeParty=ray}).slug=="mega_rayquaza")
-- Per-game reviewed override selects the requested existing form, but
-- refuses incorrect slots/forms and supports explicit boss exemptions.
local overrides={
  firered={
    [55]={slot=1,slug="mega_charizard_y"},
    [56]={disabled=true},
    [57]={slot=2,slug="mega_charizard_x"},
  },
}
local curated=Policy.new(Forms,{
  speciesName=function(sp)return names[sp]end,
  normalizeMove=function(m)return m end,
  choices=overrides,
})
local cp={mon(6),mon(130)}
local ch={session={game="firered"},foeParty=cp,trainerId=55}
assert(curated.choose(ch).slug=="mega_charizard_y")
ch.trainerId=56
assert(curated.choose(ch)==nil)
ch.trainerId=57
assert(curated.choose(ch)==nil,"mismatched curated Pokémon must fail closed")
ch.trainerId=58
assert(curated.choose(ch).slot==2,"uncurated foes choose last eligible")
ch.session.game="emerald"
ch.trainerId=55
assert(curated.choose(ch).slot==2,"overrides must not bleed between games")

-- A newly created battle resets the one-per-enemy limit.
local newParty={mon(3)}
st,b=makeState(newParty)
assert(game.beforeResolved(st,b,"TACKLE",1))
assert(game.activeForm(b.mon)=="mega_venusaur")
game.finish()

-- Check the actual standalone Gen3 resolveMove wrapper: transformation
-- must complete before the AI-selected move deals damage, and resetting
-- the battle must return the original battler identity and ability.
local Standalone=dofile("src/mega_standalone.lua")
local engineHits=0
local enemyBeforeAttack={}
local enemyParty={mon(16),mon(3)}
local enemyState,first=makeState(enemyParty)
local npc={side="enemy",id=1,mon=enemyParty[2],species=3,
  partyIndex=2,ability="OVERGROW",type1=12,type2=3,item=0}
enemyState.enemy=npc
local Engine={
  resolveMove=function(user,target,move,slot,adapter,st)
    engineHits=engineHits+1
    enemyBeforeAttack[#enemyBeforeAttack]={ability=user.ability,
      form=game.activeForm(user.mon)}
    return "attack-done"
  end,
  hasFlag=function()return false end,
}
local Damage={base=function()return 100 end}
local Ui={_st=enemyState,handleInput=function()return false end,
  takeCommand=function()return nil end,
  sidePic=function()return nil end}
local Battle={_st=enemyState,_active=true,
  start=function()return "started" end,
  reset=function()return "reset" end}
local mod={enabled=true}
local originalResolve=Engine.resolveMove
local bridge=assert(Standalone.install(mod,game,
  {Ui=Ui,Engine=Engine,Damage=Damage,Battle=Battle}))
assert(Engine.resolveMove(npc,nil,"TACKLE",1,{},enemyState)=="attack-done")
assert(engineHits==1 and enemyBeforeAttack[1].form=="mega_venusaur")
assert(enemyBeforeAttack[1].ability==bySlug.mega_venusaur.ability)
assert(npc.mon.item==0 and npc.mon.species==3)
assert(Engine.resolveMove(npc,nil,"TACKLE",1,{},enemyState)=="attack-done")
assert(engineHits==2 and enemyBeforeAttack[2].form=="mega_venusaur")
assert(npc.mon.item==0)
bridge.uninstall()
assert(Engine.resolveMove==originalResolve and npc.ability=="OVERGROW")
print("PASS: NPC trainer eligibility, ace selection, enemy activation, excluded battles, one Mega, re-entry, reset and native resolveMove")
