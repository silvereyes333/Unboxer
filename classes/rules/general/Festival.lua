
-- Events / Festivals

local addon = Unboxer
local class = addon:Namespace("rules.general")
local knownIds
local debug = false
local submenu = GetString(SI_GAMEPLAY_OPTIONS_GENERAL)

class.Festival = addon.classes.Rule:Subclass()
function class.Festival:New()
    return addon.classes.Rule.New(
        self, 
        {
            name          = "festival",
            exampleItemId = 141774, -- [Dremora Plunder Skull, Dungeon]
            dependencies  = { "excluded" },
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_FESTIVAL),
            knownIds      = knownIds,
        })
end

function class.Festival:Match(data)
    
    -- Match preloaded ids
    if knownIds[data.itemId] then 
        return self:IsUnboxableMatch()
    end
    
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

knownIds = {
  [84521]=1,[96390]=1,[114949]=1,[115023]=1,[121526]=1,[128358]=1,[133557]=1,[134245]=1,
  [134797]=1,[134978]=1,[140216]=1,[141770]=1,[141771]=1,[141772]=1,[141773]=1,[141774]=1,
  [141775]=1,[141776]=1,[141777]=1,[141823]=1,[145490]=1,[147430]=1,[147431]=1,[147432]=1,
  [147433]=1,[147434]=1,[147477]=1,[147637]=1,[150813]=1,[151560]=1
}