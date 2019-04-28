local addon = Unboxer
local class = addon.classes
local debug = false

--[[ MISCELLANEOUS SPECIAL CONTAINER RULES ]]--


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
      134683 -- [Morrowind Master Furnisher's Document]
    )
end

function class.Transmutation:Match(data)
    if self:StringContainsStringIdOrDefault(name, SI_UNBOXER_TRANSMUTATION_LOWER) then
        return true, -- isMatch
               true  -- canUnbox
    end
end