"""Separate server/client Lua VMs; transport packets are deep-copied like the wire."""
from pathlib import Path
from lupa import LuaRuntime
base=Path(__file__).resolve().parents[1]/'mods/SurvivorARPG/42/media/lua'
def vm(server):
 l=LuaRuntime(unpack_returned_tuples=True)
 l.execute('package.path=... .. package.path',';'.join(str(base/d/'?.lua') for d in ['shared','server' if server else 'client'])+';')
 l.globals().server=server
 l.execute('''
 function isServer() return server end
 function isClient() return not server end
 function isMultiplayer() return true end
 Events=setmetatable({}, {__index=function(t,k) local e={handlers={}};e.Add=function(f) table.insert(e.handlers,f) end;t[k]=e;return e end})
 C=require 'SARPG_Core';now=0;hours=10;packets={};store={}
 function getTimestampMs() return now end
 function getGameTime() return {getWorldAgeHours=function() return hours end} end
 function sendServerCommand(p,m,c,a) packets[#packets+1]={p=p,m=m,c=c,a=C.Copy(a)} end
 function sendClientCommand(p,m,c,a) packets[#packets+1]={p=p,m=m,c=c,a=C.Copy(a)} end
 ModData={getOrCreate=function(k) store[k]=store[k] or {};return store[k] end}
 function player(name,id)
  local p={md={},name=name,id=id,energy=.2}
  function p:getModData() return self.md end
  function p:getUsername() return self.name end
  function p:getOnlineID() return self.id end
  function p:isDead() return self.dead==true end
  function p:getStats() return {get=function() return p.energy end,set=function(_,e,v) p.energy=v end} end
  return p
 end
 CharacterStat={ENDURANCE={getMinimumValue=function() return 0 end,getMaximumValue=function() return 1 end}}
 a=player('alice',1);b=player('bob',2)
 function getPlayer() return a end
 function getOnlinePlayers() return {size=function() return 2 end,get=function(_,i) return i==0 and a or b end} end
 function instanceof(p,k) return k=='IsoPlayer' end
 ''')
 return l
s=vm(True)
s.execute('''
 pda={Ensure=function(p) p.md.RPGSkillTree=p.md.RPGSkillTree or {level=1,skillPoints=4};return p.md.RPGSkillTree end}
 broadcast={ToPlayer=function() end}
 commands={SyncPlayer=function(p) broadcast.ToPlayer(p,'PushState',{state=pda.Ensure(p)}) end}
 package.preload['RPG_Server_State']=function() return pda end
 package.preload['RPG_Server_Commands']=function() return commands end
 package.preload['RPG_Server_Broadcast']=function() return broadcast end
 S=require 'SARPG_Server';R=require 'SARPG_Runtime'
 S.Push(a);S.Push(b)
 local function command(p,cmd,args)
  now=now+200;local rec=store.SurvivorARPG_Server_v1[p.name]
  args=args or {};args.revision=rec.revision;args.generation=S.sessions[p].generation
  S.Command('SurvivorARPG',cmd,p,args);return C.Copy(args)
 end
 local retry=command(a,'Buy',{id='capacity',price=-100,level=999,username='bob'})
 assert(C.Rank(S.State(a),'capacity')==1 and S.State(a).spent==1)
 assert(C.Rank(S.State(b),'capacity')==0)
 now=now+200;S.Command('SurvivorARPG','Buy',a,retry)
 assert(C.Rank(S.State(a),'capacity')==1) -- replay rejected
 command(a,'Buy',{id='ward'});assert(C.Rank(S.State(a),'ward')==0)
 command(a,'Buy',{id='medic'});command(a,'Buy',{id='ward'});command(a,'Buy',{id='secondwind'})
 assert(pda.Ensure(a).skillPoints==1)
 command(a,'Toggle',{key='earned',value=true});assert(S.State(a).earned==3)
 command(a,'Toggle',{key='autoAmmo',value=false});assert(not S.State(a).autoAmmo)
 command(a,'Wind');assert(S.State(a).windReady==15 and a.energy==.2)
 local effects=0;for _,p in ipairs(packets) do if p.c=='WindEffect' then effects=effects+1 end end
 command(a,'Wind');local effects2=0;for _,p in ipairs(packets) do if p.c=='WindEffect' then effects2=effects2+1 end end
 assert(effects==1 and effects2==1)
 -- XP comes from PDA authority, awards once regardless of repeat syncs.
 pda.Ensure(a).level=5;S.Push(a);S.Push(a);assert(S.State(a).earned==15)
 -- Replace network-facing modData: server-owned profile survives unchanged.
 a.md={SurvivorARPG={earned=9999},RPGSkillTree={level=999,skillPoints=9999}}
 assert(S.State(a).earned==15 and pda.Ensure(a).skillPoints==1)
 S.Save(a);local replacement=player('alice',3)
 S.Push(replacement);assert(C.Rank(S.State(replacement),'capacity')==1)
 assert(S.State(replacement).windReady==15 and pda.Ensure(replacement).level==5)
 assert(pda.Ensure(replacement).skillPoints==1)
 assert(C.Rank(S.State(b),'capacity')==0)
 -- Dead characters cannot buy, stale old-generation requests cannot buy.
 replacement.dead=true;command(replacement,'Buy',{id='capacity'});assert(C.Rank(S.State(replacement),'capacity')==1)
 replacement.dead=false;now=now+200;S.Command('SurvivorARPG','Buy',replacement,retry)
 assert(C.Rank(S.State(replacement),'capacity')==1)
 -- Disk roundtrip: no session cache; only serialized global modData remains.
 store=C.Copy(store);S.bound={};S.sessions={};local reconnect=player('alice',4)
 assert(C.Rank(S.State(reconnect),'capacity')==1 and S.State(reconnect).windReady==15)
 assert(pda.Ensure(reconnect).skillPoints==1)
 ''')
