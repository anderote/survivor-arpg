from pathlib import Path
from lupa import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'mods/SurvivorARPG/42/media/lua'
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('package.path = '+repr(str(BASE/'shared/?.lua')+';'+str(BASE/'client/?.lua')+';')+'..package.path')
for p in BASE.rglob('*.lua'):
    lua.execute('assert(load(...))',p.read_text())
print('PASS all Lua files compile')
lua.execute(r'''
C=require 'SARPG_Core'
local s=C.New();local r={skillPoints=4}
assert(C.Points(s)==3)
C.Observe(s,4);assert(C.Points(s)==12)
C.Observe(s,4);assert(C.Points(s)==12)
assert(C.Buy(s,'capacity',r));assert(C.Points(s)==11 and r.skillPoints==4)
assert(not C.Buy(s,'ward',r))
assert(C.Buy(s,'medic',r) and r.skillPoints==3 and C.Points(s)==11)
assert(C.Buy(s,'ward',r) and C.Buy(s,'secondwind',r))
assert(not C.Buy(s,'nonsense',r))
s.windReady=50;r.level=4;r.xp=32;r.totalXP=500;r.nodes={existing=true};r.prestige={rank=2}
r.prpgeMasteryResets={cycle=2,earned={mastery=true}};r.prpgeProgressionVersion=25;r.prpgeReworkVersion=34
r.factors={carryWeightMul=99};r.rpgSPRewardedKills=200
local saved=C.Snapshot(r,s);local md={RPGSkillTree={}}
assert(C.Restore(md,saved));assert(md.RPGSkillTree.factors==nil and md.RPGSkillTree.rpgSPRewardedKills==nil)
assert(md.RPGSkillTree.nodes.existing and md.SurvivorARPG.windReady==50)
assert(md.RPGSkillTree.prpgeMasteryResets.earned.mastery and md.RPGSkillTree.prpgeProgressionVersion==25 and md.RPGSkillTree.prpgeReworkVersion==34)
C.Observe(md.SurvivorARPG,4);assert(C.Points(md.SurvivorARPG)==11)
md.RPGSkillTree.nodes.existing=false;assert(saved.rpg.nodes.existing)
assert(C.Restore(md,saved));assert(C.Points(md.SurvivorARPG)==11)
assert(not C.Restore({}, {version=999}))
C.Observe(s,1);C.Observe(s,4);assert(C.Points(s)==11) -- stale lower-level sync must not grant again
C.Observe(s,1,1);C.Observe(s,2,1);assert(C.Points(s)==14) -- genuine prestige restart
r.skillPoints=5;r.spentPoints=3;r.geneSpentPoints=2;assert(not C.Buy(s,'magnet',r))
assert(C.Points(s,'talent',r)==0)
r.skillPoints=6;assert(C.Buy(s,'magnet',r));assert(C.Points(s,'talent',r)==0)
r.skillPoints=0;assert(not C.Buy(s,'magnet',r))
s.earned=1000;for i=1,20 do C.Buy(s,'capacity',r) end
assert(C.Rank(s,'capacity')==20 and not C.Buy(s,'capacity',r))
''')
print('PASS separate currencies, prerequisites, limits, level idempotency, deep-copy respawn and cooldown persistence')
lua.execute(r'''
Events=setmetatable({}, {__index=function(t,k) local e={handlers={}};e.Add=function(f) table.insert(e.handlers,f) end;rawset(t,k,e);return e end})
function isMultiplayer() return false end
clock=0;realclock=0
function getGameTime() return {getWorldAgeHours=function() return clock end} end
function getTimestampMs() return realclock end
function list(t) return {size=function() return #t end,get=function(_,i) return t[i+1] end} end
queue={queue={}}
ISTimedActionQueue={getTimedActionQueue=function() return queue end,add=function(action) table.insert(queue.queue,action) end}
ISInventoryTransferAction={new=function(_,p,item,src,dest,time) return {item=item,src=src,dest=dest,kind='transfer'} end}
ISApplyBandage={new=function(_,p,other,item,part) return {item=item,part=part,kind='bandage'} end}
for _,n in ipairs({'ISTimedActionQueue','ISInventoryTransferAction','ISApplyBandage'}) do package.preload['TimedActions/'..n]=function() return true end end
gwActive=false
package.preload['PRPGE_Compat']=function() return {Active=function() return gwActive end} end
package.preload['WeaponSystems/Utils/Ammo']=function() return {GetFamilyForItem=function() return '9mm' end,GetOrderedBulletTypesForFamily=function() return {'SWMG.9x19_Bullet','SWMG.9x19_Bullet_HollowPoint'} end} end
package.preload['PRPGE_NPCs']=function() return {IsNPC=function(t) return t.npc==true end} end
calc={CalculateAndStoreFactors=function(p) p.md.RPGSkillTree.factors={carryWeightMul=1.2,staminaRegen=1.1} end}
package.preload['RPG_Server_Calculate']=function() return calc end
rules={Values=function() return {bite=80,dmg=1} end}
wounds={Check=function(p) p.chance=rules.Values().bite;return 1 end}
package.preload['PRPGE_DangerWounds']=function() return wounds end
package.preload['PRPGE_DangerRules']=function() return rules end
Respawn={Recoverables={},Data={Stats={}}}
package.preload['Respawn/RespawnRecoverables']=function() return true end
function enum(lo,hi) return {getMinimumValue=function() return lo end,getMaximumValue=function() return hi end} end
CharacterStat={ENDURANCE=enum(0,1),TEMPERATURE=enum(20,42)}
local statvalues={[CharacterStat.ENDURANCE]=.2,[CharacterStat.TEMPERATURE]=37}
stats={get=function(_,k) return statvalues[k] end,set=function(_,k,v) statvalues[k]=v end}
health=70;part={bleeding=function() return true end,bandaged=function() return false end}
body={AddGeneralHealth=function(_,v) health=math.min(100,health+v) end,getBodyParts=function() return list({part}) end}
function item(name,kind)
 return {name=name,kind=kind,getFullType=function(self) return self.name end,getActualWeight=function() return .1 end,
 isRanged=function() return true end,getAmmoType=function() return {getItemKey=function() return 'Base.Bullets9mm' end} end}
end
function instanceof(o,kind) return o.kind==kind end
inventoryItems={item('Base.Pistol','HandWeapon'),item('Base.Bandage')}
inv={getItems=function() return list(inventoryItems) end,hasRoomFor=function() return true end,getCapacityWeight=function() return 5 end}
corpseItems={item('Base.Bullets9mm'),item('Base.ShotgunShells'),item('Base.Bullets9mm')}
source={getItems=function() return list(corpseItems) end}
square={getDeadBodys=function() return list({{getContainer=function() return source end}}) end}
player={md={RPGSkillTree={level=1,skillPoints=20}},getModData=function(self) return self.md end,
 getStats=function() return stats end,getBodyDamage=function() return body end,getInventory=function() return inv end,
 getSquare=function() return square end,getMaxWeight=function() return 12 end}
for _,k in ipairs({'isDead','isRunning','isSprinting','isAiming','isAsleep','isMoving'}) do player[k]=function() return false end end
function getPlayer() return player end
RPG_ClientCommands={RequestSync=function() calc.CalculateAndStoreFactors(player);return true end}
function getScriptManager() return {FindItem=function(_,name) assert(type(name)=='string');return {getFullName=function() return name end} end} end
function ZombRand(n) return 0 end
M=require 'SARPG_Runtime';M.Install()
assert(M.AmmoTypes(player)['Base.Bullets9mm'])
gwActive=true;assert(M.AmmoTypes(player)['SWMG.9x19_Bullet_HollowPoint']);gwActive=false
local s=M.State(player);s.earned=100;s.ranks.capacity=3;s.ranks.endurance=4
calc.CalculateAndStoreFactors(player);local f=player.md.RPGSkillTree.factors
assert(math.abs(f.carryWeightMul-1.35)<1e-9 and math.abs(f.staminaRegen-1.3)<1e-9)
calc.CalculateAndStoreFactors(player);assert(player.md.RPGSkillTree.factors.carryWeightMul==f.carryWeightMul)
s.ranks.ward=2;wounds.Check(player);assert(player.chance==64 and rules.Values().bite==80)
s.ranks.secondwind=2;assert(M.Wind(player));assert(math.abs(stats:get(CharacterStat.ENDURANCE)-.4)<1e-9)
assert(not M.Wind(player));clock=6;assert(M.Wind(player))
s.ranks.magnet=2;s.autoBandage=false
for i=1,30 do M.Tick() end
assert(#queue.queue==2 and queue.queue[1].item.name=='Base.Bullets9mm')
for i=1,30 do M.Tick() end;assert(#queue.queue==2) -- busy does not enqueue duplicates
queue.queue={};s.autoAmmo=false;s.autoBandage=true;s.ranks.medic=1
for i=1,30 do M.Tick() end;assert(#queue.queue==1 and queue.queue[1].kind=='bandage')
queue.queue={};for i=1,30 do M.Tick() end;assert(#queue.queue==0) -- cooldown
s.autoBandage=false;s.ranks.vitality=5;s.ranks.thermal=10
clock=6.05;stats:set(CharacterStat.TEMPERATURE,38)
for i=1,30 do M.Tick() end
assert(math.abs(health-70.25)<1e-7 and math.abs(stats:get(CharacterStat.TEMPERATURE)-37.7)<1e-7)
local target={npc=false,hp=10,isZombie=function() return true end,isDead=function() return false end,getHealth=function(self) return self.hp end,setHealth=function(self,v) self.hp=v end,Kill=function(self) self.killed=true end}
s.ranks.firearms=2;M.OnHit(player,inventoryItems[1],target,2);assert(math.abs(target.hp-9.88)<1e-9)
target.npc=true;M.OnHit(player,inventoryItems[1],target,2);assert(math.abs(target.hp-9.88)<1e-9)
local drops={};local zombie={md={},getAttackedBy=function() return player end,getModData=function(self) return self.md end,getInventory=function() return {AddItem=function(_,name) table.insert(drops,name) end} end}
M.OnDeath(zombie);local n=#drops;assert(n>0);M.OnDeath(zombie);assert(#drops==n)
zombie.npc=true;zombie.md={};M.OnDeath(zombie);assert(#drops==n and zombie.md.SARPGDrop==nil)
local recovery=require 'SARPG_Respawn';recovery:Save(player)
player.md={RPGSkillTree={level=1}};recovery:Load(player)
assert(player.md.SurvivorARPG.ranks.capacity==3 and player.md.SurvivorARPG.windReady==11)
assert(next(M.errors)==nil)
''')
print('PASS carry non-stacking, conditional bite ward, powerup cooldown, selective queueing, bandage cooldown, healing, thermal damping, NPC exclusion, loot idempotency, Respawn adapter')
lua.execute(r'''
local home={Render=function() end,Click=function() return false end,Hide=function() end}
local pda={PageRect=function(ui) return {x=14,y=76,w=ui.width-28,h=900} end,Panel=function() end}
package.preload['PRPGE_PDA']=function() return pda end
package.preload['PRPGE_PDAHome']=function() return home end
UIFont={Small=1}
function getTextManager() return {MeasureStringX=function(_,font,s) return #s*7 end} end
local ui={player=player,width=1000,height=1000,drawText=function() end,drawRect=function() end,drawRectBorder=function() end}
local view=require 'SARPG_PDA';view.Install()
home.Render(ui);assert(#ui._sarpgButtons==3)
assert(home.Click(ui,145,85));assert(ui._sarpgPage=='attributes');home.Render(ui);assert(#ui._sarpgButtons==10)
local before=player.md.SurvivorARPG.spent
for _,b in ipairs(ui._sarpgButtons) do if b.id=='buy:capacity' then home.Click(ui,b.x+1,b.y+1);break end end
assert(player.md.SurvivorARPG.spent==before+1)
ui._sarpgPage='talents';home.Render(ui);assert(#ui._sarpgButtons==10)
for _,b in ipairs(ui._sarpgButtons) do assert(b.x>=14 and b.x+b.w<=986 and b.y+b.h<976) end
''')
print('PASS PDA page navigation, attribute purchase click, skill controls and button bounds')
