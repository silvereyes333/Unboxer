
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
            exampleItemIds = {
                141823, -- [New Life Festival Box]
                84521,  -- [Plunder Skull]
                140216, -- [Anniversary Jubilee Gift Box]
            },
            dependencies  = { "excluded" },
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_FESTIVAL),
            knownIds      = knownIds,
        })
end

function class.Festival:Match(data)
    
    if data.specializedItemType and data.specializedItemType == SPECIALIZED_ITEMTYPE_CONTAINER_EVENT then
        return true
    end
    if string.find(data.icon, 'event_') -- Icons with "event_" in them
       or string.find(data.icon, 'gift') -- Icons with "gift" in them 
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_FESTIVAL_LOWER) -- Name includes "festival"
    then
        return true
    end
end

knownIds = {
  [153635] = 1, -- Dragonfall Strongbox
  [84521]=1,[96390]=1,[114949]=1,[115023]=1,[121526]=1,[128358]=1,
  [133557]=1,[134245]=1,[134797]=1,[134978]=1,[140216]=1,[141770]=1,
  [141771]=1,[141772]=1,[141773]=1,[141774]=1,[141775]=1,[141776]=1,
  [141777]=1,[141823]=1,[145490]=1,[147430]=1,[147431]=1,[147432]=1,
  [147433]=1,[147434]=1,[147477]=1,[147637]=1,[150813]=1,[151560]=1,
  [153504]=1,[153505]=1,[153538]=1,[153507]=1,[153508]=1,[153509]=1,
  [153607]=1,[153616]=1,[153617]=1,[153618]=1,[153719]=1,[153720]=1,
  [153721]=1,[153722]=1,[153506]=1,[153756]=1,[153534]=1,[153502]=1,
  [153503]=1,
}