# Gen1Recomp Modkit publishing gate

**Current status: preparing v1.0.0 for publication.** The repository and historical `v1.0.0-Beta` release are public, but its ZIP predates this Modkit gate. A newly staged player archive must pass strict Modkit validation and the gameplay acceptance checks. Contributor credits remain in [CREDITS.md](../CREDITS.md).

## Packaging entrypoint

**Windows shortcut:** From the Mega Evolution repository, run `powershell -NoProfile -File .\tools\prepare_release.ps1`. This stages the runtime-only ZIP, runs the project/docs inventory checks, runs Modkit strict validation, lint and Gen 3 compatibility, and writes `dist\mega-evolution-gen3-v1.0.0.zip` with a SHA-256 checksum. The separate Gen1Recomp checkout is expected in the sibling `gen1recomp` folder; use `-EnginePath` when it is elsewhere. The command does **not** publish a GitHub release.

The repository root includes development assets and tooling that do not belong in the player ZIP. First build an isolated runtime archive using the project's file-inventory packager:

```sh
python3 tests/check_project.py
python3 tests/check_docs.py
python3 tools/package_release.py --check
python3 tools/package_release.py --private-preview
```

Extract `dist/mega-evolution-gen3-v1.0.0-private-preview.zip` into a fresh directory (e.g. `/tmp/mega-evolution-gen3`). The archive must contain `manifest.json`, `main.lua`, `DIFFERENCES.md`, runtime `src/` and `data/`, and referenced assets **at the archive root**, not beneath an extra repository folder. Do not hand out the private-preview archive as a public download.

From the **Gen1Recomp engine** repository root (the folder containing `tools/modkit.py`), run against that extracted directory:

```sh
python3 tools/modkit.py validate /tmp/mega-evolution-gen3 --strict
python3 tools/modkit.py lint /tmp/mega-evolution-gen3
python3 tools/modkit.py gen3check /tmp/mega-evolution-gen3 --strict
python3 tools/modkit.py pack /tmp/mega-evolution-gen3 -o mega-evolution-gen3-validated.zip
```

Use a real path appropriate for your OS. The `gen3check` diagnostic is a compatibility scan, not live gameplay proof. `pack` reruns strict validation and lint and refuses warnings. Do **not** run `pack` against this repository root: it would include developer-only material and source art outside the runtime inventory.

The PR workflow `.github/workflows/modkit-distribution-gate.yml` builds the same isolated test archive and runs strict validate/lint/pack against Gen1Recomp's `dev` branch, but **does not publish or upload** the output.

## Required pre-release decisions

1. **Asset inventory and credits:** Verify that each included atlas, Mega icon, UI image and cry is referenced by the runtime inventory. Retain original artist/source credits and metadata. Do not include ROM-extracted images, game audio or patches.
2. **Compatibility scope:** Only claim game IDs after testing. The current `games: ["gen3"]` declares all Gen 3 titles, but the documented live verification is incomplete. Narrow this to tested versions if the remaining titles cannot be certified.
3. **Manifest:** Retain the `github` update hint and a semver `version`; describe optional species providers truthfully. The mod is classed as Mechanics (`MECHANIC`) and is not marked `experimental` by design. This does not waive the release checks.
4. **Actual install:** Install the *new* ZIP in a clean mods folder using **MODS > Import mod .zip**, enable it for the selected game, and confirm the Key Stone shop, Mega button, transformation, party icons, faint/revert, trainer audit, and required/optional dependency behaviour.
5. **Existing saves and mixed mods:** Test loading a previous version's save, disable/re-enable mid-save, and combinations with National Dex, G9, HD Sprites, Untamed Advanced and Nuzlocke. Add `mod.migrations:add` if the mod's persistent data shape changed.
6. **Release:** After a fully green Modkit gate and gameplay checks, verify the manifest is `1.0.0`, publish the strict-Modkit-produced `mega-evolution-gen3-v1.0.0.zip` under tag `v1.0.0`, and retain the separate historical Beta tag. The historical `v1.0.0-Beta` package is **not** evidence that these checks passed.

## Failures

Any Modkit finding is a blocker at strict level: fix the reported file or reference, stage a fresh archive, and rerun the entire gate. For install failures, remove only the new test mod, consult the launcher's attributed error, and retry from a clean installation. Do not bundle `baseroms/`, extracted ROM content or player-supplied files.
