local cfg = {}

cfg.items = {
  water = {label = "Agua", desc = "Desc.", prop = '', weight = 0.01, decay = false},
  bread = {label = "Pao", desc = "Desc.", prop = '', weight = 0.01, decay = false},
}

cfg.weapons {
  pistol = {type = 'pistol', label = "Pistola", desc = "Pistola 9MM.", prop = '', weight = 1.0, decay = false},
  smg = {type = 'smg', label = "Submachine", desc = "", prop = '', weight = 1.0, decay = false},
  assaultrifle = {type = 'rifle', label = "Rifle de Assalto", desc = "Rifle Calibre 7.62mm", prop = '', weight = 1.0, decay = false},
  pumpshotgun = {type = 'shotgun', label = "Pump Shotgun", desc = "", prop = '', weight = 1.0, decay = false},
}

return cfg
