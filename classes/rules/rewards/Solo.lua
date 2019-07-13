
-- Solo activites (e.g. non-repeatable solo quests, level-up rewards, etc.)

local addon = Unboxer
local class = addon:Namespace("rules.rewards")
local rules = addon.classes.rules
local knownIds
local debug = false
local staticDlcs
local submenu = GetString(SI_UNBOXER_QUEST_REWARDS)

class.Solo = addon.classes.Rule:Subclass()
function class.Solo:New()
    return addon.classes.Rule.New(
        self, 
        {
            name           = "solo",
            exampleItemIds = {
                126012, -- [Waterlogged Strong Box]
                79502,  -- [Bloody Bag]
                146037, -- [Recovered Murkmire Weapon]
            },
            dependencies   = { "crafting", "excluded3", "festival", "furnisher", "materials", "legerdemain", "pvp", "trial", "vendorgear", "shadowysupplier", "solorepeatable", "telvar" },
            submenu        = submenu,
            title          = GetString(SI_UNBOXER_SOLO),
            knownIds       = knownIds
        })
end

function class.Solo:Match(data)
    
    -- All the vendor-supplied "Unidentified" weapon and armor boxes are already matched
    -- because of the "vendorGear" dependency in the constructor.
    -- Any others are zone quest drops, so match them here.
    if data.quality > ITEM_QUALITY_NORMAL
       and (addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_UNIDENTIFIED_LOWER)
            or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_UNIDENTIFIED2_LOWER))
    then
        return true
    end
  
    -- Matches containers like 81226 [Unidentified Craglorn Weapon] and 87704 [Serpent's Celestial Recompense],
    -- which have no flavor text.  This is needed to keep them from being categorized as PTS containers.
    if data.flavorText == "" and string.find(data.icon, "quest_container_001") 
       and data.quality < ITEM_QUALITY_ARTIFACT
    then
        return true
    end
    
    if addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_UNKNOWN_ITEM_PATTERN) -- "Unknown Item" boxes
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_UNKNOWN_ITEM_LOWER)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_UNKNOWN_ITEM_LOWER)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_STRONG_BOX_LOWER) -- "strongbox" items
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_STRONG_BOX2_LOWER)
       or data.flavorText == GetString(SI_UNBOXER_LEGACY_QUEST_FLAVOR) -- "This large box has some unknown item inside."
       or self:MatchDlcNameText(data.name)
       or self:MatchDlcNameText(data.flavorText)
    then
        return true
    end
    
    -- Fix for untranslated text not matching
    if string.find(data.icon, "quest_container_") and not string.find(data.icon, "quest_container_[0-9]") then
        return true
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
        local name = LocaleAwareToLower(zo_strformat("<<1>>", GetCollectibleName(collectibleId)))
        dlcCollectibles[collectibleId] = name
    end
    local zoneIndex = 1
    local misses = 0 -- keep track of how many empty zone names are found
    while true do
        local zoneName = GetZoneNameByIndex(zoneIndex)
        if(zoneName == "") then -- if more than 10 zone names come up empty, assume we are done. allows for a few to go missing due to not being translated.
            misses = misses + 1
            if misses > 10 then
                break
            end
        end
        local zoneId = GetZoneId(zoneIndex)
        local parentZoneId = GetParentZoneId(zoneId)
        local collectibleId = GetCollectibleIdForZone(zoneIndex)
        if collectibleId and dlcCollectibles[collectibleId] and zoneId == parentZoneId then
            zoneName = LocaleAwareToLower(zo_strformat("<<1>>", zoneName))
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
  [54986]  = 1, -- [Sealed Urn]
  [56865]  = 1, -- [Nirnhoned Coffer], awarded from Craglorn story quest, not repeatable
  [79502]  = 1, -- [Bloody Bag]
  [79503]  = 1, -- [Sealed Crate]
  [81601]  = 1, -- [Nirnhoned Coffer], awarded from Craglorn story quest, not repeatable
  [134969] = 1, -- [Item Set: Health Rings], level up bonus
  [45003]=1,[45004]=1,[55263]=1,[55358]=1,[55947]=1,
  [55948]=1,[73757]=1,[73758]=1,[73759]=1,[73760]=1,
  [73761]=1,[73762]=1,[73763]=1,[73764]=1,[73765]=1,[73766]=1,
  [73767]=1,[73768]=1,[73769]=1,[73770]=1,[77528]=1,[77529]=1,
  [77530]=1,[77531]=1,[77532]=1,[77533]=1,[77535]=1,[77536]=1,
  [77537]=1,[77538]=1,[77539]=1,[77540]=1,[77541]=1,[77542]=1,
  [77543]=1,[77544]=1,[77545]=1,[77546]=1,[77573]=1,[77574]=1,
  [78002]=1,[79489]=1,[79490]=1,[79491]=1,[79492]=1,[79493]=1,
  [79676]=1,[81226]=1,[81227]=1,[81560]=1,
  [81564]=1,[81565]=1,[87710]=1,[87711]=1,[87712]=1,
  [87713]=1,[87714]=1,[87715]=1,[87716]=1,[87717]=1,[87718]=1,
  [87719]=1,[87720]=1,[87721]=1,[87722]=1,[87723]=1,[87724]=1,
  [87725]=1,[87726]=1,[87727]=1,[87728]=1,[87729]=1,[87730]=1,
  [87731]=1,[87732]=1,[87733]=1,[87734]=1,[87735]=1,[87736]=1,
  [87737]=1,[87738]=1,[87739]=1,[87740]=1,[87741]=1,[87742]=1,
  [87743]=1,[87744]=1,[87745]=1,[87746]=1,[94085]=1,[94086]=1,
  [96969]=1,[126012]=1,[138790]=1,[140287]=1,[140288]=1,
  [140289]=1,[140290]=1,[140291]=1,[140292]=1,[140293]=1,[140294]=1,
  [140295]=1,[140296]=1,[145546]=1,[145558]=1,[145559]=1,[145560]=1,
  [145561]=1,[145562]=1,[145563]=1,[145564]=1,[145565]=1,[145566]=1,
  [145567]=1,[145568]=1,[146037]=1,[152242]=1
}

  