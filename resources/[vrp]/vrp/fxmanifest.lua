--[[ - Dione B. ~ A.K.A: @StrykeONE ]] --

resource_type 'gametype' { name = 'Roleplay' }
fx_version 'bodacious'
game 'gta5'

ui_page "gui/index.html"

author "https://github.com/ImagicTheCat"

-- server scripts
server_scripts{ 
  "lib/utils.lua",
  "base.lua",
  "queue.lua",
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
  "gui/index.html",
  "gui/design.css",
  "gui/main.js",
  "gui/Menu.js",
  "gui/ProgressBar.js",
  "gui/WPrompt.js",
  "gui/RequestManager.js",
  "gui/AnnounceManager.js",
  "gui/Div.js",
  "gui/dynamic_classes.js",
  "gui/AudioEngine.js",
  "gui/lib/libopus.wasm.js",
}
