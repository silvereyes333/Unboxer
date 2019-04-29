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
        return true, -- isMatch
               true  -- canUnbox
    end
end

crafting = {
  [30333] -- Provisioner Kit
  [30335] -- Blacksmith's Chest
  [30337] -- Enchanter's Chest
  [30338] -- Clothier's Chest
  [30339] -- Woodworker's Chest
  [55827] -- Cooking Supplies
}
