
-- Dungeon

local addon = Unboxer
local class = addon:Namespace("rules.rewards")
local debug = false
local staticDlcDungeons
local submenu = GetString(SI_UNBOXER_QUEST_REWARDS)

class.Dungeon = addon.classes.Rule:Subclass()
function class.Dungeon:New()
    local instance = addon.classes.Rule.New(
        self, 
        {
            name          = "dungeon",
            exampleItemId = 84519, -- [Unidentified Mazzatun Armaments]
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_DUNGEONS)
        })
    EVENT_MANAGER:RegisterForEvent(instance.name, EVENT_PLAYER_ACTIVATED, function() instance:GetDlcDungeons() end)
    return instance
end

function class.Dungeon:GetDlcDungeons()
    if staticDlcDungeons then
        return staticDlcDungeons
    end
    
    staticDlcDungeons = {}
    local activityType = LFG_ACTIVITY_DUNGEON
    for activityIndex = 1, GetNumActivitiesByType(activityType) do
        local activityId = GetActivityIdByTypeAndIndex(activityType, activityIndex)
        if GetRequiredActivityCollectibleId(activityId) > 0 then
            local name = LocaleAwareToLower(zo_strformat(SI_LFG_ACTIVITY_NAME, GetActivityInfo(activityId)))
            if name ~= "" then
                table.insert(staticDlcDungeons, { ["id"] = activityId, ["name"] = name })
            end
        end
    end
    
    return staticDlcDungeons
end

function class.Dungeon:Match(data)
    if not addon:StringContainsPunctuationColon(data.name)
       and data.quality < ITEM_QUALITY_LEGENDARY
       and self:MatchDlcDungeonByNameAndFlavorText(data)
    then
        return self:IsUnboxableMatch()
    end
end

function class.Dungeon:MatchDlcDungeonByNameAndFlavorText(data)
    
    if self:MatchDlcDungeonByText(data.name)
       or self:MatchDlcDungeonByText(data.flavorText)
    then
        return true
    end
end

function class.Dungeon:MatchDlcDungeonByText(text)
    
    if not text or text == "" then return end
    
    local dlcDungeons = self:GetDlcDungeons()
    
    text = LocaleAwareToLower(text)
    for _, activityLocation in ipairs(staticDlcDungeons) do
        if string.find(text, activityLocation.name) then
            return true
        end
    end
end