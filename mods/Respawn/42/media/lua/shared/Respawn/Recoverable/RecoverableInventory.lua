RecoverableInventory = {};

local function SerializeItem(item)
    if not item then return nil end

    local itemData = {
        fullType = item.getFullType and item:getFullType() or nil,
        condition = item.getCondition and item:getCondition() or nil,
        favorite = item.isFavorite and item:isFavorite() or nil,
        uses = (item.getUses and item:getUses()) or nil,
    };

    if not itemData.fullType then return nil end

    if item.isCustomName and item:isCustomName() and item.getName and item:getName() then
        itemData.customName = item:getName();
    end

    if item.isCustomColor and item:isCustomColor() then
        pcall(function()
            itemData.colorRed = item:getColorRed();
            itemData.colorGreen = item:getColorGreen();
            itemData.colorBlue = item:getColorBlue();
        end);
    end

    pcall(function()
        if (instanceof(item, "DrainableComboItem") or instanceof(item, "Drainable")) and item.getUsedDelta then
            itemData.usedDelta = item:getUsedDelta();
        end
    end);

    pcall(function()
        if instanceof(item, "Food") then
            if item.getHungerChange then itemData.hungerChange = item:getHungerChange(); end
            if item.getCalories then itemData.calories = item:getCalories(); end
            if item.getCarbohydrates then itemData.carbohydrates = item:getCarbohydrates(); end
            if item.getLipids then itemData.lipids = item:getLipids(); end
            if item.getProteins then itemData.proteins = item:getProteins(); end
            if item.getAge then itemData.age = item:getAge(); end
            if item.isCooked then itemData.cooked = item:isCooked(); end
            if item.isBurnt then itemData.burnt = item:isBurnt(); end
        end
    end);

    pcall(function()
        if instanceof(item, "Key") and item.getKeyId then
            itemData.keyId = item:getKeyId();
        end
    end);

    pcall(function()
        local isContainer = (item.IsInventoryContainer and item:IsInventoryContainer()) or 
                            (item.isInventoryContainer and item:isInventoryContainer()) or 
                            instanceof(item, "InventoryContainer");
        if isContainer and item.getItemContainer then
            local container = item:getItemContainer();
            if container and container.getItems then
                local subItems = container:getItems();
                if subItems and subItems.size and subItems.get then
                    itemData.containerItems = {};
                    for j = 0, subItems:size() - 1 do
                        local childItem = subItems:get(j);
                        local childData = SerializeItem(childItem);
                        if childData then
                            table.insert(itemData.containerItems, childData);
                        end
                    end
                end
            end
        end
    end);

    return itemData;
end

local function DeserializeItem(itemData, targetContainer)
    if not itemData or not itemData.fullType then return nil end

    local item = nil;
    pcall(function()
        if InventoryItemFactory and InventoryItemFactory.CreateItem then
            item = InventoryItemFactory.CreateItem(itemData.fullType);
        end
    end);
    if not item then
        pcall(function()
            item = instanceItem(itemData.fullType);
        end);
    end
    if not item then return nil end

    if itemData.condition and item.setCondition then
        pcall(function() item:setCondition(itemData.condition); end);
    end

    if itemData.favorite ~= nil and item.setFavorite then
        pcall(function() item:setFavorite(itemData.favorite); end);
    end

    if itemData.uses and item.setUses then
        pcall(function() item:setUses(itemData.uses); end);
    end

    if itemData.customName and item.setName then
        pcall(function()
            item:setName(itemData.customName);
            if item.setCustomName then item:setCustomName(true); end
        end);
    end

    if itemData.colorRed and itemData.colorGreen and itemData.colorBlue and item.setColorRed then
        pcall(function()
            item:setColorRed(itemData.colorRed);
            item:setColorGreen(itemData.colorGreen);
            item:setColorBlue(itemData.colorBlue);
            if item.setCustomColor then item:setCustomColor(true); end
        end);
    end

    if itemData.usedDelta and item.setUsedDelta then
        pcall(function() item:setUsedDelta(itemData.usedDelta); end);
    end

    if instanceof(item, "Food") then
        pcall(function()
            if itemData.hungerChange and item.setHungerChange then item:setHungerChange(itemData.hungerChange); end
            if itemData.calories and item.setCalories then item:setCalories(itemData.calories); end
            if itemData.carbohydrates and item.setCarbohydrates then item:setCarbohydrates(itemData.carbohydrates); end
            if itemData.lipids and item.setLipids then item:setLipids(itemData.lipids); end
            if itemData.proteins and item.setProteins then item:setProteins(itemData.proteins); end
            if itemData.age and item.setAge then item:setAge(itemData.age); end
            if itemData.cooked and item.setCooked then item:setCooked(true); end
            if itemData.burnt and item.setBurnt then item:setBurnt(true); end
        end);
    end

    if instanceof(item, "Key") and itemData.keyId and item.setKeyId then
        pcall(function() item:setKeyId(itemData.keyId); end);
    end

    if targetContainer and targetContainer.AddItem then
        pcall(function() targetContainer:AddItem(item); end);
    end

    if itemData.containerItems and item.getItemContainer then
        pcall(function()
            local childContainer = item:getItemContainer();
            if childContainer and childContainer.clear and childContainer.AddItem then
                childContainer:clear();
                for _, childData in ipairs(itemData.containerItems) do
                    DeserializeItem(childData, childContainer);
                end
            end
        end);
    end

    return item;
