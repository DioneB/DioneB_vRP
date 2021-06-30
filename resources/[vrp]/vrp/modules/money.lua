vRP.prepare("vRP/money_tables", [[
CREATE TABLE IF NOT EXISTS vrp_user_moneys(
  user_id INTEGER,
  wallet INTEGER,
  bank INTEGER,
  CONSTRAINT pk_user_moneys PRIMARY KEY(user_id),
  CONSTRAINT fk_user_moneys_users FOREIGN KEY(user_id) REFERENCES vrp_users(id) ON DELETE CASCADE
);
]])

vRP.prepare("vRP/money_init_user","INSERT IGNORE INTO vrp_user_moneys(user_id,wallet,bank) VALUES(@user_id,@wallet,@bank)")
vRP.prepare("vRP/get_money","SELECT wallet,bank FROM vrp_user_moneys WHERE user_id = @user_id")
vRP.prepare("vRP/set_money","UPDATE vrp_user_moneys SET wallet = @wallet, bank = @bank WHERE user_id = @user_id")

async(function()
  vRP.execute("vRP/money_tables")
end)

local cfg = module("cfg/money")
function vRP.getMoney(user_id)
  local tmp = vRP.getUserTmpTable(user_id)
  if tmp then
    return tmp.wallet or 0
  end
  return 0
end

function vRP.setMoney(user_id,value)
  local tmp = vRP.getUserTmpTable(user_id)
  if not tmp then return end
  tmp.wallet = value
end

function vRP.tryPayment(user_id,amount)
  local money = vRP.getMoney(user_id)
  if amount >= 0 and money >= amount then
    vRP.setMoney(user_id,money-amount)
    return true
  end
  return false
end

function vRP.giveMoney(user_id,amount)
  if amount <= 0 then return end
  local money = vRP.getMoney(user_id)
  vRP.setMoney(user_id,money+amount)
end

function vRP.getBankMoney(user_id)
  local tmp = vRP.getUserTmpTable(user_id)
  if tmp then return tmp.bank or 0 end
  return 0
end

function vRP.setBankMoney(user_id,value)
  local tmp = vRP.getUserTmpTable(user_id)
  if not tmp then return end
  tmp.bank = value
end

function vRP.giveBankMoney(user_id,amount)
  if amount <= 0 then return end
  local money = vRP.getBankMoney(user_id)
  vRP.setBankMoney(user_id,money+amount)
end

function vRP.tryWithdraw(user_id,amount)
  local money = vRP.getBankMoney(user_id)
  if amount >= 0 and money >= amount then
    vRP.setBankMoney(user_id,money-amount)
    vRP.giveMoney(user_id,amount)
    return true
  end
  return false
end

function vRP.tryDeposit(user_id,amount)
  if amount >= 0 and vRP.tryPayment(user_id,amount) then
    vRP.giveBankMoney(user_id,amount)
    return true
  end
  return false
end

function vRP.tryFullPayment(user_id,amount)
  local money = vRP.getMoney(user_id)
  if money >= amount then
    return vRP.tryPayment(user_id, amount)
  end
  if vRP.tryWithdraw(user_id, amount-money) then
    return vRP.tryPayment(user_id, amount)
  end
  return false
end

AddEventHandler("vRP:playerJoin",function(user_id,source,name,last_login)
  vRP.execute("vRP/money_init_user", {user_id = user_id, wallet = cfg.open_wallet, bank = cfg.open_bank})
  local tmp = vRP.getUserTmpTable(user_id)
  if not tmp then return end
  local rows = vRP.query("vRP/get_money", {user_id = user_id})
  if #rows <= 0 then return end
  tmp.bank = rows[1].bank
  tmp.wallet = rows[1].wallet
end)

AddEventHandler("vRP:playerLeave",function(user_id,source)
  local tmp = vRP.getUserTmpTable(user_id)
  if tmp and tmp.wallet and tmp.bank then
    vRP.execute("vRP/set_money", {user_id = user_id, wallet = tmp.wallet, bank = tmp.bank})
  end
end)

AddEventHandler("vRP:save", function()
  for k,v in pairs(vRP.user_tmp_tables) do
    if v.wallet and v.bank then
      vRP.execute("vRP/set_money", {user_id = k, wallet = v.wallet, bank = v.bank})
    end
  end
end)