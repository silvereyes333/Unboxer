local addon = Unboxer
local class = addon.classes
local debug = false

--[[ MISCELLANEOUS SPECIAL CONTAINER RULES ]]--


-- Festival / Events
class.Festival = class.Rule:Subclass()
function class.Festival:New()
    return class.Rule.New(self, 
      "festival",
      141774 -- [Dremora Plunder Skull, Dungeon]
    )
end

function class.Festival:Match(data)
    if string.find(data.icon, 'event_') -- Icons with "event_" in them
       or (string.find(data.icon, 'gift') -- Icons with "gift" in them need to have additional name checks to exclude some PTS containers
           and (addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_GIFT_LOWER)
                or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_REWARD_LOWER)
                or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_BOX_LOWER)
                or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_BOX2_LOWER)))
    then
        return true, -- isMatch
               true  -- canUnbox
    end
end


-- Fishing
class.Fishing = class.Rule:Subclass()
function class.Fishing:New()
    return class.Rule.New(self, 
      "fishing",
      43757 -- [Wet Gunny Sack]
    )
end

function class.Fishing:Match(data)
    if addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FISHING_LOWER) then
        return true, -- isMatch
               true  -- canUnbox
    end
end


-- Transmutation Geodes
class.Transmutation = class.Rule:Subclass()
function class.Transmutation:New()
    return class.Rule.New(self, 
      "transmutation",
      134623 -- [Uncracked Transmutation Geode]
    )
end

function class.Transmutation:Match(data)
    if addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_TRANSMUTATION_LOWER) then
        return true, -- isMatch
               true  -- canUnbox
    end
end


-- Treasure Maps
class.TreasureMaps = class.Rule:Subclass()
function class.TreasureMaps:New()
    return class.Rule.New(self, 
      "treasureMaps",
      45882	-- [Coldharbour Treasure Map]
    )
end

function class.TreasureMaps:Match(data)
    if addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_TREASURE_MAP_LOWER) then
        return true, -- isMatch
               true  -- canUnbox
    end
end