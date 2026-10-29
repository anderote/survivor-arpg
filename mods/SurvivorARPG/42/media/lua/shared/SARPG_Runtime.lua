local C=require 'SARPG_Core'
local M={pendingSync=false,errors={},ticks=0}
function M.Multiplayer() return isMultiplayer and isMultiplayer() end
function M.Authority() return not (isClient and isClient()) end
function M.Enabled() return true end
function M.Ready(p)
 return not M.Multiplayer() or M.Authority() or require('SARPG_Network').Ready(p)
end
function M.RPG(p)
 if M.Multiplayer() and not M.Authority() then return require('SARPG_Network').RPG(p) end
 return p:getModData().RPGSkillTree
end
function M.Toggle(p,key,value)
 if key~='autoAmmo' and key~='autoBandage' then return false end
 if M.Multiplayer() and not M.Authority() then return require('SARPG_Network').Send(p,'Toggle',{key=key,value=value}) end
 M.State(p)[key]=value;return true
end
function M.State(p)
 if M.Multiplayer() then
  if not M.Authority() then return require('SARPG_Network').State(p) end
  return require('SARPG_Server').State(p)
 end
 local md=p:getModData();if not md[C.KEY] then md[C.KEY]=C.New() end
 local s=md[C.KEY];local rpg=md.RPGSkillTree
 if rpg then C.Observe(s,rpg.level,(rpg.prestige or {}).rank) end
 return s
end
local function guarded(name,fn)
 if M.errors[name] then return end
 local ok,err=pcall(fn);if not ok then M.errors[name]=tostring(err);print('[Survivor ARPG] '..name..' disabled: '..tostring(err)) end
end
local function hour() return getGameTime():getWorldAgeHours() end
function M.Sync()
 if RPG_ClientCommands and RPG_ClientCommands.RequestSync then return RPG_ClientCommands.RequestSync() end
 return false
end
function M.Buy(p,id)
 if M.Multiplayer() and not M.Authority() then return require('SARPG_Network').Send(p,'Buy',{id=id}) end
 local s=M.State(p);if not C.Buy(s,id,p:getModData().RPGSkillTree) then return false end
 -- The carry extension is folded into the existing factor calculation.
 M.pendingSync=true;return true
end
function M.Wind(p)
 if M.Multiplayer() and not M.Authority() then return require('SARPG_Network').Send(p,'Wind',{}) end
 if not M.Enabled() or p:isDead() then return false end
 local s=M.State(p);local n=C.Rank(s,'secondwind');local t=hour()
 if n<1 or t<(s.windReady or 0) then return false end
 local stats=p:getStats();local e=CharacterStat.ENDURANCE
 local cur=stats:get(e);local hi=e:getMaximumValue()
 if cur>=hi then return false end
 local amount=(hi-e:getMinimumValue())*.1*n
 if M.Multiplayer() then require('SARPG_Server').WindEffect(p,amount)
 else stats:set(e,math.min(hi,cur+amount)) end
 s.windReady=t+5;return true
