RecoverableOccupation = {};

function RecoverableOccupation:Save(player)
    Respawn.Data.Stats.Occupation = player:getDescriptor():getProfession();
end

function RecoverableOccupation:Load(player)
    player:getDescriptor():setProfession(Respawn.Data.Stats.Occupation);
end