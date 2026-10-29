local C=require 'SARPG_Core'
local M=require 'SARPG_Runtime'
require 'Respawn/RespawnRecoverables'
local recoverable={SARPG=true}
function recoverable:Save(p)
 if M.Multiplayer() then return end
 local md=p:getModData();local s=M.State(p)
 Respawn.Data.Stats.SurvivorARPG=C.Snapshot(md.RPGSkillTree or {},s)
end
function recoverable:Load(p)
 if M.Multiplayer() then return end
 if C.Restore(p:getModData(),Respawn.Data.Stats.SurvivorARPG) then
  M.pendingSync=true
  -- SP receiver may hold the old body's state until the next authoritative sync.
  if RPG_ClientState then RPG_ClientState.ready=false;RPG_ClientState.state=nil end
  print('[Survivor ARPG] Restored PDA progression and upgrades via Respawn')
 end
end
local found=false;for _,r in ipairs(Respawn.Recoverables) do if r.SARPG then found=true end end
if not found then table.insert(Respawn.Recoverables,recoverable) end
return recoverable
