
local noclip = false
local noclip_speed = 1.0

local function MainThread()
  Citizen.CreateThread(function()
    while true do
      Citizen.Wait(0)
      if not noclip then return end
      local ped = GetPlayerPed(-1)
      local x,y,z = tvRP.getPosition()
      local dx,dy,dz = tvRP.getCamDirection()
      local speed = noclip_speed
      SetEntityVelocity(ped, 0.0001, 0.0001, 0.0001)
      if IsControlPressed(0,32) then -- MOVE UP
        x = x+speed*dx
        y = y+speed*dy
        z = z+speed*dz
      end
      if IsControlPressed(0,269) then -- MOVE DOWN
        x = x-speed*dx
        y = y-speed*dy
        z = z-speed*dz
      end
      SetEntityCoordsNoOffset(ped,x,y,z,true,true,true)
    end
  end)
end 

function tvRP.toggleNoclip()
  noclip = not noclip
  MainThread()
  local ped = GetPlayerPed(-1)
  if noclip then
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false, false)
  else
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true, false)
  end
end
function tvRP.teleportToWaypoint()
  noclip = not noclip
  MainThread()
  local ped = GetPlayerPed(-1)
  if noclip then
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false, false)
  else
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true, false)
  end
end

function tvRP.isNoclip()
  return noclip
end