print('PASS MP server: two-player isolation, server-derived costs/levels, replay/stale-body rejection, prerequisites, cooldown, respawn/reconnect/disk roundtrip')
c=vm(False)
c.execute('''
 N=require 'SARPG_Network';R=require 'SARPG_Runtime'
 assert(not R.Ready(a));assert(not R.Buy(a,'capacity'))
 local st=C.New();st.ranks.secondwind=1
 local function packet(gen,rev,id) return {state=C.Copy(st),rpg={level=2,skillPoints=5},generation=gen,revision=rev,onlineID=id or 1} end
 N.Receive('SurvivorARPG','State',packet(1,2,2));assert(not N.Ready(a))
 N.Receive('SurvivorARPG','State',packet(1,2));assert(N.Ready(a))
 assert(R.Buy(a,'capacity'));assert(C.Rank(N.State(a),'capacity')==0)
 assert(packets[#packets].a.revision==2 and packets[#packets].a.generation==1)
 N.Receive('SurvivorARPG','State',packet(1,1));assert(N.cache[a].revision==2)
 N.Receive('SurvivorARPG','State',packet(0,999));assert(N.cache[a].generation==1)
 local wind={generation=1,serial=1,onlineID=1,amount=.1}
 N.Receive('SurvivorARPG','WindEffect',wind);assert(math.abs(a.energy-.3)<.00001)
 N.Receive('SurvivorARPG','WindEffect',wind);assert(math.abs(a.energy-.3)<.00001)
 N.Receive('SurvivorARPG','State',packet(1,3))
 N.Receive('SurvivorARPG','WindEffect',wind);assert(math.abs(a.energy-.3)<.00001)
 N.Receive('SurvivorARPG','State',packet(2,4))
 N.Receive('SurvivorARPG','WindEffect',wind);assert(math.abs(a.energy-.3)<.00001)
 -- Client combat/drop callbacks are inert: no world mutation or server imports.
 R.OnHit(a,{},{} ,100);R.OnDeath({})
 assert(package.loaded.SARPG_Server==nil)
 ''')
print('PASS MP client: sync gating, no optimistic spend, target/revision/generation filtering, one-time powerup, no client damage/loot')
