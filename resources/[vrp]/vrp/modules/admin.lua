



-- COMMANDS

RegisterCommand('giveitem',function(source,args,rawCommand)
  local user_id = vRP.getUserId(source)
  if not vRP.hasPermission(user_id,"giveitem") then return end
  if not args[1] or not args[2] then return end
  vRP.giveInventoryItem(user_id,args[1],tonumber(args[2]))
end)

RegisterCommand('givemoney',function(source,args,rawCommand)
	local user_id = vRP.getUserId(source)
	if not vRP.hasPermission(user_id,"givemoney") then return end
  if not args[1] then return end
  local identity = vRP.getUserIdentity(user_id)
  local amount = tonumber(args[1])
  if not args[2] then 
    vRP.giveMoney(user_id,amount)
    local uMsg = "Ação: **Adicionou Dinheiro na Conta**\nSteamName: **"..GetPlayerName(source).."**\nIdentidade: **"..identity.name.." "..identity.firstname.."\n**UserID: **"..user_id.."**\nValor: **"..parseInt(args[1])..",00**\n"..os.date("\nData:** %d/%m/%Y \n**Horario:** %H:%M:%S **")
    vRP.ToDiscord(source,GetConvar("Wh_AdminActions", "none"),"Spawn de Dinheiro",uMsg,10053324)
  return end 
  local identity2 = vRP.getUserIdentity(tonumber(args[2]))
  vRP.giveMoney(tonumber(args[2]),amount)
  local uMsg = "Ação: **Adicionou Dinheiro na Conta de outro Jogador**\nSteamName: **"..GetPlayerName(source).."**\nIdentidade: **"..identity.name.." "..identity.firstname.."\n**UserID: **"..user_id.."**\n\nIdentidade Alvo: **"..identity2.name.." "..identity2.firstname.."\n**UserID Alvo: **"..parseInt(args[2]).."**\nValor: **"..parseInt(args[1])..",00**\n"..os.date("\nData:** %d/%m/%Y \n**Horario:** %H:%M:%S **")
  vRP.ToDiscord(source,GetConvar("Wh_AdminActions", "none"),"Spawn de Dinheiro",uMsg,10053324)
end)

RegisterCommand('tptome',function(source,args,rawCommand)
	local user_id = vRP.getUserId(source)
	if not vRP.hasPermission(user_id,"tptome") then return end
  if not args[1] then return end
  local tplayer = vRP.getUserSource(tonumber(args[1]))
  if not tplayer then return end
  local x,y,z = vRPclient.getPosition(source)
  vRPclient.teleport(tplayer,x,y,z)
end)

RegisterCommand('tpto',function(source,args,rawCommand)
	local user_id = vRP.getUserId(source)
	if not vRP.hasPermission(user_id,"tpto") then return end
  if not args[1] then return end
  local tplayer = vRP.getUserSource(tonumber(args[1]))
  if not tplayer then return end
  vRPclient.teleport(source,vRPclient.getPosition(tplayer))
end)

RegisterCommand('nc',function(source,args,rawCommand)
	local user_id = vRP.getUserId(source)
	if not vRP.hasPermission(user_id,"noclip") then return end
  vRPclient.toggleNoclip(source)
end)

RegisterCommand('tpcds',function(source,args,rawCommand)
	local user_id = vRP.getUserId(source)
	if not vRP.hasPermission(user_id,"tpcds") then return	end 
  local fcoords = args[1]
  -- local fcoords = vRP.prompt(source,"Cordenadas:","")
  if fcoords == "" then return end
  local coords = {}
  for coord in string.gmatch(fcoords or "0,0,0","[^,]+") do
    table.insert(coords,parseInt(coord))
  end
  vRPclient.teleport(source,coords[1] or 0,coords[2] or 0,coords[3] or 0)
end)

RegisterCommand('coords',function(source,args,rawCommand)
	local user_id = vRP.getUserId(source)
	if not vRP.hasPermission(user_id,"coords") then return end
  local x,y,z,h = vRPclient.getPosition(source)
  local lugar = vRP.prompt(source,"Lugar:","")
  if lugar == "" then return end
  local uMsg = "**Nome do Local:**   "..lugar.."\n\n**Coords** ```vector3("..x..","..y..","..z.."),\n\nHeading: "..h.."```"
  vRP.ToDiscord(source,GetConvar("Wh_Coords", "none"),"Coordenada Salva",uMsg,10053324)
end)

RegisterCommand('cds',function(source,args,rawCommand)
	local user_id = vRP.getUserId(source)
	if not vRP.hasPermission(user_id,"coords") then return end
  local x,y,z,h = vRPclient.getPosition(source)
  local uMsg = "**Coords** ```coords = vector3("..x..","..y..","..z.."), heading = "..h.."```"
  vRP.ToDiscord(source,GetConvar("Wh_Coords", "none"),"Coordenada Salva",uMsg,10053324)
end)
