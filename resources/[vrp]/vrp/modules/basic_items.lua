-- load config items
local cfg = module("cfg/items")

for k,v in pairs(cfg.items) do
  vRP.defInventoryItem(k,v.label,v.desc,v.prop,v.weight,v.decay)
end

for k,v in pairs(cfg.cfg.weapons) do
  vRP.defInventoryItem(k,v.label,v.desc,v.prop,v.weight,v.decay)
end
 