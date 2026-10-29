-- Server-only authority. No client-supplied levels, prices, ranks or snapshots.
if not (isServer and isServer()) then return {} end
local C=require 'SARPG_Core'
local R=require 'SARPG_Runtime'
local PDA=require 'RPG_Server_State'
local Commands=require 'RPG_Server_Commands'
local Broadcast=require 'RPG_Server_Broadcast'
local S={bound=setmetatable({},{__mode='k'}),sessions=setmetatable({},{__mode='k'})}
local ensure=PDA.Ensure
local function records() return ModData.getOrCreate('SurvivorARPG_Server_v1') end
local function record(p)
 local name=p:getUsername();if type(name)~='string' or name=='' then return nil end
 local all=records();local rec=all[name]
 if not rec then rec={custom=C.New(),revision=0,generation=0};all[name]=rec end
 return rec
end
function S.Attach(p)
 local rec=record(p);if not rec then return nil end
 local bound=S.bound[p]
 if not bound then
  -- Only this server's saved allowlist is restored on another body/reconnect.
  -- Do not import an SP/client ARPG balance into a new multiplayer identity.
  if rec.snapshot then C.Restore(p:getModData(),rec.snapshot) end
  rec.generation=(rec.generation or 0)+1
  bound={record=rec,rpg=p:getModData().RPGSkillTree};S.bound[p]=bound
  S.sessions[p]={generation=rec.generation,lastRequest=-10000,lastPoll=-10000,effect=0}
 end
 -- Rebind owned tables if incoming player modData replaced the outer table.
 p:getModData()[C.KEY]=rec.custom
 if bound.rpg then p:getModData().RPGSkillTree=bound.rpg end
 return rec,bound
end
PDA.Ensure=function(p)
 local rec,bound=S.Attach(p);local rpg=ensure(p)
 if bound then bound.rpg=rpg end
 return rpg
end
function S.State(p)
 local rec=S.Attach(p);local rpg=PDA.Ensure(p)
 if not rec then error('No authenticated username for ARPG player') end
 local earned=rec.custom.earned
 C.Observe(rec.custom,rpg.level,(rpg.prestige or {}).rank)
 if earned~=rec.custom.earned then rec.revision=rec.revision+1 end
 return rec.custom
end
function S.Save(p)
 local rec=S.Attach(p);if not rec then return end
 local state=S.State(p)
 rec.snapshot=C.Snapshot(PDA.Ensure(p),state)
end
function S.Push(p)
 local state=S.State(p);S.Save(p)
 local rec=record(p);local session=S.sessions[p]
 sendServerCommand(p,'SurvivorARPG','State',{state=C.Copy(state),
  rpg=C.Snapshot(PDA.Ensure(p),state).rpg,revision=rec.revision,
  generation=session.generation,onlineID=p:getOnlineID(),errors=C.Copy(R.errors)})
end
function S.WindEffect(p,amount)
 local session=S.sessions[p];session.effect=session.effect+1
 sendServerCommand(p,'SurvivorARPG','WindEffect',{amount=amount,serial=session.effect,
  generation=session.generation,onlineID=p:getOnlineID()})
end
local broadcast=Broadcast.ToPlayer
Broadcast.ToPlayer=function(p,command,args)
 local result=broadcast(p,command,args)
 -- After XP/tree purchases/migrations: store precisely the server's final state.
 if command=='PushState' and p then S.Push(p) end
 return result
end
function S.Command(module,command,p,args)
 if module~='SurvivorARPG' or not p or p:isDead() then return end
 if command~='Sync' and command~='Buy' and command~='Toggle' and command~='Wind' then return end
 if type(args)~='table' then return end
 local state=S.State(p);local rec=record(p);local session=S.sessions[p]
 local now=getTimestampMs()
 if now-session.lastRequest<150 then return end
 session.lastRequest=now
 if command=='Sync' then S.Push(p);return end
 -- Compare-and-swap: retries/double clicks and packets from an old body cannot spend twice.
 if args.revision~=rec.revision or args.generation~=session.generation then S.Push(p);return end
 local changed=false
 if command=='Buy' then
  if type(args.id)=='string' and #args.id<=32 then changed=C.Buy(state,args.id,PDA.Ensure(p)) end
 elseif command=='Toggle' then
  if (args.key=='autoAmmo' or args.key=='autoBandage') and type(args.value)=='boolean' then
   changed=state[args.key]~=args.value;state[args.key]=args.value
  end
 elseif command=='Wind' then changed=R.Wind(p) end
 if changed then rec.revision=rec.revision+1;S.Save(p);Commands.SyncPlayer(p) else S.Push(p) end
end
function S.Poll()
 local players=getOnlinePlayers();if not players then return end
 local now=getTimestampMs()
 for i=0,players:size()-1 do
  local p=players:get(i)
  if p then
   S.Attach(p);local session=S.sessions[p]
   if now-session.lastPoll>=2000 then
    session.lastPoll=now
    if not p:isDead() then S.Push(p) else S.Save(p) end
   end
  end
 end
end
Events.OnClientCommand.Add(S.Command)
Events.OnTick.Add(S.Poll)
Events.OnPlayerDeath.Add(function(p) if p then S.Save(p) end end)
Events.OnSave.Add(function()
 local players=getOnlinePlayers();if players then for i=0,players:size()-1 do S.Save(players:get(i)) end end
end)
Events.OnServerStarted.Add(R.Install)
return S
