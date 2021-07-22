local cfg = module("cfg/inventory")
vRP.items = {}
vRP.CreatedItems = {}
local UsableItems = {}

function vRP.defInventoryItem(idname,name,description,prop,weight,decay)
  if weight == nil then
    weight = 0
  end
  local item = {name=name,description=description,prop=prop,weight=weight,decay=decay}
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

function vRP.isItemUsable(fullid)
  if UsableItems[fullid] then
    return true
  end
end

function vRP.GetItemType(idname)
  local NameItemWBody,NameItemWAmmo = nil,nil
  if string.find(idname, "wbody") then NameItemWBody = string.gsub(idname,"wbody|","") end
  if string.find(idname, "wammo") then NameItemWAmmo = string.gsub(idname,"wammo|","") end
  if NameItemWBody or cfg.weapons[idname] then 
    return 'weapon', NameItemWBody
  elseif NameItemWAmmo or string.find(idname, "ammo_") then 
    return 'ammo', NameItemWAmmo
  else 
    return 'item', idname
  end  
end
function vRP.GetWeaponType(weapon)
  if not cfg.weapons[weapon] then return end
  return cfg.weapons[weapon].type
end

function vRP.parseItem(idname)
  return splitString(idname,"|")
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

function vRP.getItemDecayRate(idname)
  if not vRP.items[idname] then return end
  if not vRP.items[idname].decay then return 0 end
  return vRP.items[idname].decay
end

function vRP.computeItemsWeight(items)
  local weight = 0
  for k,v in pairs(items) do
    local iweight = vRP.getItemWeight(k)
    weight = weight+iweight*v.amount
  end
  return weight
end

function vRP.DecayItem(user_id,idname,value)
  local player = vRP.getUserSource(user_id)
  local data = vRP.getUserDataTable(user_id)
  local iLabel = vRP.getItemName(idname)
  local iDesc = vRP.getItemDescription(idname)
  local iDecay = data.inventory[idname].decay
  local niDecay = iDecay-value
  if niDecay <= 0 then
    data.inventory[idname] = nil 
    vRPclient._itemNotify(player,idname,iLabel,1,'rem')
  return end 
  data.inventory[idname].decay = niDecay
  vRPclient._itemNotify(player,idname,iLabel,1,'att')
end

function vRP.getVIPSlots(user_id)
  if vRP.hasPermission(user_id,"diamante.permissao") then	return 10 end
  if vRP.hasPermission(user_id,"ouro.permissao") then	return 7 end
  if vRP.hasPermission(user_id,"prata.permissao") then return 5 end
  return false
end

function vRP.GetPlayerQuickAcess(user_id)
	local data = json.decode(vRP.getUData(user_id,"vRP:QuickAccess"))
	if data then
	  return data
	end 
	return {}
end

function vRP.UpdatePlayerQuickAcess(user_id,quickslot,value)
	local data = json.decode(vRP.getUData(user_id,"vRP:QuickAccess"))
	local Found
	for slot,idata in pairs(data) do
    if idata.item == value.item then
			data[slot] = {item = '', decay = 0}
			data[quickslot] = value
			Found = true
		end
	end
	if not Found then 	
		for slot,idata in pairs(data) do
			if slot == quickslot then
				data[quickslot] = value
				break
			end
		end
	end 
	vRP.setUData(user_id,"vRP:QuickAccess",json.encode(data))
end

function vRP.getMaxSlots(user_id)
  local slots = tonumber(vRP.getUData(user_id, "vRP:MaxSlots")) or 5
  local VIPSlots = vRP.getVIPSlots(user_id)
  if VIPSlots then slots = slots + VIPSlots end
  return slots
end

function vRP.canCarry(user_id,itemname,qtd)
  local data = vRP.getUserDataTable(user_id)
  local slots,amount = vRP.getMaxSlots(user_id),0 
  local exists = data.inventory[itemname]
  if qtd then 
    local cCarry = (vRP.getInventoryWeight(user_id)+vRP.getItemWeight(itemname)*qtd) <= vRP.getInventoryMaxWeight(user_id)
    if not cCarry then return end
  end
  if not exists then 
    for item,itemdata in pairs (data.inventory) do amount = amount + 1 end
    if amount+1 > slots then return end
  end
  return true
