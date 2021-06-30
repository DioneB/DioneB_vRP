local cfg = module("cfg/inventory")
vRP.items = {}

function vRP.defInventoryItem(idname,name,description,weight)
  if weight == nil then
    weight = 0
  end
  local item = {name=name,description=description,weight=weight}
  vRP.items[idname] = item
end

function vRP.computeItemName(item,args)
  if type(item.name) == "string" then return item.name end
  return item.name(args)
end

function vRP.computeItemDescription(item,args)
  if type(item.description) == "string" then return item.description end
  return item.description(args) 
end

function vRP.computeItemWeight(item,args)
  if type(item.weight) == "number" then return item.weight end
  return item.weight(args)
end

function vRP.parseItem(idname)
  return splitString(idname,"|")
end

function vRP.getItemDefinition(idname)
  local args = vRP.parseItem(idname)
  local item = vRP.items[args[1]]
  if not item then return nil,nil,nil end
  return vRP.computeItemName(item,args), vRP.computeItemDescription(item,args), vRP.computeItemWeight(item,args)
end

function vRP.getItemName(idname)
  local args = vRP.parseItem(idname)
  local item = vRP.items[args[1]]
  if item then return vRP.computeItemName(item,args) end
  return args[1]
end

function vRP.getItemDescription(idname)
  local args = vRP.parseItem(idname)
  local item = vRP.items[args[1]]
  if item then return vRP.computeItemDescription(item,args) end
  return ""
end

function vRP.getItemWeight(idname)
  local args = vRP.parseItem(idname)
  local item = vRP.items[args[1]]
  if item then return vRP.computeItemWeight(item,args) end
  return 0
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