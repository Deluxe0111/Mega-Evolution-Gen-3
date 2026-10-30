-- Battle-only art presentation overrides. Values are in Gen 3 logical pixels.
-- Source artwork remains full-size; these only control the picture rendered
-- inside the existing battle UI. Tuning is append-only and per form/side.
--
-- The stock battle draws an image at origin (32,32); wide canvases require
-- an origin translation (provided by mega_atlas.lua) so they stay on the pad.
return {
  -- Initial calibrations based on the motion-safe atlas union rectangles.
  -- These are not per-frame auto-grounding: Charizard X keeps a small
  -- intentional air gap; Mewtwo X uses its visible resting lower bound.
  mega_charizard_x = {
    back = {
      scale = 0.72, feet = 121, baseline = 57,
      dx = 0, dy = 0,
    },
  },
  mega_mewtwo_x = {
    back = {
      scale = 0.90, feet = 86, baseline = 57,
      dx = 0, dy = 0,
    },
  },
  mega_venusaur = {
    back = {
      scale = 0.85,    -- 79px visible Mega height * .85 ~= G9 63px * 1.069
      feet = 100,     -- verified alpha bottom: 74 back frames end at source row 100
      baseline = 57,  -- G9's player back feet row, before game-specific offsets
      dx = 0, dy = 0,
    },
    front = {
      scale = 0.74,    -- keep existing distant-battler scale pending opponent-side test
      feet = 98,      -- normalized front crop starts at 19, height 79; bottom = 98
      baseline = 62,
      dx = 0, dy = 0,
    },
  },
}
