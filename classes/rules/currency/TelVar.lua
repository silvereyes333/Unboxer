
-- Tel Var Sachels/Crates

local addon = Unboxer
local class = addon:Namespace("rules.currency")
local knownIds
local debug = false
local submenu = GetString(SI_INVENTORY_MODE_CURRENCY)

class.TelVar = addon.classes.Rule:Subclass()
function class.TelVar:New()
    return addon.classes.Rule.New(
        self, 
        {
            name          = "telvar",
            exampleItemId = 69413, -- Light Tel Var Satchel
            dependencies  = { "excluded" },
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_TEL_VAR_STONES),
            knownIds      = knownIds,
        })
end

function class.TelVar:Match(data)
  
    -- Match preloaded ids
    if knownIds[data.itemId] then 
        return self:IsUnboxableMatch()
    end
  
    -- Exclude PTS containers
    if data.flavorText == "" 
       or addon:StringContainsPunctuationColon(data.name) 
       or data.bindType ~= BIND_TYPE_ON_PICKUP
    then
        return
    end
    
    -- Light, Medium and Heavy Tel Var sacks
    if addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_TEL_VAR_LOWER) then
        return self:IsUnboxableMatch()
    end
end

knownIds = {
  [69413]=1,[69414]=1,[69415]=1,[69433]=1
}