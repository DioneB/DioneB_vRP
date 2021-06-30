local cfg = module("cfg/aptitudes")
-- exp notes:
-- levels are defined by the amount of xp
-- with a step of 5: 5|15|30|50|75
-- total exp for a specific level, exp = step*lvl*(lvl+1)/2
-- level for a specific exp amount, lvl = (sqrt(1+8*exp/step)-1)/2

local exp_step = 5
local gaptitudes = {}
function vRP.defAptitudeGroup(group, title)
  gaptitudes[group] = {_title = title}
end

-- max_exp: -1 => infinite
function vRP.defAptitude(group, aptitude, title, init_exp, max_exp)
  local vgroup = gaptitudes[group]
  if vgroup ~= nil then
    vgroup[aptitude] = {title,init_exp,max_exp}
  end
end

function vRP.getAptitudeDefinition(group, aptitude)
  local vgroup = gaptitudes[group]
  if vgroup ~= nil and aptitude ~= "_title" then
    return vgroup[aptitude]   
  end
  return nil
end

function vRP.getAptitudeGroupTitle(group)
  if gaptitudes[group] ~= nil then
    return gaptitudes[group]._title
  end
  return ""
end

function vRP.getUserAptitudes(user_id)
  local data = vRP.getUserDataTable(user_id)
  if data == nil then return nil end
  if data.gaptitudes == nil then
    data.gaptitudes = {}
  end
  for k,v in pairs(gaptitudes) do
    if data.gaptitudes[k] == nil then
      data.gaptitudes[k] = {}
    end
    local group = data.gaptitudes[k]
    for l,w in pairs(v) do
      if l ~= "_title" and group[l] == nil then 
        group[l] = w[2]
      end
    end
  end
  return data.gaptitudes
end

function vRP.varyExp(user_id, group, aptitude, amount)
  local def = vRP.getAptitudeDefinition(group, aptitude)
  local uaptitudes = vRP.getUserAptitudes(user_id)
  if def ~= nil and uaptitudes ~= nil then
    local exp = uaptitudes[group][aptitude]
    local level = math.floor(vRP.expToLevel(exp))
    exp = exp+amount
    if exp < 0 then exp = 0 
    elseif def[3] >= 0 and exp > def[3] then exp = def[3] end
    uaptitudes[group][aptitude] = exp
    local player = vRP.getUserSource(user_id)
    if player ~= nil then
      local group_title = vRP.getAptitudeGroupTitle(group)
      local aptitude_title = def[1]
      if amount < 0 then
        -- vRPclient._notify(player,lang.aptitude.lose_exp({group_title,aptitude_title,-1*amount}))
      elseif amount > 0 then
        -- vRPclient._notify(player,lang.aptitude.earn_exp({group_title,aptitude_title,amount}))
      end

      --- level up/down
      local new_level = math.floor(vRP.expToLevel(exp))
      local diff = new_level-level
      if diff < 0 then
        -- vRPclient._notify(player,lang.aptitude.level_down({group_title,aptitude_title,new_level}))
      elseif diff > 0 then
        -- vRPclient._notify(player,lang.aptitude.level_up({group_title,aptitude_title,new_level}))
      end
    end
  end
end

function vRP.levelUp(user_id, group, aptitude)
  local exp = vRP.getExp(user_id,group,aptitude)
  local next_level = math.floor(vRP.expToLevel(exp))+1
  local next_exp = vRP.levelToExp(next_level)
  local add_exp = next_exp-exp
  vRP.varyExp(user_id, group, aptitude, add_exp)
end

function vRP.levelDown(user_id, group, aptitude)
  local exp = vRP.getExp(user_id,group,aptitude)
  local prev_level = math.floor(vRP.expToLevel(exp))-1
  local prev_exp = vRP.levelToExp(prev_level)
  local add_exp = prev_exp-exp
  vRP.varyExp(user_id, group, aptitude, add_exp)
end

function vRP.getExp(user_id, group, aptitude)
  local uaptitudes = vRP.getUserAptitudes(user_id)
  if not uaptitudes then return 0 end 
  local vgroup = uaptitudes[group]
  if not vgroup then return end
  return vgroup[aptitude] or 0
end

function vRP.setExp(user_id, group, aptitude, amount)
  local exp = vRP.getExp(user_id, group, aptitude)
  vRP.varyExp(user_id, group, aptitude, amount-exp)
end

function vRP.expToLevel(exp)
  return (math.sqrt(1+8*exp/exp_step)-1)/2
end

function vRP.levelToExp(lvl)
  return math.floor((exp_step*lvl*(lvl+1))/2)
end

for k,v in pairs(cfg.gaptitudes) do
  vRP.defAptitudeGroup(k,v._title or "")
  for l,w in pairs(v) do
    if l ~= "_title" then
      vRP.defAptitude(k,l,w[1],w[2],w[3])
    end
  end
end

