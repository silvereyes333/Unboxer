
-- Bequeather / Shadowy Supplier

local addon = Unboxer
local class = addon:Namespace("rules.general")
local knownIds
local debug = false
local submenu = GetString(SI_GAMEPLAY_OPTIONS_GENERAL)

class.ShadowySupplier = addon.classes.Rule:Subclass()
function class.ShadowySupplier:New()
    return addon.classes.Rule.New(
        self, 
        {
            name          = "shadowysupplier",
            exampleItemId = 79504,	-- [Unmarked Sack]
            dependencies  = { "excluded" },
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_SHADOWY_SUPPLIER),
            knownIds      = knownIds,
        })
end

function class.ShadowySupplier:Match(data)
    
    if knownIds[data.itemId] then -- Match preloaded ids
        return self:IsUnboxableMatch()
    end
end

knownIds = {
  [79504]  = true, -- [Unmarked Sack]
  [79677]  = true, -- [Assassin's Potion Kit]
}