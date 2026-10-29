RecoverableRecipes = {};

function RecoverableRecipes:Save(player)
    Respawn.Data.Stats.Recipes = {};

    local recipes = player:getKnownRecipes();
    for i = 0, recipes:size() - 1 do
        table.insert(Respawn.Data.Stats.Recipes, recipes:get(i));
    end
end

function RecoverableRecipes:Load(player)
    local recipes = player:getKnownRecipes();

    for i, recipe in ipairs(Respawn.Data.Stats.Recipes) do
        recipes:add(recipe);
    end
end