local cfg = module("cfg/survival")
-- api

function vRP.getHunger(user_id)
  local data = vRP.getUserDataTable(user_id)
  if data then
    return data.hunger
  end

  return 0
end

function vRP.getThirst(user_id)
  local data = vRP.getUserDataTable(user_id)
  if data then
    return data.thirst
  end

  return 0
end

function vRP.setHunger(user_id,value)
  local data = vRP.getUserDataTable(user_id)
  if data then
    data.hunger = value
    if data.hunger < 0 then data.hunger = 0
    elseif data.hunger > 100 then data.hunger = 100 
    end

    -- update bar
    local source = vRP.getUserSource(user_id)
    vRPclient._setProgressBarValue(source, "vRP:hunger",data.hunger)
    if data.hunger >= 100 then
      -- NUI STATUS BAIXO
    end
  end
end

function vRP.setThirst(user_id,value)
  local data = vRP.getUserDataTable(user_id)
  if data then
    data.thirst = value
    if data.thirst < 0 then data.thirst = 0
    elseif data.thirst > 100 then data.thirst = 100 
    end

    -- update bar
    local source = vRP.getUserSource(user_id)
    vRPclient._setProgressBarValue(source, "vRP:thirst",data.thirst)
    if data.thirst >= 100 then
      -- NUI STATUS BAIXO
    end
  end
end

function vRP.varyHunger(user_id, variation)
  local data = vRP.getUserDataTable(user_id)
  if data then
    local was_starving = data.hunger >= 100
    data.hunger = data.hunger + variation
    local is_starving = data.hunger >= 100

    -- apply overflow as damage
    local overflow = data.hunger-100
    if overflow > 0 then
      vRPclient._varyHealth(vRP.getUserSource(user_id),-overflow*cfg.overflow_damage_factor)
    end

    if data.hunger < 0 then data.hunger = 0
    elseif data.hunger > 100 then data.hunger = 100 
    end

    -- set progress bar data
    local source = vRP.getUserSource(user_id)
    vRPclient._setProgressBarValue(source,"vRP:hunger",data.hunger)
    if was_starving and not is_starving then
      vRPclient._setProgressBarText(source,"vRP:hunger","")
    elseif not was_starving and is_starving then
      -- vRPclient._setProgressBarText(source,"vRP:hunger",lang.survival.starving())
    end
  end
end

function vRP.varyThirst(user_id, variation)
  local data = vRP.getUserDataTable(user_id)
  if not data then return end
  local was_thirsty = data.thirst >= 100
  data.thirst = data.thirst + variation
  local is_thirsty = data.thirst >= 100
  local overflow = data.thirst-100
  if overflow > 0 then
    vRPclient._varyHealth(vRP.getUserSource(user_id),-overflow*cfg.overflow_damage_factor)
  end
  if data.thirst < 0 then data.thirst = 0
  elseif data.thirst > 100 then data.thirst = 100 
  end

  local source = vRP.getUserSource(user_id)
  vRPclient._updatePlayerStatusOnHUD(source,"thirst",data.thirst)

  if was_thirsty and not is_thirsty then
    vRPclient._setProgressBarText(source,"thirst","")
  elseif not was_thirsty and is_thirsty then
    -- vRPclient._setProgressBarText(source,"thirst",lang.survival.thirsty())
  end
end


-- tunnel api (expose some functions to clients)
function tvRP.varyHunger(variation)
  local user_id = vRP.getUserId(source)
  if not user_id then return end
  vRP.varyHunger(user_id,variation)
end

function tvRP.varyThirst(variation)
  local user_id = vRP.getUserId(source)
  if not user_id then return end
  vRP.varyThirst(user_id,variation)
end

function task_update()
  for k,v in pairs(vRP.users) do
    vRP.varyHunger(v,cfg.hunger_per_minute)
    vRP.varyThirst(v,cfg.thirst_per_minute)
  end
  SetTimeout(60000,task_update)
end

async(function()
  task_update()
end)

AddEventHandler("vRP:playerJoin",function(user_id,source,name,last_login)
  local data = vRP.getUserDataTable(user_id)
  if data.hunger ~= nil then return end
  data.hunger = 0
  data.thirst = 0
end)

AddEventHandler("vRP:playerSpawn",function(user_id, source, first_spawn)
  local data = vRP.getUserDataTable(user_id)
  vRPclient._setPolice(source,false)
  vRPclient._setFriendlyFire(source,true)
  vRP.setHunger(user_id, data.hunger)
  vRP.setThirst(user_id, data.thirst)
end)