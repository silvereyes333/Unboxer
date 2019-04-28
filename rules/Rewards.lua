local addon = Unboxer
local class = addon.classes
local debug = false
local staticLocations

--[[ REPEATABLE ACTIVITY REWARDS RULES ]]--


-- LFG activities base class
class.LFGActivity = class.Rule:Subclass()
function class.LFGActivity:New(...)
    local instance = class.Rule.New(self, ...)
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
    self.locations = staticLocations
    
    -- TODO: REMOVE THIS
    addon.Debug("Scanning container details...")
    local c = 0
    for filterCategory1, category1Filters in pairs(addon.filters) do
        for filterCategory2, filters in pairs(category1Filters) do
            addon.Debug("Scanning category "..tostring(filterCategory1)..": "..tostring(filterCategory2).."...")
            for itemId, _ in pairs(filters) do
                local itemLink = addon.GetItemLinkFromItemId(itemId)
                
                if not addon.settings.containerDetails[itemId] or (
                  not addon.settings.containerDetails[itemId]["quest"] 
                  and not addon.settings.containerDetails[itemId]["mail"]
                  and not addon.settings.containerDetails[itemId]["store"]
                ) then
                    c = c + 1
                    local itemLinkData = addon:GetItemLinkData(itemLink)
                    itemLinkData["filterCategory1"] = filterCategory1
                    itemLinkData["filterCategory2"] = filterCategory2
                    addon.settings.containerDetails[itemId] = itemLinkData
                end
            end
        end
    end
    addon.Debug(tostring(c).." containers scanned.")
    
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


-- Dungeon
class.Dungeon = class.LFGActivity:Subclass()
function class.Dungeon:New()
    return class.Rule.New(self, 
      "dungeon",
      84519 -- [Unidentified Mazzatun Armaments]
    )
end

function class.Dungeon:Match(data)
    if self:MatchActivityByNameAndFlavorText(data) == LFG_ACTIVITY_DUNGEON then
        return true, -- isMatch
               true  -- canUnbox
    end
end


-- Trial
class.Trial = class.LFGActivity:Subclass()
function class.Trial:New()
    return class.Rule.New(self, 
      "trial",
      139668 -- [Mage's Knowledgeable Coffer]
    )
end

function class.Trial:Match(data)
  
    if (  addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_UNDAUNTED_LOWER)
          and addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_WEEKLY_LOWER)
       )
       or self:MatchActivityByNameAndFlavorText(data) == LFG_ACTIVITY_TRIAL
    then
        return true, -- isMatch
               true  -- canUnbox
    end
end


-- Zone repeatable activites (e.g. dailies, Rewards for the Worthy, etc.)
class.Zone = class.Rule:Subclass()
function class.Zone:New()
    return class.Rule.New(self, 
      "zone",
      140296, -- [Unidentified Summerset Chest Armor]
      { -- dependencies
          "vendorGear" -- always process vendor gear logic first
      } 
    )
end

function class.Zone:Match(data)
    
    -- All the vendor-supplied "Unidentified" weapon and armor boxes are already matched
    -- because of the "vendorGear" dependency in the constructor.
    -- Any others are zone quest drops, so match them here.
    if data.quality > ITEM_QUALITY_NORMAL
       and (addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_UNIDENTIFIED_LOWER)
            or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_UNIDENTIFIED2_LOWER))
    then
        return true, -- isMatch
               true  -- canUnbox
    end
  
    -- Matches containers like 81226 [Unidentified Craglorn Weapon] and 87704 [Serpent's Celestial Recompense],
    -- which have no flavor text.  This is needed to keep them from being categorized as PTS containers.
    if data.flavorText == "" and string.find(data.icon, "quest_container_001") 
       and data.quality < ITEM_QUALITY_ARTIFACT
    then
        return true, -- isMatch
               true  -- canUnbox
    end
end