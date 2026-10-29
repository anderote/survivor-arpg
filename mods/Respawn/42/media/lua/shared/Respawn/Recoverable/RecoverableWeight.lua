RecoverableWeight = {};

function RecoverableWeight:Save(player)
    local nutrition = player:getNutrition();
    if nutrition then
        Respawn.Data.Stats.Weight = nutrition:getWeight();
    end
end

function RecoverableWeight:Load(player)
    local nutrition = player:getNutrition();
    if nutrition and Respawn.Data.Stats.Weight then
        nutrition:setWeight(Respawn.Data.Stats.Weight);
    end
end