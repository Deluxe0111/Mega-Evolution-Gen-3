-- Mega Stone and Key Stone registration via the public Gen 3 item registry.
-- Stone IDs/slots in data/mega_items.lua are append-only save identifiers.
local Items = {}

function Items.register(mod, catalog)
  if type(catalog) ~= "table" then return {}, { "missing Mega item catalog" } end
  local registry = mod and mod.content and mod.content.items
  if not (registry and type(registry.register) == "function") then
    return {}, { "Gen 3 item registry is unavailable" }
  end
  local added, errors = {}, {}
  local indexes, ids = {}, {}
  for _, row in ipairs(catalog) do
    local id, idx = row.id, tonumber(row.index)
    if type(id) ~= "string" or not id:match("^[A-Z0-9_]+$") or not idx or
        idx < 1 or idx > 65535 or indexes[idx] or ids[id] then
      errors[#errors + 1] = "invalid or duplicate Mega item: " .. tostring(id)
    else
      indexes[idx], ids[id] = true, true
      -- fieldUse=none: Mega Stones work only when HELD, never as a field
      -- evolution item (which would permanently mutate a saved Pokemon).
      local ok, err = pcall(function()
        registry:register(id, {
          id = id, name = row.name, index = idx, price = id == "KEY_STONE" and 10000 or 5000,
          pocket = row.pocket or "ITEMS", description = row.description,
          fieldUse = "none",
          importance = id == "KEY_STONE" and 1 or 0,
        })
      end)
      if ok then
        added[#added + 1] = { id = id, index = idx }
      else
        errors[#errors + 1] = id .. ": " .. tostring(err)
      end
    end
  end
  return added, errors
end

return Items
