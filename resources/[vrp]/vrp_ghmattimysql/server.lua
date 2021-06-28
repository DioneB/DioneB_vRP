local Proxy = module("vrp", "lib/Proxy")
local vRP = Proxy.getInterface("vRP")

local API = exports["ghmattimysql"]
queries = {}
local function blob2string(blob)
  local data = {}
  for i, byte in ipairs(blob) do data[i] = string.char(byte) end
  return table.concat(data)
end

local function on_init(cfg)
  return API ~= nil
end

local function on_prepare(name, query)
  queries[name] = query
end

local function on_query(name, params, mode)
  local query = queries[name]
  local _params = {_ = true} -- force as map
  for k,v in pairs(params) do _params[k] = v end

  local r = async()
  if mode == "execute" then
    API:execute(query, _params, function(data)
      r(data.affectedRows or 0)
    end)
  elseif mode == "scalar" then
    API:scalar(query, _params, function(scalar)
      r(scalar)
    end)
  else
    API:execute(query, _params, function(rows)
      if query:find(";.-SELECT.+LAST_INSERT_ID%(%)") then rows = rows[#rows] end
      for _,row in pairs(rows) do
        for k,v in pairs(row) do
          if type(v) == "table" then
            row[k] = blob2string(v)
          end
        end
      end
      r(rows, #rows)
    end)
  end

  return r:wait()
end

async(function()
  vRP.registerDBDriver("ghmattimysql",on_init,on_prepare,on_query)
end)