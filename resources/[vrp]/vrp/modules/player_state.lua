local cfg = module("cfg/player_state")

AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn)
  local player = source
  local data = vRP.getUserDataTable(user_id)
  local tmpdata = vRP.getUserTmpTable(user_id)
  if first_spawn then
    if data.customization == nil then
      data.customization = cfg.default_customization
    end
    if data.position then
      vRPclient.teleport(source,data.position.x,data.position.y,data.position.z)
    end
    if data.customization then
      vRPclient.setCustomization(source,data.customization) 
      if data.weapons then
        vRPclient.giveWeapons(source,data.weapons,true)
        if data.health then
          vRPclient.setHealth(source,data.health)
          SetTimeout(5000, function()
            if vRPclient.isInComa(player) then
              vRPclient.killComa(player)
            end
          end)
        end
      end
    else
      if data.weapons then
        vRPclient.giveWeapons(source,data.weapons,true)
      end
      if data.health then
        vRPclient.setHealth(source,data.health)
      end
    end
  else
    vRP.setHunger(user_id,0)
    vRP.setThirst(user_id,0)
    vRP.clearInventory(user_id)
    vRP.setMoney(user_id,0)
    if data.customization then
      vRPclient._setCustomization(source,data.customization)
    end
  end
  vRPclient._playerStateReady(source, true)
end)

function tvRP.updatePos()
  local user_id = vRP.getUserId(source)
  if not user_id then return end
  local data = vRP.getUserDataTable(user_id)
  if not data then return end
  local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(source)))
  data.position = {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
end

function tvRP.updateWeapons(weapons)
  local user_id = vRP.getUserId(source)
  if not user_id then return end 
  local data = vRP.getUserDataTable(user_id)
  if not data then return end
  data.weapons = weapons
end

function tvRP.updateCustomization(customization)
  local user_id = vRP.getUserId(source)
  if not user_id then return end 
  local data = vRP.getUserDataTable(user_id)
  if not data then return end 
  data.customization = customization
end

function tvRP.updateHealth(health)
  local user_id = vRP.getUserId(source)
  if not user_id then return end
  local data = vRP.getUserDataTable(user_id)
  if not data then return end
  data.health = health
end
