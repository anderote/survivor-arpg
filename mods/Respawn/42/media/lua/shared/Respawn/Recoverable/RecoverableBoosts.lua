RecoverableBoosts = {};

function RecoverableBoosts:Save(player)
    Respawn.Data.Stats.Boosts = {};

    local xp = player:getXp();
    if not xp or not PerkFactory.PerkList then return end

    for i = 0, PerkFactory.PerkList:size() - 1 do
        local perk = PerkFactory.PerkList:get(i);
        if perk and perk:getType() then
            local perkType = perk:getType();
            local boost = xp:getPerkBoost(perkType);

            if boost and boost > 0 then
                Respawn.Data.Stats.Boosts[tostring(perkType)] = boost;
            end
        end
    end
end

function RecoverableBoosts:Load(player)
    if not Respawn.Data.Stats or not Respawn.Data.Stats.Boosts then return end

    local xp = player:getXp();
    for perkName, boost in pairs(Respawn.Data.Stats.Boosts) do
        local perk = Perks.FromString(perkName);
        if perk and xp and xp.setPerkBoost then
            pcall(function() xp:setPerkBoost(perk, boost); end);
        end
    end
end