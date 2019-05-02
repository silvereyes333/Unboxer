
-- Treasure Maps

local addon = Unboxer
local class = addon.classes
local debug = false
local submenu = GetString(SI_GAMEPLAY_OPTIONS_GENERAL)

class.TreasureMaps = class.Rule:Subclass()
function class.TreasureMaps:New()
    return class.Rule.New(
        self, 
        {
            name          = "treasureMaps",
            exampleItemId = 45882,	-- [Coldharbour Treasure Map]
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_TREASURE_MAPS),
        })
end

function class.TreasureMaps:Match(data)
    if addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_TREASURE_MAP_LOWER) then
        return self:IsUnboxableMatch()
    end
end