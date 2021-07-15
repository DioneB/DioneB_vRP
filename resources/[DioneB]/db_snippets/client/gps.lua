Citizen.CreateThread(function()
	while true do
		timer = 1500
		if IsWaypointActive() then
			timer = 0
			rgb = RGBRainbow(1)
			AddTextEntrys()
		end
		Citizen.Wait(timer)
	end
end)

function AddTextEntrys()
    local blip = GetFirstBlipInfoId(8)
    local blipX = 0.0
    local blipY = 0.0
    
    if (blip ~= 0) then
        local coord = GetBlipCoords(blip)
        blipX = coord.x
        blipY = coord.y
        blipZ = coord.z
		DrawMarker(1, blipX, blipY, blipZ, 0, 0, 0, 0, 0, 0, 3.0, 3.0, 350.0, rgb.r, rgb.g, rgb.b, 255, 0, 0, 2, 0, 0, 0, 0)	
		-- DrawMarker(31, blipX, blipY, blipZ+375.0, 0, 0, 0, 0, 0, 0, 50.0, 50.0, 50.0, rgb.r, rgb.g, rgb.b, 255, 0, 1, 2, 0, 0, 0, 0)	
    end
end

function RGBRainbow(frequency)
    local result = {}
    local curtime = GetGameTimer() / 1000

    result.r = math.floor(math.sin(curtime * frequency + 0) * 127 + 128)
    result.g = math.floor(math.sin(curtime * frequency + 2) * 127 + 128)
    result.b = math.floor(math.sin(curtime * frequency + 4) * 127 + 128)

    return result
end