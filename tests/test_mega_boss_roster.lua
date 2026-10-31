-- All 32 approved boss picks: exact ROM-ID verification, safe add only
-- when a party slot exists, complete-starter rival, no replacement and
-- native Battle.start integration. No local ROM fixture needed.
local Approvals=dofile("data/mega_boss_selections.lua")
local Forms=dofile("data/mega_forms.lua")
local Boss=dofile("src/mega_boss_roster.lua")
local Policy=dofile("src/mega_trainer_policy.lua")
local Standalone=dofile("src/mega_standalone.lua")
assert(#Approvals.firered==14 and #Approvals.hoenn==18)
local formBySlug={}
local byName,byId={},{}
for _,row in ipairs(Forms) do formBySlug[row.slug]=row end
local ids={VENUSAUR=3,CHARIZARD=6,BLASTOISE=9,AERODACTYL=142,
 STARMIE=121,RAICHU=26,VICTREEBEL=71,BEEDRILL=15,ALAKAZAM=65,
 PYROAR=668,KANGASKHAN=115,SLOWBRO=80,STEELIX=208,GENGAR=94,
 DRAGONITE=149,MEWTWO=150,GLIMMORA=970,MEDICHAM=308,
 MANECTRIC=310,CAMERUPT=323,ALTARIA=334,MEOWSTIC=678,
 GYARADOS=130,TATSUGIRI=978,ABSOL=359,BANETTE=354,GLALIE=362,
 SALAMENCE=373,METAGROSS=376,HOUNDOOM=229,SHARPEDO=319,
 GARDEVOIR=282,PIDGEY=16}
for name,id in pairs(ids) do byId[id]=name;byName[name]=id end
local pokemon={
 keyName=function(id)return byId[id] end,
 speciesFromName=function(name)return byName[name] end
}
local rom={}
local trainers={
 get=function(id)return rom[id] end,
 pack=function()return {trainers=rom}end
}
local boss=Boss.new(Approvals,Forms,{pokemon=pokemon,trainers=trainers})
local function sample(id,name,class,party)
  rom[id]={id=id,name=name,className=class,party=party}
  return rom[id]
end
local function mon(species,level)
  return {species=ids[species],level=level or 30,rawIv=100,iv=12,
    hp=100,maxHp=100,moves={"TACKLE"},form=0}
end
local function opts(id,party,game)
  return {trainerId=id,gameId=game or "firered",
    playerParty={mon("PIDGEY",10)},
    foe={trainerId=id,nativeNpcTrainer=true,
      party=party,trainerName=rom[id].name}}
end
local function assess(id,game)
  local original=rom[id].party
  return boss.assess(game,id,original)
end
-- Verify all user selections remain present and addressable.
for _,region in ipairs({"firered","hoenn"}) do
  local seen={}
  for _,entry in ipairs(Approvals[region]) do
    assert(not seen[entry.key] and (entry.slug=="starter_x"
      or formBySlug[entry.slug]),entry.key)
    seen[entry.key]=true
  end
end
-- Brock's chosen Aerodactyl: add to a 2-mon ROM team, never overwrite.
local brockParty={mon("PIDGEY",12),mon("PIDGEY",14)}
sample(101,"BROCK","LEADER",brockParty)
local report=assess(101,"firered")
assert(report.key=="brock" and report.status=="add"
  and report.slot==3 and report.species==ids.AERODACTYL
  and report.level==14)
local originalCount=#brockParty
local patched,decision=boss.prepare(opts(101,brockParty),"firered")
assert(patched~=nil and decision.status=="add"
  and #patched.foe.party==3
  and patched.foe.party[3].species==ids.AERODACTYL
  and patched.foe.party[3].level==14
  and patched.foe.party[3].heldItem==nil
  and #brockParty==originalCount)
assert(patched.foe.party[1]==brockParty[1])
local same=opts(101,brockParty)
local returned,wrong=boss.prepare(same,"emerald")
assert(returned==same and wrong.status=="not_approved")
-- Misty already has Starmie; do not add a duplicate.
local mistyParty={mon("PIDGEY",18),mon("STARMIE",21)}
sample(102,"MISTY","LEADER",mistyParty)
local already=assess(102,"firered")
assert(already.status=="existing" and already.slot==2
  and already.slug=="mega_starmie")
local existingOpts,existingReport=boss.prepare(opts(102,mistyParty),"firered")
assert(#existingOpts.foe.party==2 and existingReport.status=="existing")
-- Full teams require another decision, no replacements are ever guessed.
local full={}
for i=1,6 do full[i]=mon("PIDGEY",i+10) end
sample(103,"KOGA","LEADER",full)
local blocked=assess(103,"firered")
assert(blocked.status=="full_party_needs_approval")
local originalOpts=opts(103,full)
local returnedFull=boss.prepare(originalOpts,"firered")
assert(returnedFull==originalOpts and #full==6)
-- Wrong trainer class/name cannot authorise a famous boss ID.
sample(104,"BROCK","HIKER",{mon("PIDGEY")})
assert(assess(104,"firered").status=="not_approved")
sample(105,"GIOVANNI","LEADER",{mon("KANGASKHAN")})
sample(106,"GIOVANNI","BOSS",{mon("PIDGEY")})
assert(assess(105,"firered").slug=="mega_kangaskhan")
assert(assess(106,"firered").slug=="mega_mewtwo_y")
-- Even with the correct ID, altered party species/levels fails closed.
local corrupted=opts(101,{mon("PIDGEY",7),mon("PIDGEY",14)})
local noPatch,mismatch=boss.prepare(corrupted,"firered")
assert(noPatch==corrupted and mismatch.status=="rom_party_mismatch")
-- If National Dex species is unavailable, Roxanne's Glimmora
-- remains queued, without inserting an invalid species ID.
sample(107,"ROXANNE","LEADER",{mon("PIDGEY",13)})
byName.GLIMMORA=nil
assert(assess(107,"emerald").status=="species_not_registered")
byName.GLIMMORA=ids.GLIMMORA
assert(assess(107,"emerald").status=="add")
-- Tate & Liza's double battle needs owner/party partition review.
sample(108,"TATE&LIZA","LEADER",{mon("PIDGEY",40)})
assert(assess(108,"emerald").status=="double_party_review")
-- Rival Champion: detect actual starter, no auto-add to missing team.
sample(109,"TERRY","CHAMPION",{mon("CHARIZARD",60)})
assert(assess(109,"firered").slug=="mega_charizard_x")
rom[109].party={mon("BLASTOISE",60)}
assert(assess(109,"firered").slug=="mega_blastoise")
rom[109].party={mon("VENUSAUR",60)}
assert(assess(109,"firered").slug=="mega_venusaur")
rom[109].party={mon("PIDGEY",60)}
assert(assess(109,"firered").status=="starter_not_present")
-- Pokemon variants and original trainer class are game-aware.
sample(110,"JUAN","LEADER",{mon("PIDGEY",43)})
assert(assess(110,"emerald").slug=="mega_tatsugiri_curly")
assert(assess(110,"ruby").status=="not_approved")
sample(111,"WALLACE","CHAMPION",{mon("GYARADOS",60)})
assert(assess(111,"emerald").status=="existing")
assert(assess(111,"ruby").status=="not_approved")
sample(112,"WALLACE","LEADER",{mon("PIDGEY",44)})
assert(assess(112,"ruby").slug=="mega_gyarados")
assert(assess(112,"emerald").status=="not_approved")
local audit=assert(boss.audit("firered"))
local byKey={}
for _,x in ipairs(audit) do byKey[x.key]=x end
assert(byKey.brock.trainerId==101 and byKey.misty.trainerId==102
  and byKey.giovanni_gym.trainerId==105
  and byKey.giovanni_rocket.trainerId==106)
-- Runtime approved boss choice wins over generic "last eligible."
local policy=Policy.new(Forms,{
  speciesName=function(id)return byId[id] end,
  choices={},
})
local active={mon("STARMIE"),mon("GYARADOS")}
local state={foeParty=active,trainerId=102,
  session={version="firered"},
  megaBossChoice={trainerId=102,slot=1,slug="mega_starmie"}}
assert(policy.choose(state).slot==1 and
  policy.choose(state).slug=="mega_starmie")
state.megaBossChoice={trainerId=102,slot=1,slug="mega_beedrill"}
assert(policy.choose(state)==nil)
-- Integration uses the native Battle.start boundary, and applies its
-- report to st only AFTER a successful native start.
local observed
local Battle={_active=false}
Battle.start=function(options)
  observed=options
  Battle._st={trainerId=options.trainerId,foeParty=options.foe.party,
    session={version=options.gameId}}
  Battle._active=true
  return "started"
end
Battle.reset=function()end
local Ui={handleInput=function()return false end,
 takeCommand=function()end,sidePic=function()end}
local Engine={resolveMove=function()end,hasFlag=function()return false end}
local Damage={base=function()return 100 end}
local game={finish=function()end,
 beforeResolved=function()end,
 input=function()end,command=function(_,_,a)return a end}
local bridge=assert(Standalone.install({enabled=true},game,{
  Battle=Battle,Ui=Ui,Engine=Engine,Damage=Damage,
  MegaBoss=boss,
}))
local current=opts(101,brockParty)
assert(Battle.start(current)=="started")
assert(observed~=current and #observed.foe.party==3)
assert(Battle._st.megaBossChoice.trainerId==101
  and Battle._st.megaBossChoice.slug=="mega_aerodactyl"
  and Battle._st.megaBossChoice.slot==3)
bridge.uninstall()
assert(#brockParty==2)
print("PASS: 32 approved Megas, verified ROM IDs/parties, safe add, no replacement, class/edition, National Dex, rival variants and native start")
