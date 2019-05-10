
-- Crafting Quest Rewards

local addon = Unboxer
local class = addon:Namespace("rules.crafting")
local knownIds
local debug = false
local submenu = GetString("SI_QUESTTYPE", QUEST_TYPE_CRAFTING)

class.CraftingRewards = class.Rule:Subclass()
function class.CraftingRewards:New()
    return class.Rule.New(
        self, 
        {
            name          = "crafting",
            exampleItemId = 138810, -- [Enchanter's Coffer X]
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_CRAFTING_REWARDS),
            -- knownIds      = knownIds
        })
end

function class.CraftingRewards:Match(data)
    if knownIds[data.itemId]
       or (addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_CRAFTED_LOWER)
           and addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_REWARD_LOWER))
    then
        return self:IsUnboxableMatch()
    end
end

function class.CraftingRewards:DisableWritCreaterAutoloot(savedVars)
    if not savedVars then return end
    local displayLazyWarning
    if not savedVars.ignoreAuto then
        savedVars.ignoreAuto = true
        displayLazyWarning = true
    end
    if savedVars.autoLoot then
        savedVars.autoLoot = false
        displayLazyWarning = true
    end
    if savedVars.lootContainerOnReceipt then
        savedVars.lootContainerOnReceipt = false
        displayLazyWarning = true
    end
    return displayLazyWarning
end

function class.CraftingRewards:OnAutolootSet(value)
    if not value or not WritCreater then return end
    local displayLazyWarning = self:DisableWritCreaterAutoloot(WritCreater.savedVars)
    local displayLazyWarningAccountWide = self:DisableWritCreaterAutoloot(
        WritCreater.savedVarsAccountWide and WritCreater.savedVarsAccountWide.accountWideProfile)
    if displayLazyWarning or displayLazyWarningAccountWide then
        addon.Print("Disabled autoloot settings for |r"..tostring(WritCreater.settings["panel"].displayName))
    end
end

knownIds = {
  [30333] = true, -- Provisioner Kit
  [30335] = true, -- Blacksmith's Chest
  [30337] = true, -- Enchanter's Chest
  [30338] = true, -- Clothier's Chest
  [30339] = true, -- Woodworker's Chest
  [55827] = true, -- Cooking Supplies
}
