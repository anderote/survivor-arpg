local Original_Create = CharacterCreationProfession.create;
local Original_SetVisible = CharacterCreationProfession.setVisible;
local Profession;

local function CreateRespawnTrait()
    TraitFactory.addTrait(Respawn.Id, Respawn.Name, 0, "Reject zombiehood", true, false);

    local traits = TraitFactory.getTraits();
    for i = 0, traits:size() - 1 do
        TraitFactory.setMutualExclusive(Respawn.Id, traits:get(i):getType());
    end
end

local function CreateRespawnProfession()
    local prof = ProfessionFactory.addProfession(Respawn.Id, Respawn.Name, "", 0);
    
    CreateRespawnTrait();
    prof:addFreeTrait(Respawn.Id);

    return prof;
end

local function GetRespawnAvailable()
    local available = Respawn.File.Load(Respawn.AvailablePath);

    return available and available[Respawn.GetUserID()];
end

function CharacterCreationProfession:create()
    Original_Create(self);

    Profession = CreateRespawnProfession();
end

function CharacterCreationProfession:setVisible(visible, joypadData)
    Original_SetVisible(self, visible, joypadData);

    if not visible then
        return;
    end

    self:removeRespawnProfession();

    if GetRespawnAvailable() then
        writeLog(Respawn.GetLogName(), "respawn available!");
        self:addRespawnProfession();
    end
end

function CharacterCreationProfession:addRespawnProfession()
    self.listboxProf:insertItem(0, Respawn.Id, Profession);
    self:onSelectProf(Profession);
end

function CharacterCreationProfession:removeRespawnProfession()
    self.listboxProf:removeItem(Respawn.Id);

    self.listboxProf.selected = 1;
    self:onSelectProf(self.listboxProf.items[1].item);
end