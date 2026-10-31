# Contributing

This is a Beta Gen1Recomp Gen 3 Mega Evolution mechanics mod. Please open a focused pull request rather than committing unreviewed ROM, save or asset changes directly to `main`.

Before contributing, read the [development guide](docs/DEVELOPMENT.md), [runtime architecture](docs/ARCHITECTURE.md), [dependency policy](docs/DEPENDENCIES.md), [test matrix](docs/TESTING.md), and [art rights](CREDITS.md).

## Pull request checklist

- [ ] Document which game/ROM, Gen1Recomp build and mod versions were tested.
- [ ] Include a regression test for new battle or trainer rules, including invalid/missing-data cases.
- [ ] Keep the saved Pokémon and original imported ROM trainer pack immutable.
- [ ] Declare new dependencies using the other mod's actual manifest ID and `dependency_sources` repository.
- [ ] Run the Python validators and relevant Lua tests; check GitHub Actions results.
- [ ] If artwork or audio is changed, retain original source credits and confirm distribution rights.
- [ ] Mark untested gameplay scenarios clearly rather than describing them as working.

**Do not attach copyrighted game ROMs or redistribute third-party assets without their appropriate permissions.**
