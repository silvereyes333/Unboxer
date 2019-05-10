local addon = Unboxer
local class = addon:Namespace("rules.rewards")
local debug = false
local staticLocations

--[[ REPEATABLE ACTIVITY REWARDS RULES ]]--


-- LFG activities base class
class.LFGActivity = addon.classes.Rule:Subclass()
function class.LFGActivity:New(...)
    local instance = addon.classes.Rule.New(self, ...)
    EVENT_MANAGER:RegisterForEvent(instance.name, EVENT_PLAYER_ACTIVATED, function() instance:GetLocations() end)
    return instance
end

function class.LFGActivity:GetLocations()
    if staticLocations then
        return staticLocations
    end
    
    staticLocations = {
        [LFG_ACTIVITY_DUNGEON] = {},
        [LFG_ACTIVITY_TRIAL]   = {},
    }
    local activityType = LFG_ACTIVITY_DUNGEON
    for activityIndex = 1, GetNumActivitiesByType(activityType) do
        local activityId = GetActivityIdByTypeAndIndex(activityType, activityIndex)
        if GetRequiredActivityCollectibleId(activityId) > 0 then
            local name = LocaleAwareToLower(zo_strformat(SI_LFG_ACTIVITY_NAME, GetActivityInfo(activityId)))
            table.insert(staticLocations[activityType], { ["id"] = activityId, ["name"] = name })
        end
    end
    activityType = LFG_ACTIVITY_TRIAL
    local veteranSuffix = " (" .. GetString(SI_DUNGEONDIFFICULTY2) .. ")"
    for raidIndex = 1, GetNumRaidLeaderboards(RAID_CATEGORY_TRIAL) do
        local raidName, raidId = GetRaidLeaderboardInfo(RAID_CATEGORY_TRIAL, raidIndex)
        if string.find(raidName, GetString(SI_DUNGEONDIFFICULTY2)) then
            raidName = string.sub(raidName, 1, -ZoUTF8StringLength(veteranSuffix) - 1)
        end
        table.insert(staticLocations[activityType], { ["id"] = raidId, ["name"] = LocaleAwareToLower(raidName) })
    end
    
    return staticLocations
end

function class.LFGActivity:MatchActivityByText(text)
    
    if not text or text == "" then return end
    
    local locations = self:GetLocations()
    
    text = LocaleAwareToLower(text)
    for lfgActivity, activityLocations in pairs(locations) do
        local found
        local multipleFound
        for _, activityLocation in ipairs(activityLocations) do
            if string.find(text, activityLocation.name) then
                if found then
                    multipleFound = true
                    break
                else
                    found = true
                end
            end
        end
        if found then
            return lfgActivity, multipleFound
        end
    end
end

function class.LFGActivity:MatchActivityByNameAndFlavorText(data)
    
    local lfgActivity = self:MatchActivityByText(data.name)
    if not lfgActivity then
        lfgActivity = self:MatchActivityByText(data.flavorText)
    end
    return lfgActivity
end