end

function RecoverableInventory:Save(player)
    Respawn.Data.Stats.Inventory = {};

    local restoreInv = true;
    if Respawn.Data and Respawn.Data.Options and Respawn.Data.Options.RestoreInventory ~= nil then
        restoreInv = Respawn.Data.Options.RestoreInventory;
    end

    if not restoreInv then
        print("[Respawn] RestoreInventory option is disabled; skipping inventory save.");
        return;
    end

    local inv = player:getInventory();
    if not inv then return end

    local items = inv:getItems();
    if not items then return end

    for i = 0, items:size() - 1 do
        local item = items:get(i);
        if item then
            local ok, data = pcall(function() return SerializeItem(item); end);
            if ok and data then
                pcall(function()
                    if player.isHandItem and player:isHandItem(item) then
                        if player.getPrimaryHandItem and player:getPrimaryHandItem() == item then
                            data.equippedHand = "primary";
                        elseif player.getSecondaryHandItem and player:getSecondaryHandItem() == item then
                            data.equippedHand = "secondary";
                        end
                    end
                end);

                pcall(function()
                    local wornLocation = nil;
                    if player.getWornItems then
                        local wornItems = player:getWornItems();
                        if wornItems and wornItems.size and wornItems.get then
                            for w = 0, wornItems:size() - 1 do
                                local wornItem = wornItems:get(w);
                                if wornItem and wornItem.getItem and wornItem:getItem() == item then
                                    if wornItem.getLocation then
                                        wornLocation = wornItem:getLocation();
                                    end
                                    break;
                                end
                            end
                        end
                    end
                    if not wornLocation and item.isWorn and item:isWorn() and item.getBodyLocation then
                        wornLocation = item:getBodyLocation();
                    end
                    if wornLocation then
                        data.wornLocation = wornLocation;
                        data.isWorn = true;
                    end
                end);

                table.insert(Respawn.Data.Stats.Inventory, data);
            end
        end
    end

    print("[Respawn] Saved " .. tostring(#Respawn.Data.Stats.Inventory) .. " inventory items.");
end

function RecoverableInventory:Load(player)
    local restoreInv = true;
    if Respawn.Data and Respawn.Data.Options and Respawn.Data.Options.RestoreInventory ~= nil then
        restoreInv = Respawn.Data.Options.RestoreInventory;
    end

    if not restoreInv or not Respawn.Data.Stats or not Respawn.Data.Stats.Inventory then
        return;
    end

    local inv = player:getInventory();
    if not inv then return end

    print("[Respawn] Restoring " .. tostring(#Respawn.Data.Stats.Inventory) .. " saved inventory items...");

    if #Respawn.Data.Stats.Inventory > 0 then
        pcall(function() inv:clear(); end);
        if player.getWornItems and player:getWornItems() then
            pcall(function() player:getWornItems():clear(); end);
        end
    end

    for _, itemData in ipairs(Respawn.Data.Stats.Inventory) do
        local ok, item = pcall(function() return DeserializeItem(itemData, inv); end);
        if ok and item then
            pcall(function()
                if itemData.wornLocation and player.setWornItem then
                    player:setWornItem(itemData.wornLocation, item);
                elseif itemData.isWorn and item.getBodyLocation and item:getBodyLocation() and player.setWornItem then
                    player:setWornItem(item:getBodyLocation(), item);
                elseif itemData.equippedHand == "primary" and player.setPrimaryHandItem then
                    player:setPrimaryHandItem(item);
                elseif itemData.equippedHand == "secondary" and player.setSecondaryHandItem then
                    player:setSecondaryHandItem(item);
                end
            end);
        end
    end
end
