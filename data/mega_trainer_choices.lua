-- Curated Mega choices, indexed by game identity then native trainer ID.
-- Intentionally empty pending a trainer-by-trainer review.
--
-- Example (only after confirming the native trainer ID and party slots):
-- return {
--   firered = {
--     [123] = { slot = 3, slug = "mega_alakazam" },
--     [124] = { disabled = true },
--   },
--   emerald = {},
-- }
--
-- These entries SELECT an existing eligible Pokémon; they do not grant
-- items or modify species, moves, levels or ROM trainer-party records.
-- Boss party additions/replacements require a separate explicit team patch
-- that can be reviewed alongside the original ROM party.
return {
  firered = {},
  leafgreen = {},
  ruby = {},
  sapphire = {},
  emerald = {},
}
