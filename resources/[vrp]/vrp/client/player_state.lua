local state_ready = false

function tvRP.playerStateReady(state)
  state_ready = state
end

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(30000)
    if IsPlayerPlaying(PlayerId()) and state_ready then
      local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(-1),true))
      vRPserver._updatePos(x,y,z)
      vRPserver._updateHealth(tvRP.getHealth())
      vRPserver._updateWeapons(tvRP.getWeapons())
      vRPserver._updateCustomization(tvRP.getCustomization())
    end
  end
end)

-- WEAPONS
local weapon_types = {
  "WEAPON_KNIFE",
  "WEAPON_STUNGUN",
  "WEAPON_FLASHLIGHT",
  "WEAPON_NIGHTSTICK",
  "WEAPON_HAMMER",
  "WEAPON_BAT",
  "WEAPON_GOLFCLUB",
  "WEAPON_CROWBAR",
  "WEAPON_PISTOL",
  "WEAPON_COMBATPISTOL",
  "WEAPON_APPISTOL",
  "WEAPON_PISTOL50",
  "WEAPON_MICROSMG",
  "WEAPON_SMG",
  "WEAPON_ASSAULTSMG",
  "WEAPON_ASSAULTRIFLE",
  "WEAPON_CARBINERIFLE",
  "WEAPON_ADVANCEDRIFLE",
  "WEAPON_MG",
  "WEAPON_COMBATMG",
  "WEAPON_PUMPSHOTGUN",
  "WEAPON_SAWNOFFSHOTGUN",
  "WEAPON_ASSAULTSHOTGUN",
  "WEAPON_BULLPUPSHOTGUN",
  "WEAPON_STUNGUN",
  "WEAPON_SNIPERRIFLE",
  "WEAPON_HEAVYSNIPER",
  "WEAPON_REMOTESNIPER",
  "WEAPON_GRENADELAUNCHER",
  "WEAPON_GRENADELAUNCHER_SMOKE",
  "WEAPON_RPG",
  "WEAPON_PASSENGER_ROCKET",
  "WEAPON_AIRSTRIKE_ROCKET",
  "WEAPON_STINGER",
  "WEAPON_MINIGUN",
  "WEAPON_GRENADE",
  "WEAPON_STICKYBOMB",
  "WEAPON_SMOKEGRENADE",
  "WEAPON_BZGAS",
  "WEAPON_MOLOTOV",
  "WEAPON_FIREEXTINGUISHER",
  "WEAPON_PETROLCAN",
  "WEAPON_DIGISCANNER",
  "WEAPON_BRIEFCASE",
  "WEAPON_BRIEFCASE_02",
  "WEAPON_BALL",
  "WEAPON_FLARE"
}

function tvRP.getWeaponTypes()
  return weapon_types
end

function tvRP.getWeapons()
  local player = GetPlayerPed(-1)
  local ammo_types = {}
  local weapons = {}
  for k,v in pairs(weapon_types) do
    local hash = GetHashKey(v)
    if HasPedGotWeapon(player,hash) then
      local weapon = {}
      weapons[v] = weapon
      local atype = Citizen.InvokeNative(0x7FEAD38B326B9F74, player, hash)
      if ammo_types[atype] == nil then
        ammo_types[atype] = true
        weapon.ammo = GetAmmoInPedWeapon(player,hash)
      else
        weapon.ammo = 0
      end
    end
  end
  return weapons
end

function tvRP.replaceWeapons(weapons)
  local old_weapons = tvRP.getWeapons()
  tvRP.giveWeapons(weapons, true)
  return old_weapons
end

function tvRP.giveWeapons(weapons,clear_before)
  local player = GetPlayerPed(-1)
  if clear_before then
    RemoveAllPedWeapons(player,true)
  end
  for k,weapon in pairs(weapons) do
    local hash = GetHashKey(k)
    local ammo = weapon.ammo or 0
    GiveWeaponToPed(player, hash, ammo, false)
  end
end

function tvRP.setArmour(amount)
  SetPedArmour(GetPlayerPed(-1), amount)
end

local function parse_part(key)
  if type(key) == "string" and string.sub(key,1,1) == "p" then
    return true,tonumber(string.sub(key,2))
  end
  return false,tonumber(key)
end

function tvRP.getDrawables(part)
  local isprop, index = parse_part(part)
  if isprop then
    return GetNumberOfPedPropDrawableVariations(GetPlayerPed(-1),index) 
  end
  return GetNumberOfPedDrawableVariations(GetPlayerPed(-1),index)
end

function tvRP.getDrawableTextures(part,drawable)
  local isprop, index = parse_part(part)
  if isprop then
    return GetNumberOfPedPropTextureVariations(GetPlayerPed(-1),index,drawable)
  end
  return GetNumberOfPedTextureVariations(GetPlayerPed(-1),index,drawable)
end

function tvRP.getCustomization()
  local ped = GetPlayerPed(-1)
  local custom = {}
  custom.modelhash = GetEntityModel(ped)
  for i=0,20 do
    custom[i] = {GetPedDrawableVariation(ped,i), GetPedTextureVariation(ped,i), GetPedPaletteVariation(ped,i)}
  end
  for i=0,10 do
    custom["p"..i] = {GetPedPropIndex(ped,i), math.max(GetPedPropTextureIndex(ped,i),0)}
  end
  return custom
end

function tvRP.setCustomization(custom)
  local r = async()
  Citizen.CreateThread(function()
    if custom then
      local ped = GetPlayerPed(-1)
      local mhash = nil
      if custom.modelhash then
        mhash = custom.modelhash
      elseif custom.model then
        mhash = GetHashKey(custom.model)
      end
      if mhash then
        local i = 0
        while not HasModelLoaded(mhash) and i < 10000 do
          RequestModel(mhash)
          Citizen.Wait(10)
        end
        if HasModelLoaded(mhash) then
          -- changing player model remove weapons and armour, so save it
          local weapons = tvRP.getWeapons()
          local armour = GetPedArmour(ped)
          SetPlayerModel(PlayerId(), mhash)
          tvRP.giveWeapons(weapons,true)
          tvRP.setArmour(armour)
          SetPedMaxHealth(PlayerPedId(),400)
          SetModelAsNoLongerNeeded(mhash)
        end
      end
      ped = GetPlayerPed(-1)
      for k,v in pairs(custom) do
        if k ~= "model" and k ~= "modelhash" then
          local isprop, index = parse_part(k)
          if isprop then
            if v[1] < 0 then
              ClearPedProp(ped,index)
            else
              SetPedPropIndex(ped,index,v[1],v[2],v[3] or 2)
            end
          else
            SetPedComponentVariation(ped,index,v[1],v[2],v[3] or 2)
          end
        end
      end
    end
    r()
  end)
  return r:wait()
end

-- fix invisible players by resetting customization every minutes
--[[
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(60000)
    if state_ready then
      local custom = tvRP.getCustomization()
      custom.model = nil
      custom.modelhash = nil
      tvRP.setCustomization(custom)
    end
  end
end)
--]]
