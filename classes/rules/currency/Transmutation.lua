
-- Transmutation Geodes

local addon = Unboxer
local class = addon:Namespace("rules.currency")
local debug = false
local submenu = GetString(SI_INVENTORY_MODE_CURRENCY)

class.Transmutation = class.Rule:Subclass()
function class.Transmutation:New()
    local instance = class.Rule.New(
        self, 
        {
            name          = "transmutation",
            exampleItemId = 134623, -- [Uncracked Transmutation Geode]
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_TRANSMUTATION),
        })
    instance.pts = class.Pts:New()
    return instance
end

function class.Transmutation:Match(data)
    if addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_TRANSMUTATION_LOWER)
       and not self.pts:MatchAbsoluteIndicators(data)
       and data.flavorText ~= ""
       and not string.find(data.name, ":")
    then
        return self:IsUnboxableMatch()
    end
end
