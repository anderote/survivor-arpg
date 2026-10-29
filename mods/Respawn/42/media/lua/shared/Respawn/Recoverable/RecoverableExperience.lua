RecoverableExperience = {};

function RecoverableExperience:Save(player)
    Respawn.Data.Stats.Experience = {};

    if not PerkFactory.PerkList then return end

    for i = 0, PerkFactory.PerkList:size() - 1 do
        local perk = PerkFactory.PerkList:get(i);
        if perk then
            self:SavePerkXP(player, perk);
        end
    end
end

function RecoverableExperience:SavePerkXP(player, perk)
    local xp = player:getXp();
    if not xp then return end

    local perkType = perk:getType() or perk;
    local perkId = tostring(perkType);

    if (Respawn.Data.Options.ExcludeStrength and (perkType == Perks.Strength or perkId == "Strength")) or
       (Respawn.Data.Options.ExcludeFitness and (perkType == Perks.Fitness or perkId == "Fitness")) then
        Respawn.Data.Stats.Experience[perkId] = xp:getXP(perkType);
        return;
    end
        
    if Respawn.Data.Options.XPRestored == 21 then
        xp:setXPToLevel(perkType, player:getPerkLevel(perkType));
        Respawn.Data.Stats.Experience[perkId] = xp:getXP(perkType);
    else
        local ratio = (Respawn.Data.Options.XPRestored or 20) / 20;
        Respawn.Data.Stats.Experience[perkId] = xp:getXP(perkType) * ratio;
    end
end

function RecoverableExperience:Load(player)
    if not Respawn.Data.Stats or not Respawn.Data.Stats.Experience then
        return;
    end

    local expTable = Respawn.Data.Stats.Experience;
    local hasAnyXP = false;
    for _, _ in pairs(expTable) do
        hasAnyXP = true;
        break;
    end
    if not hasAnyXP then
        return;
    end

    self:ResetXP(player);

    local xp = player:getXp();
    if not xp then return end

    for perkName, experience in pairs(Respawn.Data.Stats.Experience) do
        local perk = Perks.FromString(perkName);
        if perk and experience and experience > 0 then
            local ok = pcall(function() xp:AddXP(perk, experience, false, false, false, false); end);
            if not ok then
                ok = pcall(function() xp:AddXP(perk, experience, false, false, false); end);
                if not ok then
                    pcall(function() xp:AddXP(perk, experience); end);
                end
            end
        end
    end

    if SyncXp then
        pcall(function() SyncXp(player); end);
    end
end

function RecoverableExperience:ResetXP(player)
    local xp = player:getXp();
    if not xp or not PerkFactory.PerkList then return end

    for i = 0, PerkFactory.PerkList:size() - 1 do
        local perk = PerkFactory.PerkList:get(i);
        if perk then
            local perkType = perk:getType() or perk;
            if perkType and perkType ~= Perks.None then
                pcall(function()
                    xp:setXPToLevel(perkType, 0);
                    while player:getPerkLevel(perkType) > 0 do
                        player:LoseLevel(perkType);
                    end
                end);
            end
        end
    end
end