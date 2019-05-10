
-- Treasure Maps

local addon = Unboxer
local class = addon:Namespace("rules.general")
local debug = false
local submenu = GetString(SI_GAMEPLAY_OPTIONS_GENERAL)

class.TreasureMaps = addon.classes.Rule:Subclass()
function class.TreasureMaps:New()
    return addon.classes.Rule.New(
        self, 
        {
            name          = "treasuremaps",
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