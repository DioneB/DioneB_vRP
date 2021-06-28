function vRP.save_idle_custom(player,custom)
	local r_idle = {}
	local user_id = vRP.getUserId(player)
	if user_id then
		local data = vRP.getUserDataTable(user_id)
		if data then
			if data.cloakroom_idle == nil then
				data.cloakroom_idle = custom
			end

			for k,v in pairs(data.cloakroom_idle) do
				r_idle[k] = v
			end
		end
	end
	return r_idle
end

-- remove the player uniform (cloakroom)
function vRP.removeCloak(player)
  local user_id = vRP.getUserId(player)
  if user_id then
    local data = vRP.getUserDataTable(user_id)
    if data then
      if data.cloakroom_idle ~= nil then -- consume cloakroom idle
        vRPclient._setCustomization(player,data.cloakroom_idle)
        data.cloakroom_idle = nil
      end
    end
  end
end