
-- Furnisher Documents

local addon = Unboxer
local class = addon:Namespace("rules.vendor")
local rules = addon.classes.rules
local knownIds
local debug = false
local submenu = GetString(SI_GAMEPAD_VENDOR_CATEGORY_HEADER)

class.Furnisher = addon.classes.Rule:Subclass()
function class.Furnisher:New()
    local instance = addon.classes.Rule.New(
        self, 
        {
            name          = "furnisher",
            exampleItemId = 134683, -- [Morrowind Master Furnisher's Document]
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_FURNISHER),
            knownIds      = knownIds,
        })
    instance.pts = rules.Pts:New()
    return instance
end

function class.Furnisher:Match(data)
  
    -- Match preloaded ids
    if knownIds[data.itemId] then 
        return self:IsUnboxableMatch()
    end
  
    -- Exclude PTS items
    if self.pts:MatchAbsoluteIndicators(data) then
        return
    end
    
    if data.bindType == BIND_TYPE_ON_PICKUP 
       and addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FURNISHING_LOWER)
    then
        return self:IsUnboxableMatch()
    end
end

knownIds = {
  [121364]=1,[127106]=1,[134681]=1,[134682]=1,[134683]=1,[134684]=1
}