require "Respawn/RespawnRecoverables"

local function SetRespawnAvailable(player)
    local available = Respawn.File.Load(Respawn.AvailablePath) or {};
    available[Respawn.GetUserID(player)] = true;
    available[Respawn.GetUserID()] = true;

    Respawn.File.Save(Respawn.AvailablePath, available);
end

local function SavePlayer(player)
    if not player then return end

    writeLog(Respawn.GetLogName(), "saving player death stats for " .. tostring(player:getUsername()));
    print("[Respawn] Saving player death stats for " .. tostring(player:getUsername()) .. "...");

    Respawn.Data.Stats = {};

    for _, recoverable in ipairs(Respawn.Recoverables) do
        local ok, err = pcall(function() recoverable:Save(player); end);
        if not ok then
            print("[Respawn ERROR] Error saving recoverable: " .. tostring(err));
        end
    end

    local statsKey = Respawn.GetModDataStatsKey(player);
    ModData.add(statsKey, Respawn.Data.Stats);
    print("[Respawn] Saved stats under key: " .. tostring(statsKey));

    if isClient() then
        Respawn.Sync.SaveRemote();
    end

    SetRespawnAvailable(player);
end

Events.OnPlayerDeath.Add(SavePlayer);