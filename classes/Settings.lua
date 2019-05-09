local addon = Unboxer
local LibSavedVars = LibStub("LibSavedVars")
local LAM2 = LibAddonMenu2 or LibStub("LibAddonMenu-2.0")

-- Local functions
local setAutolootDefaults

-- Local variables
local debug = false
local exampleFormat = GetString(SI_UNBOXER_TOOLTIP_EXAMPLE)
local renamedSettings, removedSettings

----------------- Settings -----------------------
function addon:SetupSettings()
    
    self.Debug("SetupSettings()", debug)
    
    self.defaults = 
    {
        autoloot = tonumber(GetSetting(SETTING_TYPE_LOOT,LOOT_SETTING_AUTO_LOOT)) ~= 0,
        autolootDelay = 2,
        reservedSlots = 0,
        verbose = true,
    }
    
    for _, rule in ipairs(self.rules) do
        if not self.defaults[rule.name] then
            self.defaults[rule.name] = false
        end
        self.defaults[rule.autolootSettingName] = self.defaults[rule.name]
        self.defaults[rule.summarySettingName] = false
    end

    self.settings =
      LibSavedVars:NewAccountWide(self.name .. "_Account", self.defaults)
                  :AddCharacterSettingsToggle(self.name .. "_Character")
                  :RenameSettings(4, renamedSettings)
                  :RemoveSettings(4, removedSettings)
    
    local panelData = {
        type = "panel",
        name = addon.title,
        displayName = addon.title,
        author = addon.author,
        version = addon.version,
        slashCommand = "/unboxer",
        registerForRefresh = true,
        registerForDefaults = true,
    }
  
    self.optionsTable = {
        
        -- Account-wide settings
        self.settings:GetLibAddonMenuAccountCheckbox(),
        
        -- Verbose
        {
            type    = "checkbox",
            name    = GetString(SI_UNBOXER_VERBOSE),
            tooltip = GetString(SI_UNBOXER_VERBOSE_TOOLTIP),
            getFunc = function() return self.settings.verbose end,
            setFunc = function(value) self.settings.verbose = value end,
            default = self.defaults.verbose,
        },
        -- Autoloot
        {
            type    = "checkbox",
            name    = GetString(SI_UNBOXER_AUTOLOOT_GLOBAL),
            tooltip = GetString(SI_UNBOXER_AUTOLOOT_GLOBAL_TOOLTIP),
            getFunc = function() return self.settings.autoloot end,
            setFunc = function(value) self.settings.autoloot = value end,
            default = self.defaults.autoloot,
        },
        -- Autoloot delay
        {
            type    = "slider",
            name    = GetString(SI_UNBOXER_AUTOLOOT_DELAY),
            tooltip = GetString(SI_UNBOXER_AUTOLOOT_DELAY_TOOLTIP),
            min     = 0,
            max     = 20,
            getFunc = function() return self.settings.autolootDelay end,
            setFunc = function(value) self.settings.autolootDelay = value end,
            default = self.defaults.autolootDelay,
            disabled = function() return not addon.settings.autoloot end,
        },
        -- Reserved slots
        {
            type = "slider",
            name = zo_strformat(GetString(SI_UNBOXER_RESERVED_SLOTS), GetString(SI_BINDING_NAME_UNBOX_ALL)),
            tooltip = zo_strformat(GetString(SI_UNBOXER_RESERVED_SLOTS_TOOLTIP), GetString(SI_BINDING_NAME_UNBOX_ALL)),
            getFunc = function() return self.settings.reservedSlots end,
            setFunc = function(value) self.settings.reservedSlots = value end,
            min = 0,
            max = 200,
            step = 1,
            clampInput = true,
            width = "full",
            default = self.defaults.reservedSlots,
        },
    }
    
    self.firstSubmenuOptionIndex = #self.optionsTable + 1
    
    LAM2:RegisterAddonPanel(self.name.."Options", panelData)
    
    LAM2:RegisterOptionControls(self.name.."Options", self.optionsTable)
    
    self:RegisterEvents()
end

----------------------------------------------------------------------------
--
--       Local methods
-- 
----------------------------------------------------------------------------


