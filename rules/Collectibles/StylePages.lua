-- Style Pages

local addon = Unboxer
local class = addon.classes
local stylePages
local debug = false

-- Collectibles submenu
local submenu = GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_COLLECTIBLE)

class.StylePages  = class.Rule:Subclass()
function class.StylePages:New()
    return class.Rule.New(
        self, 
        {
            name          = "outfitstyles",
            exampleItemId = 140309 --	[Style Page: Molag Kena's Shoulder]
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_OUTFITSTYLES),
            tooltip       = GetString(SI_UNBOXER_OUTFITSTYLES_TOOLTIP),
        }
    )
end

function class.StylePages:Match(data)
    if data.collectibleCategoryType 
       and data.collectibleCategoryType == COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE
    then
        return true,                     -- isMatch
               data.collectibleUnlocked  -- canUnbox
    end
    
    if stylePages[data.itemId] then
        return self:IsUnboxableMatch()
    end
end

stylePages = {
  [135005] = true, -- Ragged Style Box
  [147442] = true, -- Event Style Page: Lyris Titanborn's Helmet
  [147459] = true  -- Event Style Page: Abner Tharn's Hat
}