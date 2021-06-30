cfg = module("cfg/client")
local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
local Tools = module("vrp", "lib/Tools")

tvRP = {}
Tunnel.bindInterface("vRP", tvRP)
vRPserver = Tunnel.getInterface("vRP")
Proxy.addInterface("vRP",tvRP)

function onClientMapStart(...)
  if not Ran then ShutdownLoadingScreenNui() Ran = true end
  DoScreenFadeOut(1000)
  exports.spawnmanager:setAutoSpawn(true)
  exports.spawnmanager:forceRespawn()
end
AddEventHandler('onClientMapStart', onClientMapStart)

function tvRP.teleport(x,y,z)
	SetEntityCoords(PlayerPedId(),x+0.0001,y+0.0001,z+0.0001,1,0,0,1)
	vRPserver._updatePos(x,y,z)
end

function tvRP.getUserHeading()
	return GetEntityHeading(PlayerPedId())
end

function tvRP.clearWeapons()
  RemoveAllPedWeapons(PlayerPedId(),true)
end

function tvRP.getPosition()
	local x,y,z = table.unpack(GetEntityCoords(PlayerPedId(),true))
	local heading = GetEntityHeading(PlayerPedId())
	return x,y,z,heading
end

function tvRP.isInside()
  local x,y,z = tvRP.getPosition()
  return not (GetInteriorAtCoords(x,y,z) == 0)
end

function tvRP.getSpeed()
  local vx,vy,vz = table.unpack(GetEntityVelocity(PlayerPedId()))
  return math.sqrt(vx*vx+vy*vy+vz*vz)
end

function tvRP.getCamDirection()
  local heading = GetGameplayCamRelativeHeading()+GetEntityHeading(PlayerPedId())
  local pitch = GetGameplayCamRelativePitch()
  local x = -math.sin(heading*math.pi/180.0)
  local y = math.cos(heading*math.pi/180.0)
  local z = math.sin(pitch*math.pi/180.0)
  local len = math.sqrt(x*x+y*y+z*z)
  if len ~= 0 then
    x = x/len
    y = y/len
    z = z/len
  end
  return x,y,z
end

function tvRP.notify(msg)
  SetNotificationTextEntry("STRING")
  AddTextComponentString(msg)
  DrawNotification(true, false)
end

function tvRP.playScreenEffect(name, duration)
  if duration >= 0 then
    StartScreenEffect(name, 0, true)
    Citizen.CreateThread(function()
      Citizen.Wait(math.floor((duration+1)*1000))
      StopScreenEffect(name)
    end)
  return end 
  StartScreenEffect(name, 0, true)
end

function tvRP.stopScreenEffect(name)
  StopScreenEffect(name)
end

local anims = {}
local anim_ids = Tools.newIDGenerator()
function tvRP.playAnim(upper, seq, looping)
  if seq.task then
    tvRP.stopAnim(true)
    local ped = PlayerPedId()
    if seq.task == "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER" then
      local x,y,z = tvRP.getPosition()
      TaskStartScenarioAtPosition(ped, seq.task, x, y, z-1, GetEntityHeading(ped), 0, 0, false)
    return end
    TaskStartScenarioInPlace(ped, seq.task, 0, not seq.play_exit)
  return end
  tvRP.stopAnim(upper)
  local flags = 0
  if upper then flags = flags+48 end
  if looping then flags = flags+1 end
  Citizen.CreateThread(function()
    local id = anim_ids:gen()
    anims[id] = true
    for k,v in pairs(seq) do
      local dict = v[1]
      local name = v[2]
      local loops = v[3] or 1
      for i=1,loops do
        if anims[id] then
          local first = (k == 1 and i == 1)
          local last = (k == #seq and i == loops)
          RequestAnimDict(dict)
          local i = 0
          while not HasAnimDictLoaded(dict) and i < 1000 do -- max time, 10 seconds
            Citizen.Wait(10)
            RequestAnimDict(dict)
            i = i+1
          end
          if HasAnimDictLoaded(dict) and anims[id] then
            local inspeed = 8.0001
            local outspeed = -8.0001
            if not first then inspeed = 2.0001 end
            if not last then outspeed = 2.0001 end
            TaskPlayAnim(PlayerPedId(),dict,name,inspeed,outspeed,-1,flags,0,0,0,0)
          end
          Citizen.Wait(0)
          while GetEntityAnimCurrentTime(PlayerPedId(),dict,name) <= 0.95 and IsEntityPlayingAnim(PlayerPedId(),dict,name,3) and anims[id] do
            Citizen.Wait(0)
          end
        end
      end
    end
    anim_ids:free(id)
    anims[id] = nil
  end)
end

function tvRP.stopAnim(upper)
  anims = {}
  if upper then
    ClearPedSecondaryTask(PlayerPedId())
  return end
  ClearPedTasks(PlayerPedId())
end

local ragdoll = false
local function RagdollThread()
  Citizen.CreateThread(function()
    while true do
      Citizen.Wait(10)
      if not ragdoll then return end
      SetPedToRagdoll(PlayerPedId(), 1000, 1000, 0, 0, 0, 0)
    end
  end)
end

function tvRP.setRagdoll(flag)
  ragdoll = flag
  RagdollThread()
end

AddEventHandler("playerSpawned",function()
  TriggerServerEvent("vRPcli:playerSpawned")
end)

AddEventHandler("onPlayerDied",function(player,reason)
  TriggerServerEvent("vRPcli:playerDied")
end)

AddEventHandler("onPlayerKilled",function(player,killer,reason)
  TriggerServerEvent("vRPcli:playerDied")
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		if NetworkIsSessionStarted() then
			TriggerServerEvent("Queue:playerActivated")
		return end
	end
end)