local addon = Unboxer
local class = addon.classes
local debug = false

--[[ COLLECTIBLES RULES ]]--


-- Runeboxes
local runeboxCollectibleCategoryTypes
class.Runeboxes  = class.Rule:Subclass()
function class.Runeboxes:New()
    return class.Rule.New(self, 
      "runeboxes",
      96951,	-- [Runebox: Nordic Bather's Towel]
      { -- dependencies
          "outfitstyles",
      }
    )
end

function class.Runeboxes:Match(data)
    if data.collectibleCategoryType 
       and runeboxCollectibleCategoryTypes[data.collectibleCategoryType]
    then
        return true,                     -- isMatch
               data.collectibleUnlocked  -- canUnbox
    end
end

runeboxCollectibleCategoryTypes = {
  [COLLECTIBLE_CATEGORY_TYPE_ABILITY_SKIN] = true,
  [COLLECTIBLE_CATEGORY_TYPE_ASSISTANT] = true,
  [COLLECTIBLE_CATEGORY_TYPE_BODY_MARKING] = true,
  [COLLECTIBLE_CATEGORY_TYPE_COSTUME] = true,
  [COLLECTIBLE_CATEGORY_TYPE_EMOTE] = true,
  [COLLECTIBLE_CATEGORY_TYPE_FACIAL_ACCESSORY] = true,
  [COLLECTIBLE_CATEGORY_TYPE_FACIAL_HAIR_HORNS] = true,
  [COLLECTIBLE_CATEGORY_TYPE_HAIR] = true,
  [COLLECTIBLE_CATEGORY_TYPE_HAT] = true,
  [COLLECTIBLE_CATEGORY_TYPE_HEAD_MARKING] = true,
  [COLLECTIBLE_CATEGORY_TYPE_MEMENTO] = true,
  [COLLECTIBLE_CATEGORY_TYPE_PERSONALITY] = true,
  [COLLECTIBLE_CATEGORY_TYPE_PIERCING_JEWELRY] = true,
  [COLLECTIBLE_CATEGORY_TYPE_POLYMORPH] = true,
  [COLLECTIBLE_CATEGORY_TYPE_SKIN] = true,
  [COLLECTIBLE_CATEGORY_TYPE_VANITY_PET] = true,
}


-- Style Pages
local stylePages
class.StylePages  = class.Rule:Subclass()
function class.StylePages:New()
    return class.Rule.New(self, 
      "outfitstyles",
      140309 --	[Style Page: Molag Kena's Shoulder]
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