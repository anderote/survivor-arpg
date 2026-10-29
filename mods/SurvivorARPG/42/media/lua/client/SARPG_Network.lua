-- Owner-client presentation cache; purchases never mutate it optimistically.
local C=require 'SARPG_Core'
local N={cache=setmetatable({},{__mode='k'}),lastRequest=setmetatable({},{__mode='k'})}
function N.Ready(p) return N.cache[p]~=nil end
function N.State(p) return N.cache[p] and N.cache[p].state or C.New() end
function N.RPG(p) return N.cache[p] and N.cache[p].rpg or {} end
function N.Send(p,command,args)
 if not p or p:isDead() then return false end
 local cache=N.cache[p];if command~='Sync' and not cache then return false end
 args=args or {}
 if cache then args.revision=cache.revision;args.generation=cache.generation end
 sendClientCommand(p,'SurvivorARPG',command,args);return true
end
function N.Poll(p)
 local now=getTimestampMs()
 if now-(N.lastRequest[p] or -10000)>=5000 then N.lastRequest[p]=now;N.Send(p,'Sync',{}) end
end
function N.Receive(module,command,args)
 if module~='SurvivorARPG' or type(args)~='table' then return end
 local p=getPlayer();if not p or args.onlineID~=p:getOnlineID() then return end
 local current=N.cache[p]
 if command=='State' then
  if type(args.state)~='table' or type(args.rpg)~='table' or type(args.revision)~='number' or type(args.generation)~='number' then return end
  if current and (args.generation<current.generation or
   (args.generation==current.generation and args.revision<current.revision)) then return end
  args.lastEffect=current and current.generation==args.generation and current.lastEffect or 0
  N.cache[p]=args
  local runtime=require 'SARPG_Runtime';runtime.errors=args.errors or {}
 elseif command=='WindEffect' then
  if not current or args.generation~=current.generation or type(args.serial)~='number' or args.serial<=(current.lastEffect or 0) then return end
  if type(args.amount)~='number' or args.amount<=0 or args.amount>.31 then return end
  current.lastEffect=args.serial
  local stats=p:getStats();local e=CharacterStat.ENDURANCE
  stats:set(e,math.min(e:getMaximumValue(),stats:get(e)+args.amount))
 end
end
if isClient and isClient() then
 Events.OnServerCommand.Add(N.Receive)
 Events.OnCreatePlayer.Add(function(_,p) if p then N.cache[p]=nil;N.lastRequest[p]=nil end end)
end
return N
