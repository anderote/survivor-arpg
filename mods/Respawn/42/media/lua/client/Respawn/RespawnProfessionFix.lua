function CharacterCreationProfession:resetBuild()
    local index = self:getUnemployedProfessionIndex();

    self.listboxProf.selected = index;
    if self.listboxProf.items[self.listboxProf.selected] then
        self:onSelectProf(self.listboxProf.items[self.listboxProf.selected].item);
    end

    if self.removeAllTraits then
        self:removeAllTraits();
    else
        while #self.listboxTraitSelected.items > 0 do
            self.listboxTraitSelected.selected = 1;
            self:onOptionMouseDown(self.removeTraitBtn);
        end
    end
    self:checkXPBoost();
    self.listboxTraitSelected.selected = -1;
end

function CharacterCreationProfession:resetTraits()
    local index = self:getUnemployedProfessionIndex();
    
    if self.listboxProf.items[index] then
        self:onSelectProf(self.listboxProf.items[index].item);
    end

    if self.removeAllTraits then
        self:removeAllTraits();
    else
        while #self.listboxTraitSelected.items > 0 do
            self.listboxTraitSelected.selected = 1;
            self:onOptionMouseDown(self.removeTraitBtn);
        end
    end

    if self.listboxProf.items[self.listboxProf.selected] then
        self:onSelectProf(self.listboxProf.items[self.listboxProf.selected].item);
    end
end

function CharacterCreationProfession:getUnemployedProfessionIndex()
    for index, item in ipairs(self.listboxProf.items) do
        if item.item and item.item:getType() == CharacterProfession.UNEMPLOYED then
            return index;
        end
    end
    return 1;
end