
-- Transmutation Geodes

local addon = Unboxer
local class = addon.classes
local debug = false
local submenu = GetString("SI_QUESTTYPE", QUEST_TYPE_CRAFTING)

class.Transmutation = class.Rule:Subclass()
function class.Transmutation:New()
    return class.Rule.New(
        self, 
        {
            name          = "transmutation",
            exampleItemId = 134623, -- [Uncracked Transmutation Geode]
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_TRANSMUTATION),
        })
end

function class.Transmutation:Match(data)
    if addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_TRANSMUTATION_LOWER) then
        return self:IsUnboxableMatch()
    end
end
