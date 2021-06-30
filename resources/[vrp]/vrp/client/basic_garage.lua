function tvRP.getNearestVehicle(radius)
  local x,y,z = tvRP.getPosition()
  local ped = GetPlayerPed(-1)
  if IsPedSittingInAnyVehicle(ped) then
    return GetVehiclePedIsIn(ped, true) 
  end
  local veh = GetClosestVehicle(x+0.0001,y+0.0001,z+0.0001, radius+0.0001, 0, 8192+4096+4+2+1)  -- boats, helicos
  if not IsEntityAVehicle(veh) then veh = GetClosestVehicle(x+0.0001,y+0.0001,z+0.0001, radius+0.0001, 0, 4+2+1) end -- cars
  return veh
end

function tvRP.fixeNearestVehicle(radius)
  local veh = tvRP.getNearestVehicle(radius)
  if not IsEntityAVehicle(veh) then return end
  SetVehicleFixed(veh)
end

function tvRP.ejectVehicle()
  local ped = GetPlayerPed(-1)
  if not IsPedSittingInAnyVehicle(ped) then return end
  local veh = GetVehiclePedIsIn(ped,false)
  TaskLeaveVehicle(ped, veh, 4160)
end

function tvRP.isInVehicle()
  local ped = GetPlayerPed(-1)
  return IsPedSittingInAnyVehicle(ped) 
end