end
local function items(container,out,depth)
 out=out or {};depth=depth or 0;if depth>5 then return out end
 local list=container:getItems()
 for i=0,list:size()-1 do
  local item=list:get(i);out[#out+1]=item
  if instanceof(item,'InventoryContainer') then items(item:getInventory(),out,depth+1) end
 end
 return out
end
function M.AmmoTypes(p)
 local result={}
 local function add(key)
  if not key or key=='' then return end
  local def=getScriptManager():FindItem(key)
  if def then result[def:getFullName()]=true end
 end
 local gw
 if require('PRPGE_Compat').Active('SWMG') then gw=require 'WeaponSystems/Utils/Ammo' end
 for _,item in ipairs(items(p:getInventory())) do
  if instanceof(item,'HandWeapon') and item:isRanged() then
   -- B42.21 AmmoType is a registry object, not an inventory type string.
   local ammo=item:getAmmoType()
   if ammo then add(type(ammo)=='string' and ammo or ammo:getItemKey()) end
   -- Read-only Gunworks family API includes caliber conversions and variants.
   -- Never call AmmoProfileSetter or change the firearm's active ammunition.
   if gw then
    local family=gw.GetFamilyForItem(item)
    if family then for _,key in ipairs(gw.GetOrderedBulletTypesForFamily(p,family) or {}) do add(key) end end
   end
  end
 end
 return result
end
local function idle(p)
 local q=ISTimedActionQueue.getTimedActionQueue(p)
 return not p:isDead() and not p:isRunning() and not p:isSprinting() and not p:isAiming()
  and not p:isAsleep() and not p:isMoving() and q and #q.queue==0
end
local function pickup(p,s)
 local rank=C.Rank(s,'magnet');if rank<1 or not s.autoAmmo or not idle(p) then return end
 local sq=p:getSquare();if not sq then return end
 local types=M.AmmoTypes(p);local bodies=sq:getDeadBodys();local queued=0;local reserved=0
 local dest=p:getInventory()
 for i=0,bodies:size()-1 do
  local src=bodies:get(i):getContainer();local list=src:getItems()
  for j=0,list:size()-1 do
   local item=list:get(j)
   if types[item:getFullType()] and dest:hasRoomFor(p,item)
    and dest:getCapacityWeight()+reserved+item:getActualWeight()<=p:getMaxWeight() then
    ISTimedActionQueue.add(ISInventoryTransferAction:new(p,item,src,dest,10))
    reserved=reserved+item:getActualWeight();queued=queued+1
    if queued>=rank then return end
   end
  end
 end
end
local cleanBandages={['Base.Bandage']=true,['Base.AlcoholBandage']=true,['Base.RippedSheets']=true,['Base.AlcoholRippedSheets']=true}
local function bandage(p,s)
 local rank=C.Rank(s,'medic');if rank<1 or not s.autoBandage or not idle(p) then return end
 local t=getTimestampMs();if t<(M.bandageReady or 0) then return end
 local found
 -- Main inventory only: don't teleport supplies out of a closed bag.
 local inv=p:getInventory():getItems()
 for i=0,inv:size()-1 do local item=inv:get(i);if cleanBandages[item:getFullType()] then found=item;break end end
 if not found then return end
 local parts=p:getBodyDamage():getBodyParts()
 for i=0,parts:size()-1 do
  local part=parts:get(i)
  if part:bleeding() and not part:bandaged() then
   ISTimedActionQueue.add(ISApplyBandage:new(p,p,found,part,true))
   M.bandageReady=t+60000/rank;return
  end
 end
end
function M.OnDeath(z)
 if not M.Authority() then return end
 guarded('ammo drops',function()
  if require('PRPGE_NPCs').IsNPC(z) then return end
  local p=z:getAttackedBy();if not p or p:isDead() then return end
  if M.Multiplayer() then if not instanceof(p,'IsoPlayer') then return end
  elseif p~=getPlayer() then return end
  local md=z:getModData();if md.SARPGDrop then return end;md.SARPGDrop=true
  local s=M.State(p);local types=M.AmmoTypes(p);local pool={}
  for k in pairs(types) do pool[#pool+1]=k end;table.sort(pool)
  local inv=z:getInventory()
  if #pool>0 and ZombRand(100)<12+2*C.Rank(s,'luck') then
   local ammo=pool[ZombRand(#pool)+1];local count=3+ZombRand(6)+C.Rank(s,'luck')
   for _=1,count do inv:AddItem(ammo) end
  end
  -- Supply boost uses ordinary base-game firearms, avoiding Gunworks build APIs.
  if ZombRand(100)<2 then
   local gun=ZombRand(2)==0 and 'Base.Pistol' or 'Base.Shotgun'
   if getScriptManager():FindItem(gun) then inv:AddItem(gun) end
  end
 end)
end
function M.Tick()
 if isServer and isServer() then return end
 M.ticks=M.ticks+1;if M.ticks%30~=0 then return end
 local p=getPlayer();if not p or p:isDead() then return end
 if M.Multiplayer() then require('SARPG_Network').Poll(p);if not M.Ready(p) then return end end
 local s=M.State(p)
 if M.player~=p then M.player=p;M.lastHour=hour();M.lastTemp=nil;M.bandageReady=0;M.pendingSync=true end
 if M.pendingSync then guarded('PDA sync',function() if M.Sync() then M.pendingSync=false end end) end
 guarded('healing',function()
  local t=hour();local dt=math.max(0,math.min(.05,t-(M.lastHour or t)));M.lastHour=t
  if C.Rank(s,'vitality')>0 then p:getBodyDamage():AddGeneralHealth(dt*C.Rank(s,'vitality')) end
 end)
 guarded('temperature',function()
  local rank=C.Rank(s,'thermal');local stats=p:getStats();local e=CharacterStat.TEMPERATURE
  local t=stats:get(e);local prev=M.lastTemp
  if rank>0 and prev and ((t>37 and t>prev) or (t<37 and t<prev)) then
   t=prev+(t-prev)*(1-.03*rank);stats:set(e,t)
  end
  M.lastTemp=t
 end)
 guarded('auto bandage',function() bandage(p,s) end)
 guarded('ammo pickup',function() pickup(p,s) end)
end
function M.Install()
 if M.installed then return end;M.installed=true
 if not (isServer and isServer()) then
 require 'TimedActions/ISTimedActionQueue'
 require 'TimedActions/ISInventoryTransferAction'
 require 'TimedActions/ISApplyBandage'
 end
 if not M.Authority() then return end
 guarded('carry integration',function()
  local calc=require 'RPG_Server_Calculate';local old=calc.CalculateAndStoreFactors
  calc.CalculateAndStoreFactors=function(p,...)
   local result=old(p,...);local st=p:getModData().RPGSkillTree
   if st and st.factors then
    local s=M.State(p)
    st.factors.carryWeightMul=(st.factors.carryWeightMul or 1)+.05*C.Rank(s,'capacity')
    st.factors.staminaRegen=(st.factors.staminaRegen or 1)+.05*C.Rank(s,'endurance')
   end
   return result
  end
 end)
 guarded('bite ward',function()
  local wounds=require 'PRPGE_DangerWounds';local rules=require 'PRPGE_DangerRules'
  local check,values=wounds.Check,rules.Values;local checking
  rules.Values=function(...)
   local v=values(...)
   if checking then v=C.Copy(v);v.bite=v.bite*(1-.1*C.Rank(M.State(checking),'ward')) end
   return v
  end
  wounds.Check=function(p)
   checking=p;local ok,result=pcall(check,p);checking=nil
   if not ok then error(result) end;return result
  end
 end)
 print('[Survivor ARPG] 0.2.0 authority installed; PDA/Respawn integration')
end
function M.OnHit(p,weapon,target,damage)
 if not M.Authority() or not p or not weapon or not target then return end
 if M.Multiplayer() then if not instanceof(p,'IsoPlayer') then return end
 elseif p~=getPlayer() then return end
 guarded('combat attributes',function()
  if not target:isZombie() or require('PRPGE_NPCs').IsNPC(target) or target:isDead() then return end
  local n=C.Rank(M.State(p),weapon:isRanged() and 'firearms' or 'strength')
  local extra=math.max(0,tonumber(damage) or 0)*.03*n
  local hp=target:getHealth();if extra<=0 or hp<=0 then return end
  if extra>=hp then target:Kill(weapon,p) else target:setHealth(hp-extra) end
 end)
end
Events.OnWeaponHitXp.Add(M.OnHit)
Events.OnGameStart.Add(M.Install)
Events.OnTick.Add(M.Tick)
Events.OnZombieDead.Add(M.OnDeath)
return M
