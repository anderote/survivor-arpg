require "Respawn/RespawnLoadCore"

local function OnCreatePlayer(id, player)
    player = player or (type(id) == "number" and getSpecificPlayer(id)) or getPlayer();
    if not player then
        return;
    end

    local hasProf = Respawn.HasRespawnProfession(player);
    print("[Respawn] OnCreatePlayer triggered for " .. tostring(player:getUsername()) .. ", hasRespawnProf=" .. tostring(hasProf));

    if not hasProf then
        return;
    end

    if isClient() then
        sendClientCommand(player, Respawn.Id, "RequestLoad", {});
    else
        local key = Respawn.GetModDataStatsKey(player);
        print("[Respawn] Loading saved stats from key: " .. tostring(key));
        Respawn.Data.Stats = ModData.get(key) or {};
        writeLog(Respawn.GetLogName(), "loading saved stats for " .. tostring(player:getUsername()));
        Respawn.LoadPlayer(player);
    end
end

Events.OnCreatePlayer.Add(OnCreatePlayer);
