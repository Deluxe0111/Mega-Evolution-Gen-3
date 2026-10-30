-- Mega Evolution Gen 3: initial, intentionally non-invasive foundation.
-- No species slots, battles, or persistent Pokemon data are modified yet.
return function(mod)
  -- Other mods may discover the project without confusing the scaffold for
  -- a working Mega Evolution implementation.
  mod.exports.apiVersion = 0
  mod.exports.isActive = function() return false end
  mod.exports.supportedGames = { "gen3" }
  if mod.log and type(mod.log.info) == "function" then
    mod.log:info("Mega Evolution Gen 3: foundation loaded; battle mechanics not installed")
  end
end
