Respawn = {};

Respawn.Id = "respawn";
Respawn.Name = "Respawn";
Respawn.FullId = "respawn:respawn";

Respawn.OptionsPath = "respawn-options.json";
Respawn.AvailablePath = "respawn-available.json";

Respawn.Data = {};
Respawn.Data.Stats = {};
Respawn.Data.Options = {};

function Respawn.GetModDataStatsKey(player)
    return Respawn.Id..'-'..Respawn.GetUserID(player);
end

function Respawn.GetModDataOptionsKey()
    return Respawn.Id..'-options';
end

function Respawn.GetUserID(player)
    local world = (getWorld() and getWorld():getWorld()) or "default";
    if isClient() then
        local username = getClientUsername();
        if username and username ~= "" then
            return "player-"..world.."-"..username;
        end
    elseif isServer() and player then
        local username = player:getUsername();
        if username and username ~= "" then
            return "player-"..world.."-"..username;
        end
    end
    return "player-"..world;
end

function Respawn.GetLogName()
    return isClient() and "respawn-client" or "respawn-server";
end

local function SafeSetProfessionDescription()
    if BaseGameCharacterDetails and BaseGameCharacterDetails.SetProfessionDescription then
        local Original_SetProfessionDescription = BaseGameCharacterDetails.SetProfessionDescription;
        BaseGameCharacterDetails.SetProfessionDescription = function(professionDefinition)
            if not professionDefinition then return end
            local status, err = pcall(Original_SetProfessionDescription, professionDefinition);
            if not status then
                if professionDefinition.getDescription and (professionDefinition:getDescription() == nil or professionDefinition:getDescription() == "") then
                    local uiName = professionDefinition:getUIName() or "Respawn";
                    professionDefinition:setDescription(uiName);
                end
            end
        end
    end
end

SafeSetProfessionDescription();