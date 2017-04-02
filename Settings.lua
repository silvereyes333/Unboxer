local addon = Unboxer

----------------- Settings -----------------------
function addon:SetupSettings()
    local LAM2 = LibStub("LibAddonMenu-2.0")
    if not LAM2 then return end

    local panelData = {
        type = "panel",
        name = addon.title,
        displayName = addon.title,
        author = addon.author,
        version = addon.version,
        slashCommand = "/unboxer",
        -- registerForRefresh = true,
        registerForDefaults = true,
    }
    LAM2:RegisterAddonPanel(addon.name.."Options", panelData)

    local optionsTable = {
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_VERBOSE),
            tooltip = GetString(SI_UNBOXER_VERBOSE_TOOLTIP),
            getFunc = function() return addon.settings.verbose end,
            setFunc = function(value) addon.settings.verbose = value end,
            default = self.defaults.verbose,
        },
        
        --[ GEAR ]--
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_MONSTER),
            tooltip = GetString(SI_UNBOXER_MONSTER_TOOLTIP),
            getFunc = function() return addon.settings.monster end,
            setFunc = function(value) addon.settings.monster = value end,
            default = self.defaults.monster,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_ARMOR),
            tooltip = GetString(SI_UNBOXER_ARMOR_TOOLTIP),
            getFunc = function() return addon.settings.armor end,
            setFunc = function(value) addon.settings.armor = value end,
            default = self.defaults.armor,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_WEAPONS),
            tooltip = GetString(SI_UNBOXER_WEAPONS_TOOLTIP),
            getFunc = function() return addon.settings.weapons end,
            setFunc = function(value) addon.settings.weapons = value end,
            default = self.defaults.weapons,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_ACCESSORIES),
            tooltip = GetString(SI_UNBOXER_ACCESSORIES_TOOLTIP),
            getFunc = function() return addon.settings.accessories end,
            setFunc = function(value) addon.settings.accessories = value end,
            default = self.defaults.accessories,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_OVERWORLD),
            tooltip = GetString(SI_UNBOXER_OVERWORLD_TOOLTIP),
            getFunc = function() return addon.settings.overworld end,
            setFunc = function(value) addon.settings.overworld = value end,
            default = self.defaults.overworld,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_DUNGEON),
            tooltip = GetString(SI_UNBOXER_DUNGEON_TOOLTIP),
            getFunc = function() return addon.settings.dungeon end,
            setFunc = function(value) addon.settings.dungeon = value end,
            default = self.defaults.dungeon,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_TRIALS),
            tooltip = GetString(SI_UNBOXER_TRIALS_TOOLTIP),
            getFunc = function() return addon.settings.trials end,
            setFunc = function(value) addon.settings.trials = value end,
            default = self.defaults.trials,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_CYRODIIL),
            tooltip = GetString(SI_UNBOXER_CYRODIIL_TOOLTIP),
            getFunc = function() return addon.settings.cyrodiil end,
            setFunc = function(value) addon.settings.cyrodiil = value end,
            default = self.defaults.cyrodiil,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_IC),
            tooltip = GetString(SI_UNBOXER_IC_TOOLTIP),
            getFunc = function() return addon.settings.imperialCity end,
            setFunc = function(value) addon.settings.imperialCity = value end,
            default = self.defaults.imperialCity,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_DB),
            tooltip = GetString(SI_UNBOXER_DB_TOOLTIP),
            getFunc = function() return addon.settings.darkBrotherhood end,
            setFunc = function(value) addon.settings.darkBrotherhood = value end,
            default = self.defaults.darkBrotherhood,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_NONSET),
            tooltip = GetString(SI_UNBOXER_NONSET_TOOLTIP),
            getFunc = function() return addon.settings.nonSet end,
            setFunc = function(value) addon.settings.nonSet = value end,
            default = self.defaults.nonSet,
        },
        
        
        
        --[ LOOT ]--
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_REWARDS),
            tooltip = GetString(SI_UNBOXER_REWARDS_TOOLTIP),
            getFunc = function() return addon.settings.rewards end,
            setFunc = function(value) addon.settings.rewards = value end,
            default = self.defaults.rewards,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_GENERIC),
            tooltip = GetString(SI_UNBOXER_GENERIC_TOOLTIP),
            getFunc = function() return addon.settings.gunnySacks end,
            setFunc = function(value) addon.settings.gunnySacks = value end,
            default = self.defaults.gunnySacks,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_GIFTBOXES),
            tooltip = GetString(SI_UNBOXER_GIFTBOXES_TOOLTIP),
            getFunc = function() return addon.settings.giftBoxes end,
            setFunc = function(value) addon.settings.giftBoxes = value end,
            default = self.defaults.giftBoxes,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_RUNEBOXES),
            tooltip = GetString(SI_UNBOXER_RUNEBOXES_TOOLTIP),
            getFunc = function() return addon.settings.runeBoxes end,
            setFunc = function(value) addon.settings.runeBoxes = value end,
            default = self.defaults.runeBoxes,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_ENCHANTMENTS),
            tooltip = GetString(SI_UNBOXER_ENCHANTMENTS_TOOLTIP),
            getFunc = function() return addon.settings.enchantments end,
            setFunc = function(value) addon.settings.enchantments = value end,
            default = self.defaults.enchantments,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_CONSUMABLES),
            tooltip = GetString(SI_UNBOXER_CONSUMABLES_TOOLTIP),
            getFunc = function() return addon.settings.potions end,
            setFunc = function(value) addon.settings.potions = value end,
            default = self.defaults.potions,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_THIEF),
            tooltip = GetString(SI_UNBOXER_THIEF_TOOLTIP),
            getFunc = function() return addon.settings.thief end,
            setFunc = function(value) addon.settings.thief = value end,
            default = self.defaults.thief,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_MAPS),
            tooltip = GetString(SI_UNBOXER_MAPS_TOOLTIP),
            getFunc = function() return addon.settings.treasureMaps end,
            setFunc = function(value) addon.settings.treasureMaps = value end,
            default = self.defaults.treasureMaps,
        },
        
        
        
        --[ CRAFTING ]--
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_ALCHEMIST),
            tooltip = GetString(SI_UNBOXER_ALCHEMIST_TOOLTIP),
            getFunc = function() return addon.settings.alchemist end,
            setFunc = function(value) addon.settings.alchemist = value end,
            default = self.defaults.alchemist,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_BLACKSMITH),
            tooltip = GetString(SI_UNBOXER_BLACKSMITH_TOOLTIP),
            getFunc = function() return addon.settings.blacksmith end,
            setFunc = function(value) addon.settings.blacksmith = value end,
            default = self.defaults.blacksmith,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_CLOTHIER),
            tooltip = GetString(SI_UNBOXER_CLOTHIER_TOOLTIP),
            getFunc = function() return addon.settings.clothier end,
            setFunc = function(value) addon.settings.clothier = value end,
            default = self.defaults.clothier,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_ENCHANTER),
            tooltip = GetString(SI_UNBOXER_ENCHANTER_TOOLTIP),
            getFunc = function() return addon.settings.enchanter end,
            setFunc = function(value) addon.settings.enchanter = value end,
            default = self.defaults.enchanter,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_PROVISIONER),
            tooltip = GetString(SI_UNBOXER_PROVISIONER_TOOLTIP),
            getFunc = function() return addon.settings.provisioner end,
            setFunc = function(value) addon.settings.provisioner = value end,
            default = self.defaults.provisioner,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_WOODWORKER),
            tooltip = GetString(SI_UNBOXER_WOODWORKER_TOOLTIP),
            getFunc = function() return addon.settings.woodworker end,
            setFunc = function(value) addon.settings.woodworker = value end,
            default = self.defaults.woodworker,
        },
        
        --[ HOUSING ]--
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_FURNISHER),
            tooltip = GetString(SI_UNBOXER_FURNISHER_TOOLTIP),
            getFunc = function() return addon.settings.furnisher end,
            setFunc = function(value) addon.settings.furnisher = value end,
            default = self.defaults.furnisher,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_MG_REPRINTS),
            tooltip = GetString(SI_UNBOXER_MG_REPRINTS_TOOLTIP),
            getFunc = function() return addon.settings.mageGuildReprints end,
            setFunc = function(value) addon.settings.mageGuildReprints = value end,
            default = self.defaults.mageGuildReprints,
        },
        
        --[ PTS ]--
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_PTS_COLLECT),
            tooltip = GetString(SI_UNBOXER_PTS_COLLECT_TOOLTIP),
            getFunc = function() return addon.settings.ptsCollectibles end,
            setFunc = function(value) addon.settings.ptsCollectibles = value end,
            default = self.defaults.ptsCollectibles,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_PTS_CONSUME),
            tooltip = GetString(SI_UNBOXER_PTS_CONSUME_TOOLTIP),
            getFunc = function() return addon.settings.ptsConsumables end,
            setFunc = function(value) addon.settings.ptsConsumables = value end,
            default = self.defaults.ptsConsumables,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_PTS_CRAFTING),
            tooltip = GetString(SI_UNBOXER_PTS_CRAFTING_TOOLTIP),
            getFunc = function() return addon.settings.ptsCrafting end,
            setFunc = function(value) addon.settings.ptsCrafting = value end,
            default = self.defaults.ptsCrafting,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_PTS_CURRENCY),
            tooltip = GetString(SI_UNBOXER_PTS_CURRENCY_TOOLTIP),
            getFunc = function() return addon.settings.ptsCurrency end,
            setFunc = function(value) addon.settings.ptsCurrency = value end,
            default = self.defaults.ptsCurrency,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_PTS_GEAR),
            tooltip = GetString(SI_UNBOXER_PTS_GEAR_TOOLTIP),
            getFunc = function() return addon.settings.ptsGear end,
            setFunc = function(value) addon.settings.ptsGear = value end,
            default = self.defaults.ptsGear,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_PTS_HOUSING),
            tooltip = GetString(SI_UNBOXER_PTS_HOUSING_TOOLTIP),
            getFunc = function() return addon.settings.ptsHousing end,
            setFunc = function(value) addon.settings.ptsHousing = value end,
            default = self.defaults.ptsHousing,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_PTS_SKILLS),
            tooltip = GetString(SI_UNBOXER_PTS_SKILLS_TOOLTIP),
            getFunc = function() return addon.settings.ptsSkills end,
            setFunc = function(value) addon.settings.ptsSkills = value end,
            default = self.defaults.ptsSkills,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_PTS_OTHER),
            tooltip = GetString(SI_UNBOXER_PTS_OTHER_TOOLTIP),
            getFunc = function() return addon.settings.ptsOther end,
            setFunc = function(value) addon.settings.ptsOther = value end,
            default = self.defaults.ptsOther,
        },
        
        --[ OTHER ]--
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_OTHER),
            tooltip = GetString(SI_UNBOXER_OTHER_TOOLTIP),
            getFunc = function() return addon.settings.other end,
            setFunc = function(value) addon.settings.other = value end,
            default = self.defaults.other,
        },
    }
    LAM2:RegisterOptionControls(addon.name.."Options", optionsTable)
end