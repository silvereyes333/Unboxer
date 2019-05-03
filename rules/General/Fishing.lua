
-- Fishing

local addon = Unboxer
local class = addon.classes
local debug = false
local knownIds
local submenu = GetString(SI_GAMEPLAY_OPTIONS_GENERAL)

class.Fishing = class.Rule:Subclass()
function class.Fishing:New()
    return class.Rule.New(
        self, 
        {
            name          = "fishing",
            exampleItemId = 43757, -- [Wet Gunny Sack]
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_FISHING),
            -- knownIds      = knownIds
        })
end

function class.Fishing:Match(data)
    if knownIds[data.itemId] 
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FISHING_LOWER)
    then
        return self:IsUnboxableMatch()
    end
end
knownIds = {
  [139011] = true -- Waterlogged Psijic Satchel
}