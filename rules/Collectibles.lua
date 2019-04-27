local addon = Unboxer
local class = addon.classes
local debug = false

--[[ COLLECTIBLES RULES ]]--


-- Runeboxes
class.Runeboxes  = class.Rule:Subclass()
function class.Runeboxes:New()
    return class.Rule.New(self, 
      "runeboxes",
      96951	-- [Runebox: Nordic Bather's Towel]
    )
end

function class.Runeboxes:Match(data)
    if data.collectibleCategoryType == COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE then
        return true,                     -- isMatch
               data.collectibleUnlocked  -- canUnbox
    end
end


-- Style Pages
class.StylePages  = class.Rule:Subclass()
function class.StylePages:New()
    return class.Rule.New(self, 
      "outfitstyles",
      140309 --	[Style Page: Molag Kena's Shoulder]
    )
end

function class.StylePages:Match(data)
    if data.collectibleCategoryType ~= COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE then
        return true,                     -- isMatch
               data.collectibleUnlocked  -- canUnbox
    end
end