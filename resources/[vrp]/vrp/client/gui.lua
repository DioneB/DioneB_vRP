
-- PROMPT
function tvRP.prompt(title,default_text)
  SendNUIMessage({type = "UPDATE_PROMPT_DATA", data = {msg = tostring(title)}})
	SetNuiFocus(true)
end

function tvRP.destroyPrompt()
	SendNUIMessage({type = "UPDATE_PROMPT_ANIM", data = {anim = 'CenterClipPathOut'}})
    Citizen.SetTimeout(900, function()
        SendNUIMessage({type = "HIDE_PROMPT"})
    end)
end

-- REQUEST
function tvRP.request(id,text,time)
  SendNUIMessage({type = "ADD_REQUEST", data = {request = {id = id, timer = time, msg = tostring(text)}}})
  SetNuiFocus(true)
  tvRP.playSound("HUD_MINI_GAME_SOUNDSET","5_SEC_WARNING")
end

function tvRP.destroyRequest()
	SendNUIMessage({type = "UPDATE_REQUEST_ANIM", data = {anim = 'ClipPathOut'}})
  Citizen.SetTimeout(900, function()
      SendNUIMessage({type = "UPDATE_REQUEST_TIMER", data = {timer = 0}})
      SendNUIMessage({type = "UPDATE_REQUEST_STATE", data = {runing = false}})
      SendNUIMessage({type = "HIDE_REQUEST"})
  end)
end


-- HELP TEXT
function tvRP.showHelpText(key,text)
  SendNUIMessage({type = "UPDATE_HELPTEXT_DATA", data = {control = key, msg = text}})
  tvRP.playSound("HUD_MINI_GAME_SOUNDSET","5_SEC_WARNING")
end

function tvRP.destroyHelpText()
	SendNUIMessage({type = "UPDATE_HELPTEXT_ANIM", data = {anim = 'CenterClipPathOut'}})
  Citizen.SetTimeout(900, function()
    SendNUIMessage({type = "HIDE_HELPTEXT"})
  end)
end

-- NOTIFY
-- success | error | alert | info | money
function tvRP.notify(ntype,timer,title,msg)
  SendNUIMessage({type = "ADD_NOTIFY", data = {notification = {id = ntype..'_'..math.random(1,9000), ntype = ntype, timer = timer, title = title, msg = msg}}})
end

-- ITEM NOTIFY
function tvRP.itemNotify(name,label,amount,action)
  SendNUIMessage({type = "ADD_ITEM_NOTIFY", payload = {notification = {id = name..'_'..math.random(1,9000), name = name, label = label, amount = amount, action = action}}})
end


-- ACTION
function tvRP.showAction(timer,msg)
  SendNUIMessage({type = "UPDATE_ACTION_DATA", data = {timer = timer, msg = msg}})
end

function tvRP.destroyAction()
	SendNUIMessage({type = "UPDATE_ACTION_ANIM", data = {anim = 'ClipPathOut'}})
  Citizen.SetTimeout(900, function()
      SendNUIMessage({type = "HIDE_ACTION"})
  end)
end


-- NUI CBs
RegisterNUICallback('PROMPT_AWNSER', function(data,cb)
  vRPserver._promptResult(data.input)
  SetNuiFocus(false)
  cb('ok')
end)

RegisterNUICallback('AWNSER_REQUEST', function(data,cb)
  vRPserver._requestResult(data.id,data.awnser)
  SetNuiFocus(false)
  cb('ok')
end)
