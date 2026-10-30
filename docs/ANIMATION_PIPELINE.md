# Mega Evolution animation pipeline

## Approach

[G9 Battle Sprites (Gen 3)](https://github.com/poooooby/g9-battle-sprites-gen3) packages animated Pokémon as PNG atlas pages, with a Lua index and runtime frame selection. Our EBDX input art is likewise packaged as PNG strips of square frames. This builder follows that general technique but maintains **form-keyed Mega sprites**, rather than introducing permanent species IDs.

All six original EBDX sprite kinds are supported: front, back, front shiny, back shiny, party icon and shiny party icon.

The build **does not resize source art, change alpha, edit original files, register species, or hook battle graphics**. It reports invalid/missing source sheets instead of guessing how to split them.

## Run it

Install Python 3.11+ and Pillow 11.3.0:

    py -3 -m pip install --only-binary=:all: Pillow==13.0.0

On Windows, double-click `4_PREVIEW_MEGA_VENUSAUR.bat`; it uses your installed Python 3 and downloads the compatible prebuilt Pillow package without attempting a source compile.

From the repository root:

    py -3 tools/build_mega_atlas.py --audit-only
    py -3 tools/build_mega_atlas.py --only mega_venusaur --preview
    py -3 tools/build_mega_atlas.py
    py -3 -m unittest discover -s tests -p "test_mega_atlas.py"

The first command checks all 588 source PNGs. The second builds six Mega Venusaur atlases and GIF previews to inspect. The third builds the entire 98-variant Mega roster.

The packer uses 2048px atlas pages by default, with configurable 256–4096px page size. Large strips can be split across segments without losing a frame. Generated pages are not yet committed or packaged as a player release.

## Generated files

    assets/runtime/
      atlas/battle_front_0.png
      atlas/battle_front_shiny_0.png
      atlas/battle_back_0.png
      atlas/battle_back_shiny_0.png
      atlas/battle_icon_0.png
      atlas/battle_icon_shiny_0.png
      mega_atlas_index.json
      mega_atlas_index.lua
      previews/mega_venusaur_front.gif
      ...
    reports/
      mega_sheet_geometry.csv

The actual number of PNG atlas pages is determined by the source images.

The Lua and JSON indexes are keyed by stable Mega slugs, such as mega_venusaur and mega_charizard_x. Each sprite variant records the square frame size, number of frames, playback FPS and one or more atlas segments. Each segment stores: sheet (page index), first (first frame of the segment), frames (frame count), ox and oy (page origin), cols (columns) and fs (frame size).

To locate an animation frame:

    segment = segment_containing_frame_n
    local_frame = n - segment.first
    x = segment.ox + (local_frame % segment.cols) * segment.fs
    y = segment.oy + floor(local_frame / segment.cols) * segment.fs

Battle FPS defaults to 8, like G9 Battle Sprites; icon FPS defaults to 2. **These are preliminary playback rates, not verified original EBDX timing.** Timing and sprite positioning will need visual QA.

## What is still missing

This milestone provides atlas conversion, metadata, tests and visual previews. It does **not yet display Megas in a running battle**. Next we need to integrate a deliberately composed renderer into G9's picture pipeline, including front/back anchors, sizing and shiny flags. A temporary Mega battle form must never overwrite the Pokémon's saved species identity.

CI creates a Mega Venusaur proof artifact for inspection. Original sprite and audio credits remain in CREDITS.md and the EBDX source metadata.
