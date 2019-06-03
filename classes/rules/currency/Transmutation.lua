
-- Transmutation Geodes

local addon = Unboxer
local class = addon:Namespace("rules.currency")
local rules = addon.classes.rules
local knownIds
local debug = false
local submenu = GetString(SI_INVENTORY_MODE_CURRENCY)

class.Transmutation = addon.classes.Rule:Subclass()
function class.Transmutation:New()
    return addon.classes.Rule.New(
        self, 
        {
            name           = "transmutation",
            exampleItemIds = {
                134588, -- [Transmutation Geode]
                134623, -- [Uncracked Transmutation Geode]
            },
            dependencies   = { "excluded" },
            submenu        = submenu,
            title          = GetString(SI_UNBOXER_TRANSMUTATION),
            knownIds       = knownIds,
        })
end

function class.Transmutation:Match(data)
    
    if addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_TRANSMUTATION_LOWER)
       and data.flavorText ~= ""
       and not string.find(data.name, "[0-9]") -- no numbers in name
    then
        return true
    end
end

knownIds = {
  [134583]=1,[134588]=1,[134589]=1,[134590]=1,[134591]=1,[134618]=1,
  [134622]=1,[134623]=1
}