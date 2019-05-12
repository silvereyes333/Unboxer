
-- Materials

local addon = Unboxer
local class = addon:Namespace("rules.crafting")
local knownIds
local debug = false
local submenu = GetString("SI_QUESTTYPE", QUEST_TYPE_CRAFTING)

class.Materials = addon.classes.Rule:Subclass()
function class.Materials:New()
    return addon.classes.Rule.New(
        self, 
        {
            name          = "materials",
            exampleItemId = 142173, -- [Shipment of Ounces IV]
            submenu       = submenu,
            title         = GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_RAW_MATERIALS),
            -- knownIds      = knownIds
        })
end

function class.Materials:Match(data)
    
    -- Match preloaded ids
    if knownIds[data.itemId] then
        return self:IsUnboxableMatch()
    end
    
    if data.bindType ~= BIND_TYPE_ON_PICKUP or data.quality > ITEM_QUALITY_ARCANE then
        return
    end
    
    if addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_RAW_MATERIAL_LOWER)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FOR_CRAFTING_LOWER)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_WAXED_LOWER)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_WAXED2_LOWER)
    then
        return self:IsUnboxableMatch()
    end
end
knownIds = {
  [79675] = true, -- Toxin Sachel
}