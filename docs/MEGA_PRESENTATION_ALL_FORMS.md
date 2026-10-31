# Mega presentation: all 98 forms at 1× (first-pass tuning)

Every pinned EBDX Mega form is now explicitly listed in
`data/mega_presentation.lua`, with independent `back` and `front` settings.

- **scale = 1** on every entry, including Mega Venusaur and Mega Mewtwo X,
  as the default. This is a presentation baseline, **not** a guarantee every
  sprite fits the battle screen at 1×. Large forms can be oversized.
- **feet** is determined from the complete animation's shared alpha envelope
  (`cy + fh` in the normalised atlas). All frames of a species/side share the
  same anchor. Frames are not recropped or centred separately, so the animation's
  authored movement survives.
- For a small, explicit set of airborne species, up to **six pixels of
  original transparent clearance** beneath the animated art are retained as
  an initial hover offset; other forms default to their visible union bottom.
  This is a curated first pass rather than a claim every species is grounded.
- `baseline = 57` for the player's back and `62` for the opponent's front.
  `dx=0`, `dy=0` unless explicitly adjusted.
- **Mega Mewtwo X** has `back.dy = 4`, placing its back sprite four logical
  pixels *lower* than the measured initial alignment; its scale is now 1.
- Mega Pyroar's **front shiny** and Zygarde Form 5's **back shiny** have their
  own frame geometry; `front_shiny` / `back_shiny` overrides are supplied.
  All other shiny animations inherit their normal side's parameters.

## Editing

Example:

```lua
mega_mewtwo_x = {
  back  = { scale = 1, feet = 86, baseline = 57, dx = 0, dy = 4 },
  front = { scale = 1, feet = 71, baseline = 62, dx = 0, dy = 0 },
},
```

- Decrease `scale` from 1 to make the sprite smaller, increase it for bigger.
- Increase `dy` to move down; decrease `dy` to move up.
- Increase `dx` to move right; decrease `dx` to move left.
- The `feet` coordinate is in the **original source square**, not the packed
  crop rectangle. Raising `feet` raises the Pokémon; lowering it lowers it.
- For a floating form, give it extra space below its measured feet or adjust
  `dy` without changing its frame-by-frame motion.
- To tune only the shiny artwork where source geometry differs, edit the
  `back_shiny` or `front_shiny` entry instead of normal front/back.

The source geometry comes from
`assets/runtime/mega_atlas_index.json`. The test
`lua tests/test_mega_presentation.lua` verifies 98 complete forms, 1× default
scales, feet relative to source envelopes and both shiny overrides.

## Live test

Completely restart Gen1Recomp after changing mods, particularly after any
previous G9/HD graphics wrapper regression. Compare a normal Pokémon,
Mega Venusaur, Mega Mewtwo X, and at least one hovering Pokémon in Emerald
and FireRed. Check the front and back, shiny variants, and HD on/off.

This changes only **presentation data and the shiny-specific selection path**.
The temporary battle mechanics, party stats and permanent saves are not
modified.
