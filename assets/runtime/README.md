# Generated Mega animation runtime artwork

The 156 PNG atlas pages and two animation indexes are committed under this folder. They cover 98 Mega form variants, 588 PNG sprite variants, and 24,018 animation frames. Source sheets remain in ../source/ebdx/.

The Lua provider in ../../src/mega_atlas.lua lazily loads only the requested atlas page and returns a form-keyed picture entry; it does not install game hooks or implement Mega Evolution gameplay. For implementation and regeneration details, see ../../docs/ANIMATION_PIPELINE.md and ../../docs/ARCHITECTURE.md.
