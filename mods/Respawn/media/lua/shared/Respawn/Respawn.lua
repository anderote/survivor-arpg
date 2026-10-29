Respawn = {};

Respawn.Id = "respawn";
Respawn.Name = "Respawn";

Respawn.OptionsPath = "respawn-options.json";
Respawn.AvailablePath = "respawn-available.json";

Respawn.Data = {};
Respawn.Data.Stats = {};
Respawn.Data.Options = {};

function Respawn.GetModDataStatsKey()
    return Respawn.Id..'-'..Respawn.GetUserID();
end

function Respawn.GetModDataOptionsKey()
    return Respawn.Id..'-options';
end

function Respawn.GetUserID()
    return isClient() and "player-"..getWorld():getWorld().."-"..getClientUsername() or "player-"..getWorld():getWorld();
end

function Respawn.GetLogName()
    return isClient() and "respawn-client" or "respawn-server";
end