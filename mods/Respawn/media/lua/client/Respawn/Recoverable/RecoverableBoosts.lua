RecoverableBoosts = {};

function RecoverableBoosts:Save(player)
    Respawn.Data.Stats.Boosts = {};

    local perks = PerkFactory.PerkList;
    local xp = player:getXp();

    for i = 0, perks:size() - 1 do
        local perk = perks:get(i);
        local boost = xp:getPerkBoost(perk);

        if boost > 0 then
            Respawn.Data.Stats.Boosts[perk:getName()] = boost;
        end
    end
end

function RecoverableBoosts:Load(player)
    local prof = ProfessionFactory.getProfession(Respawn.Id);

    for perkName, boost in pairs(Respawn.Data.Stats.Boosts) do
        prof:addXPBoost(PerkFactory.getPerkFromName(perkName), boost);
    end

    player:getDescriptor():setProfessionSkills(prof);
end