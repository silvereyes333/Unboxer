
-- Dungeon

local addon = Unboxer
local class = addon:Namespace("rules.rewards")
local debug = false
local submenu = GetString(SI_UNBOXER_QUEST_REWARDS)

class.Dungeon = class.LFGActivity:Subclass()
function class.Dungeon:New()
    return class.Rule.New(
        self, 
        {
            name          = "dungeon",
            exampleItemId = 84519, -- [Unidentified Mazzatun Armaments]
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_DUNGEONS)
        })
end

function class.Dungeon:Match(data)
    if not string.find(data.name, ":")
       and data.quality < ITEM_QUALITY_LEGENDARY
       and self:MatchActivityByNameAndFlavorText(data) == LFG_ACTIVITY_DUNGEON
    then
        return self:IsUnboxableMatch()
    end
end