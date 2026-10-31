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
 GARDEVOIR=282,PIDGEY=16,EKANS=23,
 AERODACTYL=142,GOLEM=76,OMASTAR=139,KABUTOPS=141,NOSEPASS=299,
 LAPRAS=131,WHISCASH=340,POLIWHIRL=61,WALREIN=365,CRAWDAUNT=342,
 KINGDRA=230,POLITOED=186,CLAYDOL=344,XATU=178,LUNATONE=337,
 SOLROCK=338,SLOWPOKE=79,DROWZEE=96,HYPNO=97,SLOWKING=199,
 STEELIX=208}
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
local earlyRocket={
  mon("PIDGEY",25),mon("PIDGEY",24),mon("KANGASKHAN",29)}
sample(348,"GIOVANNI","BOSS",earlyRocket)
local laterRocket={
  mon("PIDGEY",37),mon("KANGASKHAN",35),
  mon("PIDGEY",37),mon("PIDGEY",41)}
sample(349,"GIOVANNI","BOSS",laterRocket)
assert(assess(105,"firered").slug=="mega_kangaskhan")
local early=assess(348,"firered")
assert(early.status=="disabled_by_choice" and early.slug==nil)
local earlyOpts=opts(348,earlyRocket)
local unchanged,earlyReport=boss.prepare(earlyOpts,"firered")
assert(unchanged==earlyOpts and earlyReport.status=="disabled_by_choice")
local later=assess(349,"firered")
assert(later.slug=="mega_mewtwo_y" and later.status=="add"
  and later.slot==5 and later.level==41)
local lateOpts,lateReport=boss.prepare(opts(349,laterRocket),"firered")
assert(lateReport.status=="add" and #lateOpts.foe.party==5
  and lateOpts.foe.party[5].species==ids.MEWTWO)
assert(assess(349,"leafgreen").status=="not_approved",
  "Don't guess unverified LeafGreen Rocket trainer IDs")
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
-- The FireRed import contains a #38 CHAMPION placeholder with no name
-- and one Lv.5 Ekans. That record is NOT the Champion Rival.
sample(38,"","CHAMPION",{mon("EKANS",5)})
assert(assess(38,"firered").status=="not_approved")
-- Real six-mon Rival Champion: select actual fully evolved starter.
local function rivalParty(starter)
  return {mon("PIDGEY",59),mon("PIDGEY",57),
    mon("PIDGEY",59),mon("PIDGEY",59),
    mon("PIDGEY",61),mon(starter,63)}
end
sample(109,"TERRY","CHAMPION",rivalParty("CHARIZARD"))
assert(assess(109,"firered").slug=="mega_charizard_x")
rom[109].party=rivalParty("BLASTOISE")
assert(assess(109,"firered").slug=="mega_blastoise")
rom[109].party=rivalParty("VENUSAUR")
assert(assess(109,"firered").slug=="mega_venusaur")
rom[109].party=rivalParty("PIDGEY")
assert(assess(109,"firered").status=="not_approved",
  "Champion must have a final-stage starter to qualify")
-- Last of two matching Pokémon is the chosen Mega, not the first.
sample(412,"AGATHA","ELITE FOUR",{
  mon("GENGAR",54),mon("PIDGEY",54),mon("PIDGEY",53),
  mon("EKANS",56),mon("GENGAR",58)})
assert(assess(412,"firered").slot==5)
sample(737,"AGATHA","ELITE FOUR",{
  mon("GENGAR",66),mon("PIDGEY",66),mon("PIDGEY",65),
  mon("EKANS",68),mon("GENGAR",70)})
assert(assess(737,"firered").slot==5)
sample(738,"LANCE","ELITE FOUR",{
  mon("PIDGEY",68),mon("DRAGONITE",66),mon("PIDGEY",66),
  mon("PIDGEY",70),mon("DRAGONITE",72)})
assert(assess(738,"firered").slot==5)
-- The dynamic rival fallback also selects the LAST starter in a team.
sample(440,"TERRY","CHAMPION",{
  mon("CHARIZARD",59),mon("PIDGEY",57),mon("PIDGEY",59),
  mon("PIDGEY",59),mon("PIDGEY",61),mon("CHARIZARD",63)})
