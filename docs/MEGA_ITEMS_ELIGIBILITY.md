# Mega Stone eligibility and item registration

This is the next step toward the ORAS-style battle Mega toggle. It **does not enable the on-screen toggle or perform Mega Evolution yet**.

## Items

The public Gen1Recomp Gen 3 registry is used (mod.content.items:register), following National Dex Gen 3. The stable IDs are in data/mega_items.lua:

- **92 Mega Stones** at item numbers 1500–1591 (fixed, alphabetically pinned in the first published catalogue).
- **Key Stone** at item number 1599 in the KEY_ITEMS pocket.

All items have a non-consumable field-use setting. Mega Stones are held items; they must never be usable as evolution stones from the Bag, because Mega Evolution does not permanently change the saved Pokémon.

The IDs are **save-affecting**: never reorder or renumber existing items in subsequent releases. Future items must be appended at unused IDs after checking other mods; any registration collision is logged and the item fails closed rather than overwriting someone else's item.

This import does NOT distribute the Key Stone or Mega Stones to player inventories, place them in shops, or retroactively alter saves. Item icons still need a separate native Bag icon adapter (source PNG files already exist).

## Form lookup

The 98 EBDX Mega forms have stable slugs in data/mega_forms.lua. The eligibility module matches the **real base species** and currently held **correct Mega Stone** (number or canonical ID); Charizard X/Y and other multiple forms are selected by held item.

For player eligibility, main.lua also checks that a registered Key Stone is **actually in session.bag** via the native Bag.has function. Missing Key Stones do not silently grant one.

Eligibility rejects:
- Knocked-off or incorrect held Stones, missing Key Stone, unsupported species.
- Fainted Pokémon, transformed Pokémon, restricted tutorial/safari/link scenes.
- Ambiguous form mappings rather than guessing which form is active.

Source data's Stone-free **Mega Rayquaza** is still gated off until Dragon Ascent, its special trigger and the relevant battle mechanics are implemented. Enemy trainer Key Stone state likewise still needs a trainer-side implementation.

The public function is:

    local mega = mod:find("mega-evolution-gen3")
    local slug, reason = mega.exports.checkMegaEligibility(battleState, battler)

For example an eligible Venusaur with its Venusaurite and a player Key Stone returns "mega_venusaur". The API is read-only: it never spends the held item or updates the battle.

## Why there's no active battle button yet

Gen1Recomp has three distinct move-menu render paths (FireRed/LeafGreen, Ruby/Sapphire, Emerald), double-battle target selection, and a turn engine which **rebuilds command action tables when planning moves**. Merely tagging the menu action is insufficient: the Mega request must be retained outside the copied command and matched to the right battler at action execution. G9 Battle Sprites already owns the picture hooks.

Before exposing an active control we must connect a transformation handler that actually adjusts stats/types/abilities, plays the transformation, swaps only that battler's art, and can revert safely. We should not install a cosmetic button which consumes a turn or silently does nothing.

## Tests

    lua tests/test_mega_items.lua

CI also runs this alongside tests for the 98-form art provider and the Mega selection state machine.
