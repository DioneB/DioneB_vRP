function tvRP.varyHealth(variation)
	local ped = PlayerPedId()
	local n = math.floor(GetEntityHealth(ped)+variation)
	SetEntityHealth(ped,n)
end
  
function tvRP.getHealth()
	return GetEntityHealth(PlayerPedId())
end

function tvRP.setHealth(health)
	local n = math.floor(health)
	SetEntityHealth(PlayerPedId(),n)
end


function tvRP.setFriendlyFire(flag)
  NetworkSetFriendlyFireOption(flag)
  SetCanAttackFriendly(PlayerPedId(), flag, flag)
end

function tvRP.setPolice(flag)
  local player = PlayerId()
  SetPoliceIgnorePlayer(player, not flag)
  SetDispatchCopsForPlayer(player, flag)
end

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(5000)
    if IsPlayerPlaying(PlayerId()) then
      local ped = PlayerPedId()
      local vthirst = 0
      local vhunger = 0
      if IsPedOnFoot(ped) and not tvRP.isNoclip() then
        local factor = math.min(tvRP.getSpeed(),10)
        vthirst = vthirst+1*factor
        vhunger = vhunger+0.5*factor
      end
      if IsPedInMeleeCombat(ped) then
        vthirst = vthirst+10
        vhunger = vhunger+5
      end
      if IsPedHurt(ped) or IsPedInjured(ped) then
        vthirst = vthirst+2
        vhunger = vhunger+1
      end
      if vthirst ~= 0 then
        vRPserver._varyThirst(vthirst/12.0)
      end
      if vhunger ~= 0 then
        vRPserver._varyHunger(vhunger/12.0)
      end
    end
  end
end)

local in_coma = false
local coma_left = cfg.coma_duration*60
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    local ped = PlayerPedId()
    local health = GetEntityHealth(ped)
    if health <= 120 and coma_left > 0 then
      if not in_coma then
        if IsEntityDead(ped) then
          local x,y,z = tvRP.getPosition()
          NetworkResurrectLocalPlayer(x, y, z, true, true, false)
          Citizen.Wait(0)
        end
        in_coma = true
        vRPserver._updateHealth(120)
        SetEntityHealth(ped, 120)
        SetEntityInvincible(ped,true)
        tvRP.playScreenEffect(cfg.coma_effect,-1)
        tvRP.ejectVehicle()
        tvRP.setRagdoll(true)
      else 
        if health < 120 then 
          SetEntityHealth(ped, 120) 
        end
      end
    else
      if in_coma then -- get out of coma state
        in_coma = false
        SetEntityInvincible(ped,false)
        tvRP.setRagdoll(false)
        tvRP.stopScreenEffect(cfg.coma_effect)
        if coma_left <= 0 then -- get out of coma by death
          SetEntityHealth(ped, 0)
        end
        SetTimeout(5000, function()
          coma_left = cfg.coma_duration*60
        end)
      end
    end
  end
end)

function tvRP.isInComa()
  return in_coma
end

function tvRP.killComa()
  if in_coma then
    coma_left = 0
  end
end

Citizen.CreateThread(function()
  while true do 
    Citizen.Wait(1000)
    if in_coma then
      coma_left = coma_left-1
    end
  end
end)

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(100)
    SetPlayerHealthRechargeMultiplier(PlayerId(), 0)
  end
end)


