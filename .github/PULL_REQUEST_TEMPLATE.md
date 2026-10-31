## What changed?

Describe the behaviour, assets or documentation changed and why.

## Dependencies / compatibility

- Does this add or change a manifest dependency? Verify its **mod ID** and GitHub source.
- Which Gen1Recomp version/game(s) and optional mods are affected?
- Does this touch saved Pokémon, battle hooks, imported trainer data or normal G9/HD rendering ownership?

## Verification

- [ ] `python tests/check_project.py`
- [ ] `python tests/check_docs.py` if docs/links changed
- [ ] Relevant Lua regressions pass
- [ ] GitHub Actions checks pass
- [ ] Live game check completed, or explicitly marked pending

**Tested game/ROM:**  
**Gen1Recomp commit/version:**  
**Enabled mod IDs/versions:**  

## Risks / outstanding QA

List any known failures, unverified interactions, changed artwork permissions or release impacts.