assert(assess(440,"firered").slot==6)
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
-- Emerald IDs below are from the user's actual exported ROM audit, not
-- hard-coded guesses. Every changed roster is fingerprinted and verified.
local function namedParty(...)
  local out={}
  for _,pair in ipairs({...}) do
    local species,level=pair[1],pair[2]
    out[#out+1]=mon(species,level)
  end
  return out
end
local roxanneFinal=namedParty({"AERODACTYL",47},{"GOLEM",47},
  {"OMASTAR",47},{"KABUTOPS",50},{"STEELIX",50},{"NOSEPASS",52})
sample(773,"ROXANNE","LEADER",roxanneFinal)
local rx=assess(773,"emerald")
assert(rx.status=="replace" and rx.slot==2
  and rx.replacedName=="GOLEM" and rx.level==47)
local rxBefore=opts(773,roxanneFinal,"emerald")
local rxPatched,rxDecision=boss.prepare(rxBefore,"emerald")
assert(rxDecision.status=="replace" and #rxPatched.foe.party==6
  and rxPatched.foe.party[2].species==ids.GLIMMORA
  and rxPatched.foe.party[2].level==47
  and rxPatched.foe.party[2].heldItem==nil)
assert(roxanneFinal[2].species==ids.GOLEM
  and rxPatched.foe.party[6]==roxanneFinal[6],
  "Keep Nosepass and never modify the original trainer pack")
local juan800=namedParty({"LAPRAS",56},{"WHISCASH",58},
  {"POLIWHIRL",56},{"WALREIN",58},{"CRAWDAUNT",58},
  {"KINGDRA",61})
local juan801=namedParty({"LAPRAS",61},{"WHISCASH",63},
  {"POLITOED",61},{"WALREIN",63},{"CRAWDAUNT",63},
  {"KINGDRA",66})
sample(800,"JUAN","LEADER",juan800)
sample(801,"JUAN","LEADER",juan801)
for _,id in ipairs({800,801}) do
  local original=rom[id].party
  local checked=assess(id,"emerald")
  assert(checked.status=="replace" and checked.slot==5
    and checked.replacedName=="CRAWDAUNT")
  local changed,rpt=boss.prepare(opts(id,original,"emerald"),"emerald")
  assert(rpt.status=="replace" and #changed.foe.party==6
    and changed.foe.party[5].species==ids.TATSUGIRI
    and changed.foe.party[5].level==original[5].level
    and changed.foe.party[6]==original[6]
    and original[5].species==ids.CRAWDAUNT,
    "Juan keeps his original Kingdra, untouched")
end
local tateSets={
  [271]=namedParty({"CLAYDOL",41},{"XATU",41},
    {"LUNATONE",42},{"SOLROCK",42}),
  [794]=namedParty({"SLOWPOKE",48},{"CLAYDOL",49},
    {"XATU",49},{"LUNATONE",50},{"SOLROCK",50}),
  [795]=namedParty({"DROWZEE",53},{"SLOWPOKE",53},
    {"CLAYDOL",54},{"XATU",54},{"LUNATONE",55},{"SOLROCK",55}),
  [796]=namedParty({"HYPNO",58},{"CLAYDOL",59},
    {"SLOWPOKE",58},{"XATU",59},{"LUNATONE",60},{"SOLROCK",60}),
  [797]=namedParty({"HYPNO",63},{"CLAYDOL",64},
    {"SLOWKING",63},{"XATU",64},{"LUNATONE",65},{"SOLROCK",65}),
}
for _,id in ipairs({271,794,795,796,797}) do
  local original=tateSets[id]
  sample(id,"TATE&LIZA","LEADER",original)
  rom[id].doubleBattle=true
  local checked=assess(id,"emerald")
  local expected=(id==271 or id==794) and "add" or "replace"
  assert(checked.status==expected and checked.doubleBattle)
  local before=opts(id,original,"emerald")
  before.foe.doubleBattle=true
  local after,result=boss.prepare(before,"emerald")
  assert(result.status==expected
    and #after.foe.party==math.min(6,#original+1))
  local slot=(expected=="add") and #original+1 or 1
  assert(after.foe.party[slot].species==ids.MEOWSTIC
    and after.foe.party[slot].heldItem==nil)
  assert(after.foe.party[#after.foe.party].species==ids.SOLROCK)
  assert(after.foe.party[#after.foe.party-1].species==ids.LUNATONE)
  assert(original[1].species~=ids.MEOWSTIC)
  -- Two-owner doubles and incorrect native flags cannot be patched.
  before.twoOpponents=true
  local blocked,why=boss.prepare(before,"emerald")
  assert(blocked==before and why.status=="double_party_ownership_unverified")
  before.twoOpponents=nil
  before.foe.doubleBattle=false
  local blockedFlag,whyFlag=boss.prepare(before,"emerald")
  assert(blockedFlag==before
    and whyFlag.status=="double_party_ownership_unverified")
end
-- The imported doubleBattle flag itself is mandatory, not merely a
-- name/party match.
rom[271].doubleBattle=false
assert(assess(271,"emerald").status=="double_battle_flag_unverified")
rom[271].doubleBattle=true
-- Altered party data and unfamiliar trainer IDs never receive swaps.
local changedRom=opts(800,namedParty({"LAPRAS",56},{"WHISCASH",58},
  {"POLIWHIRL",56},{"WALREIN",58},{"CRAWDAUNT",59},
  {"KINGDRA",61}),"emerald")
local noPatch,wrongParty=boss.prepare(changedRom,"emerald")
assert(noPatch==changedRom and wrongParty.status=="rom_party_mismatch")
rom[800].party[5].level=59
assert(assess(800,"emerald").status=="audited_party_mismatch")
rom[800].party[5].level=58
sample(802,"JUAN","LEADER",juan801)
assert(assess(802,"emerald").status=="emerald_id_not_audited")
-- No verified Wally IDs in the supplied Emerald export. Candidates must
-- be discoverable by their genuine ROM ID, but never altered from guesses.
sample(901,"WALLY","POKéMON TRAINER",{mon("GARDEVOIR",45)})
assert(assess(901,"emerald").status=="trainer_identity_unverified")
sample(902,"WALLY","UNKNOWN CLASS",{mon("GARDEVOIR",40)})
assert(assess(902,"emerald").status=="not_approved")
local emeraldAudit=assert(boss.audit("emerald"))
local wallyFound={}
for _,row in ipairs(emeraldAudit) do
  if row.key=="wally" then
    wallyFound[row.trainerId]=row
    assert(row.status=="trainer_identity_unverified")
  end
end
assert(wallyFound[901] and wallyFound[902],
  "Wally candidate discovery must preserve actual trainer IDs")

local audit=assert(boss.audit("firered"))
local byKey={}
for _,x in ipairs(audit) do byKey[x.key]=x end
assert(byKey.brock.trainerId==101 and byKey.misty.trainerId==102
  and byKey.giovanni_gym.trainerId==105
  and byKey.giovanni_rocket.trainerId==349)
assert(byKey.erika.status=="trainer_identity_not_found",
  "The ROM audit must list unverified/missing approved bosses")
for _,row in ipairs(audit) do
  assert(row.trainerId~=38,
    "Fake Champion #38 must be absent from the Mega audit")
end
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
state.trainerId=348
state.foeParty=earlyRocket
state.megaBossChoice={trainerId=348,disabled=true}
assert(policy.choose(state)==nil,
  "Disabling Giovanni #348 must override the general trainer Mega rule")
state.trainerId=349
-- Battle.start normalises newly added mons and computes their HP.
state.foeParty={
  mon("PIDGEY",37),mon("KANGASKHAN",35),
  mon("PIDGEY",37),mon("PIDGEY",41),mon("MEWTWO",41),
}
state.megaBossChoice={trainerId=349,slot=5,slug="mega_mewtwo_y"}
assert(policy.choose(state).slot==5
  and policy.choose(state).slug=="mega_mewtwo_y")
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
assert(#brockParty==2)
Battle._active=false
assert(Battle.start(opts(348,earlyRocket))=="started")
assert(Battle._st.megaBossChoice.trainerId==348
  and Battle._st.megaBossChoice.disabled==true)
assert(policy.choose(Battle._st)==nil,
  "Early Giovanni must not Mega Evolve after native Battle.start")
Battle._active=false
assert(Battle.start(opts(349,laterRocket))=="started")
assert(Battle._st.megaBossChoice.trainerId==349
  and Battle._st.megaBossChoice.slug=="mega_mewtwo_y"
  and Battle._st.megaBossChoice.slot==5)
bridge.uninstall()
print("PASS: 32 boss choices, Giovanni #348 blocked / #349 Mewtwo Y, false #38 excluded, final duplicate ace, native start")
