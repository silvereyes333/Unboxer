local addon = Unboxer
local class = addon.classes
local debug = false

--[[ VENDOR CONTAINER RULES ]]--


-- Mages Guild Reprints
class.MagesGuildReprints  = class.Rule:Subclass()
function class.MagesGuildReprints:New()
    return class.Rule.New(self, 
      "mageGuildReprints",
      120384 -- [Guild Reprint: Daedric Princes]
    )
end

function class.MagesGuildReprints:Match(data)
    if string.find(data.icon, 'housing.*book') then
        return true, -- isMatch
               true  -- canUnbox
    end
end


-- Furnisher Documents
class.Furnisher = class.Rule:Subclass()
function class.Furnisher:New()
    return class.Rule.New(self, 
      "furnisher",
      134683 -- [Morrowind Master Furnisher's Document]
    )
end

function class.Furnisher:Match(data)
    if data.bindType == BIND_TYPE_ON_PICKUP 
       and addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FURNISHING_LOWER)
    then
        return true, -- isMatch
               true  -- canUnbox
    end
end


-- Vendor Equipment Boxes
local vendorGear
class.VendorGear = class.Rule:Subclass()
function class.VendorGear:New()
    return class.Rule.New(self, 
      "vendorGear",
      117643 -- [Black Rose Equipment Box]
    )
end

function class.VendorGear:Match(data)
    
    -- Match various known vendors
    if vendorGear[data.itemId]
       or string.find(data.icon, 'zonebag')                                                          -- Regional Equipment Vendor
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_RENOWNED_LOWER)          -- Regional Equipment Vendor (backup in case icon changes)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_BATTLEGROUND_LOWER)            -- Battlegrounds Equipment Vendor
       or addon:StringContainsNotAtStart(data.name, SI_UNBOXER_JEWELRY_BOX_LOWER)                    -- Tel-Var Jewelry Merchant (legacy)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_EQUIPMENT_BOX_LOWER)           -- Tel-Var Equipment Vendor (current)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_EQUIPMENT_BOX2_LOWER)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_CP160_ADVENTURERS_LOWER) -- Tel-Var Equipment Vendor (legacy)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_COMMON_LOWER)            -- Legacy "Unidentified" gear
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_OFFENSIVE_LOWER)         -- Elite Gear Vendor 
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_DEFENSIVE_LOWER)         -- Elite Gear Vendor
    then
        return true, -- isMatch
               true  -- canUnbox
    end
    
    -- Match generic leveling containers like 55328	[Secret Heavy Armor], which have no flavor text
    if data.flavorText == "" and string.find(data.icon, "quest_container_001") 
       and data.quality < ITEM_QUALITY_ARTIFACT
       and self:MatchGenericEquipmentText(data.name)
    then
        return true, -- isMatch
               true  -- canUnbox
    end
end

function class.VendorGear:MatchGenericEquipmentText(text)
    local stringIds = { 
        SI_UNBOXER_1H_WEAPON_LOWER, SI_UNBOXER_2H_WEAPON_LOWER, SI_UNBOXER_METAL_WEAPON_LOWER,
        SI_UNBOXER_WOOD_WEAPON_LOWER, SI_UNBOXER_ACCESSORY_LOWER, SI_UNBOXER_HEAVY_ARMOR_LOWER,
        SI_UNBOXER_LIGHT_ARMOR_LOWER, SI_UNBOXER_MEDIUM_ARMOR_LOWER, SI_UNBOXER_STAFF_LOWER
    }
    for _, stringId in ipairs(stringIds) do
        if addon:StringContainsStringIdOrDefault(text, stringId) then
            return true
        end
    end
end

vendorGear = {
  [69416] = true,
  [69418] = true,
}