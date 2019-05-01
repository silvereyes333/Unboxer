
-- Legerdemain

local addon = Unboxer
local class = addon.classes
local debug = false
local submenu = GetString(SI_GAMEPLAY_OPTIONS_GENERAL)

class.Legerdemain = class.Rule:Subclass()
function class.Legerdemain:New()
    return class.Rule.New(
        self, 
        {
            name          = "legerdemain",
            exampleItemId = 119561 -- Professional Thief's Satchel of Laundered Goods
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_LEGERDEMAIN),
        })
end

function class.Legerdemain:Match(data)
    if addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_STOLEN_LOWER)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_LAUNDERED_LOWER)
    then
        return self:IsUnboxableMatch()
    end
end