-- Regression for the actual FireRed PartyMenu.draw path, where the
-- battle-switch menu can contain reordered COPY records instead of the exact
-- Pokémon table stored in Mega selection state.
local Ui = dofile("src/mega_ui.lua")
local original={species=9,nickname="BLASTOISE",personality=1}
local copied={species=9,nickname="BLASTOISE",personality=1}
local other={species=1,nickname="BULBASAUR"}
local mega={slug="mega_blastoise",stats={attack=140},ability="MEGA_LAUNCHER"}
local function iconTag(slug)
  return {image=slug,quads={[0]="frame0",[1]="frame1"},w=32,h=32}
end
local pokemon={
  monIcon=function(mon) return iconTag("vanilla:"..tostring(mon.nickname)) end,
  monFrontPic=function()return {image="regular"}end,
  isShiny=function()return false end,
  gender=function()return "M" end,
  speciesOf=function(mon)return mon.species end,
}
local calls={}
local order={[1]=2,[2]=1}
local party={copied,other}
local PartyMenu={
  open=true,_battle=true,_order=order,_party=party,
  draw=function()
    calls[#calls+1]={
      [1]=pokemon.monIcon(PartyMenu._party[1]).image,
      [2]=pokemon.monIcon(PartyMenu._party[2]).image,
      seenCopy=PartyMenu._party[1]~=copied,
      seenMega=PartyMenu._party[1].__megaUiView,
    }
    return "party drawn"
  end,
}
local game={
  view=function(mon) return mon==original and mega or nil end,
  partyView=function(slot) return slot==2 and mega or nil end,
}
local warnings={}
local mod={log={warn=function(_,fmt,...)warnings[#warnings+1]=string.format(fmt,...)end}}
local ui=assert(Ui.install(mod,game,{
  picture=function(slug)return {image=slug}end,
  icon=function(slug,shiny,female)
    assert(slug=="mega_blastoise" and not shiny and not female)
    return iconTag("animated-mega-blastoise")
  end,
},{Pokemon=pokemon,PartyMenu=PartyMenu}))
assert(PartyMenu.draw()=="party drawn")
assert(calls[1][1]=="animated-mega-blastoise", "FireRed must use Mega icon by slot")
assert(calls[1][2]=="vanilla:BULBASAUR")
assert(calls[1].seenCopy and calls[1].seenMega==mega)
assert(party[1]==copied and party[2]==other and copied.__megaUiView==nil,
  "real party references must be restored, no save mutation")
local d=ui.diagnostics()
assert(d.partySlotOverrides==1 and d.megaIconSuccess==1
  and d.megaIconFailures==0)
-- Without a battle, party menu must remain ordinary.
PartyMenu._battle=false
assert(PartyMenu.draw()=="party drawn")
assert(calls[2][1]=="vanilla:BLASTOISE" and party[1]==copied)
PartyMenu._battle=true
-- If the provider cannot create its icon, do not leave a blank OAM sprite:
-- use the native species icon and log one meaningful failure diagnostic.
ui.uninstall()
local failing=assert(Ui.install(mod,game,{
  picture=function(slug)return {image=slug}end,
  icon=function()return nil end,
},{Pokemon=pokemon,PartyMenu=PartyMenu}))
assert(PartyMenu.draw()=="party drawn")
assert(calls[3][1]=="vanilla:BLASTOISE")
assert(failing.diagnostics().megaIconFailures==1 and #warnings==1)
assert(warnings[1]:find("mega_blastoise",1,true))
-- Lua error during native draw must not leave a mirror in the party array.
local originalDraw=PartyMenu.draw
PartyMenu.draw=function()
  originalDraw()
  error("simulated FireRed party draw failure")
end
failing.uninstall()
local safety=assert(Ui.install(mod,game,{
  picture=function(slug)return {image=slug}end,
  icon=function()return iconTag("mega")end,
},{Pokemon=pokemon,PartyMenu=PartyMenu}))
assert(not pcall(PartyMenu.draw))
assert(party[1]==copied and copied.__megaUiView==nil)
assert(pokemon.monIcon(copied).image=="vanilla:BLASTOISE")
safety.uninstall()
assert(party[1]==copied and party[2]==other)
print("PASS: FireRed party copied/reordered slot Mega icon, native fallback, failure diagnostics, and exception-safe save pointers")
