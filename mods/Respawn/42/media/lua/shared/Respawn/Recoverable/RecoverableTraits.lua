RecoverableTraits = {};

function RecoverableTraits:Save(player)
    Respawn.Data.Stats.Traits = {};

    local characterTraits = player:getCharacterTraits();
    if characterTraits and characterTraits:getKnownTraits() then
        local traits = characterTraits:getKnownTraits();
        for i = 0, traits:size() - 1 do
            local trait = traits:get(i);
            if trait then
                local name = trait:getName();
                if name and name ~= "respawn:respawn" and name ~= "respawn" then
                    table.insert(Respawn.Data.Stats.Traits, name);
                end
            end
        end
    end
end

function RecoverableTraits:Load(player)
    if not Respawn.Data.Stats or not Respawn.Data.Stats.Traits then
        return;
    end

    local characterTraits = player:getCharacterTraits();
    if characterTraits and characterTraits:getKnownTraits() then
        local traits = characterTraits:getKnownTraits();
        traits:clear();

        for _, traitName in ipairs(Respawn.Data.Stats.Traits) do
            local trait = nil;
            pcall(function()
                if not string.find(traitName, ":") then
                    trait = CharacterTrait.get(ResourceLocation.of("base:" .. traitName)) or CharacterTrait.get(ResourceLocation.of(traitName));
                else
                    trait = CharacterTrait.get(ResourceLocation.of(traitName));
                end
            end);

            if trait then
                traits:add(trait);
                if player.modifyTraitXPBoost then
                    pcall(function() player:modifyTraitXPBoost(trait, false); end);
                end
            end
        end
        if SyncXp then
            pcall(function() SyncXp(player); end);
        end
    end
end