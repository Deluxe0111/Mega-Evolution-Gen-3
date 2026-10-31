# Mega Evolution animation pipeline

## Approach

[G9 Battle Sprites (Gen 3)](https://github.com/poooooby/g9-battle-sprites-gen3) packages animated Pokémon as PNG atlas pages, with a Lua index and runtime frame selection. The EBDX input art is likewise packaged as PNG strips of square frames. This builder follows that general technique but maintains **form-keyed Mega sprites**, rather than introducing permanent species IDs.

All six original EBDX sprite kinds are supported: front, back, front shiny, back shiny, party icon and shiny party icon.

The build **does not resize source art, change alpha, edit original files, register species, or hook battle graphics**. It reports invalid/missing source sheets instead of guessing how to split them.

## Run it

Install Python 3.11–3.15 and Pillow 13.0.0, including prebuilt wheels for Python 3.15:

    py -3 -m pip install --only-binary=:all: Pillow==13.0.0

On Windows, double-click `4_PREVIEW_MEGA_VENUSAUR.bat`; it uses your installed Python 3 and downloads the compatible prebuilt Pillow package without attempting a source compile.

From the repository root:

    py -3 tools/build_mega_atlas.py --audit-only
    py -3 tools/build_mega_atlas.py --only mega_venusaur --preview
    py -3 tools/build_mega_atlas.py --only mega_venusaur --preview --normalize-padding
    py -3 tools/build_mega_atlas.py --normalize-padding
    py -3 -m unittest discover -s tests -p "test_mega_atlas.py"

The first command checks all 588 source PNGs. The second makes a six-variant preview; the third demonstrates **motion-safe transparent-padding normalisation** for Mega Venusaur. The fourth builds the full 98-form roster with shared-border packing. **Rebuild the complete atlas and validate the generated index before replacing the committed runtime artwork.** The normalised format remains opt-in; existing atlas pages remain supported. Alternatively, on Windows run `5_BUILD_ALL_MEGA_ATLASES.bat` for the complete collection. The repository also includes a separately triggered **Full Mega atlas build** workflow, which checks that every frame range and generated PNG page resolves correctly. For locally generated output, run `py -3 tests/check_full_mega_atlas.py` after the full build.

The packer uses 2048px atlas pages by default, with configurable 256–4096px page size. Large strips can be split across segments without losing a frame. Generated atlas pages and indexes are committed under `assets/runtime/`. The release archive must include every runtime page referenced by the index.

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

The Lua and JSON indexes are keyed by stable Mega slugs, such as mega_venusaur and mega_charizard_x. Each sprite variant records the square frame size, number of frames, playback FPS and one or more atlas segments. Each legacy segment stores: sheet (page index), first (first frame of the segment), frames (frame count), ox and oy (page origin), cols (columns) and fs (source frame size). With `--normalize-padding` the segment additionally stores `fw` and `fh` (packed rectangle width/height), and `cx` and `cy` (original source-frame crop origin). Runtime restores these offsets when drawing. Square source frame size `fs` remains unchanged for sprite scale/positioning. No new source format or Gen1Recomp hook is required.

To locate an animation frame:

    segment = segment_containing_frame_n
    local_frame = n - segment.first
    x = segment.ox + (local_frame % segment.cols) * segment.fs
    y = segment.oy + floor(local_frame / segment.cols) * segment.fs

Battle FPS defaults to 8, like G9 Battle Sprites; icon FPS defaults to 2. **These are preliminary playback rates, not verified original EBDX timing.** Timing and sprite positioning will need visual QA.

## Motion-safe normalisation (opt-in)

A visible gap in an atlas does **not** necessarily mean a tile-spacing error: the
Mega Venusaur example is already a contiguous 9×9 grid of 121px source-frame
cells, but its visible pixels occupy less than each full cell. Much of the
spacing is intentionally transparent within frames.

To reduce transparent padding without changing motion, the builder:

1. Reads alpha bounding boxes across the **entire animation** (all frames of
   one Mega form and one front/back/shiny variant).
2. Computes **one shared union rectangle**, including the Pokémon's highest
   leap, lowest bob and furthest lateral movement. Fully transparent strips
   retain their original full frame.
3. Packs the same shared crop rectangle for **every frame**, recording its
   offset relative to the original source square.
4. At runtime, draws with that offset restored. Both the normal 64px picture
   canvas and the optional full-resolution HD battle tag retain the source
   frame's intended position.

There is **no per-frame centring**, baseline guessing, automatic grounding,
or movement smoothing. Floating Pokémon can remain above the platform and
bouncing animations keep their authored trajectory. Battle-scene placement
and individual Mega scale are still controlled separately by
`data/mega_presentation.lua`.

Use `get_frame` or GIF previews to inspect frame alignment. Python tests use
a synthetic hovering/bouncing Pokémon and check **all visible pixels** match
the original source coordinates exactly; cropped transparent RGB bytes are
not semantically meaningful. Keep the optional mode separate until the full
atlas is rebuilt, validated and visually reviewed.

## What is still missing

The runtime uses the indexed frames to render temporary in-battle Mega forms. Changing atlas geometry requires testing front/back anchors, shiny art, party icons and interactions with the installed G9/HD graphics providers. A temporary Mega battle form must never overwrite the Pokémon's saved species identity.

CI creates a Mega Venusaur proof artifact for inspection. Original sprite and audio credits remain in CREDITS.md and the EBDX source metadata.
