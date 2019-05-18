local addon = Unboxer
local LSV  = LibSavedVars or LibStub("LibSavedVars")
local LAM2 = LibAddonMenu2 or LibStub("LibAddonMenu-2.0")

-- Local functions
local setAutolootDefaults

-- Local variables
local debug = false
local exampleFormat = GetString(SI_UNBOXER_TOOLTIP_EXAMPLE)
local renamedSettings, removedSettings, refreshPrefix

----------------- Settings -----------------------
function addon:SetupSettings()
    
    self.Debug("SetupSettings()", debug)
    
    self.defaults = 
    {
        autoloot = tonumber(GetSetting(SETTING_TYPE_LOOT,LOOT_SETTING_AUTO_LOOT)) ~= 0,
        autolootDelay = 2,
        reservedSlots = 0,
        chatColor = { 1, 1, 1, 1 },
        shortPrefix = true,
        chatUseSystemColor = true,
        chatContainerOpen = true,
        chatContentsSummary = true,
    }
    
    for _, rule in ipairs(self.rules) do
        if not self.defaults[rule.name] then
            self.defaults[rule.name] = false
        end
        self.defaults[rule.autolootSettingName] = self.defaults[rule.name]
        self.defaults[rule.summarySettingName] = false
    end

    self.settings =
      LSV:NewAccountWide(self.name .. "_Account", self.defaults)
         :AddCharacterSettingsToggle(self.name .. "_Character")
         :RenameSettings(4, renamedSettings)
         :RemoveSettings(4, removedSettings)
                  
    self.chatColor = ZO_ColorDef:New(unpack(self.settings.chatColor))
    refreshPrefix()
    
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
        
        {
            type     = "submenu",
            name     = GetString(SI_UNBOXER_CHAT_MESSAGES),
            controls = {
          
                -- Short prefix
                {
                    type = "checkbox",
                    name = GetString(SI_UNBOXER_SHORT_PREFIX),
                    tooltip = GetString(SI_UNBOXER_SHORT_PREFIX_TOOLTIP),
                    getFunc = function() return self.settings.shortPrefix end,
                    setFunc = function(value)
                                  self.settings.shortPrefix = value
                                  refreshPrefix()
                              end,
                    default = self.defaults.shortPrefix,
                },
                -- Use default system color
                {
                    type = "checkbox",
                    name = GetString(SI_UNBOXER_CHAT_USE_SYSTEM_COLOR),
                    getFunc = function() return self.settings.chatUseSystemColor end,
                    setFunc = function(value)
                                  self.settings.chatUseSystemColor = value
                                  refreshPrefix()
                              end,
                    default = self.defaults.chatUseSystemColor,
                },
                -- Message color
                {
                    type = "colorpicker",
                    name = GetString(SI_UNBOXER_CHAT_COLOR),
                    getFunc = function() return unpack(self.settings.chatColor) end,
                    setFunc = function(r, g, b, a)
                                  self.settings.chatColor = { r, g, b, a }
                                  self.chatColor = ZO_ColorDef:New(r, g, b, a)
                                  refreshPrefix()
                              end,
                    default = self.defaults.chatColor,
                    disabled = function() return self.settings.chatUseSystemColor end,
                },
                -- Old Prefix Colors
                {
                    type = "checkbox",
                    name = GetString(SI_UNBOXER_COLORED_PREFIX),
                    tooltip = GetString(SI_UNBOXER_COLORED_PREFIX_TOOLTIP),
                    getFunc = function() return self.settings.coloredPrefix end,
                    setFunc = function(value)
                                  self.settings.coloredPrefix = value
                                  refreshPrefix()
                              end,
                    default = self.defaults.coloredPrefix,
                },
                -- Display Messages For:
                {
                    type = "header",
                    name = GetString(SI_UNBOXER_CHAT_MESSAGES_HEADER),
                },
                -- Log container open to chat
                {
                    type = "checkbox",
                    name = GetString(SI_UNBOXER_CHAT_CONTAINERS),
                    getFunc = function() return self.settings.chatContainerOpen end,
                    setFunc = function(value) self.settings.chatContainerOpen = value end,
                    default = self.defaults.chatContainerOpen,
                },
                -- Log container contents to chat
                {
                    type = "checkbox",
                    name = GetString(SI_UNBOXER_CHAT_CONTENTS),
                    tooltip = GetString(SI_UNBOXER_CHAT_CONTENTS_TOOLTIP),
                    getFunc = function() return self.settings.chatContentsSummary end,
                    setFunc = function(value) self.settings.chatContentsSummary = value end,
                    default = self.defaults.chatContentsSummary,
                },
            },
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
end

----------------------------------------------------------------------------
--
--       Local methods
-- 
----------------------------------------------------------------------------

function refreshPrefix()
    local self = addon
    local stringId
    local startColor = self.settings.chatUseSystemColor and "" or "|c" .. self.chatColor:ToHex()
    if self.settings.coloredPrefix then
        self.prefix = GetString(self.settings.shortPrefix and SI_UNBOXER_COLORED_SHORT or SI_UNBOXER_COLORED)
            .. startColor .. " "
    else
        self.prefix = startColor
            .. GetString(self.settings.shortPrefix and SI_UNBOXER_SHORT or SI_UNBOXER_PREFIX)
            .. " "
    end
    self.suffix = self.settings.chatUseSystemColor and "" or "|r"
end

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
    ["verbose"]                    = "chatContainerOpen",
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