end

function vRP.giveInventoryItem(user_id,idname,amount,notify)
  if notify == nil then notify = true end
  local data = vRP.getUserDataTable(user_id)
  if not data or amount <= 0 then return end
  local entry = data.inventory[idname]
  local label = vRP.getItemName(idname)
  if not vRP.canCarry(user_id,idname,amount,entry) then
    vRPclient._notify(player,'error',5,'Erro ao Adicionar Item','Você não suporta Carregar mais x'..amount..' de '..label)
  return end
  if notify then
    local player = vRP.getUserSource(user_id)
    vRPclient._itemNotify(player,idname,label,amount,'add')
  end
  if not entry then
    data.inventory[idname] = {amount=amount, decay = 100}
  return end
  entry.amount = entry.amount+amount
end


function vRP.tryGetInventoryItem(user_id,idname,amount,notify)
  if notify == nil then notify = true end
  local data = vRP.getUserDataTable(user_id)
  if not data or amount <= 0 then return false end 
  local label = vRP.getItemName(idname)
  local entry = data.inventory[idname]
  if not entry or entry.amount < amount then
    local entry_amount = 0
    if entry then entry_amount = entry.amount end
    if notify then
      local player = vRP.getUserSource(user_id)
      if not player then return end
      vRPclient._notify(player,'error',5,'Item Faltando','Está Faltando x'..amount-entry_amount..' de '..label)
    end
  return end
  entry.amount = entry.amount-amount
  if entry.amount <= 0 then
    local i_type = vRP.GetItemType(idname)
    if i_type == 'weapon' then TriggerClientEvent('Inv:RemoveWeapon', player, string.upper('weapon_'..idname)) end 
    local uQuickAcess = vRP.GetPlayerQuickAcess(user_id)
    for slot,slotdata in pairs(uQuickAcess) do 
      if slotdata.id == id then 
        vRP.UpdatePlayerQuickAcess(user_id,slot,{item = '', decay = 0})
      end 
    end
    data.inventory[idname] = nil 
  end
  if notify then
    local player = vRP.getUserSource(user_id)
    if not player then return end
    vRPclient._itemNotify(player,idname,label,amount,'rem')
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
  data.inventory = {}
  local QData = {
    slot_1= { item= '', decay= 0 },
    slot_2= { item= '', decay= 0 },
    slot_3= { item= '', decay= 0 },
    slot_4= { item= '', decay= 0 },
    slot_5= {item= '', decay= 0 },
  }
  vRP.setUData(user_id,"vRP:QuickAccess",json.encode(QData))
end


function task_decay_items()
	for user_id,p_source in pairs(vRP.getUsers()) do
    local inv = vRP.getInventory(parseInt(user_id))
    for item,itemdata in pairs(inv) do
      vRP.DecayItem(user_id,item,vRP.getItemDecayRate(item))
    end 
  end
  SetTimeout(5*60000,task_decay_items)
end
async(function()
   task_decay_items()
end)


AddEventHandler("vRP:playerJoin", function(user_id,source,name,last_login)
  local data = vRP.getUserDataTable(user_id)
  if not data.inventory then 
    data.inventory = {}
  end 
  local maxslots = vRP.getUData(user_id, "vRP:MaxSlots")
  if maxslots == '' then 
    vRP.setUData(user_id,"vRP:MaxSlots",5)
  end
  local QuickAccessData = json.decode(vRP.getUData(user_id,"vRP:QuickAccess"))
  if not QuickAccessData or QuickAccessData == '' or QuickAccessData == {} then 
		local QData = {
			slot_1= { item= '', decay= 0 },
			slot_2= { item= '', decay= 0 },
			slot_3= { item= '', decay= 0 },
			slot_4= { item= '', decay= 0 },
			slot_5= {item= '', decay= 0 },
		}
		vRP.setUData(user_id,"vRP:QuickAccess",json.encode(QData))
	end
  local engrams = vRP.getUData(user_id,"vRP:Engrams")
	if not engrams or engrams == '' then
		vRP.setUData(user_id,"vRP:Engrams",json.encode({['baseado'] = true}))
	end
end)