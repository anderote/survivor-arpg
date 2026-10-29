local Original_SetVisible = CharacterCreationProfession.setVisible;
local Original_PopulateProfessionList = CharacterCreationProfession.populateProfessionList;

local function GetRespawnAvailable()
    local available = Respawn.File.Load(Respawn.AvailablePath);
    return available and available[Respawn.GetUserID()];
end

function CharacterCreationProfession:populateProfessionList(list)
    Original_PopulateProfessionList(self, list);
    if not GetRespawnAvailable() then
        self:removeRespawnProfession();
    end
end

function CharacterCreationProfession:setVisible(visible, joypadData)
    Original_SetVisible(self, visible, joypadData);

    if not visible then
        return;
    end

    if GetRespawnAvailable() then
        writeLog(Respawn.GetLogName(), "respawn available!");
        self:addRespawnProfession();
    else
        self:removeRespawnProfession();
    end
end

function CharacterCreationProfession:addRespawnProfession()
    local respawnProf = CharacterProfession.get(ResourceLocation.of("respawn:respawn"));
    if not respawnProf then return end
    local respawnProfDef = CharacterProfessionDefinition.getCharacterProfessionDefinition(respawnProf);
    if not respawnProfDef then return end

    local foundIndex = nil;
    for i, item in ipairs(self.listboxProf.items) do
        if item.item and item.item:getType() == respawnProf then
            foundIndex = i;
            break;
        end
    end

    if not foundIndex then
        local newItem = {
            text = respawnProfDef:getUIName(),
            item = respawnProfDef,
            tooltip = respawnProfDef:getDescription()
        };
        table.insert(self.listboxProf.items, 1, newItem);
        foundIndex = 1;
    else
        if foundIndex > 1 then
            local item = table.remove(self.listboxProf.items, foundIndex);
            table.insert(self.listboxProf.items, 1, item);
            foundIndex = 1;
        end
    end

    self.listboxProf.selected = foundIndex;
    self:onSelectProf(respawnProfDef);
    if self.listboxProf.ensureVisible then
        self.listboxProf:ensureVisible(foundIndex);
    end
end

function CharacterCreationProfession:removeRespawnProfession()
    local respawnProf = CharacterProfession.get(ResourceLocation.of("respawn:respawn"));
    if not respawnProf then return end

    for i = #self.listboxProf.items, 1, -1 do
        local item = self.listboxProf.items[i];
        if item and item.item and item.item:getType() == respawnProf then
            table.remove(self.listboxProf.items, i);
        end
    end

    if #self.listboxProf.items > 0 then
        if self.listboxProf.selected > #self.listboxProf.items or (self.profession and self.profession:getType() == respawnProf) then
            self.listboxProf.selected = 1;
            if self.listboxProf.items[1] then
                self:onSelectProf(self.listboxProf.items[1].item);
            end
        end
    end
end