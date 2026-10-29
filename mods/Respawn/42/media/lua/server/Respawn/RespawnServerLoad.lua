require "Respawn/RespawnLoadCore"

if not isServer() then
    return;
end

local function OnRequestLoad(module, command, player, args)
    if module ~= Respawn.Id or command ~= "RequestLoad" then
        return;
    end

    if not player or not Respawn.HasRespawnProfession(player) then
        return;
    end

    local key = Respawn.GetModDataStatsKey(player);
    Respawn.Data.Stats = ModData.get(key) or {};

    writeLog(Respawn.GetLogName(), "applying saved stats for "..tostring(player:getUsername()));
    Respawn.LoadPlayer(player);
end

Events.OnClientCommand.Add(OnRequestLoad);
