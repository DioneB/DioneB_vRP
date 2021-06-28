
local cfg = {}

-- mysql credentials
cfg.db = {
  driver = "ghmattimysql",
  host = "127.0.0.1",
  database = "dioneb_vrp",
  user = "root",
  password = ""
}

cfg.debug = false

-- time to wait before displaying async return warning (seconds)
cfg.debug_async_time = 2

return cfg
