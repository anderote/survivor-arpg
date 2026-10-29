RecoverableRecipes = {};

function RecoverableRecipes:Save(player)
    Respawn.Data.Stats.Recipes = {};

    local recipes = player:getKnownRecipes();
    if recipes then
        for i = 0, recipes:size() - 1 do
            local recipe = recipes:get(i);
            if recipe then
                table.insert(Respawn.Data.Stats.Recipes, recipe);
            end
        end
    end
end

function RecoverableRecipes:Load(player)
    local recipes = player:getKnownRecipes();
    if recipes and Respawn.Data.Stats.Recipes then
        for _, recipe in ipairs(Respawn.Data.Stats.Recipes) do
            if not recipes:contains(recipe) then
                recipes:add(recipe);
            end
        end
    end
end