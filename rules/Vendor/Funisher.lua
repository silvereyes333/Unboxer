
-- Furnisher Documents

local addon = Unboxer
local class = addon.classes
local debug = false
local submenu = GetString(SI_GAMEPAD_VENDOR_CATEGORY_HEADER)

class.Furnisher = class.Rule:Subclass()
function class.Furnisher:New()
    return class.Rule.New(self, 
      "furnisher",
      134683 -- [Morrowind Master Furnisher's Document]
    )
end

function class.Furnisher:Match(data)
    if data.bindType == BIND_TYPE_ON_PICKUP 
       and addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FURNISHING_LOWER)
    then
        return self:IsUnboxableMatch()
    end
end