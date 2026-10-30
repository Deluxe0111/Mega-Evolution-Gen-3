-- Runs with stock Lua 5.4; fake graphics never need a GPU or the game.
local Provider = dofile("src/mega_atlas.lua")
local realIndex = dofile("assets/runtime/mega_atlas_index.lua")
local count = 0
for _ in pairs(realIndex.forms) do count = count + 1 end
assert(count == 98, "expected all 98 imported Mega forms")
for slug, form in pairs(realIndex.forms) do
  local num = 0
  for kind, cell in pairs(form.variants) do
    num = num + 1
    assert(cell.frames >= 1)
    local first = Provider.locate(realIndex, slug, kind, 0)
    local last = Provider.locate(realIndex, slug, kind, cell.frames - 1)
    assert(first and last and first.fs > 0 and last.fs > 0, slug .. "/" .. kind)
    assert(Provider.locate(realIndex, slug, kind, cell.frames).frame == 0)
  end
  assert(num == 6, slug .. " does not have six artwork variants")
end

-- Explicit synthetic multi-page case, including a frame located on another page.
local synthetic = {
  schema = 1,
  forms = {
    mega_test = {
      display_name = "Mega Test", species = "TEST", pbs_key = "TEST,1",
      mega_stone = "TESTITE", source_form = 1,
      variants = {
        front = {
          frames = 4, fps = 8,
          segments = {
            { sheet = 0, first = 0, frames = 2, ox = 32, oy = 64, cols = 2, fs = 32 },
            { sheet = 1, first = 2, frames = 2, ox = 0, oy = 0, cols = 1, fs = 32 },
          }
        },
        front_shiny = {
          frames = 1, fps = 8, segments = {
            { sheet = 0, first = 0, frames = 1, ox = 0, oy = 0, cols = 1, fs = 32 },
          }
        }
      }
    },
    mega_crop = {
      display_name = "Mega Hover", species = "HOVER",
      variants = {
        back = {frames=3, fps=8, segments={
          {sheet=0, first=0, frames=3, ox=0, oy=0, cols=2, fs=32,
           fw=20, fh=14, cx=4, cy=7}
        }}
      }
    }
  }
}
assert(Provider.locate(synthetic, "mega_test", "front", 1).x == 64)
local croppedFrame = Provider.locate(synthetic, "mega_crop", "back", 2)
assert(croppedFrame and croppedFrame.x == 0 and croppedFrame.y == 14)
assert(croppedFrame.fs == 32 and croppedFrame.fw == 20 and croppedFrame.fh == 14)
assert(croppedFrame.cx == 4 and croppedFrame.cy == 7)
-- New index uses a padded stride, while the Quad crops exactly the source
-- rectangle. Adjacent poses must not lie one texture pixel from its edge.
synthetic.forms.mega_crop.variants.back.segments[1].ox = 2
synthetic.forms.mega_crop.variants.back.segments[1].oy = 2
synthetic.forms.mega_crop.variants.back.segments[1].stepX = 24
synthetic.forms.mega_crop.variants.back.segments[1].stepY = 18
synthetic.forms.mega_crop.variants.back.segments[1].gutter = 2
local padded = Provider.locate(synthetic, "mega_crop", "back", 2)
assert(padded.x == 2 and padded.y == 20)
assert(Provider.locate(synthetic, "mega_crop", "back", 1).x == 26)
-- Existing indexed atlases without stepX/stepY keep their old coordinates.
synthetic.forms.mega_crop.variants.back.segments[1].stepX = nil
synthetic.forms.mega_crop.variants.back.segments[1].stepY = nil
assert(Provider.locate(synthetic, "mega_crop", "back", 2).y == 16)
synthetic.forms.mega_crop.variants.back.segments[1].ox = 0
synthetic.forms.mega_crop.variants.back.segments[1].oy = 0
local p2 = Provider.locate(synthetic, "mega_test", "front", 3)
assert(p2.file == "battle_front_1.png" and p2.y == 32 and p2.frame == 3)
assert(Provider.locate(synthetic, "mega_test", "front", 4).frame == 0)
assert(Provider.locate(synthetic, "fake", "front", 0) == nil)
assert(Provider.locate(synthetic, "mega_test", "back", 0) == nil)
assert(Provider.locate(synthetic, "mega_test", "nope", 0) == nil)

