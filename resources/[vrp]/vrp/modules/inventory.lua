local cfg = module("cfg/inventory")
vRP.items = {}
local UsableItems = {}
function vRP.defInventoryItem(idname,name,description,prop,weight)
  if weight == nil then
    weight = 0
  end
  local item = {name=name,description=description,prop=prop,weight=weight}
  vRP.items[idname] = item
end

function vRP.RegisterItem(fullid, cb)
	UsableItems[fullid] = cb
end

function vRP.UseItem(source, fullid)
  if UsableItems[fullid] then
    UsableItems[fullid](source)
  end
end

function vRP.parseItem(idname)
  return splitString(idname,"|")
end

function vRP.getItemName(idname)
  if not vRP.items[idname] then return end
  return vRP.items[idname].name
end

function vRP.getItemDescription(idname)
  if not vRP.items[idname] then return end
  return vRP.items[idname].description
end

function vRP.getItemWeight(idname)
  if not vRP.items[idname] then return end
  return vRP.items[idname].weight
end

function vRP.getItemProp(idname)
  if not vRP.items[idname] then return end
  return vRP.items[idname].prop
end

function vRP.computeItemsWeight(items)
  local weight = 0
  for k,v in pairs(items) do
    local iweight = vRP.getItemWeight(k)
    weight = weight+iweight*v.amount
  end
  return weight
end

function vRP.giveInventoryItem(user_id,idname,amount,notify)
  if notify == nil then notify = true end
  local data = vRP.getUserDataTable(user_id)
  if not data or amount <= 0 then return end
  local entry = data.inventory[idname]
  if notify then
    local player = vRP.getUserSource(user_id)
    if not player then return end
    -- vRPclient._notify(player,lang.inventory.give.received({vRP.getItemName(idname),amount}))
  end
  if not entry then
    data.inventory[idname] = {amount=amount}
  return end
  entry.amount = entry.amount+amount
end

function vRP.tryGetInventoryItem(user_id,idname,amount,notify)
  if notify == nil then notify = true end
  local data = vRP.getUserDataTable(user_id)
  if not data or amount <= 0 then return false end 
  local entry = data.inventory[idname]
  if not entry or entry.amount < amount then
    local entry_amount = 0
    if entry then entry_amount = entry.amount end
    if notify then
      local player = vRP.getUserSource(user_id)
      if not player then return end
      -- vRPclient._notify(player,lang.inventory.missing({vRP.getItemName(idname),amount-entry_amount}))
    end
  return end
  entry.amount = entry.amount-amount
  if entry.amount <= 0 then
    data.inventory[idname] = nil 
  end
  if notify then
    local player = vRP.getUserSource(user_id)
    if not player then return end
    -- vRPclient._notify(player,lang.inventory.give.given({vRP.getItemName(idname),amount}))
  end
  return true
end

function vRP.getInventoryItemAmount(user_id,idname)
  local data = vRP.getUserDataTable(user_id)
  if not data or not data.inventory then return 0 end 
  local entry = data.inventory[idname]
  if not entry then return end
  return entry.amount
end

function vRP.getInventory(user_id)
  local data = vRP.getUserDataTable(user_id)
  if not data then return end
  return data.inventory
end

function vRP.getInventoryWeight(user_id)
  local data = vRP.getUserDataTable(user_id)
  if not data or not data.inventory then return 0 end
  return vRP.computeItemsWeight(data.inventory)
end

function vRP.getInventoryMaxWeight(user_id)
  return math.floor(vRP.expToLevel(vRP.getExp(user_id, "physical", "strength")))*cfg.inventory_weight_per_strength
end

function vRP.clearInventory(user_id)
  local data = vRP.getUserDataTable(user_id)
  if not data then return end
  data.inventory = {}
end

AddEventHandler("vRP:playerJoin", function(user_id,source,name,last_login)
  local data = vRP.getUserDataTable(user_id)
  if data.inventory then return end
  data.inventory = {}
end)