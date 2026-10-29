require "Respawn/Respawn"
require "Respawn/RespawnOptions"

local MOD_ID = "Respawn"
local MOD_NAME = "UI_Respawn_ModName"

local function ApplyPZAPIOptions(options)
    if not options then return end

    local xpOption = options:getOption("XPRestored")
    if xpOption then
        Respawn.Data.Options.XPRestored = xpOption:getValue()
    end

    local fitOption = options:getOption("ExcludeFitness")
    if fitOption then
        Respawn.Data.Options.ExcludeFitness = fitOption:getValue()
    end

    local strOption = options:getOption("ExcludeStrength")
    if strOption then
        Respawn.Data.Options.ExcludeStrength = strOption:getValue()
    end

    local invOption = options:getOption("RestoreInventory")
    if invOption then
        Respawn.Data.Options.RestoreInventory = invOption:getValue()
    end
end

local function InitPZAPIOptions()
    if not PZAPI or not PZAPI.ModOptions then return end

    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if not options then
        options = PZAPI.ModOptions:create(MOD_ID, MOD_NAME)

        local xpCombo = options:addComboBox(
            "XPRestored",
            "UI_Respawn_Opt_XPRestored",
            "UI_Respawn_Opt_XPRestoredTooltip"
        )
        xpCombo:addItem("UI_Respawn_XP_5")
        xpCombo:addItem("UI_Respawn_XP_10")
        xpCombo:addItem("UI_Respawn_XP_15")
        xpCombo:addItem("UI_Respawn_XP_20")
        xpCombo:addItem("UI_Respawn_XP_25")
        xpCombo:addItem("UI_Respawn_XP_30")
        xpCombo:addItem("UI_Respawn_XP_35")
        xpCombo:addItem("UI_Respawn_XP_40")
        xpCombo:addItem("UI_Respawn_XP_45")
        xpCombo:addItem("UI_Respawn_XP_50")
        xpCombo:addItem("UI_Respawn_XP_55")
        xpCombo:addItem("UI_Respawn_XP_60")
        xpCombo:addItem("UI_Respawn_XP_65")
        xpCombo:addItem("UI_Respawn_XP_70")
        xpCombo:addItem("UI_Respawn_XP_75")
        xpCombo:addItem("UI_Respawn_XP_80")
        xpCombo:addItem("UI_Respawn_XP_85")
        xpCombo:addItem("UI_Respawn_XP_90")
        xpCombo:addItem("UI_Respawn_XP_95")
        xpCombo:addItem("UI_Respawn_XP_100")
        xpCombo:addItem("UI_Respawn_XP_Last", true)

        options:addTickBox(
            "ExcludeFitness",
            "UI_Respawn_Opt_ExcludeFitness",
            true,
            "UI_Respawn_Opt_ExcludeFitnessTooltip"
        )

        options:addTickBox(
            "ExcludeStrength",
            "UI_Respawn_Opt_ExcludeStrength",
            true,
            "UI_Respawn_Opt_ExcludeStrengthTooltip"
        )

        options:addTickBox(
            "RestoreInventory",
            "UI_Respawn_Opt_RestoreInventory",
            true,
            "UI_Respawn_Opt_RestoreInventoryTooltip"
        )

        options.apply = function(self)
            ApplyPZAPIOptions(self)
        end
    end

    ApplyPZAPIOptions(options)
end

InitPZAPIOptions()
Events.OnGameBoot.Add(InitPZAPIOptions)
