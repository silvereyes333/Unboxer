-- Crafting Quest Rewards

local addon = Unboxer
local class = addon.classes
local crafting
local debug = false
local submenu = GetString("SI_QUESTTYPE", QUEST_TYPE_CRAFTING)

--[[ CRAFTING RULES ]]--

class.CraftingRewards = class.Rule:Subclass()
function class.CraftingRewards:New()
    return class.Rule.New(
        self, 
        {
            name          = "crafting",
            exampleItemId = 138810 -- [Enchanter's Coffer X]
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_CRAFTING_REWARDS),
        })
end

function class.CraftingRewards:Match(data)
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
