
-- Vendor Equipment Boxes

local addon = Unboxer
local class = addon.classes
local vendorGear
local debug = false
local submenu = GetString(SI_GAMEPAD_VENDOR_CATEGORY_HEADER)

class.VendorGear = class.Rule:Subclass()
function class.VendorGear:New()
    local instance = class.Rule.New(self, 
      "vendorGear",
      117643 -- [Black Rose Equipment Box]
    )
    instance.pts = addon.classes.Pts:New()
    return instance
end

function class.VendorGear:Match(data)
    
    if string.find(data.name, ":") 
       or self.pts:MatchAbsoluteIndicators(data)
    then
        return
    end
    
    -- Match various known vendors
    if vendorGear[data.itemId]
       or string.find(data.icon, 'zonebag')                                                          -- Regional Equipment Vendor
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_RENOWNED_LOWER)          -- Regional Equipment Vendor (backup in case icon changes)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_BATTLEGROUND_LOWER)            -- Battlegrounds Equipment Vendor
       or addon:StringContainsNotAtStart(data.name, SI_UNBOXER_JEWELRY_BOX_LOWER)                    -- Tel-Var Jewelry Merchant (legacy)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_EQUIPMENT_BOX_LOWER)           -- Tel-Var Equipment Vendor (current)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_EQUIPMENT_BOX2_LOWER)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_ARMOR_BOX_LOWER)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_CP160_ADVENTURERS_LOWER) -- Tel-Var Equipment Vendor (legacy)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_COMMON_LOWER)            -- Legacy "Unidentified" gear
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_OFFENSIVE_LOWER)         -- Elite Gear Vendor 
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_DEFENSIVE_LOWER)         -- Elite Gear Vendor
    then
        return self:IsUnboxableMatch()
    end
    
    -- Match generic leveling containers like 55328	[Secret Heavy Armor], which have no flavor text
    if data.flavorText == "" and string.find(data.icon, "quest_container_001") 
       and data.quality < ITEM_QUALITY_ARTIFACT
       and self:MatchGenericEquipmentText(data.name)
    then
        return self:IsUnboxableMatch()
    end
    
    -- Match non-legendary enchantment boxes (legacy)
    if data.quality < ITEM_QUALITY_LEGENDARY
       and addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_ENCHANTMENT_LOWER)
    then
        return self:IsUnboxableMatch()
    end
end

function class.VendorGear:MatchGenericEquipmentText(text)
    local stringIds = { 
        SI_UNBOXER_1H_WEAPON_LOWER, SI_UNBOXER_2H_WEAPON_LOWER, SI_UNBOXER_METAL_WEAPON_LOWER,
        SI_UNBOXER_WOOD_WEAPON_LOWER, SI_UNBOXER_ACCESSORY_LOWER, SI_UNBOXER_HEAVY_ARMOR_LOWER,
        SI_UNBOXER_LIGHT_ARMOR_LOWER, SI_UNBOXER_MEDIUM_ARMOR_LOWER, SI_UNBOXER_STAFF_LOWER,
        SI_UNBOXER_EQUIPMENT_LOWER
    }
    for _, stringId in ipairs(stringIds) do
        if addon:StringContainsStringIdOrDefault(text, stringId) then
            return true
        end
    end
end

vendorGear = {
  [69416]  = true, -- Unknown Imperial Reward
  [69418]  = true, -- Superb Imperial Reward
  [44798]  = true, -- Unidentified Accessory
  [44891]  = true, -- Unidentified Armor
  [44892]  = true, -- Unidentified Weapon
  [117924] = true  -- Superb Imperial Reward
}