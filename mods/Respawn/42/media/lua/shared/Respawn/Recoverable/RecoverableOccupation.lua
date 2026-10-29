RecoverableOccupation = {};

function RecoverableOccupation:Save(player)
    local desc = player:getDescriptor();
    if desc and desc:getCharacterProfession() then
        local prof = desc:getCharacterProfession();
        local name = (prof.getName and prof:getName()) or tostring(prof);
        if name and name ~= "respawn:respawn" and name ~= "respawn" then
            Respawn.Data.Stats.Occupation = name;
        end
    end
end

function RecoverableOccupation:Load(player)
    if not Respawn.Data.Stats or not Respawn.Data.Stats.Occupation then
        return;
    end

    local occName = Respawn.Data.Stats.Occupation;
    local prof = nil;
    pcall(function()
        if not string.find(occName, ":") then
            prof = CharacterProfession.get(ResourceLocation.of("base:" .. occName)) or CharacterProfession.get(ResourceLocation.of(occName));
        else
            prof = CharacterProfession.get(ResourceLocation.of(occName));
        end
    end);

    if prof then
        local desc = player:getDescriptor();
        if desc then
            desc:setCharacterProfession(prof);
            local profDef = CharacterProfessionDefinition.getCharacterProfessionDefinition(prof);
            if profDef then
                desc:setProfessionSkills(profDef);
            end
        end
    end
end