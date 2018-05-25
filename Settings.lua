local addon = Unboxer

local AddSettingOptions
local AddSettingsForFilterCategory
local DisableWritCreaterAutoloot
local UpgradeSettings

----------------- Settings -----------------------
function addon:SetupSettings()
    local LAM2 = LibStub("LibAddonMenu-2.0")
    
    self.defaults = 
    {
        autoloot = tonumber(GetSetting(SETTING_TYPE_LOOT,LOOT_SETTING_AUTO_LOOT)) ~= 0,
        reservedSlots = 0,
        verbose = true,
        other = true,
        monster = true,
        armor = true,
        weapons = true,
        jewelry = true,
        overworld = true,
        dungeon = true,
        cyrodiil = true,
        imperialCity = true,
        battlegrounds = true,
        darkBrotherhood = true,
        nonSet = true,
        consumables = true,
        enchantments = true,
        festival = true,
        generic = true,
        rewards = true,
        runeBoxes = true,
        treasureMaps = true,
        transmutation = true,
        alchemy = true,
        blacksmithing = true,
        clothier = true,
        enchanting = true,
        jewelrycrafting = true,
        provisioning = true,
        woodworking = true,
        furnisher = true,
        mageGuildReprints = true,
    }
    
    for filterCategory, subfilters in pairs(self.filters) do
       for settingName in pairs(subfilters) do
            if not self.defaults[settingName] then
                self.defaults[settingName] = false
            end
            self.defaults[settingName .. "Autoloot"] = self.defaults[settingName]
            self.defaults[settingName .. "Summary"] = false
        end
    end

    self.settings = ZO_SavedVars:NewAccountWide("Unboxer_Data", 1, nil, self.defaults)
    UpgradeSettings(self.settings)

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
    LAM2:RegisterAddonPanel(self.name.."Options", panelData)

    local optionsTable = {
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
    
    AddSettingsForFilterCategory(optionsTable, "gear")
    AddSettingsForFilterCategory(optionsTable, "loot")
    AddSettingsForFilterCategory(optionsTable, "crafting", DisableWritCreaterAutoloot)
    AddSettingsForFilterCategory(optionsTable, "collectibles")
    AddSettingsForFilterCategory(optionsTable, "housing")
    AddSettingsForFilterCategory(optionsTable, "pts")
    AddSettingOptions(optionsTable, false, "other")
    
    LAM2:RegisterOptionControls(self.name.."Options", optionsTable)
end

local exampleFormat = GetString(SI_UNBOXER_TOOLTIP_EXAMPLE)
local exampleItemIds = {
    ["generic"] = 43757,
    ["weapons"] = 54397,
    ["jewelry"] = 76877,
    ["ptsConsumables"] = 71051,
}
AddSettingOptions = function(optionsTable, settingCategory, settingName, onAutolootSet)
    if not settingName then return end
    local title = GetString(_G[string.format("SI_UNBOXER_%s", settingName:upper())])
    local tooltip = GetString(_G[string.format("SI_UNBOXER_%s_TOOLTIP", settingName:upper())])
    if settingCategory and settingName then
        local exampleItemId
        if exampleItemIds[settingName] then
            exampleItemId = exampleItemIds[settingName]
        else
            exampleItemId = next(addon.filters[settingCategory][settingName])
        end
        tooltip = tooltip .. string.format(exampleFormat, exampleItemId)
    end
    local autolootSettingName = settingName .. "Autoloot"
    local summarySettingName = settingName .. "Summary"
    table.insert(optionsTable,
        {
            type     = "checkbox",
            name     = title,
            tooltip  = tooltip,
            getFunc  = function() 
                           return addon.settings[settingName] 
                       end,
            setFunc  = function(value) 
                           addon.settings[settingName] = value
                       end,
            default  = addon.defaults[settingName],
        })
    table.insert(optionsTable,
        {
            type     = "checkbox",
            name     = GetString(SI_UNBOXER_AUTOLOOT),
            tooltip  = GetString(SI_UNBOXER_AUTOLOOT_TOOLTIP),
            width    = "half",
            getFunc  = function() return addon.settings[autolootSettingName] end,
            setFunc  = function(value) 
                           addon.settings[autolootSettingName] = value
                           if onAutolootSet and type(onAutolootSet) == "function" then
                               onAutolootSet(value)
                           end
                       end,
            default  = addon.defaults[autolootSettingName],
            disabled = function() 
                           return not addon.settings.autoloot 
                                  or not addon.settings[settingName] 
                       end,
        })
    table.insert(optionsTable,
        {
            type     = "checkbox",
            name     = GetString(SI_UNBOXER_SUMMARY),
            tooltip  = GetString(SI_UNBOXER_SUMMARY_TOOLTIP),
            width    = "half",
            getFunc  = function() 
                           return addon.settings[summarySettingName] 
                       end,
            setFunc  = function(value) 
                           addon.settings[summarySettingName] = value 
                       end,
            default  = addon.defaults[summarySettingName],
            disabled = function() 
                           return not addon.settings[settingName] 
                       end,
        })
    
    if onAutolootSet and type(onAutolootSet) == "function" then
        onAutolootSet(addon.settings[settingName .. "Autoloot"])
    end
end

AddSettingsForFilterCategory = function(optionsTable, filterCategory, onAutolootSet)
    -- Sort filter names
    local filterNames = {}
    for filterName in pairs(addon.filters[filterCategory]) do 
        table.insert(filterNames, filterName) 
    end
    table.sort(filterNames)
    -- Add options for each filter name
    for _, filterName in ipairs(filterNames) do
        AddSettingOptions(optionsTable, filterCategory, filterName, onAutolootSet)
    end
end

local function disableWritCreaterSavedVarsAutoloot(savedVars)
    if not savedVars then return end
    local displayLazyWarning
    if not savedVars.ignoreAuto then
        savedVars.ignoreAuto = true
        displayLazyWarning = true
    end
    if savedVars.autoLoot then
        savedVars.autoLoot = false
        displayLazyWarning = true
    end
    if savedVars.lootContainerOnReceipt then
        savedVars.lootContainerOnReceipt = false
        displayLazyWarning = true
    end
    return displayLazyWarning
end

DisableWritCreaterAutoloot = function(value)
    if not value or not WritCreater then return end
    local displayLazyWarning = disableWritCreaterSavedVarsAutoloot(WritCreater.savedVars)
    local displayLazyWarningAccountWide = disableWritCreaterSavedVarsAutoloot(
        WritCreater.savedVarsAccountWide and WritCreater.savedVarsAccountWide.accountWideProfile)
    if displayLazyWarning or displayLazyWarningAccountWide then
        addon.d("Disabled autoloot settings for |r"..tostring(WritCreater.settings["panel"].displayName))
    end
end

local function RenameSetting(settings, oldSetting, newSetting)
    if settings[oldSetting] == nil then 
        return
    end
    settings[newSetting] = settings[oldSetting]
    settings[oldSetting] = nil
end

local function RenameSettingAndSummary(settings, oldSetting, newSetting)
    RenameSetting(settings, oldSetting, newSetting)
    RenameSetting(settings, oldSetting .. "Summary", newSetting .. "Summary")
end

UpgradeSettings = function(settings)
    if not settings.dataVersion then
        settings.dataVersion = 1
        RenameSettingAndSummary(settings, "accessories", "jewelry")
        RenameSettingAndSummary(settings, "potions", "consumables")
        RenameSettingAndSummary(settings, "giftBoxes", "festival")
        RenameSettingAndSummary(settings, "gunnySacks", "generic")
        RenameSettingAndSummary(settings, "alchemist", "alchemy")
        RenameSettingAndSummary(settings, "blacksmith", "blacksmithing")
        RenameSettingAndSummary(settings, "enchanter", "enchanting")
        RenameSettingAndSummary(settings, "provisioner", "provisioning")
        RenameSettingAndSummary(settings, "woodworker", "woodworking")
        RenameSettingAndSummary(settings, "runeBoxes", "runeboxes")
        
        for filterCategory, subfilters in pairs(addon.filters) do
           for settingName in pairs(subfilters) do
               settings[settingName.."Autoloot"] = settings[settingName]
            end
        end
        settings.otherAutoloot = settings.other
    end
end