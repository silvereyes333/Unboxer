--[[ 
     Base class for an Unboxer configurable category matching rule.  
     Child classes implement matching logic for whether an itemLink matches the rule.
]]--

local addon = Unboxer
local class = addon.classes
local exampleFormat = GetString(SI_UNBOXER_TOOLTIP_EXAMPLE)
local debug = false
class.Rule = ZO_Object:Subclass()

function class.Rule:New(...)
    local instance = ZO_Object.New(self)
    instance:Initialize(...)
    return instance
end

function class.Rule:Initialize(name, exampleItemId, dependencies)
    self.name = name
    self.exampleItemId = exampleItemId
    self.autolootSettingName = self.name .. "Autoloot"
    self.summarySettingName = self.name .. "Summary"
    if type(dependencies) ~= "table" then
        dependencies = { dependencies }
    end
    self.dependencies = {}
    for _, dependencyName in ipairs(dependencies) do
        self.dependencies[dependencyName] = true
    end
end

--[[ Generates LibAddonMenu2 configuration options for enabling/disabling this rule ]]--
function class.Rule:CreateLAM2Options()
    if not self.name then return end
    local title = GetString(_G[string.format("SI_UNBOXER_%s", self.name:upper())])
    local tooltip = GetString(_G[string.format("SI_UNBOXER_%s_TOOLTIP", self.name:upper())])
    if self.exampleItemId then
        tooltip = tooltip .. string.format(exampleFormat, self.exampleItemId)
    end
    local optionsTable = {}
    table.insert(optionsTable,
        {
            type     = "checkbox",
            name     = title,
            tooltip  = tooltip,
            getFunc  = function() return self:IsEnabled() end,
            setFunc  = function(value) self:SetIsEnabled(value) end,
            default  = addon.defaults[self.name],
        })
    table.insert(optionsTable,
        {
            type     = "checkbox",
            name     = GetString(SI_UNBOXER_AUTOLOOT),
            tooltip  = GetString(SI_UNBOXER_AUTOLOOT_TOOLTIP),
            width    = "half",
            getFunc  = function() return self:IsAutolootEnabled() end,
            setFunc  = function(value) self:SetAutoloot(value) end,
            default  = self:IsAutolootDefault(),
            disabled = function()
                           return not addon.settings.autoloot
                                  or not self:IsEnabled()
                       end,
        })
    table.insert(optionsTable,
        {
            type     = "checkbox",
            name     = GetString(SI_UNBOXER_SUMMARY),
            tooltip  = GetString(SI_UNBOXER_SUMMARY_TOOLTIP),
            width    = "half",
            getFunc  = function() return self:IsSummaryEnabled() end,
            setFunc  = function(value) self:SetSummaryEnabled(value) end,
            default  = self:IsSummaryDefault(),
            disabled = function() return not self:IsEnabled() end,
        })
    
    self:OnAutolootSet(self:IsAutolootEnabled())
end

--[[ Abstract: determines if this rule applies to a given item link. 
     data: table containing infomation about the item to match, like itemType, quality, lowercase name and lowercase flavorText.
     Returns: 
     * isMatch:  true if the data matches this rule; otherwise nil
     * canUnbox: true if the given item is able to be unboxed by the current character; otherwise nil
]]--
function class.Rule:Match(data)
    error("Unboxer.Rule:Match() must be overriden in child class for rule '" .. self.name .. "'")
end

function class.Rule:IsAutolootDefault()
    return addon.defaults[self.autolootSettingName]
end

function class.Rule:IsAutolootEnabled()
    return addon.settings[self.autolootSettingName]
end

function class.Rule:IsDependentUpon(rule)
    return self.dependencies[rule.name]
end

function class.Rule:IsEnabled()
    return addon.settings[self.name]
end

function class.Rule:IsSummaryDefault()
    return addon.defaults[self.summarySettingName]
end

function class.Rule:IsSummaryEnabled()
    return addon.settings[self.summarySettingName]
end

function class.Rule:OnAutolootSet(value)
    -- Optional: Override this in your child class
end

function class.Rule:SetAutolootEnabled(value) 
    addon.settings[self.autolootSettingName] = value
    addon.Debug("auto loot set for " .. self.name, debug)
    self:OnAutolootSet(value)
end

function class.Rule:SetEnabled(enabled)
    addon.settings[self.name] = enabled
end

function class.Rule:SetSummaryEnabled(enabled)
    addon.settings[self.summarySettingName] = enabled
end