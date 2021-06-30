local htmlEntities = module("lib/htmlEntities")
local cfg = module("cfg/identity")
local sanitizes = module("cfg/sanitizes")

vRP.prepare("vRP/identity_tables", [[
CREATE TABLE IF NOT EXISTS vrp_user_identities(
  user_id INTEGER,
  registration VARCHAR(20),
  phone VARCHAR(20),
  firstname VARCHAR(50),
  name VARCHAR(50),
  age INTEGER,
  CONSTRAINT pk_user_identities PRIMARY KEY(user_id),
  CONSTRAINT fk_user_identities_users FOREIGN KEY(user_id) REFERENCES vrp_users(id) ON DELETE CASCADE,
  INDEX(registration),
  INDEX(phone)
);
]])

vRP.prepare("vRP/get_user_identity","SELECT * FROM vrp_user_identities WHERE user_id = @user_id")
vRP.prepare("vRP/init_user_identity","INSERT IGNORE INTO vrp_user_identities(user_id,registration,phone,firstname,name,age) VALUES(@user_id,@registration,@phone,@firstname,@name,@age)")
vRP.prepare("vRP/update_user_identity","UPDATE vrp_user_identities SET firstname = @firstname, name = @name, age = @age, registration = @registration, phone = @phone WHERE user_id = @user_id")
vRP.prepare("vRP/get_userbyreg","SELECT user_id FROM vrp_user_identities WHERE registration = @registration")
vRP.prepare("vRP/get_userbyphone","SELECT user_id FROM vrp_user_identities WHERE phone = @phone")

async(function()
  vRP.execute("vRP/identity_tables")
end)

function vRP.getUserIdentity(user_id, cbr)
  local rows = vRP.query("vRP/get_user_identity", {user_id = user_id})
  return rows[1]
end

function vRP.getUserByRegistration(registration, cbr)
  local rows = vRP.query("vRP/get_userbyreg", {registration = registration or ""})
  if #rows > 0 then return rows[1].user_id end
end

function vRP.getUserByPhone(phone, cbr)
  local rows = vRP.query("vRP/get_userbyphone", {phone = phone or ""})
  if #rows > 0 then return rows[1].user_id end
end

function vRP.generateStringNumber(format)
  local abyte = string.byte("A")
  local zbyte = string.byte("0")
  local number = ""
  for i=1,#format do
    local char = string.sub(format, i,i)
    if char == "D" then number = number..string.char(zbyte+math.random(0,9))
    elseif char == "L" then number = number..string.char(abyte+math.random(0,25))
    else number = number..char end
  end
  return number
end

function vRP.generateRegistrationNumber(cbr)
  local user_id = nil
  local registration = ""
  repeat
    registration = vRP.generateStringNumber("DDDLLL")
    user_id = vRP.getUserByRegistration(registration)
  until not user_id
  return registration
end

function vRP.generatePhoneNumber(cbr)
  local user_id = nil
  local phone = ""
  repeat
    phone = vRP.generateStringNumber(cfg.phone_format)
    user_id = vRP.getUserByPhone(phone)
  until not user_id
  return phone
end

AddEventHandler("vRP:playerJoin",function(user_id,source,name,last_login)
  if vRP.getUserIdentity(user_id) then return end
  local registration = vRP.generateRegistrationNumber()
  local phone = vRP.generatePhoneNumber()
  vRP.execute("vRP/init_user_identity", {
    user_id = user_id,
    registration = registration,
    phone = phone,
    firstname = 'Sem',
    name = 'Nome',
    age = math.random(25,40)
  })
end)

AddEventHandler("vRP:playerSpawn",function(user_id, source, first_spawn)
  local identity = vRP.getUserIdentity(user_id)
  if not identity then return end
  vRPclient._setRegistrationNumber(source,identity.registration or "000AAA")
end)