local addon = Unboxer
local class = addon.classes
local debug = false

-- PTS
class.Pts = class.Rule:Subclass()
function class.Pts:New()
    return class.Rule.New(self, 
      "pts",
      119566, -- [Exquisite Furniture Tome]
      { -- dependencies
          "dungeon",
          "mageGuildReprints",
          "outfitstyles",
          "runeboxes",
          "treasureMaps",
          "trial",
          "vendorGear",
          "zone",
      }
    )
end

function class.Pts:Match(data)
    if self:MatchExceptIcon(data)
       or (string.find(data.icon, "quest_container_001") -- misc containers
           and data.quality < ITEM_QUALITY_ARTIFACT)
    then
        return true, -- isMatch
               true  -- canUnbox
    end
end

function class.Pts:MatchExceptIcon(data)
    if data.flavorText == "" -- if flavorText is still empty after processing dependencies, assume PTS box
       or string.find(data.name, ":") -- if name still contains colon after processing mage guild reprints and collectibles, assume PTS box
       or data.hasSet -- if item set information is displayed on the container, even after all the tel-var merchant containers are processed, assume PTS box
       or GetItemLinkOnUseAbilityInfo(data.itemLink) -- only PTS boxes grant abilities
       or string.find(data.flavorText, " pts ")
       or self:MatchItemSetsText(data.name)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_ALL_LOWER) -- Contains the word " all " surrounded by spaces (if supported by locale)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FOUND_LOWER) -- Contains the phrase " found in " surrounded by spaces (if supported by locale)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FOUND2_LOWER)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FULL_SUITE_LOWER) -- Contains the phrase "full set" or "full suite"
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FULL_SUITE2_LOWER)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FULL_SUITE3_LOWER)
    then
        return true, -- isMatch
               true  -- canUnbox
    end
end

function class.Pts:MatchItemSetsText(text)
  
    -- Need to exclude matches for Summerset (which, translated, also matches translated 'sets')
    local summerset = LocaleAwareToLower(GetZoneNameById(1011))
    if string.find(text, summerset) then return end
    
    local startIndex, endIndex = addon:StringContainsStringIdOrDefault(text, SI_UNBOXER_ITEM_SETS_LOWER)
    if startIndex == 1 or endIndex == ZoUTF8StringLength(text) then
        return true
    end
end