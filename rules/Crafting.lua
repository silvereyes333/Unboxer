local addon = Unboxer
local class = addon.classes
local debug = false

--[[ CRAFTING RULES ]]--


-- Materials
local materials
class.CraftingMaterials = class.Rule:Subclass()
function class.CraftingMaterials:New()
    return class.Rule.New(self, 
      "materials",
      142173 -- [Shipment of Ounces IV]
    )
end

function class.CraftingMaterials:Match(data)
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


-- Crafting Quest Rewards
local crafting
class.CraftingQuests = class.Rule:Subclass()
function class.CraftingQuests:New()
    return class.Rule.New(self, 
      "crafting",
      138810 -- [Enchanter's Coffer X]
    )
end

function class.CraftingQuests:Match(data)
    if crafting[data.itemId]
       or (addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_CRAFTED_LOWER)
           and addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_REWARD_LOWER))
    then
        return self:IsUnboxableMatch()
    end
end

crafting = {
  [30333] = true, -- Provisioner Kit
  [30335] = true, -- Blacksmith's Chest
  [30337] = true, -- Enchanter's Chest
  [30338] = true, -- Clothier's Chest
  [30339] = true, -- Woodworker's Chest
  [55827] = true, -- Cooking Supplies
}
