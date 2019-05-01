local addon = Unboxer
local class = addon.classes
local debug = false
local staticDlcs
local submenu = GetString(SI_UNBOXER_QUEST_REWARDS)

--[[ REPEATABLE ACTIVITY REWARDS RULES ]]--


-- Zone repeatable activites (e.g. dailies, Rewards for the Worthy, etc.)
local zone
class.Zone = class.Rule:Subclass()
function class.Zone:New()
    local instance = class.Rule.New(
        self, 
        {
            name          = "zone",
            exampleItemId = 140296, -- [Unidentified Summerset Chest Armor]
            dependencies  = { "crafting", "festival", "materials", "thief", "trial", "vendorGear" },
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_ZONE),
        })
    instance.pts = class.Pts:New()
    return instance
end

function class.Zone:Match(data)
  
    if zone[data.itemId] then
        return self:IsUnboxableMatch()
    end
  
    if string.find(data.name, ":") 
       or data.quality == ITEM_QUALITY_LEGENDARY
    then
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
  [54986]  = true, -- Sealed Urn
  [79502]  = true, -- Bloody Bag
  [79503]  = true, -- Sealed Crate
  [79504]  = true, -- Unmarked Sack, dropped from DB shadowy supplier
  [79677]  = true, -- Assassin's Potion Kit, dropped from DB shadowy supplier
  [134969] = true  -- Item Set: Health Rings, level up bonus
}

  