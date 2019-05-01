local addon = Unboxer
local LibSavedVars = LibStub("LibSavedVars")
local LAM2 = LibStub("LibAddonMenu-2.0")

-- Local functions
local addSettingOptions, addSettingsForFilterCategory, disableWritCreaterAutoloot, setAutolootDefaults

-- Local variables
local debug = false
local exampleFormat = GetString(SI_UNBOXER_TOOLTIP_EXAMPLE)
local exampleItemIds = {
    ["generic"] = 43757,
    ["weapons"] = 54397,
    ["jewelry"] = 76877,
    ["ptsConsumables"] = 71051,
    ["runeboxes"] = 79329,
    ["outfitstyles"] = 140308,
}
local renamedSettings

local optionsCreated = false
local onLamPanelEffectivelyShown
local function CreateOptionsOnLamPanelOpened(panel)
    
    local self = addon
    
    
    
    
    self.defaults = 
    {
        autoloot = tonumber(GetSetting(SETTING_TYPE_LOOT,LOOT_SETTING_AUTO_LOOT)) ~= 0,
        autolootDelay = 2,
        reservedSlots = 0,
        verbose = true,
        containerDetails = {},
    }
    
    -- TODO: 
    self.defaults.crafting = true
    self.defaults.dungeon = true
    self.defaults.festival = true
    self.defaults.furnisher = true
    self.defaults.materials = true
    self.defaults.outfitstyles = false
    self.defaults.reprints = true
    self.defaults.runeboxes = false
    self.defaults.transmutation = false
    self.defaults.treasureMaps = true
    self.defaults.trial = true
    self.defaults.unknown = true
    self.defaults.vendorGear = true
    self.defaults.zone = true
    
    for filterCategory, subfilters in pairs(self.filters) do
       for settingName in pairs(subfilters) do
            if not self.defaults[settingName] then
                self.defaults[settingName] = false
            end
            self.defaults[settingName .. "Autoloot"] = self.defaults[settingName]
            self.defaults[settingName .. "Summary"] = false
        end
    end

    self.settings =
      LibSavedVars:NewAccountWide(self.name .. "_Account", self.defaults)
                  :AddCharacterSettingsToggle(self.name .. "_Character")
                  :MigrateFromAccountWide( { name=self.name .. "_Data" } )
                  :RenameSettings(2, renamedSettings)
                  :Version(2, setAutolootDefaults)
                  :RemoveSettings(3, "dataVersion")
  
    local optionsTable = {
        
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
    
    addSettingsForFilterCategory(optionsTable, "gear")
    addSettingsForFilterCategory(optionsTable, "loot")
    addSettingsForFilterCategory(optionsTable, "crafting", disableWritCreaterAutoloot)
    -- collectibles
    addSettingOptions(optionsTable, "collectibles", "runeboxes")
    addSettingOptions(optionsTable, "collectibles", "outfitstyles")
    addSettingsForFilterCategory(optionsTable, "housing")
    addSettingsForFilterCategory(optionsTable, "pts")
    addSettingOptions(optionsTable, false, "other")
    
    LAM2:RegisterOptionControls(self.name.."Options", optionsTable)
    
    onLamPanelEffectivelyShown(panel)
end

----------------- Settings -----------------------
function addon:SetupSettings()
    
    self.Debug("SetupSettings()", debug)
    
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
    self.optionsPanel = LAM2:RegisterAddonPanel(self.name.."Options", panelData)
    
    -- Hook into the panel creation handler for LAM2
    onLamPanelEffectivelyShown = self.optionsPanel:GetHandler("OnEffectivelyShown")
    self.optionsPanel:SetHandler("OnEffectivelyShown", CreateOptionsOnLamPanelOpened)
    
    self:RegisterEvents()
end

----------------------------------------------------------------------------
--
--       Local methods
-- 
----------------------------------------------------------------------------


function addSettingOptions(optionsTable, settingCategory, settingName, onAutolootSet)
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
                               addon.Debug("auto loot set for "..settingName, debug)
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

function addSettingsForFilterCategory(optionsTable, filterCategory, onAutolootSet)
    -- Sort filter names
    local filterNames = {}
    for filterName in pairs(addon.filters[filterCategory]) do 
        table.insert(filterNames, filterName) 
    end
    table.sort(filterNames)
    -- Add options for each filter name
    for _, filterName in ipairs(filterNames) do
        addSettingOptions(optionsTable, filterCategory, filterName, onAutolootSet)
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

function disableWritCreaterAutoloot(value)
    if not value or not WritCreater then return end
    local displayLazyWarning = disableWritCreaterSavedVarsAutoloot(WritCreater.savedVars)
    local displayLazyWarningAccountWide = disableWritCreaterSavedVarsAutoloot(
        WritCreater.savedVarsAccountWide and WritCreater.savedVarsAccountWide.accountWideProfile)
    if displayLazyWarning or displayLazyWarningAccountWide then
        addon.Print("Disabled autoloot settings for |r"..tostring(WritCreater.settings["panel"].displayName))
    end
end

function setAutolootDefaults(sv)     
    for filterCategory, subfilters in pairs(addon.filters) do
       for settingName in pairs(subfilters) do
           sv[settingName.."Autoloot"] = sv[settingName]
        end
    end
    sv.otherAutoloot = sv.other
end

renamedSettings = 
    {
        ["accessories"]        = "jewelry",
        ["potions"]            = "consumables",
        ["giftBoxes"]          = "festival",
        ["gunnySacks"]         = "generic",
        ["alchemist"]          = "alchemy",
        ["blacksmith"]         = "blacksmithing",
        ["enchanter"]          = "enchanting",
        ["provisioner"]        = "provisioning",
        ["woodworker"]         = "woodworking",
        ["runeBoxes"]          = "runeboxes",
        ["accessoriesSummary"] = "jewelrySummary",
        ["potionsSummary"]     = "consumablesSummary",
        ["giftBoxesSummary"]   = "festivalSummary",
        ["gunnySacksSummary"]  = "genericSummary",
        ["alchemistSummary"]   = "alchemySummary",
        ["blacksmithSummary"]  = "blacksmithingSummary",
        ["enchanterSummary"]   = "enchantingSummary",
        ["provisionerSummary"] = "provisioningSummary",
        ["woodworkerSummary"]  = "woodworkingSummary",
        ["runeBoxesSummary"]   = "runeboxesSummary",
    }