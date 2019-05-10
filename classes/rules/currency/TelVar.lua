
-- Tel Var Sachels/Crates

local addon = Unboxer
local class = addon:Namespace("rules.currency")
local debug = false
local submenu = GetString(SI_INVENTORY_MODE_CURRENCY)

class.TelVar = class.Rule:Subclass()
function class.TelVar:New()
    return class.Rule.New(
        self, 
        {
            name          = "telvar",
            exampleItemId = 69413, -- Light Tel Var Satchel
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_TEL_VAR_STONES),
        })
end

function class.TelVar:Match(data)
  
    -- Exclude PTS containers
    if data.flavorText == "" or string.find(data.name, ":") or data.bindType ~= BIND_TYPE_ON_PICKUP then
        return
    end
    
    -- Light, Medium and Heavy Tel Var sacks
    if addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_TEL_VAR_LOWER) then
        return self:IsUnboxableMatch()
    end
end
