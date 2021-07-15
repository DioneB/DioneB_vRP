local cfg = module("cfg/groups")
local groups = cfg.groups
local users = cfg.users

function vRP.getGroupTitle(group)
  local g = groups[group]
  if g and g._config and g._config.title then
    return g._config.title
  end
  return group
end

function vRP.getUserGroups(user_id)
  local data = vRP.getUserDataTable(user_id)
  if data then 
    if data.groups == nil then
      data.groups = {}
    end
    return data.groups
  end
  return {}
end

function vRP.getUserGroupByType(user_id,gtype)
  local user_groups = vRP.getUserGroups(user_id)
  for k,v in pairs(user_groups) do
    local kgroup = groups[k]
    if kgroup then
      if kgroup._config and kgroup._config.gtype and kgroup._config.gtype == gtype then
        return k
      end
    end
  end
  return ""
end

function vRP.getUsersByGroup(group)
  local users = {}
  for k,v in pairs(vRP.rusers) do
    if vRP.hasGroup(tonumber(k),group) then table.insert(users, tonumber(k)) end
  end
  return users
end

function vRP.getUsersByPermission(perm)
  local users = {}
  for k,v in pairs(vRP.rusers) do
    if vRP.hasPermission(tonumber(k),perm) then table.insert(users, tonumber(k)) end
  end
  return users
end

function vRP.hasGroup(user_id,group)
  local user_groups = vRP.getUserGroups(user_id)
  return (user_groups[group] ~= nil)
end


function vRP.addUserGroup(user_id,group)
  if vRP.hasGroup(user_id,group) then return end
  local user_groups = vRP.getUserGroups(user_id)
  local ngroup = groups[group]
  if not ngroup then return end
  local player = vRP.getUserSource(user_id)
  if player then
    if ngroup._config and ngroup._config.gtype ~= nil then 
      local _user_groups = {}
      for k,v in pairs(user_groups) do
        _user_groups[k] = v
      end
      for k,v in pairs(_user_groups) do
        local kgroup = groups[k]
        if kgroup and kgroup._config and ngroup._config and kgroup._config.gtype == ngroup._config.gtype then
          vRP.removeUserGroup(user_id,k)
        end
      end
    end
    user_groups[group] = true
    if ngroup._config and ngroup._config.onjoin and player ~= nil then
      ngroup._config.onjoin(player)
    end
    local gtype = nil
    if ngroup._config then
      gtype = ngroup._config.gtype 
    end
    TriggerEvent("vRP:playerJoinGroup", user_id, group, gtype)
  return end
  local sdata = json.decode(vRP.getUData(user_id, "vRP:datatable"))
  sdata.groups[group] = true
  vRP.setUData(user_id,"vRP:datatable",json.encode(sdata))
end

function vRP.removeUserGroup(user_id,group)
  local user_groups = vRP.getUserGroups(user_id)
  local groupdef = groups[group]
  if not groupdef then return end
  local player = vRP.getUserSource(user_id)
  if player then
    if groupdef._config and groupdef._config.onleave then
      groupdef._config.onleave(player)
    end
    local gtype = nil
    if groupdef._config then
      gtype = groupdef._config.gtype 
    end
    TriggerEvent("vRP:playerLeaveGroup", user_id, group, gtype)
    user_groups[group] = nil
  return end
  local sdata = json.decode(vRP.getUData(user_id, "vRP:datatable"))
  sdata.groups[group] = nil
  vRP.setUData(user_id,"vRP:datatable",json.encode(sdata))
end


local func_perms = {}
function vRP.registerPermissionFunction(name, callback)
  func_perms[name] = callback
end

vRP.registerPermissionFunction("not", function(user_id, parts)
  return not vRP.hasPermission(user_id, "!"..table.concat(parts, ".", 2))
end)

vRP.registerPermissionFunction("is", function(user_id, parts)
  local param = parts[2]
  if param == "inside" then
    local player = vRP.getUserSource(user_id)
    if not player then return end
    return vRPclient.isInside(player)
  end
  if param == "invehicle" then
    local player = vRP.getUserSource(user_id)
    if not player then return end
    return vRPclient.isInVehicle(player)
  end
end)
function vRP.hasPermission(user_id, perm)
  local user_groups = vRP.getUserGroups(user_id)
  local fchar = string.sub(perm,1,1)
  if fchar == "@" then -- special aptitude permission
    local _perm = string.sub(perm,2,string.len(perm))
    local parts = splitString(_perm,".")
    if #parts == 3 then -- decompose group.aptitude.operator
      local group = parts[1]
      local aptitude = parts[2]
      local op = parts[3]
      local alvl = math.floor(vRP.expToLevel(vRP.getExp(user_id,group,aptitude)))
      local fop = string.sub(op,1,1)
      if fop == "<" then  -- less (group.aptitude.<x)
        local lvl = parseInt(string.sub(op,2,string.len(op)))
        if alvl < lvl then return true end
      elseif fop == ">" then -- greater (group.aptitude.>x)
        local lvl = parseInt(string.sub(op,2,string.len(op)))
        if alvl > lvl then return true end
      else -- equal (group.aptitude.x)
        local lvl = parseInt(string.sub(op,1,string.len(op)))
        if alvl == lvl then return true end
      end
    end
  elseif fchar == "#" then -- special item permission
    local _perm = string.sub(perm,2,string.len(perm))
    local parts = splitString(_perm,".")
    if #parts == 2 then -- decompose item.operator
      local item = parts[1]
      local op = parts[2]

      local amount = vRP.getInventoryItemAmount(user_id, item)

      local fop = string.sub(op,1,1)
      if fop == "<" then  -- less (item.<x)
        local n = parseInt(string.sub(op,2,string.len(op)))
        if amount < n then return true end
      elseif fop == ">" then -- greater (item.>x)
        local n = parseInt(string.sub(op,2,string.len(op)))
        if amount > n then return true end
      else -- equal (item.x)
        local n = parseInt(string.sub(op,1,string.len(op)))
        if amount == n then return true end
      end
    end
  elseif fchar == "!" then -- special function permission
    local _perm = string.sub(perm,2,string.len(perm))
    local parts = splitString(_perm,".")
    if #parts > 0 then
      local fperm = func_perms[parts[1]]
      if fperm then
        return fperm(user_id, parts) or false
      else
        return false
      end
    end
  else -- regular plain permission
    -- precheck negative permission
    local nperm = "-"..perm
    for k,v in pairs(user_groups) do
      if v then -- prevent issues with deleted entry
        local group = groups[k]
        if group then
          for l,w in pairs(group) do -- for each group permission
            if l ~= "_config" and w == nperm then return false end
          end
        end
      end
    end
    -- check if the permission exists
    for k,v in pairs(user_groups) do
      if v then -- prevent issues with deleted entry
        local group = groups[k]
        if group then
          for l,w in pairs(group) do -- for each group permission
            if l ~= "_config" and w == perm then return true end
          end
        end
      end
    end
  end

  return false
end

function vRP.hasPermissions(user_id, perms)
  for k,v in pairs(perms) do
    if not vRP.hasPermission(user_id, v) then
      return false
    end
  end
  return true
end

AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn)
  if first_spawn then
    local user = users[user_id]
    if user then
      for k,v in pairs(user) do
        vRP.addUserGroup(user_id,v)
      end
    end
    vRP.addUserGroup(user_id,"user")
  end
  local user_groups = vRP.getUserGroups(user_id)
  for k,v in pairs(user_groups) do
    local group = groups[k]
    if group and group._config and group._config.onspawn then
      group._config.onspawn(source)
    end
  end
end)
