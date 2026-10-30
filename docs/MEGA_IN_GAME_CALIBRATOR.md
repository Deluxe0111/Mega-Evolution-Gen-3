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
4. Use **L/R shoulder buttons** to browse Megas. The D-pad immediately
   moves the selected sprite. Both front (enemy) and back (player) are
   visible on the preview stage.

This screen uses a *battle-style rendering preview*, not a real playable test
fight. That makes iteration fast, safe and available without a save full of
every stone. Final placements should still be checked in live battles with
G9 Battle Sprites and Gen 3 HD Sprites enabled.

## Controls

| Button | Action |
| --- | --- |
| **L / R shoulders** | Previous / next Mega |
| **D-pad Left / Right** | Move the selected sprite horizontally by one game pixel |
| **D-pad Up / Down** | Move the selected sprite vertically by one game pixel |
| **Hold B + Up / Down** | Increase / decrease scale by 0.05 |
| **A** | Switch between player **BACK** and enemy **FRONT** |
| **Select** | Toggle normal / shiny |
| **Start** | Export **all 98** settings, then exit (only if export succeeds) |

There is **one direct editing mode**, with no extra field selector. `dx`,
`dy` and `scale` are the only adjustable values. `feet` and
`baseline` are still preserved in the full Lua export but are deliberately
not editable here: both overlap with vertical positioning. Increasing
`dy` moves down, decreasing moves up. `B` alone does nothing; it's the
held scaling modifier. All frames in the animation retain their relative
positions and hovering motion. The HUD uses the game's native pixel font
at integer coordinates for legibility.

## Exporting the adjustments

Press **START**. The tuner writes the **entire**
`mega_presentation_export.lua` file — not just the last Pokémon — and
**exits the tuner on successful export**. If no export backend is available,
it stays open and displays an error so your edits are not silently lost.

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
