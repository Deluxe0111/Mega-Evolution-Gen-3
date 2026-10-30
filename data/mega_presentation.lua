-- Battle-only art presentation overrides. Values are in Gen 3 logical pixels.
-- Source artwork remains full-size; these only control the picture rendered
-- inside the existing battle UI. Tuning is append-only and per form/side.
--
-- The stock battle draws an image at origin (32,32); wide canvases require
-- an origin translation (provided by mega_atlas.lua) so they stay on the pad.
return {
  mega_venusaur = {
    back = {
      scale = 0.80,    -- 121px EBDX frame; approximate G9 Venusaur back footprint
      feet = 111,     -- source-pixel line under the resting body
      baseline = 57,  -- G9's player back feet row, before game-specific offsets
      dx = 0, dy = 0,
    },
    front = {
      scale = 0.74,    -- 117px EBDX frame; match G9 distant-battler proportions
      feet = 108,
      baseline = 62,
      dx = 0, dy = 0,
    },
  },
}
