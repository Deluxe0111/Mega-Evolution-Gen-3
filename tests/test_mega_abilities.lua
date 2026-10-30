local Ability = dofile("src/mega_abilities.lua")
local active={}
local game={view=function(mon)return active[mon] end}
local attacker={mon={hp=150,maxHp=150},side="player"}
local defender={mon={hp=200,maxHp=200},side="enemy"}
local function setA(ab)active[attacker.mon]={ability=ab} end
local function setD(ab)active[defender.mon]={ability=ab} end
local function power(ab,move,opts)
  setA(ab)
  local original=(opts and opts.power) or move.power
  local resulting=Ability.baseOptions(game,attacker,move,opts)
  assert(move.power==original or opts and opts.power~=nil,
    "base move definition was mutated")
  return (resulting and resulting.power) or original,resulting
end
local function check(ab,move,expected,opts)
  local p=power(ab,move,opts)
  assert(p==expected,ab.." expected "..expected.." got "..tostring(p)
    .." move "..tostring(move.id))
end
check("TOUGH_CLAWS",{id="SLASH",flags=1,power=100},130)
check("TOUGH_CLAWS",{id="SLASH",flags=0,power=100},100)
check("TECHNICIAN",{id="QUICK_ATTACK",power=60},90)
check("TECHNICIAN",{id="QUICK_ATTACK",power=61},61)
check("TECHNICIAN",{id="HIDDEN_POWER",power=70},90,{power=60})
check("IRON_FIST",{id="FIRE_PUNCH",power=75},90)
check("IRON_FIST",{id="SUCKER_PUNCH",power=70},70)
check("STRONG_JAW",{id="CRUNCH",power=80},120)
check("STRONG_JAW",{id="PSYCHIC_FANGS",power=85},127)
check("STRONG_JAW",{id="SUPER_FANG",power=1},1)
check("MEGA_LAUNCHER",{id="DARK_PULSE",power=80},120)
check("MEGA_LAUNCHER",{id="DRAGON_PULSE",power=85},127)
check("MEGA_LAUNCHER",{id="HEAL_PULSE",power=0},0)
check("SHARPNESS",{id="LEAF_BLADE",power=90},135)
check("SHARPNESS",{id="SHADOW_BALL",power=80},80)
check("SAND_FORCE",{id="ROCK_SLIDE",type=5,power=75},97,{weatherKind="SAND"})
check("SAND_FORCE",{id="ROCK_SLIDE",type=5,power=75},75,{weatherKind="SUN"})
check("SAND_FORCE",{id="SURF",type=11,power=95},95,{weatherKind="SAND"})
local originalOpts={power=60}
local adjusted=Ability.baseOptions(game,attacker,{id="QUICK_ATTACK",power=40},originalOpts)
assert(originalOpts.power==60 and adjusted==originalOpts) -- Sand Force not enabled
setA("TECHNICIAN")
adjusted=Ability.baseOptions(game,attacker,{id="QUICK_ATTACK",power=40},originalOpts)
assert(adjusted~=originalOpts and adjusted.power==90 and originalOpts.power==60)
active[attacker.mon]=nil
local unmodified={power=70}
assert(Ability.baseOptions(game,attacker,{id="QUICK_ATTACK",power=40},unmodified)==unmodified,
  "non-Mega Pokémon must bypass modifiers")
setA("ADAPTABILITY")
local info={stab=1.5,effectiveness=1,typeFlags={immune=false}}
local v=Ability.finalDamage(game,attacker,defender,90,info)
assert(v==120)
info.stab=1
assert(Ability.finalDamage(game,attacker,defender,90,info)==90)
info.stab=1.5
setD("FILTER")
info.effectiveness=2
assert(Ability.finalDamage(game,attacker,defender,90,info)==90,
  "Adaptability and Filter must combine once")
info.effectiveness=1
assert(Ability.finalDamage(game,attacker,defender,90,info)==120)
active[attacker.mon]=nil
info.effectiveness=2
assert(Ability.finalDamage(game,attacker,defender,80,info)==60)
info.effectiveness=1
assert(Ability.finalDamage(game,attacker,defender,80,info)==80)
setD("MULTISCALE")
assert(Ability.finalDamage(game,attacker,defender,80,info)==40)
defender.mon.hp=199
assert(Ability.finalDamage(game,attacker,defender,80,info)==80)
defender.mon.hp=200
for _,extra in ipairs({{fixed=true},{status=true},{failed=true},{setDamage=true},
  {typeFlags={immune=true}}}) do
  assert(Ability.finalDamage(game,attacker,defender,80,extra)==80,
    "fixed, immune or failed moves must not be modified")
end
active[defender.mon]=nil
assert(Ability.finalDamage(game,attacker,defender,80,info)==80)

-- Integration through the same external Damage.base and Damage.calc tables
-- as the real engine. Simulate a damage calculator using base plus a STAB
-- step and verify final modifiers run exactly once, without a second hit.
local Standalone=dofile("src/mega_standalone.lua")
local Ui={handleInput=function()return false end,takeCommand=function()end,
  sidePic=function()return {} end}
local Engine={resolveMove=function()end}
local Battle={start=function()end,reset=function()end}
local calls=0
local Damage={}
Damage.base=function(a,d,move,opts)
  calls=calls+1
  return tonumber(opts and opts.power) or move.power
end
Damage.calc=function(a,d,move,opts)
  local base=Damage.base(a,d,move,opts)
  return base,{stab=opts and opts.stab or 1,effectiveness=opts and opts.eff or 1}
end
local origBase,origCalc=Damage.base,Damage.calc
local bridge=assert(Standalone.install({enabled=true},game,{
  Ui=Ui,Engine=Engine,Battle=Battle,Damage=Damage,MegaAbilities=Ability,
}))
setA("TOUGH_CLAWS")
local move={id="SLASH",power=100,flags=1}
local result=Damage.calc(attacker,defender,move,{})
assert(result==130 and calls==1)
assert(move.power==100,"ROM move row must not be changed")
setA("ADAPTABILITY")
result=Damage.calc(attacker,defender,move,{stab=1.5})
assert(result==133)
setD("FILTER")
result=Damage.calc(attacker,defender,move,{stab=1.5,eff=2})
assert(result==99)
bridge.uninstall()
assert(Damage.base==origBase and Damage.calc==origCalc,"hooks must uninstall")
assert(Damage.calc(attacker,defender,move,{})==100,"vanilla damage restored")
print("PASS: 9 Mega damage abilities, eligibility, status/fixed bypass, native calc integration and cleanup")
