local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

RegisterCommand('testev',function(source,args,rawCommand)
  local user_id = vRP.getUserId(source)
  local fcoords = vRP.prompt(source,"Cordenadas:","")
  if fcoords == "" then return end
  local coords = {}
  for coord in string.gmatch(fcoords or "0,0,0","[^,]+") do
    table.insert(coords,parseInt(coord))
  end
  vRPclient.teleport(source,coords[1] or 0,coords[2] or 0,coords[3] or 0)
end)



function task_ping()
	for user_id,p_source in pairs(vRP.getUsers()) do
		local p_ping = GetPlayerPing(p_source)
		print('^2Jogador: ^0'..p_source..'^2 | ^1Ping: '..p_ping..'^0')
	end
	print('^2Verificando Ping dos Jogadores Conectados^0')
	SetTimeout(2*10000,task_ping)
end

-- async(function()
-- 	task_ping()
-- end)
