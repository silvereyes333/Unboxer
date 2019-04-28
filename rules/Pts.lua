local addon = Unboxer
local class = addon.classes
local debug = false

-- PTS
class.Pts = class.Rule:Subclass()
function class.Pts:New()
    return class.Rule.New(self, 
      "pts",
      141774, -- [Dremora Plunder Skull, Dungeon]
      { -- dependencies
          "dungeon",
          "trial",
          "vendorGear",
          "zone",
      }
    )
end

function class.Pts:Match(data)
    if data.flavorText == "" -- if flavorText is still empty after processing dependencies, assume PTS box
       or GetItemLinkOnUseAbilityInfo(data.itemLink) -- only PTS boxes grant abilities
       or string.find(data.flavorText, " pts ")
       or self:MatchItemSetsText(data.name)
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
end