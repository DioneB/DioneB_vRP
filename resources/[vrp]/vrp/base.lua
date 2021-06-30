local Proxy = module("lib/Proxy")
local Tunnel = module("lib/Tunnel")
Debug = module("lib/Debug")
local config = module("cfg/base")
vRP = {}
Proxy.addInterface("vRP",vRP)
tvRP = {}
Tunnel.bindInterface("vRP",tvRP) 
vRPclient = Tunnel.getInterface("vRP") 

vRP.users,vRP.rusers,vRP.user_tables,vRP.user_tmp_tables,vRP.user_sources = {},{},{},{},{}

local db_driver
local db_drivers,cached_prepares,cached_queries,prepared_queries,db_initialized = {},{},{},{},false

function vRP.registerDBDriver(name, on_init, on_prepare, on_query)
  if not db_drivers[name] then
    db_drivers[name] = {on_init, on_prepare, on_query}
    if name == config.db.driver then 
      db_driver = db_drivers[name] 
      local ok = on_init(config.db)
      if ok then
        print("^1[DioneB vRPEX] ^2Conectado ao Banco de Dados usando o Driver: ^0\""..name.."\".")
        db_initialized = true
        for _,prepare in pairs(cached_prepares) do
          on_prepare(table.unpack(prepare, 1, table.maxn(prepare)))
        end
        for _,query in pairs(cached_queries) do
          async(function()
            query[2](on_query(table.unpack(query[1], 1, table.maxn(query[1]))))
          end)
        end
        cached_prepares = nil
        cached_queries = nil
      else
        error("^1[DioneB vRPEX] ^2Erro ao estabelecer uma Conexão ao Banco de Dados. Driver: ^0\""..name.."\".")
      end
    end
  end
end

function vRP.prepare(name, query)
  if Debug.active then
    Debug.log("prepare "..name.." = \""..query.."\"")
  end
  prepared_queries[name] = true
  if db_initialized then
    db_driver[2](name, query)
  else
    table.insert(cached_prepares, {name, query})
  end
end

function vRP.query(name, params, mode)
  if not prepared_queries[name] then
    error("^1[DioneB vRPEX] ^2A Querie: ^0"..name.." ^2Não foi Encontrada. Você Registrou antes usando ^0vRP.prepare ?")
  end
  if not mode then mode = "query" end
  if Debug.active then
    Debug.log("query "..name.." ("..mode..") params = "..json.encode(params or {}))
  end
  if db_initialized then 
    return db_driver[3](name, params or {}, mode)
  else
    local r = async()
    table.insert(cached_queries, {{name, params or {}, mode}, r})
    return r:wait()
  end
end
function vRP.execute(name, params)
  return vRP.query(name, params, "execute")
end
function vRP.scalar(name, params)
  return vRP.query(name, params, "scalar")
end
if not config.db or not config.db.driver then
  error("^1[DioneB vRPEX] ^2Erro ao encontrar as Definições do DB^0")
end

