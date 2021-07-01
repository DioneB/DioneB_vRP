local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP","vRP")

RegisterServerEvent('chat:init')
RegisterServerEvent('chat:addTemplate')
RegisterServerEvent('chat:addMessage')
RegisterServerEvent('chat:addSuggestion')
RegisterServerEvent('chat:removeSuggestion')
RegisterServerEvent('_chat:messageEntered')
RegisterServerEvent('chat:clear')
RegisterServerEvent('__cfx_internal:commandFallback')


AddEventHandler('_chat:messageEntered',function(author,color,message)
	local source = source
	local user_id = vRP.getUserId(source)
	local identity = vRP.getUserIdentity(user_id)

	if not message or not author or not identity then
		return
	end

	if not WasEventCanceled() then
		TriggerClientEvent("chatMessage",source,identity.name.." "..identity.firstname,{131,174,0},message)
	end
end)

AddEventHandler('__cfx_internal:commandFallback',function(command)
	local name = GetPlayerName(source)
	if not command or not name then
		return
	end

	if not WasEventCanceled() then
		TriggerEvent("chatMessage",source,name,'/'..command)
	end
	CancelEvent()
end)

-- local commandos = {
-- 	["asss"] = { hellp = "teste" },
-- }
  -- SUGESTÃO DE COMANDOS
local function refreshCommands(player)
    if GetRegisteredCommands then
        local registeredCommands = GetRegisteredCommands()

        local suggestions = {}

        for _, command in ipairs(registeredCommands) do
            if IsPlayerAceAllowed(player, ('command.%s'):format(command.name)) then
                table.insert(suggestions, {
                    name = '/' .. command.name,
                    help = '' -- COLOCAR DESC DE COMANDOS
                })
            end
        end

        TriggerClientEvent('chat:addSuggestions', player, suggestions)
    end
end

AddEventHandler('chat:init', function()
    refreshCommands(source)
end)

AddEventHandler('onServerResourceStart', function(resName)
    Wait(500)

    for _, player in ipairs(GetPlayers()) do
        refreshCommands(player)
    end
end)

--[ CLEAR ]-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand('clearchat', function(source)
    local user_id = vRP.getUserId(source);
    if user_id ~= nil then
        if vRP.hasPermission(user_id, "superadm.permissao") then
            TriggerClientEvent("chat:clear", -1);
        --  TriggerClientEvent("chatMessage", source, " ");
        else
            TriggerClientEvent("chat:clear", source);
            --TriggerClientEvent("chatMessage", source, "Você não tem permissão");
        end
    end
end)

RegisterCommand('me', function(source, args, rawCommand)
    local text = '*' .. rawCommand:sub(4) .. '*'
    local players = vRP.GetClosestPlayers(source,15)
    for _,player in pairs(players) do 
        TriggerClientEvent('DisplayMe',player,text,source)
    end 
    TriggerClientEvent('DisplayMe',source,text,source)
end)