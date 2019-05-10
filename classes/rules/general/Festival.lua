
-- Events / Festivals

local addon = Unboxer
local class = addon:Namespace("rules.general")
local debug = false
local submenu = GetString(SI_GAMEPLAY_OPTIONS_GENERAL)

class.Festival = addon.classes.Rule:Subclass()
function class.Festival:New()
    return addon.classes.Rule.New(
        self, 
        {
            name          = "festival",
            exampleItemId = 141774, -- [Dremora Plunder Skull, Dungeon]
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_FESTIVAL),
        })
end

function class.Festival:Match(data)
    
    -- Exclude PTS item
    if data.itemId == 147759 then
        return
    end
  
    if string.find(data.icon, 'event_') -- Icons with "event_" in them
       or (string.find(data.icon, 'gift') -- Icons with "gift" in them need to have additional name checks to exclude some PTS containers
           and (addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_GIFT_LOWER)
                or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_REWARD_LOWER)
                or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_BOX_LOWER)
                or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_BOX2_LOWER)
                or data.name == "CONTAINER")) -- fix for untranslated ruESO boxes
    then
        return self:IsUnboxableMatch()
    end
end