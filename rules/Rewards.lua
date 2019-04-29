local addon = Unboxer
local class = addon.classes
local debug = false
local staticLocations
local staticDlcs

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
            for itemId, _ in pairs(filters) do
                local itemLink = addon.GetItemLinkFromItemId(itemId)
                c = c + 1
                local itemLinkData = addon:GetItemLinkData(itemLink)
                addon.settings.containerDetails[itemId] = itemLinkData
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
    if not string.find(data.name, ":")
       and data.quality < ITEM_QUALITY_LEGENDARY
       and self:MatchActivityByNameAndFlavorText(data) == LFG_ACTIVITY_DUNGEON
    then
        return self:IsUnboxableMatch()
    end
end


-- Trial
local trial
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


-- Zone repeatable activites (e.g. dailies, Rewards for the Worthy, etc.)
local zone
class.Zone = class.Rule:Subclass()
function class.Zone:New()
    local instance = class.Rule.New(self, 
      "zone",
      140296, -- [Unidentified Summerset Chest Armor]
      { -- dependencies
          "crafting",
          "festival",
          "materials",
          "thief",
          "trial",
          "vendorGear",
      }
    )
    instance.pts = class.Pts:New()
    return instance
end

function class.Zone:Match(data)
  
    if zone[data.itemId] then
        return self:IsUnboxableMatch()
    end
  
    if string.find(data.name, ":") then
        return
    end
    
    -- All the vendor-supplied "Unidentified" weapon and armor boxes are already matched
    -- because of the "vendorGear" dependency in the constructor.
    -- Any others are zone quest drops, so match them here.
    if data.quality > ITEM_QUALITY_NORMAL
       and (addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_UNIDENTIFIED_LOWER)
            or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_UNIDENTIFIED2_LOWER))
    then
        return self:IsUnboxableMatch()
    end
    
    -- Match champion caches
    if string.find(data.icon, "mail_armor_container") then
        return self:IsUnboxableMatch()
    end
  
    -- Matches containers like 81226 [Unidentified Craglorn Weapon] and 87704 [Serpent's Celestial Recompense],
    -- which have no flavor text.  This is needed to keep them from being categorized as PTS containers.
    if data.flavorText == "" and string.find(data.icon, "quest_container_001") 
       and data.quality < ITEM_QUALITY_ARTIFACT
    then
        return self:IsUnboxableMatch()
    end
    
    
    -- Matches daily reward containers
    if data.bindType == BIND_TYPE_ON_PICKUP
       and (self:MatchDailyQuestText(data.name)
            or self:MatchDailyQuestText(data.flavorText))
    then
        return self:IsUnboxableMatch()
    end
    
    
    if addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_UNKNOWN_ITEM_PATTERN) -- "Unknown Item" boxes
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_UNKNOWN_ITEM_LOWER)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_UNKNOWN_ITEM_LOWER)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_COFFER_LOWER) -- "coffer" and "strongbox" items
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_STRONG_BOX_LOWER)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_STRONG_BOX2_LOWER)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_GIFT_FROM_LOWER) -- "gift from" boxes
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_GIFT_FROM2_LOWER)
    then
        return self:IsUnboxableMatch()
    end
    
    
    
    --[[ EVERYTHING BELOW HERE SHOULD EXCLUDE SPECIFICALLY-MATCHED PTS GEAR ]]--
    if self.pts:MatchExceptIcon(data) then return end
    
    
    
    
    if self:MatchGuildSkillLineName(data.name) -- Matches "Merit" for guild skill tree lines
       or self:MatchDlcNameText(data.name) or self:MatchDlcNameText(data.flavorText) -- DLC zone names
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_CYRODIIL_LOWER) -- cyrodiil in name
    then
        return self:IsUnboxableMatch()
    end
end



local defaultGuildSkillLineNames = {
    "mages guild",
    "fighters guild",
    "thieves guild",
    "dark brotherhood",
    "undaunted",
    "psijic order",
}
function class.Zone:MatchGuildSkillLineName(text)
  
    local skillType = SKILL_TYPE_GUILD
    for skillLineIndex=1, GetNumSkillLines(skillType) do
        local skillLineName = LocaleAwareToLower(GetSkillLineName(skillType, skillLineIndex))
        if string.find(text, skillLineName) then
            return true
        end
    end
    if addon:IsDefaultLanguageSelected() then
        return
    end
    -- Fallback to default language when running on an incomplete translation, like ruESO
    for _, skillLineName in ipairs(defaultGuildSkillLineNames) do
        if string.find(text, skillLineName) then
            return true
        end
    end
end
function class.Zone:MatchDailyQuestText(text)
    return addon:StringContainsStringIdOrDefault(text, SI_UNBOXER_REWARD_LOWER)
           or addon:StringContainsStringIdOrDefault(text, SI_UNBOXER_DAILY_LOWER)
           or addon:StringContainsStringIdOrDefault(text, SI_UNBOXER_DAILY2_LOWER)
           or addon:StringContainsStringIdOrDefault(text, SI_UNBOXER_JOB_LOWER)
           or addon:StringContainsStringIdOrDefault(dext, SI_UNBOXER_CONTRACT_LOWER)
    
end
function class.Zone:MatchDlcNameText(text)
    for _, dlc in ipairs(self:GetDlcs()) do
        if string.find(text, dlc.name) or string.find(text, dlc.zoneName) then
            return true
        end
    end
end


function class.Zone:GetDlcs()
    if staticDlcs then return staticDlcs end
    
    local dlcType=COLLECTIBLE_CATEGORY_TYPE_DLC
    local dlcCollectibles = {}
    staticDlcs = {}
    for index=1,GetTotalCollectiblesByCategoryType(dlcType) do
        local collectibleId = GetCollectibleIdFromType(dlcType, index)
        local name = LocaleAwareToLower(GetCollectibleName(collectibleId))
        dlcCollectibles[collectibleId] = name
    end
    local zoneIndex = 1
    while true do
        local zoneName = GetZoneNameByIndex(zoneIndex)
        if(zoneName == "") then break end
        local zoneId = GetZoneId(zoneIndex)
        local parentZoneId = GetParentZoneId(zoneId)
        local collectibleId = GetCollectibleIdForZone(zoneIndex)
        if collectibleId and dlcCollectibles[collectibleId] and zoneId == parentZoneId then
            zoneName = LocaleAwareToLower(zoneName)
            local collectibleName = dlcCollectibles[collectibleId]
            table.insert(staticDlcs, {
                    ["collectibleId"] = collectibleId,
                    ["name"] = collectibleName,
                    ["zoneIndex"] = zoneIndex,
                    ["zoneName"] = zoneName,
                })
        end
        zoneIndex = zoneIndex + 1
    end
    return staticDlcs
end

zone = {
  [54986] = true, -- Sealed Urn
  [79502] = true, -- Bloody Bag
  [79503] = true, -- Sealed Crate
  [79504] = true, -- Unmarked Sack, dropped from DB shadowy supplier
  [79677] = true -- Assassin's Potion Kit, dropped from DB shadowy supplier
}

  