local images, draws, canvases, pushes, pops = 0, 0, 0, 0, 0
local drawX, drawY
local oldPage = {}
local G = {
  newImage = function(path)
    images = images + 1
    local t = { path = path }
    function t:getDimensions() return 128, 128 end
    function t:setFilter() end
    return t
  end,
  newQuad = function(x, y, w, h, iw, ih)
    return {x=x, y=y, w=w, h=h, iw=iw, ih=ih}
  end,
  newCanvas = function(w,h,opts)
    assert(w == 64 and h == 64 and opts.dpiscale == 4)
    canvases = canvases + 1
    return {setFilter = function() end}
  end,
  push = function(mode) assert(mode == "all"); pushes = pushes + 1 end,
  pop = function() pops = pops + 1 end,
  origin = function() end,
  setScissor = function() end,
  setShader = function() end,
  setBlendMode = function() end,
  setColor = function() end,
  setCanvas = function() end,
  clear = function() end,
  draw = function(texture,quad,x,y,...)
    draws = draws + 1
    drawX, drawY = x, y
  end
}
local mod = { path = "mods/mega-evolution", log = {warn=function()end} }
local atlas = assert(Provider.new(mod, synthetic, G, function()return 0.375 end))
assert(atlas.hasSprite("mega_test", "front"))
assert(not atlas.hasSprite("mega_test", "back"))
local form = atlas.formInfo("mega_test")
assert(form.species == "TEST" and form.mega_stone == "TESTITE")
form.species = "BAD"
assert(atlas.formInfo("mega_test").species == "TEST", "formInfo is not a copy")
local source = atlas.frame("mega_test", "front", 3)
assert(source and source.quad.y == 32 and source.image.path:find("battle_front_1.png", 1, true))
local entry = atlas.picture("mega_test", "front", false, 3)
assert(entry and entry.image and entry.w == 64 and entry.h == 64)
assert(atlas.picture("mega_test", "front", false, 3) == entry, "cached frame should be reused")
assert(canvases == 1 and draws == 1)
assert(pushes == 1 and pops == 1, "graphics state was not restored")
assert(atlas.picture("mega_test", "back", false, 0) == nil)
assert(atlas.picture("mega_test", "front", true, 0))
assert(atlas.stats().cachedPages == 2)
local sprite = atlas.frame("mega_crop", "back", 1)
assert(sprite and sprite.w == 32 and sprite.h == 32)
assert(sprite.quad.w == 20 and sprite.quad.h == 14)
assert(sprite.cropX == 4 and sprite.cropY == 7)
assert(atlas.picture("mega_crop", "back", false, 1))
-- A common crop is packed smaller, but the ORIGINAL on-screen pose remains.
-- 64px presentation box: (64-32)/2 + cropX, 64-32 + cropY.
assert(drawX == 20 and drawY == 39, "crop origin lost: hover pose would jump")

-- Main.lua must provide discovery API without overriding global Pokemon graphics hooks.
local oldFront = function()return "native" end
local Pokemon = {frontPic=oldFront,backPic=function()end,icon=function()end}
local modWithExports = {
  path = "mods/mega-evolution",
  exports = {},
  log = {warn=function()end,info=function()end},
  events = {on=function()end},
  read = function(_,path)
    local file = io.open(path, "rb")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content
  end
}
love = {graphics=G,timer={getTime=function()return 0 end}}
local entrypoint = dofile("main.lua")
entrypoint(modWithExports)
assert(modWithExports.exports.apiVersion == 1)
assert(modWithExports.exports.isActive() == false, "art must not pretend gameplay is active")
assert(modWithExports.exports.artAvailable())
assert(modWithExports.exports.hasSprite("mega_venusaur", "front"))
assert(modWithExports.exports.frameLocation("mega_venusaur", "front", 0))
assert(Pokemon.frontPic == oldFront, "main.lua changed unrelated Pokemon rendering")
print("PASS: 98 form keys, six variants, paging, canvas cache, state restoration, non-invasive exports")
