local addon = Unboxer
local class = addon.classes
local debug = false

--[[ CRAFTING RULES ]]--


-- Materials
class.CraftingMaterials = class.Rule:Subclass()
function class.CraftingMaterials:New()
    return class.Rule.New(self, 
      "materials",
      142173 -- [Shipment of Ounces IV]
    )
end

function class.CraftingMaterials:Match(data)
    if addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_RAW_MATERIAL_LOWER) then
        return true, -- isMatch
               true  -- canUnbox
    end
end


-- Writ Rewards
class.CraftingWrits = class.Rule:Subclass()
function class.CraftingWrits:New()
    return class.Rule.New(self, 
      "crafting",
      138810 -- [Enchanter's Coffer X]
    )
end

function class.CraftingWrits:Match(data)
    if addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_CRAFTED_LOWER)
       and addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_REWARD_LOWER)
    then
        return true, -- isMatch
               true  -- canUnbox
    end
end