local Tools = module("lib/Tools")

local prompts = {}

-- prompt textual (and multiline) information from player
-- return entered text
function vRP.prompt(source,title,default_text)
  local r = async()
  prompts[source] = r

  vRPclient._prompt(source, title,default_text)

  return r:wait()
end

-- REQUEST

local request_ids = Tools.newIDGenerator()
local requests = {}

-- ask something to a player with a limited amount of time to answer (yes|no request)
-- time: request duration in seconds
-- return true (yes) or false (no)
function vRP.request(source,text,time)
  local r = async()

  local id = request_ids:gen()
  local request = {source = source, cb_ok = r, done = false}
  requests[id] = request

  vRPclient.request(source,id,text,time) -- send request to client

  -- end request with a timeout if not already ended
  SetTimeout(time*1000,function()
    if not request.done then
      request.cb_ok(false) -- negative response
      request_ids:free(id)
      requests[id] = nil
    end
  end)

  return r:wait()
end

-- receive prompt result
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

-- receive request result
function tvRP.requestResult(id,ok)
  local request = requests[id]
  if request and request.source == source then -- end request
    request.done = true -- set done, the timeout will not call the callback a second time
    request.cb_ok(not not ok) -- callback
    request_ids:free(id)
    requests[id] = nil
  end
end