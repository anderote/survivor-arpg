require "Respawn/Respawn"
require "Respawn/RespawnRecoverables"

function Respawn.HasRespawnProfession(player)
    if not player then return false end

    local respawnProf = nil;
    pcall(function()
        respawnProf = CharacterProfession.get(ResourceLocation.of("respawn:respawn")) or CharacterProfession.get(ResourceLocation.of("respawn"));
    end);

    local desc = player:getDescriptor();
    if desc and desc:getCharacterProfession() then
        local prof = desc:getCharacterProfession();
        if respawnProf and prof == respawnProf then
            return true;
        end
        local profName = (prof.getName and prof:getName()) or tostring(prof);
        if profName == "respawn:respawn" or profName == "respawn" or profName == "Respawn" or string.find(string.lower(profName), "respawn") then
            return true;
        end
    end

    if player.HasTrait then
        if player:HasTrait("respawn:respawn") or player:HasTrait("respawn") or player:HasTrait("Respawn") then
            return true;
        end
    end

    if player.getCharacterTraits and player:getCharacterTraits() then
        local ct = player:getCharacterTraits();
        if ct and ct.getKnownTraits then
            local kt = ct:getKnownTraits();
            if kt and kt.size and kt.get then
                for i = 0, kt:size() - 1 do
                    local t = kt:get(i);
                    local tName = (t and t.getName and t:getName()) or tostring(t);
                    if string.find(string.lower(tName), "respawn") then
                        return true;
                    end
                end
            end
        end
    end

    return false;
end

function Respawn.LoadPlayer(player)
    if not player or not Respawn.HasRespawnProfession(player) then
        return;
    end

    print("[Respawn] Starting LoadPlayer for: " .. tostring(player:getUsername()));

    for _, recoverable in ipairs(Respawn.Recoverables) do
        local ok, err = pcall(function() recoverable:Load(player); end);
        if not ok then
            print("[Respawn ERROR] Failed to load recoverable: " .. tostring(err));
        end
    end

    local available = Respawn.File.Load(Respawn.AvailablePath);
    if available then
        available[Respawn.GetUserID(player)] = nil;
        available[Respawn.GetUserID()] = nil;
        Respawn.File.Save(Respawn.AvailablePath, available);
    end

    print("[Respawn] Finished LoadPlayer successfully.");
end
