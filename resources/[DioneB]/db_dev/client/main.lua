local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
Client = Proxy.getInterface("vRP")
Remote = Tunnel.getInterface("db_dev")


function createPedScreen() 
  CreateThread(function()

      heading = GetEntityHeading(PlayerPedId())
      SetScriptGfxAlign(67, 67)
      SetFrontendActive(true)
      ActivateFrontendMenu('FE_MENU_VERSION_EMPTY_NO_BACKGROUND', true, -1)
      Citizen.Wait(100)
      SetMouseCursorVisibleInMenus(false)

      PlayerPedPreview = ClonePed(PlayerPedId(), heading, true, false)

      local x,y,z = table.unpack(GetEntityCoords(PlayerPedPreview))

      SetEntityCoords(PlayerPedPreview, x ,y,z-100)

      FreezeEntityPosition(PlayerPedPreview, true)

      SetEntityVisible(PlayerPedPreview, false, false)

      NetworkSetEntityInvisibleToNetwork(PlayerPedPreview, false)

      Wait(200)

      SetPedAsNoLongerNeeded(PlayerPedPreview)

      GivePedToPauseMenu(PlayerPedPreview, 2)
      
      SetPauseMenuPedLighting(true)

      SetPauseMenuPedSleepState(true)

  end)

end

RegisterCommand('ttt',function(source,args,rawCommand)
  SetTimecycleModifier("BlackOut")
  ShakeGameplayCam("HAND_SHAKE",1.0)
end)
RegisterCommand('ttt2',function(source,args,rawCommand)
  ClearTimecycleModifier()
  ShakeGameplayCam("HAND_SHAKE",0.0)
end)
RegisterCommand('screen',function(source,args,rawCommand)
  createPedScreen()
end)
RegisterCommand('inv',function(source,args,rawCommand)
  StartScreenEffect("MenuMGSelectionIn", 0, true)
end)

Citizen.CreateThread(function()
  StopScreenEffect("MenuMGSelectionIn")
end)