local LoadingPlayer = false;

local function LoadPlayer()
    if not getPlayer():HasTrait(Respawn.Id) then
        return;
    end

    LoadingPlayer = false;

    for i, recoverable in ipairs(Respawn.Recoverables) do
        recoverable:Load(getPlayer());
    end
end

local function OnCreatePlayer(id, player)
    if not player:HasTrait(Respawn.Id) then
        return;
    end

    LoadingPlayer = true;

    if isClient() then
        Respawn.Sync.LoadRemote();
    else
        Respawn.Data.Stats = ModData.get(Respawn.GetModDataStatsKey());
        LoadPlayer();
    end
end

local function OnReceiveModData(key, modData)
    if not LoadingPlayer or key ~= Respawn.GetModDataStatsKey() or not modData then
        return;
    end

    LoadPlayer();
end

Events.OnCreatePlayer.Add(OnCreatePlayer);
Events.OnReceiveGlobalModData.Add(OnReceiveModData);