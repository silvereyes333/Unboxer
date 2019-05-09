
-- Furnisher Documents

local addon = Unboxer
local class = addon.classes
local debug = false
local submenu = GetString(SI_GAMEPAD_VENDOR_CATEGORY_HEADER)

class.Furnisher = class.Rule:Subclass()
function class.Furnisher:New()
    local instance = class.Rule.New(
        self, 
        {
            name          = "furnisher",
            exampleItemId = 134683, -- [Morrowind Master Furnisher's Document]
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_FURNISHER),
        })
    instance.pts = class.Pts:New()
    return instance
end

function class.Furnisher:Match(data)
  
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