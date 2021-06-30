local Tools = module("lib/Tools")

local prompts = {}

function vRP.prompt(source,title,default_text)
  local r = async()
  prompts[source] = r
  vRPclient._prompt(source, title,default_text)
  return r:wait()
end

local request_ids = Tools.newIDGenerator()
local requests = {}
function vRP.request(source,text,time)
  local r = async()
  local id = request_ids:gen()
  local request = {source = source, cb_ok = r, done = false}
  requests[id] = request
  vRPclient.request(source,id,text,time)
  SetTimeout(time*1000,function()
    if not request.done then
      request.cb_ok(false)
      request_ids:free(id)
      requests[id] = nil
    end
  end)
  return r:wait()
end

function tvRP.promptResult(text)
  if text == nil then
    text = ""
  end
  local prompt = prompts[source]
  if prompt ~= nil then
    prompts[source] = nil
    prompt(text)
  end
end

function tvRP.requestResult(id,ok)
  local request = requests[id]
  if request and request.source == source then 
    request.done = true
    request.cb_ok(not not ok)
    request_ids:free(id)
    requests[id] = nil
  end
end