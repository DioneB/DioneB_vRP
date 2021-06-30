function vRP.save_idle_custom(player,custom)
	local r_idle = {}
	local user_id = vRP.getUserId(player)
	if not user_id then return r_idle end 
	local data = vRP.getUserDataTable(user_id)
	if not data then return end
	if data.cloakroom_idle == nil then
		data.cloakroom_idle = custom
	end
	for k,v in pairs(data.cloakroom_idle) do
		r_idle[k] = v
	end
end

function vRP.removeCloak(player)
  local user_id = vRP.getUserId(player)
  if not user_id then return end
	local data = vRP.getUserDataTable(user_id)
	if not data then return end
	if not data.cloakroom_idle then return end
	vRPclient._setCustomization(player,data.cloakroom_idle)
	data.cloakroom_idle = nil
end