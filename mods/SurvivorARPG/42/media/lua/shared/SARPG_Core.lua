-- Pure progression rules; no engine calls. Separate points, shared PDA level.
local C={KEY='SurvivorARPG',VERSION=1}
C.ATTRIBUTES={
 {id='capacity',name='Carry Capacity',max=20,desc='+5% carrying capacity per point.'},
 {id='firearms',name='Firearms',max=20,desc='+3% firearm hit damage per point.'},
 {id='vitality',name='Health',max=20,desc='+1 health regenerated per game hour per point.'},
 {id='strength',name='Strength',max=20,desc='+3% melee hit damage per point.'},
 {id='endurance',name='Endurance',max=20,desc='+5% stamina recovery per point.'},
 {id='thermal',name='Temperature Resilience',max=20,desc='Resists 3% of outward core-temperature drift per point.'},
 {id='luck',name='Luck',max=20,desc='+2% matching ammo drop chance per point.'},
}
C.TALENTS={
 {id='magnet',name='Ammo Magnet',max=3,desc='Auto-loot matching loose ammo from corpses on your tile. Rank = batch size.'},
 {id='medic',name='Field Medic',max=3,desc='Auto-bandage bleeding with clean carried supplies. Cooldown 60/30/20 sec.'},
 {id='ward',name='Bite Ward',max=5,requires='medic',desc='Requires Field Medic. -10% relative new-bite infection chance per rank.'},
 {id='secondwind',name='Second Wind',max=3,requires='ward',desc='Requires Bite Ward. Active: restore 10/20/30% stamina; five-hour cooldown.'},
}
C.DEFS={};C.BY_ID={}
for _,d in ipairs(C.ATTRIBUTES) do d.kind='attribute';C.DEFS[#C.DEFS+1]=d;C.BY_ID[d.id]=d end
for _,d in ipairs(C.TALENTS) do d.kind='talent';C.DEFS[#C.DEFS+1]=d;C.BY_ID[d.id]=d end
function C.Copy(t)
 if type(t)~='table' then return t end
 local r={};for k,v in pairs(t) do if type(v)~='userdata' and type(v)~='function' then r[k]=C.Copy(v) end end;return r
end
function C.New() return {version=C.VERSION,earned=3,spent=0,levelSeen=1,levelHigh={['0']=1},ranks={},autoAmmo=true,autoBandage=true,windReady=0} end
function C.Observe(s,level,cycle)
 level=tonumber(level);if not level or level~=level or level==math.huge then return end
 level=math.max(1,math.floor(level))
 cycle=tostring(math.max(0,math.floor(tonumber(cycle) or 0)))
 -- A high-water mark per genuine prestige cycle prevents duplicate awards after
 -- transient lower-level syncs, while still rewarding levels after prestige.
 if not s.levelHigh then s.levelHigh={[cycle]=s.levelSeen or 1} end
 local highest=s.levelHigh[cycle] or 1
 if level>highest then s.earned=s.earned+(level-highest)*3;s.levelHigh[cycle]=level end
 s.levelSeen=level
end
function C.Points(s,kind,rpg) if kind=='talent' then return math.max(0,(tonumber(rpg and rpg.skillPoints) or 0)-(tonumber(rpg and rpg.spentPoints) or 0)-(tonumber(rpg and rpg.geneSpentPoints) or 0)) end;return math.max(0,s.earned-s.spent) end
function C.Rank(s,id) return tonumber(s.ranks[id]) or 0 end
function C.Buy(s,id,rpg)
 local d=C.BY_ID[id];if not d or C.Points(s,d.kind,rpg)<1 or C.Rank(s,id)>=d.max then return false end
 if d.requires and C.Rank(s,d.requires)<1 then return false end
 s.ranks[id]=C.Rank(s,id)+1
 if d.kind=='talent' then rpg.skillPoints=rpg.skillPoints-1 else s.spent=s.spent+1 end
 return true
end
-- Explicit allowlist: no kill counters, cached equipment factors, temporary buffs,
-- trader deliveries or world quests. Those must not replay on a new body.
C.PERSIST={'saveVersion','level','xp','totalXP','skillPoints','resetPoints','spentPoints',
 'geneSpentPoints','geneEdits','geneEditSeq','resetEarnedTotal','nodes','prestige','ui',
 'prpgeMasteryResets','prpgeProgressionVersion','prpgeReworkVersion','prpgeReworkRespecGranted'}
function C.Snapshot(rpg,custom)
 local r={};for _,k in ipairs(C.PERSIST) do r[k]=C.Copy(rpg[k]) end
 return {version=C.VERSION,rpg=r,custom=C.Copy(custom)}
end
function C.Restore(md,snapshot)
 if type(snapshot)~='table' or snapshot.version~=C.VERSION then return false end
 if type(snapshot.rpg)~='table' or type(snapshot.custom)~='table' then return false end
 md.RPGSkillTree=md.RPGSkillTree or {}
 for _,k in ipairs(C.PERSIST) do md.RPGSkillTree[k]=C.Copy(snapshot.rpg[k]) end
 md[C.KEY]=C.Copy(snapshot.custom)
 -- Existing PDA XP observers establish a fresh baseline for this body.
 md.RPGSkillTree.rpgSPRewardedKills=nil
 md.RPGSkillTree.rpgMPAccountingVersion=nil
 return true
end
return C
