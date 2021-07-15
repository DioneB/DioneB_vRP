Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
        SetCreateRandomCops(false) 
		SetCreateRandomCopsNotOnScenarios(false) 
		SetCreateRandomCopsOnScenarios(false)
        SetPoliceIgnorePlayer(PlayerId(), true)
        DisablePlayerVehicleRewards(PlayerId())
        SetVehicleDensityMultiplierThisFrame(0.01)
        SetPedDensityMultiplierThisFrame(0.01)
        SetRandomVehicleDensityMultiplierThisFrame(0.01)
        SetParkedVehicleDensityMultiplierThisFrame(0.01)
        SetScenarioPedDensityMultiplierThisFrame(0.0,0)
        if GetPlayerWantedLevel(PlayerId()) ~= 0 then
            SetPlayerWantedLevel(PlayerId(), 0, false)
            SetPlayerWantedLevelNow(PlayerId(), false)
        end
        SetRadarAsExteriorThisFrame()
        SetRadarAsInteriorThisFrame("h4_fake_islandx",vec(4700.0,-5145.0),0,0)
	end
end)
