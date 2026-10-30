# In-game Mega Battle Calibrator (developer tool)

The **MEGA TUNER** is an opt-in, **non-combat battle-stage preview** for
placing all 98 Mega forms in Emerald and FireRed. It draws the game's native
battle background and the **real animated Mega front/back atlas frames**
with the same placement formula the Mega runtime uses. It never starts a
trainer/wild encounter, runs turn logic, changes Pokémon party records,
consumes items or touches the saved game.

## Opening it

1. Install the `feature/mega-in-game-calibrator` branch of this mod and fully
   restart Gen1Recomp.
2. Open the Mod Manager/options for **Mega Evolution Gen 3** and turn on
   **MEGA TUNER** (off by default), or start Gen1Recomp in developer mode.
3. Enter the overworld, open the game **Start menu**, choose **MEGA TUNER**.
4. Browse Megas and press **A** to edit the selected form. Both front (enemy)
   and back (player) are visible on the preview stage.

This screen uses a *battle-style rendering preview*, not a real playable test
fight. That makes iteration fast, safe and available without a save full of
every stone. Final placements should still be checked in live battles with
G9 Battle Sprites and Gen 3 HD Sprites enabled.

## Controls

| Screen | Button | Action |
| --- | --- | --- |
| Browse | LEFT / RIGHT | Previous / next Mega |
| Browse | UP / DOWN | Jump backward / forward 10 Megas |
| Browse | A | Enter adjustment mode |
| Browse | B | Close tuner |
| Either | SELECT | Choose player **BACK** / enemy **FRONT** |
| Either | START | Export full tuning file |
| Adjust | UP / DOWN | Select scale, dx, dy, feet, baseline |
| Adjust | LEFT / RIGHT | Decrease / increase selected value |
| Adjust | A | Toggle normal / shiny animation |
| Adjust | B | Return to Browse |

Scale changes in **0.05** increments; other values move by **one logical
game pixel**. Increase `dy` to move **down**, decrease to move **up**.
`feet` is an anchor in the original frame's coordinate space, and may
intentionally lie below the Pokémon's visible pixels for hovering Megas.
All frames in one animation continue sharing their position: **the tool does
not automatically ground or re-centre individual animation frames**.

## Exporting the adjustments

Press **START** from either screen. The tuner writes the **entire**
`mega_presentation_export.lua` file — not just the last Pokémon.

Export goes to the mod's installation-scoped storage:
`mod_cache/mega-evolution-gen3/exports/mega_presentation_export.lua`.
For convenient sharing it also attempts a second copy, using Gen1Recomp's
sandbox-compatible file write, at
`mod_compat/mega-evolution-gen3/mega_presentation_export.lua`
under the game's persistent data directory. The exact parent directory
depends on the Gen1Recomp installation and platform; some portable setups
may use a different backing store. If only the primary export succeeds,
the file can still be retrieved from the mod cache.

The mod also exposes `exportMegaTuning()` / `megaTuningText()` for
connected tools. **Neither export automatically changes the installed mod**.
Send me the generated `.lua` file here and I can apply the values,
review outliers and make a PR.

## Notes

- The whole-roster export is intentionally complete, and syntax-checked in
  `tests/test_mega_tuner_model.lua`.
- Saved game stats, moves, abilities and held stones are unaffected.
- The preview uses the current GBA 240×160 battlefield coordinates.
- Mod calibration settings are **session-only until exported**. Keep a copy
  of the exported file before closing the game. Import changes through a
  new mod update, not by overwriting shipped atlas or save data.
- An export during an unmodified session still includes all 98 existing
  values, so it can serve as a full baseline snapshot.
