
-- Trials

local addon = Unboxer
local class = addon.classes
local debug = false
local trial
local submenu = GetString(SI_UNBOXER_QUEST_REWARDS)

class.Trial = class.LFGActivity:Subclass()
function class.Trial:New()
    return class.Rule.New(
        self, 
        {
            name          = "trial",
            exampleItemId = 139668, -- [Mage's Knowledgeable Coffer]
            submenu       = submenu,
            title         = GetString("SI_RAIDCATEGORY", RAID_CATEGORY_TRIAL)
        })
end

function class.Trial:Match(data)
  
    if (  addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_UNDAUNTED_LOWER)
          and addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_WEEKLY_LOWER)
       )
       or (not string.find(data.name, ":") 
           and self:MatchActivityByNameAndFlavorText(data) == LFG_ACTIVITY_TRIAL)
       or trial[data.itemId]
    then
        return self:IsUnboxableMatch()
    end
end

trial = {
  [87704] = true -- Serpent's Celestial Recompense
}