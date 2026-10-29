require "Respawn/Respawn"
require "Respawn/Recoverable/RecoverableOccupation"
require "Respawn/Recoverable/RecoverableTraits"
require "Respawn/Recoverable/RecoverableBoosts"
require "Respawn/Recoverable/RecoverableExperience"
require "Respawn/Recoverable/RecoverableRecipes"
require "Respawn/Recoverable/RecoverableWeight"
require "Respawn/Recoverable/RecoverableInventory"

Respawn.Recoverables = {};

local function AddRecoverable(recoverable)
    if recoverable then
        table.insert(Respawn.Recoverables, recoverable);
    end
end

AddRecoverable(RecoverableOccupation);
AddRecoverable(RecoverableTraits);
AddRecoverable(RecoverableBoosts);
AddRecoverable(RecoverableExperience);
AddRecoverable(RecoverableRecipes);
AddRecoverable(RecoverableWeight);
AddRecoverable(RecoverableInventory);