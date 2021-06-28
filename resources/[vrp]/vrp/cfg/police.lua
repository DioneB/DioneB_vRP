
local cfg = {}


-- illegal items (seize)
-- specify list of "idname" or "*idname" to seize all parametric items
cfg.seizable_items = {
  "dirty_money",
  "weed",
  "*wbody",
  "*wammo"
}
-- fines
-- map of name -> money
cfg.fines = {
  ["Insult"] = 100,
  ["Speeding"] = 250,
  ["Stealing"] = 1000,
  ["Organized crime (low)"] = 10000,
  ["Organized crime (medium)"] = 25000,
  ["Organized crime (high)"] = 50000
}

return cfg
