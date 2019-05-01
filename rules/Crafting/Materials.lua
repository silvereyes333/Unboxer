-- Materials

local addon = Unboxer
local class = addon.classes
local materials
local debug = false
local submenu = GetString("SI_QUESTTYPE", QUEST_TYPE_CRAFTING)

--[[ CRAFTING RULES ]]--


class.Materials = class.Rule:Subclass()
function class.Materials:New()
    return class.Rule.New(
        self, 
        {
            name          = "materials",
            exampleItemId = 142173 -- [Shipment of Ounces IV]
            submenu       = submenu,
            title         = GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_RAW_MATERIALS),
        })
end

function class.Materials:Match(data)
    if materials[data.itemId] 
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_RAW_MATERIAL_LOWER)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FOR_CRAFTING_LOWER)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_WAXED_LOWER)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_WAXED2_LOWER)
    then
        return self:IsUnboxableMatch()
    end
end
materials = {
  [79675] = true, -- Toxin Sachel
}