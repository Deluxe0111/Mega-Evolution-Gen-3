# v1.0.0 release preparation and status

**The GitHub repository and its existing `v1.0.0-Beta` release are public.** The existing release predates the current strict Modkit distribution checks and is not yet verified against them. Prepare and test the new `v1.0.0` archive rather than treating the original beta as validated.

On Windows, run `powershell -NoProfile -File .\tools\prepare_release.ps1` in the mod repository to build `dist\mega-evolution-gen3-v1.0.0.zip` and its SHA-256 checksum. See [Modkit publishing checklist](MODKIT_PUBLISHING.md) for the exact strict `validate`, `lint`, compatibility scan and `pack` workflow, and [testing](TESTING.md) for the gameplay matrix. The new distribution-gate GitHub workflow tests a staged player archive without uploading or publishing it.

## Remaining release checks

1. **Asset inventory and credits:** Verify that referenced runtime sprites, icons, atlas pages and cries are included, and keep all source/contributor credits. Exclude ROM files and extracted ROM assets.
2. **Strict Modkit validation:** Prepare a player ZIP from the runtime inventory, extract to a clean folder and pass the engine's strict `modkit validate`, `lint` and `pack` checks. A green repository metadata/test workflow alone is not sufficient.
3. **Game coverage:** Test the specific claimed Gen 3 games and optional-mod configurations. `games: ["gen3"]` is a family-wide claim, not proof of testing every title.
4. **Clean install and save safety:** Confirm ZIP import (and manual folder install), the Key Stone shop, Mega action, shiny/normal front/back art, party/switch icons, cries, trainer fights, faint/revert, disable/re-enable and previous-version save migration.
5. **Release notes:** Describe tested game versions and known limitations; publish the new `v1.0.0` tag only after the validated ZIP is ready. Keep `v1.0.0-Beta` as the historical pre-release.

## Runtime inventory

The isolated archive is prepared by `tools/package_release.py`. It includes the manifest, entrypoint, runtime `src/*.lua` and `data/*.lua`, the indexed atlas pages and Lua index, Mega Stone and Key Stone icons, EBDX UI images, direct-read Mega party icons and cries, `README.md`, `DIFFERENCES.md` and credited source metadata. It intentionally excludes source animation sheets, developer tooling, tests and workflows. The test builder's `--private-preview` flag is for local verification only.

**Historical automation:** `.github/workflows/publish-beta.yml` is a retired Beta publisher and does not publish from this public repository. Use the v1.0.0 preparation script and upload the validated ZIP to a new `v1.0.0` GitHub release after strict Modkit and gameplay checks pass.
