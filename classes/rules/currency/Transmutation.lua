
-- Transmutation Geodes

local addon = Unboxer
local class = addon:Namespace("rules.currency")
local rules = addon.classes.rules
local knownIds
local debug = false
local submenu = GetString(SI_INVENTORY_MODE_CURRENCY)

class.Transmutation = addon.classes.Rule:Subclass()
function class.Transmutation:New()
    local instance = addon.classes.Rule.New(
        self, 
        {
            name          = "transmutation",
            exampleItemId = 134623, -- [Uncracked Transmutation Geode]
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_TRANSMUTATION),
            knownIds      = knownIds,
        })
    instance.pts = rules.Pts:New()
    return instance
end

function class.Transmutation:Match(data)
  
    -- Match preloaded ids
    if knownIds[data.itemId] then 
        return self:IsUnboxableMatch()
    end
    
    if addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_TRANSMUTATION_LOWER)
       and not self.pts:MatchAbsoluteIndicators(data)
       and data.flavorText ~= ""
       and not addon:StringContainsPunctuationColon(data.name)
       and not string.find(data.name, "[0-9]") -- no numbers in name
    then
        return self:IsUnboxableMatch()
    end
end

knownIds = {
  [134583]=1,[134588]=1,[134589]=1,[134590]=1,[134591]=1,[134618]=1,[134622]=1,[134623]=1
}