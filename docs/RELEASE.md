# Release preparation

The current manifest version is `0.1.0` and the build is marked `experimental`. The repository is not yet a certified public release.

## Distribution prerequisites

1. **Asset permissions:** Verify redistribution permission for each included Mega sprite, item icon, UI image and cry. Retain creator credits and original source metadata; third-party files must not be implicitly relicensed by a code licence.
2. **Copyright:** Do not package a GBA ROM, BIOS, Pokémon game executable, decompiled ROM assets, personal saves or another mod's distribution.
3. **Gameplay:** Run the acceptance and cross-mod matrix in [Testing](TESTING.md), including FireRed and Emerald with/without National Dex and G9/HD sprite providers.
4. **Build health:** Confirm required GitHub Actions workflows pass. A green metadata check alone is insufficient.
5. **Installability:** Test a clean extracted mod and the actual ZIP through Gen1Recomp's Mods UI. Check for the Key Stone shop, Mega button, animations, switch/faint behaviour and the party screen.
6. **Version:** Only after release evidence exists should a version tag and GitHub Release be created. Keep the manifest's `experimental` flag until the gameplay matrix warrants a stable label.

## Runtime contents to preserve

The installed mod requires:

- `manifest.json` and `main.lua`;
- every runtime `src/*.lua` and `data/*.lua` module;
- `assets/runtime/mega_atlas_index.lua` and all referenced `assets/runtime/atlas/*.png` pages;
- `assets/source/ebdx/mega_stones/*.png`, the Key Stone and battle UI images in `assets/source/ebdx/ui_reference/`, and `assets/source/ebdx/megas/*/cry.ogg`;
- `README.md`, `CREDITS.md`, this release guide and retained upstream `assets/source/ebdx/source_metadata/README.md`.

Source animation PNGs, EBDX import tooling, local previews, test fixtures, GitHub workflows and transient reports need not be in the player archive unless a runtime path references them. Never remove files based only on their location under `assets/source`.

## Player archive

After all art/audio rights are cleared, build and verify the distributable ZIP:

```powershell
py -3 tests/check_project.py
py -3 tests/check_docs.py
py -3 tools/package_release.py --check
py -3 tools/package_release.py --rights-cleared
```

The output is `dist/mega-evolution-gen3-v<version>.zip` plus a SHA-256 checksum. The ZIP contains root-level `manifest.json`, runtime Lua code, atlas pages, icons, cries and essential documentation. It omits development tooling and unneeded source animation PNGs. `--check` is safe to run in CI and never creates a distributable package; `--rights-cleared` is an explicit maintainer assertion, not an automatic rights check.

## Publication

Check the archive inventory, calculate a SHA-256 checksum, attach the tested ZIP and checksum to the versioned GitHub Release, and document the exact Gen1Recomp build and supported games. Keep links to required optional content packs in [Dependencies](DEPENDENCIES.md). Publish only after permissions and live tests are recorded.

Release blockers must remain visible rather than converting untested features into release claims.
