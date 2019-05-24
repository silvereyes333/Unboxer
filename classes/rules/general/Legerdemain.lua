
-- Legerdemain

local addon = Unboxer
local class = addon:Namespace("rules.general")
local knownIds
local debug = false
local submenu = GetString(SI_GAMEPLAY_OPTIONS_GENERAL)

class.Legerdemain = addon.classes.Rule:Subclass()
function class.Legerdemain:New()
    return addon.classes.Rule.New(
        self, 
        {
            name          = "legerdemain",
            exampleItemId = 119561, -- Professional Thief's Satchel of Laundered Goods
            dependencies  = { "excluded" },
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_LEGERDEMAIN),
            knownIds      = knownIds,
        })
end

function class.Legerdemain:Match(data)
    
    if knownIds[data.itemId] -- Match preloaded ids
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_STOLEN_LOWER)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_LAUNDERED_LOWER)
    then
        return self:IsUnboxableMatch()
    end
end

knownIds = {
  [74651]=1,[74683]=1,[75227]=1,[75339]=1,[78003]=1,[119561]=1
}