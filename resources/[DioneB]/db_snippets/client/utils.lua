Citizen.CreateThread(function()
	for i = 1,16 do
		EnableDispatchService(i,false)
	end
end)

Citizen.CreateThread(function()
	while true do
		local cSleep = 100
		local ped = PlayerPedId()
		if IsPedInAnyVehicle(ped) then
			if GetPedInVehicleSeat(GetVehiclePedIsIn(ped),0) == ped then
				cSleep = 4
				if GetIsTaskActive(ped,165) then
					SetPedIntoVehicle(ped,GetVehiclePedIsIn(ped),0)
				end
			end
		end
		Citizen.Wait(cSleep)
	end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)
        local ped = PlayerPedId()
		SleepCArm = true
        if IsPedArmed(ped,6) then
			SleepCArm = false
            DisableControlAction(0,140,true)
            DisableControlAction(0,141,true)
            DisableControlAction(0,142,true)
        end
		if SleepCArm then
			Citizen.Wait(1200)
		end
    end
end)

Citizen.CreateThread(function()
    while true do
		Citizen.Wait(0)
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
		letSleepCapot = true
        if DoesEntityExist(veh) and not IsEntityDead(veh) then
			letSleepCapot = false
            local model = GetEntityModel(veh)
            if not IsVehicleModel(veh, GetHashKey("DELUXO")) and not IsThisModelABoat(model) and not IsThisModelAHeli(model) and not IsThisModelAPlane(model) and not IsThisModelABike(model) and not IsThisModelABicycle(model) and IsEntityInAir(veh) then
                DisableControlAction(0, 59) -- leaning left/right
                DisableControlAction(0, 60) -- leaning up/down
            end
            if GetPedInVehicleSeat(veh, -1) == GetPlayerPed(-1) then
                local roll = GetEntityRoll(veh)
                if (roll > 75.0 or roll < -75.0) then
                    DisableControlAction(2, 59, true)
                    DisableControlAction(2, 60, true)
                end
            end
        end
		if letSleepCapot then
			Citizen.Wait(2500)
		end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10000)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped) then
            local vehicle = GetVehiclePedIsIn(ped)
            if GetPedInVehicleSeat(vehicle,-1) == ped then
                local speed = GetEntitySpeed(vehicle)*2.236936
                if speed >= 180 and math.random(100) >= 97 then
                    if GetVehicleTyresCanBurst(vehicle) == false then return end
                    local pneus = GetVehicleNumberOfWheels(vehicle)
                    local pneusEffects
                    if pneus == 2 then
                        pneusEffects = (math.random(2)-1)*4
                    elseif pneus == 4 then
                        pneusEffects = (math.random(4)-1)
                        if pneusEffects > 1 then
                            pneusEffects = pneusEffects + 2
                        end
                    elseif pneus == 6 then
                        pneusEffects = (math.random(6)-1)
                    else
                        pneusEffects = 0
                    end
                    SetVehicleTyreBurst(vehicle,pneusEffects,false,1000.0)
                end
            end
        end		
    end
end)

local tasertime = false
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(100)
		local ped = PlayerPedId()
		if IsPedBeingStunned(ped) then
			SetPedToRagdoll(ped,10000,10000,0,0,0,0)
		end
		if IsPedBeingStunned(ped) and not tasertime then
			tasertime = true
			SetTimecycleModifier("REDMIST_blend")
			ShakeGameplayCam("FAMILY5_DRUG_TRIP_SHAKE",1.0)
		elseif not IsPedBeingStunned(ped) and tasertime then
			tasertime = false
			SetTimeout(5000,function()
				SetTimecycleModifier("hud_def_desat_Trevor")
				SetTimeout(10000,function()
					SetTimecycleModifier("")
					SetTransitionTimecycleModifier("")
					StopGameplayCamShaking()
				end)
			end)
		end
	end
end)
