
-- Fishing

local addon = Unboxer
local class = addon:Namespace("rules.general")
local knownIds
local debug = false
local submenu = GetString(SI_GAMEPLAY_OPTIONS_GENERAL)

class.Fishing = addon.classes.Rule:Subclass()
function class.Fishing:New()
    return addon.classes.Rule.New(
        self, 
        {
            name          = "fishing",
            exampleItemIds = {
                43757,  -- [Wet Gunny Sack]
                139011, -- [Waterlogged Psijic Satchel]
            },
            dependencies  = { "excluded2" },
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_FISHING),
            knownIds      = knownIds,
        })
end

function class.Fishing:Match(data)
    
    if addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FISHING_LOWER) then
        return true
    end
end

knownIds = {
  [139011] = 1, -- Waterlogged Psijic Satchel
  [43757]=1,[140443]=1
}