Citizen.CreateThread(function()
  while not db_initialized do
    print("^1[DioneB vRPEX] ^3O Driver ^0\""..config.db.driver.."\" ^3não foi Inicializado ainda ^0(^5"..#cached_prepares.." Prepares Agendados ^0| ^5"..#cached_queries.." Queries Agendadas^0)")
    Citizen.Wait(5000)
  end
end)

-- queries
vRP.prepare("vRP/base_tables",[[
CREATE TABLE IF NOT EXISTS vrp_users(
  id INTEGER AUTO_INCREMENT,
  last_login VARCHAR(255),
  whitelisted BOOLEAN,
  banned BOOLEAN,
  CONSTRAINT pk_user PRIMARY KEY(id)
);

CREATE TABLE IF NOT EXISTS vrp_user_ids(
  identifier VARCHAR(100),
  user_id INTEGER,
  CONSTRAINT pk_user_ids PRIMARY KEY(identifier),
  CONSTRAINT fk_user_ids_users FOREIGN KEY(user_id) REFERENCES vrp_users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vrp_user_data(
  user_id INTEGER,
  dkey VARCHAR(100),
  dvalue TEXT,
  CONSTRAINT pk_user_data PRIMARY KEY(user_id,dkey),
  CONSTRAINT fk_user_data_users FOREIGN KEY(user_id) REFERENCES vrp_users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vrp_users_priority(
  steam VARCHAR(100),
  user_id INTEGER,
  priority INTEGER,
  CONSTRAINT pk_user_priority PRIMARY KEY(steam),
  CONSTRAINT fk_user_priority_users FOREIGN KEY(user_id) REFERENCES vrp_users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vrp_srv_data(
  dkey VARCHAR(100),
  dvalue TEXT,
  CONSTRAINT pk_srv_data PRIMARY KEY(dkey)
);
]])

vRP.prepare("vRP/create_user","INSERT INTO vrp_users(whitelisted,banned) VALUES(false,false); SELECT LAST_INSERT_ID() AS id")
vRP.prepare("vRP/add_identifier","INSERT INTO vrp_user_ids(identifier,user_id) VALUES(@identifier,@user_id)")
vRP.prepare("vRP/userid_byidentifier","SELECT user_id FROM vrp_user_ids WHERE identifier = @identifier")

vRP.prepare("vRP/set_userdata","REPLACE INTO vrp_user_data(user_id,dkey,dvalue) VALUES(@user_id,@key,@value)")
vRP.prepare("vRP/get_userdata","SELECT dvalue FROM vrp_user_data WHERE user_id = @user_id AND dkey = @key")

vRP.prepare("vRP/set_srvdata","REPLACE INTO vrp_srv_data(dkey,dvalue) VALUES(@key,@value)")
vRP.prepare("vRP/get_srvdata","SELECT dvalue FROM vrp_srv_data WHERE dkey = @key")

vRP.prepare("vRP/get_banned","SELECT banned FROM vrp_users WHERE id = @user_id")
vRP.prepare("vRP/set_banned","UPDATE vrp_users SET banned = @banned WHERE id = @user_id")
vRP.prepare("vRP/get_whitelisted","SELECT whitelisted FROM vrp_users WHERE id = @user_id")
vRP.prepare("vRP/set_whitelisted","UPDATE vrp_users SET whitelisted = @whitelisted WHERE id = @user_id")
vRP.prepare("vRP/set_last_login","UPDATE vrp_users SET last_login = @last_login WHERE id = @user_id")
vRP.prepare("vRP/get_last_login","SELECT last_login FROM vrp_users WHERE id = @user_id")
vRP.prepare("vRP/get_priority_list","SELECT * FROM vrp_users_priority")

print("^1[DioneB vRPEX] ^3INICIALIZANDO ESTRUTURA DO DB^0")
async(function()
  vRP.execute("vRP/base_tables")
end)

function vRP.getUserIdByIdentifiers(ids)
  if ids and #ids then
    for i=1,#ids do
      if (string.find(ids[i], "ip:") == nil) then
        local rows = vRP.query("vRP/userid_byidentifier", {identifier = ids[i]})
        if #rows > 0 then
          return rows[1].user_id
        end
      end
    end
    local rows, affected = vRP.query("vRP/create_user", {})
    if #rows > 0 then
      local user_id = rows[1].id
      for l,w in pairs(ids) do
        if (string.find(w, "ip:") == nil) then
          vRP.execute("vRP/add_identifier", {user_id = user_id, identifier = w})
        end
      end
      return user_id
    end
  end
end

function vRP.getSourceIdKey(source)
  local ids = GetPlayerIdentifiers(source)
  local idk = "idk_"
  for k,v in pairs(ids) do
    idk = idk..v
  end
  return idk
end

function vRP.getPlayerEndpoint(player)
  return GetPlayerEP(player) or "0.0.0.0"
end

function vRP.getPlayerName(player)
  return GetPlayerName(player) or "unknown"
end

function vRP.isBanned(user_id, cbr)
  local rows = vRP.query("vRP/get_banned", {user_id = user_id})
  if #rows > 0 then
    return rows[1].banned
  else
    return false
  end
end

function vRP.setBanned(user_id,banned)
  vRP.execute("vRP/set_banned", {user_id = user_id, banned = banned})
end

function vRP.isWhitelisted(user_id, cbr)
  local rows = vRP.query("vRP/get_whitelisted", {user_id = user_id})
  if #rows > 0 then
    return rows[1].whitelisted
  else
    return false
  end
end

function vRP.setWhitelisted(user_id,whitelisted)
  vRP.execute("vRP/set_whitelisted", {user_id = user_id, whitelisted = whitelisted})
end

function vRP.getLastLogin(user_id, cbr)
  local rows = vRP.query("vRP/get_last_login", {user_id = user_id})
  if #rows > 0 then
    return rows[1].last_login
  else
    return ""
  end
end

function vRP.setUData(user_id,key,value)
  vRP.execute("vRP/set_userdata", {user_id = user_id, key = key, value = value})
end

function vRP.getUData(user_id,key,cbr)
  local rows = vRP.query("vRP/get_userdata", {user_id = user_id, key = key})
  if #rows > 0 then
    return rows[1].dvalue
  else
    return ""
  end
end

function vRP.setSData(key,value)
  vRP.execute("vRP/set_srvdata", {key = key, value = value})
end

function vRP.getSData(key, cbr)
  local rows = vRP.query("vRP/get_srvdata", {key = key})
  if #rows > 0 then
    return rows[1].dvalue
  else
    return ""
  end
end

function vRP.getUserDataTable(user_id)
  return vRP.user_tables[user_id]
end

function vRP.getUserTmpTable(user_id)
  return vRP.user_tmp_tables[user_id]
end

function vRP.getSpawns(user_id)
  local tmp = vRP.getUserTmpTable(user_id)
  if tmp then
    return tmp.spawns or 0
  end
  return 0
end

function vRP.getUserId(source)
  if source ~= nil then
    local ids = GetPlayerIdentifiers(source)
    if ids ~= nil and #ids > 0 then
      return vRP.users[ids[1]]
    end
  end
  return nil
end

function vRP.getUsers()
  local users = {}
  for k,v in pairs(vRP.user_sources) do
    users[k] = v
  end
  return users
end

function vRP.getUserSource(user_id)
  return vRP.user_sources[user_id]
end

function vRP.ban(source,reason)
  local user_id = vRP.getUserId(source)
  if user_id then
    vRP.setBanned(user_id,true)
    vRP.kick(source,"[Você foi Deportado da Cidade]: "..reason)
  end
end

function vRP.kick(source,reason)
  DropPlayer(source,reason)
end

function vRP.GetClosestPlayer(src,radius)
	local players = GetPlayers()
	local p_coords = GetEntityCoords(GetPlayerPed(src))
	for index, player in ipairs(players) do
		if parseInt(player) ~= parseInt(src) then
			local playerPed = GetPlayerPed(parseInt(player))
			if(DoesEntityExist(playerPed)) then
				local coords = GetEntityCoords(playerPed)
				if #(coords - p_coords) <= radius then 
					return parseInt(player)
				end 
			end
		end
	end
end
function vRP.GetClosestPlayers(src,radius)
	local users = {}
	local players = GetPlayers()
	local p_coords = GetEntityCoords(GetPlayerPed(src))
	for index, player in ipairs(players) do
		if parseInt(player) ~= parseInt(src) then
			local playerPed = GetPlayerPed(parseInt(player))
			if(DoesEntityExist(playerPed)) then
				local coords = GetEntityCoords(playerPed)
				if #(coords - p_coords) <= radius then 
					table.insert(users, parseInt(player))
				end 
			end
		end
	end
	return users
end

function vRP.GetClosestUsers(src,radius)
	local users = {}
	local players = GetPlayers()
	local p_coords = GetEntityCoords(GetPlayerPed(src))
	for index, player in ipairs(players) do
		if parseInt(player) ~= parseInt(src) then
			local playerPed = GetPlayerPed(parseInt(player))
			if(DoesEntityExist(playerPed)) then
				local coords = GetEntityCoords(playerPed)
				if #(coords - p_coords) <= radius then
					local user_id = vRP.getUserId(parseInt(player))
					table.insert(users, user_id)
				end 
			end
		end
	end
	return users
end

function vRP.IsClosestUser(src,uid,radius)
	local players = GetPlayers()
	local p_coords = GetEntityCoords(GetPlayerPed(src))
	for index, player in ipairs(players) do
		if parseInt(player) ~= parseInt(src) then
			local playerPed = GetPlayerPed(parseInt(player))
			if(DoesEntityExist(playerPed)) then
				local coords = GetEntityCoords(playerPed)
				if #(coords - p_coords) <= radius then
					if uid == vRP.getUserId(parseInt(player)) then return true end
				end 
			end
		end
	end
end

function vRP.dropPlayer(source)
  local user_id = vRP.getUserId(source)
  local endpoint = vRP.getPlayerEndpoint(source)
  vRPclient._removePlayer(-1, source)
  if user_id then
    TriggerEvent("vRP:playerLeave", user_id, source)
    vRP.setUData(user_id,"vRP:datatable",json.encode(vRP.getUserDataTable(user_id)))
    vRP.users[vRP.rusers[user_id]] = nil
    vRP.rusers[user_id] = nil
    vRP.user_tables[user_id] = nil
    vRP.user_tmp_tables[user_id] = nil
    vRP.user_sources[user_id] = nil
  end
end

function task_save_datatables()
  SetTimeout(60000, task_save_datatables)
  TriggerEvent("vRP:save")
  Debug.log("DataTables Salvos")
  for k,v in pairs(vRP.user_tables) do
    vRP.setUData(k,"vRP:datatable",json.encode(v))
  end
end

async(function()
  task_save_datatables()
end)

AddEventHandler("queue:playerConnecting",function(source,ids,name,setKickReason,deferrals)
	deferrals.defer()
	Debug.log("playerConnecting "..name)
	local source = source
	local ids = ids  
	local WLStats = GetConvar('wl_status', 'Ativa')
	if ids ~= nil and #ids > 0 then
		deferrals.update("Checando seus Identificadores.")
		local user_id = vRP.getUserIdByIdentifiers(ids)
		if user_id then
		  deferrals.update("Checando Lista de Extraditados.")
		  if not vRP.isBanned(user_id) then
			deferrals.update("Verificando seu Passaporte.")
			if (WLStats == "Ativa") then
				if vRP.isWhitelisted(user_id) then
				  if vRP.rusers[user_id] == nil then
					deferrals.update("Tudo Certo, Bem-Vindo\nAproveite nossa Cidade....")
					local sdata = vRP.getUData(user_id, "vRP:datatable")
					vRP.users[ids[1]] = user_id
					vRP.rusers[user_id] = ids[1]
					vRP.user_tables[user_id] = {}
					vRP.user_tmp_tables[user_id] = {}
					vRP.user_sources[user_id] = source
					local data = json.decode(sdata)
					if type(data) == "table" then vRP.user_tables[user_id] = data end
            local tmpdata = vRP.getUserTmpTable(user_id)
            deferrals.update("Obtendo dados da Ultima Conexao...")
            local last_login = vRP.getLastLogin(user_id)
            tmpdata.last_login = last_login or ""
            tmpdata.spawns = 0
            local ep = vRP.getPlayerEndpoint(source)
            local last_login_stamp = os.date("%H:%M:%S %d/%m/%Y")
            vRP.execute("vRP/set_last_login", {user_id = user_id, last_login = last_login_stamp})
            print("^0[^2DioneB vRPEX^0] ^2Jogador Conectado: ^0Nome: ^5" ..name.. " ^0IP: ^5(" ..vRP.getPlayerEndpoint(source).. ") ^0User ID: ^5" .. user_id .. "^0")
            TriggerEvent("vRP:playerJoin", user_id, source, name, tmpdata.last_login)
            deferrals.done()
				  else 
            local tmpdata = vRP.getUserTmpTable(user_id)
            tmpdata.spawns = 0
            TriggerEvent("vRP:playerRejoin", user_id, source, name)
            print("^0[^2DioneB vRPEX^0] ^3Jogador Reconectado: ^0Nome: ^5" ..name.. " ^0IP: ^5(" ..vRP.getPlayerEndpoint(source).. ") ^0User ID: ^5" .. user_id .. "^0")
            deferrals.done()
				  end
				else
					print("^0[^2DioneB vRPEX ^0] ^1Jogador Sem Whitelist: ^0Nome: ^5" ..name.. " ^0IP: ^5(" ..vRP.getPlayerEndpoint(source).. ") ^0User ID: ^5" .. user_id .. "^0")
					TriggerEvent("queue:playerConnectingRemoveQueues",ids)
					deferrals.done("\nSeus Documentos não foram encontrados na Lista de Sobreviventes.\nNumero do seu RG: ( "..user_id.." )\nDiscord da Cidade: https://discord.gg/")
				end
			else
				if vRP.rusers[user_id] == nil then
					deferrals.update("Tudo Certo, Bem-Vindo\nAproveite nossa Cidade....")
					local sdata = vRP.getUData(user_id, "vRP:datatable")
					vRP.users[ids[1]] = user_id
					vRP.rusers[user_id] = ids[1]
					vRP.user_tables[user_id] = {}
					vRP.user_tmp_tables[user_id] = {}
					vRP.user_sources[user_id] = source
					local data = json.decode(sdata)
					if type(data) == "table" then vRP.user_tables[user_id] = data end
            local tmpdata = vRP.getUserTmpTable(user_id)
            deferrals.update("Obtendo dados da Ultima Conexao...")
            local last_login = vRP.getLastLogin(user_id)
            tmpdata.last_login = last_login or ""
            tmpdata.spawns = 0
            local ep = vRP.getPlayerEndpoint(source)
            local last_login_stamp = os.date("%H:%M:%S %d/%m/%Y")
            vRP.execute("vRP/set_last_login", {user_id = user_id, last_login = last_login_stamp})
            print("^0[^2DioneB vRPEX^0] ^2Jogador Conectado: ^0Nome: ^5" ..name.. " ^0IP: ^5(" ..vRP.getPlayerEndpoint(source).. ") ^0User ID: ^5" .. user_id .. "^0")
            TriggerEvent("vRP:playerJoin", user_id, source, name, tmpdata.last_login)
            deferrals.done()
				else
					local tmpdata = vRP.getUserTmpTable(user_id)
					tmpdata.spawns = 0
					TriggerEvent("vRP:playerRejoin", user_id, source, name)
					print("^0[^2DioneB vRPEX^0] ^3Jogador Reconectado: ^0Nome: ^5" ..name.. " ^0IP: ^5(" ..vRP.getPlayerEndpoint(source).. ") ^0User ID: ^5" .. user_id .. "^0")
					deferrals.done()
				end
			end
		  else
        print("^0[^2DioneB vRPEX^0] ^1Jogador Rejeitado (BANIDO): ^0Nome: ^5" ..name.. " ^0IP: ^5(" ..vRP.getPlayerEndpoint(source).. ") ^0User ID: ^5" .. user_id .. "^0")
        TriggerEvent("queue:playerConnectingRemoveQueues",ids)
        deferrals.done("Você foi Banido da Cidade.")
		  end
		else
			print("^0[^2DioneB vRPEX^0] ^1Jogador Rejeitado (Erro nos Identificadores): ^0Nome: ^5" ..name.. " ^0IP: ^5(" ..vRP.getPlayerEndpoint(source).. ") ^0User ID: ^5" .. user_id .. "^0")
			deferrals.done("Erro nos Identificadores.")
			TriggerEvent("queue:playerConnectingRemoveQueues",ids)
		end
	else
		print("^0[^2BRZ ^0] ^1Jogador Rejeitado (Identificador Faltando, Steam ou Rockstar ou Discord): ^0Nome: ^5" ..name.. " ^0IP: ^5(" ..vRP.getPlayerEndpoint(source).. ") ^0User ID: ^5" .. user_id .. "^0")
		deferrals.done("Identificador Faltando, Steam ou Rockstar ou Discord.")
		TriggerEvent("queue:playerConnectingRemoveQueues",ids)
	end
end)

AddEventHandler("playerDropped",function(reason)
	Debug.log("playerDropped "..source)
	local source = source
	print("^0[^2DioneB vRPEX^0] ^1Jogador Desconectou: ^0Nome: ^5" ..GetPlayerName(source).. " ^0IP: ^5(" ..vRP.getPlayerEndpoint(source).. ") ^0User ID: ^5" .. vRP.getUserId(source) .. "^0")
	vRP.dropPlayer(source)
end)

RegisterServerEvent("vRPcli:playerSpawned")
AddEventHandler("vRPcli:playerSpawned",function()
	local user_id = vRP.getUserId(source)
	if user_id then
		vRP.user_sources[user_id] = source
		local tmp = vRP.getUserTmpTable(user_id)
		tmp.spawns = tmp.spawns+1
		local first_spawn = (tmp.spawns == 1)

		if first_spawn then
			for k,v in pairs(vRP.user_sources) do
				vRPclient._addPlayer(source,v)
			end
			vRPclient._addPlayer(-1,source)
			Tunnel.setDestDelay(source,0)
		end
		TriggerEvent("vRP:playerSpawn",user_id,source,first_spawn)
	end
end)

RegisterServerEvent("vRP:playerDied")