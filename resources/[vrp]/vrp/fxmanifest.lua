--[[ - Dione B. ~ A.K.A: @StrykeONE ]] --

resource_type 'gametype' { name = 'Roleplay' }
fx_version 'bodacious'
game 'gta5'

author "https://github.com/ImagicTheCat"

-- server scripts
server_scripts{ 
  "lib/utils.lua",
  "base.lua",
  "queue.lua",
  "modules/admin.lua",
  "modules/gui.lua",
  "modules/group.lua",
  "modules/survival.lua",
  "modules/player_state.lua",
  "modules/money.lua",
  "modules/inventory.lua",
  "modules/identity.lua",
  "modules/aptitude.lua",
  "modules/basic_items.lua",
  "modules/cloakroom.lua",
} 

-- client scripts
client_scripts{
  "lib/utils.lua",
  "client/base.lua",
  "client/iplloader.lua",
  "client/gui.lua",
  "client/player_state.lua",
  "client/survival.lua",
  "client/identity.lua",
  "client/basic_garage.lua",
  "client/admin.lua",
  "client/police.lua",
}

-- client files
files{
  "lib/Tunnel.lua",
  "lib/Proxy.lua",
  "lib/Debug.lua",
  "lib/Luaseq.lua",
  "lib/Tools.lua",
  "cfg/client.lua",
}
