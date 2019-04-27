--[[ 
     Base class for an unboxer category.  
     Child classes implement matching logic for whether an itemLink matches the rule.
]]--

local addon = Unboxer
local class = addon.classes
local exampleFormat = GetString(SI_UNBOXER_TOOLTIP_EXAMPLE)
class.Rule = ZO_Object:Subclass()

function class.Rule:New(...)
    local instance = ZO_Object.New(self)
    instance:Initialize(...)
    return instance
end

function class.Rule:Initialize(name, exampleItemId)
    self.name = name
    self.exampleItemId = exampleItemId
    self.autolootSettingName = self.name .. "Autoloot"
    self.summarySettingName = self.name .. "Summary"
end

--[[ Generates LibAddonMenu2 configuration options for enabling/disabling this rule ]]--
function class.Rule:CreateLAM2Options()
    if not self.name then return end
    local title = GetString(_G[string.format("SI_UNBOXER_%s", self.name:upper())])
    local tooltip = GetString(_G[string.format("SI_UNBOXER_%s_TOOLTIP", self.name:upper())])
    if self.exampleItemId then
        tooltip = tooltip .. string.format(exampleFormat, self.exampleItemId)
    end
    table.insert(optionsTable,
        {
            type     = "checkbox",
            name     = title,
            tooltip  = tooltip,
            getFunc  = function() 
                           return addon.settings[self.name] 
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

--[[ Generates LibAddonMenu2 configuration options for enabling/disabling this rule ]]--
function class.Rule:Match(itemLink)
    
end

function class.Rule:IsAutolootEnabled()
    return addon.settings[self.name .. "Autoloot"]
end

function class.Rule:IsEnabled()
    return addon.settings[self.name]
end

function class.Rule:IsSummaryEnabled()
    return addon.settings[self.name .. "Summary"]
end

function class.Rule:SetIsEnabled(enabled)
    return addon.settings[self.name] = enabled
end