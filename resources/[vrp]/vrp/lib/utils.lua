SERVER = IsDuplicityVersion()
CLIENT = not SERVER

function table.maxn(t)
  local max = 0
  for k,v in pairs(t) do
    local n = tonumber(k)
    if n and n > max then max = n end
  end
  return max
end


local modules = {}
function module(rsc, path)
  if path == nil then
    path = rsc
    rsc = "vrp"
  end
  local key = rsc..path
  local module = modules[key]
  if module then return module end
  local code = LoadResourceFile(rsc, path..".lua")
  if not code then
    print("resource file "..rsc.."/"..path..".lua not found")
  return end
  local f,err = load(code, rsc.."/"..path..".lua")
  if not f then
    print("error parsing module "..rsc.."/"..path..":"..debug.traceback(err))
  return end
  local ok, res = xpcall(f, debug.traceback)
  if not ok then
    print("error loading module "..rsc.."/"..path..":"..res)
  return end
  modules[key] = res
  return res
end

local Debug = module("vrp", "lib/Debug")
local function wait(self)
  if Debug.active then -- debug
    SetTimeout(math.floor(Debug.async_time)*1000, function()
      if not self.r then
        Debug.log("WARNING: in resource \""..GetCurrentResourceName().."\" async return take more than "..Debug.async_time.."s "..self.traceback, true)
      end
    end)
  end
  local rets = Citizen.Await(self.p)
  if not rets then rets = self.r end
  return table.unpack(rets, 1, table.maxn(rets))
end

local function areturn(self, ...)
  self.r = {...}
  self.p:resolve(self.r)
end

function async(func)
  if func then
    Citizen.CreateThreadNow(func)
  end
  if Debug.active then -- debug
    return setmetatable({ wait = wait, p = promise.new(), traceback = debug.traceback("",2) }, { __call = areturn })
  end
  return setmetatable({ wait = wait, p = promise.new() }, { __call = areturn })
end

function parseInt(v)
  local n = tonumber(v)
  if n == nil then return 0 end
  return math.floor(n)
end

function parseDouble(v)
  local n = tonumber(v)
  if n == nil then n = 0 end
  return n
end

function parseFloat(v)
  return parseDouble(v)
end

local sanitize_tmp = {}
function sanitizeString(str, strchars, allow_policy)
  local r = ""
  local chars = sanitize_tmp[strchars]
  if chars == nil then
    chars = {}
    local size = string.len(strchars)
    for i=1,size do
      local char = string.sub(strchars,i,i)
      chars[char] = true
    end
    sanitize_tmp[strchars] = chars
  end
  size = string.len(str)
  for i=1,size do
    local char = string.sub(str,i,i)
    if (allow_policy and chars[char]) or (not allow_policy and not chars[char]) then
      r = r..char
    end
  end
  return r
end

function splitString(str, sep)
  if sep == nil then sep = "%s" end
  local t={}
  local i=1
  for str in string.gmatch(str, "([^"..sep.."]+)") do
    t[i] = str
    i = i + 1
  end
  return t
end

function joinStrings(list, sep)
  if sep == nil then sep = "" end
  local str = ""
  local count = 0
  local size = #list
  for k,v in pairs(list) do
    count = count+1
    str = str..v
    if count < size then str = str..sep end
  end
  return str
end