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
local PartyMenu={open=true,_battle=true,_order=order,_party=party}
PartyMenu.draw=function()
  calls[#calls+1]={
    [1]=pokemon.monIcon(PartyMenu._party[1]).image,
    [2]=pokemon.monIcon(PartyMenu._party[2]).image,
    seenCopy=PartyMenu._party[1]~=copied,
    seenMega=PartyMenu._party[1].__megaUiView,
  }
  return "party drawn"
end
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

-- A regression that the earlier mocked PartyMenu.draw() test missed:
-- FireRed's real icons are OAM sprites. An unrelated mod can bypass our
-- Pokemon.monIcon wrapper or OAM can already contain a vanilla sprite from
-- PartyMenu.show(). The last native OAM paint must still show the Mega.
local originalSprite={image="vanilla-blastoise",quad="vanilla-frame",
  data={[2]=1}}
local otherSprite={image="vanilla-bulbasaur",quad="vanilla-other",
  data={[2]=0}}
local flushed={}
local Oam={}
function Oam.get(id)
  if id==101 then return originalSprite end
  if id==102 then return otherSprite end
end
function Oam.flushOne(sprite)
  flushed[#flushed+1]={image=sprite.image,quad=sprite.quad}
end
local originalFlush=Oam.flushOne
PartyMenu._oam={[1]={mon=101},[2]={mon=102}}
PartyMenu._battle=true
PartyMenu.draw=function()
  -- Intentionally bypass Pokemon.monIcon, like a separate sprite provider.
  Oam.flushOne(originalSprite)
  Oam.flushOne(otherSprite)
  return "native OAM painted"
end
local iconArgs={}
local nativeUi=assert(Ui.install(mod,game,{
  picture=function(slug)return {image=slug}end,
  icon=function(slug,isShiny,isFemale)
    iconArgs[#iconArgs+1]={slug,isShiny,isFemale}
    return {image="oam-mega-blastoise",
      quads={[0]="mega-frame-0",[1]="mega-frame-1"},w=32,h=32}
  end,
},{Pokemon=pokemon,PartyMenu=PartyMenu,Oam=Oam}))
assert(PartyMenu.draw()=="native OAM painted")
assert(flushed[1].image=="oam-mega-blastoise"
  and flushed[1].quad=="mega-frame-1",
  "FireRed OAM paint must replace the battle Mega's animated frame")
assert(flushed[2].image=="vanilla-bulbasaur"
  and flushed[2].quad=="vanilla-other",
  "OAM paint must not alter a non-Mega party member")
assert(originalSprite._quads[0]=="mega-frame-0"
  and originalSprite._quads[1]=="mega-frame-1",
  "both frames must stay available to native party icon animation")
local nd=nativeUi.diagnostics()
assert(nd.nativePartyFlushes==2 and nd.nativeMegaOverrides==1
  and nd.lastNativeSlot==2 and nd.lastNativeSlug=="mega_blastoise",
  "the Mega icon must resolve the original party slot through _order")
assert(iconArgs[1][1]=="mega_blastoise")
-- Female/shiny flags must reach the source icon provider.
pokemon.isShiny=function(m)return m and m.isShiny==true end
copied.gender="F"
copied.isShiny=true
flushed={}
assert(PartyMenu.draw()=="native OAM painted")
local args=iconArgs[#iconArgs]
assert(args[1]=="mega_blastoise" and args[2]==true and args[3]==true,
  "native FireRed OAM must preserve the shiny/female icon variants")
-- Menu closes / non-battle menu: the native icon must remain untouched.
PartyMenu._battle=false
originalSprite.image,originalSprite.quad="normal-again","normal-frame"
flushed={}
assert(PartyMenu.draw()=="native OAM painted")
assert(flushed[1].image=="normal-again" and flushed[1].quad=="normal-frame",
  "ordinary party icons must not be overridden")
nativeUi.uninstall()
assert(Oam.flushOne==originalFlush,"OAM hook must uninstall without residue")
assert(party[1]==copied and party[2]==other and original.__megaUiView==nil,
  "Mega OAM paint must not change party or save records")
print("PASS: FireRed party copied/reordered Mega icons including final OAM paint, shiny/female variants, native fallback, and safe cleanup")