function setAutolootDefaults(sv)
    for _, settingName in pairs(renamedSettings) do
        if not find(settingName, "Summary") then
            sv[settingName.."Autoloot"] = sv[settingName]
        end
    end
    sv.otherAutoloot = sv.other
end

renamedSettings = {
    ["giftBoxes"]                  = "festival",
    ["gunnySacks"]                 = "fishing",
    ["runeBoxes"]                  = "runeboxes",
    ["mageGuildReprints"]          = "reprints",
    ["thief"]                      = "legerdemain",
    ["treasureMaps"]               = "treasuremaps",
    ["giftBoxesSummary"]           = "festivalSummary",
    ["gunnySacksSummary"]          = "fishingSummary",
    ["runeBoxesSummary"]           = "runeboxesSummary",
    ["mageGuildReprintsSummary"]   = "reprintsSummary",
    ["thiefSummary"]               = "legerdemainSummary",
    ["treasuremapsSummary"]        = "treasuremapsSummary",
    ["mageGuildReprintsAutoloot"]  = "reprintsAutoloot",
    ["thiefAutoloot"]              = "legerdemainAutoloot",
    ["treasuremapsAutoloot"]       = "treasuremapsAutoloot",
}

removedSettings = {
    "accessories",
    "accessoriesSummary",
    "alchemist",
    "alchemistSummary",
    "alchemy",
    "alchemy",
    "alchemyAutoloot",
    "alchemySummary",
    "armor",
    "armorAutoloot",
    "armorSummary",
    "autoloot",
    "battlegrounds",
    "battlegroundsAutoloot",
    "battlegroundsSummary",
    "blacksmith",
    "blacksmithSummary",
    "blacksmithing",
    "blacksmithingAutoloot",
    "blacksmithingSummary",
    "clothier",
    "clothierAutoloot",
    "clothierSummary",
    "consumables",
    "consumablesAutoloot",
    "consumablesSummary",
    "cyrodiil",
    "cyrodiilAutoloot",
    "cyrodiilSummary",
    "darkBrotherhood",
    "darkBrotherhoodAutoloot",
    "darkBrotherhoodSummary",
    "dataVersion",
    "enchanter",
    "enchanterSummary",
    "enchanting",
    "enchantingAutoloot",
    "enchantingSummary",
    "enchantments",
    "enchantmentsAutoloot",
    "enchantmentsSummary",
    "imperialCity",
    "imperialCityAutoloot",
    "imperialCitySummary",
    "jewelry",
    "jewelryAutoloot",
    "jewelrySummary",
    "jewelrycrafting",
    "jewelrycraftingAutoloot",
    "jewelrycraftingSummary",
    "monster",
    "nonSet",
    "nonSetAutoloot",
    "nonSetSummary",
    "other",
    "otherAutoloot",
    "otherSummary",
    "overworld",
    "overworldAutoloot",
    "overworldSummary",
    "potions",
    "potionsSummary",
    "provisioner",
    "provisionerSummary",
    "provisioning",
    "provisioningAutoloot",
    "provisioningSummary",
    "ptsCollectibles",
    "ptsCollectiblesAutoloot",
    "ptsCollectiblesSummary",
    "ptsConsumables",
    "ptsConsumablesAutoloot",
    "ptsConsumablesSummary",
    "ptsCrafting",
    "ptsCraftingAutoloot",
    "ptsCraftingSummary",
    "ptsCurrency",
    "ptsCurrencyAutoloot",
    "ptsCurrencySummary",
    "ptsGear",
    "ptsGearAutoloot",
    "ptsGearSummary",
    "ptsHousing",
    "ptsHousingAutoloot",
    "ptsHousingSummary",
    "ptsOther",
    "ptsOtherAutoloot",
    "ptsOtherSummary",
    "ptsSkills",
    "ptsSkillsAutoloot",
    "ptsSkillsSummary",
    "rewards",
    "rewardsAutoloot",
    "rewardsSummary",
    "weapons",
    "weaponsAutoloot",
    "weaponsSummary",
    "woodworker",
    "woodworkerSummary",
    "woodworking",
    "woodworkingAutoloot",
    "woodworkingSummary",
}