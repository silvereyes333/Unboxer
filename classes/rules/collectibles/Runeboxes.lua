
-- Runeboxes

local addon = Unboxer
local class = addon:Namespace("rules.collectibles")
local debug = false

-- Collectibles submenu
local submenu = GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_COLLECTIBLE)

local runeboxCollectibleCategoryTypes
class.Runeboxes  = class.Rule:Subclass()
function class.Runeboxes:New()
    return class.Rule.New(
        self, 
        {
            name          = "runeboxes",
            exampleItemId = 96951, -- [Runebox: Nordic Bather's Towel]
            dependencies  = { "outfitstyles" },
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_RUNEBOXES),
            tooltip       = GetString(SI_UNBOXER_RUNEBOXES_TOOLTIP),
        })
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