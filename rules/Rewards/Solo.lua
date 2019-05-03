
-- Solo activites (e.g. non-repeatable solo quests, level-up rewards, etc.)

local addon = Unboxer
local class = addon.classes
local debug = false
local staticDlcs
local knownIds
local submenu = GetString(SI_UNBOXER_QUEST_REWARDS)

class.Solo = class.Rule:Subclass()
function class.Solo:New()
    local instance = class.Rule.New(
        self, 
        {
            name          = "solo",
            exampleItemId = 140296, -- [Unidentified Summerset Chest Armor]
            dependencies  = { "crafting", "festival", "furnisher", "materials", "legerdemain", "trial", "vendorgear", "solorepeatable" },
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_SOLO),
            -- knownIds      = knownIds
        })
    instance.pts = class.Pts:New()
    return instance
end

function class.Solo:Match(data)
  
    if knownIds[data.itemId] then
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
  
    -- Matches containers like 81226 [Unidentified Craglorn Weapon] and 87704 [Serpent's Celestial Recompense],
    -- which have no flavor text.  This is needed to keep them from being categorized as PTS containers.
    if data.flavorText == "" and string.find(data.icon, "quest_container_001") 
       and data.quality < ITEM_QUALITY_ARTIFACT
    then
        return self:IsUnboxableMatch()
    end
    
    
    if addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_UNKNOWN_ITEM_PATTERN) -- "Unknown Item" boxes
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_UNKNOWN_ITEM_LOWER)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_UNKNOWN_ITEM_LOWER)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_STRONG_BOX_LOWER) -- "strongbox" items
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_STRONG_BOX2_LOWER)
    then
        return self:IsUnboxableMatch()
    end
    
    
    
    --[[ EVERYTHING BELOW HERE SHOULD EXCLUDE SPECIFICALLY-MATCHED PTS GEAR ]]--
    if self.pts:MatchExceptIcon(data) then return end
    
    
    
    
    if self:MatchDlcNameText(data.name) or self:MatchDlcNameText(data.flavorText) then
        return self:IsUnboxableMatch()
    end
end

function class.Solo:MatchDlcNameText(text)
    for _, dlc in ipairs(self:GetDlcs()) do
        if string.find(text, dlc.name) or string.find(text, dlc.zoneName) then
            return true
        end
    end
end


function class.Solo:GetDlcs()
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

knownIds = {
  [54986]  = true, -- Sealed Urn
  [79502]  = true, -- Bloody Bag
  [79503]  = true, -- Sealed Crate
  [79504]  = true, -- Unmarked Sack, dropped from DB shadowy supplier
  [79677]  = true, -- Assassin's Potion Kit, dropped from DB shadowy supplier
  [134969] = true, -- Item Set: Health Rings, level up bonus
}

  