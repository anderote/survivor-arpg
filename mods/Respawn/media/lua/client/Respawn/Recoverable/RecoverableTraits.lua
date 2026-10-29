RecoverableTraits = {};

function RecoverableTraits:Save(player)
    Respawn.Data.Stats.Traits = {};
    
    local traits = player:getTraits();
    for i = 0, traits:size() - 1 do
        table.insert(Respawn.Data.Stats.Traits, traits:get(i));
    end
end

function RecoverableTraits:Load(player)
    player:getTraits():clear();

    for i, trait in ipairs(Respawn.Data.Stats.Traits) do
        player:getTraits():add(trait);
    end
end