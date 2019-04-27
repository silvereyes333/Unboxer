Unboxer = {
    name = "Unboxer",
    title = GetString(SI_UNBOXER),
    author = "|c99CCEFsilvereyes|r",
    version = "2.9.1",
    filters = {},
    itemSlotStack = {},
    defaultLanguage = "en",
    debugMode = false,
}

local addon = Unboxer
local LLS = LibStub("LibLootSummary")
local prefix = zo_strformat("<<1>>|cFFFFFF: ", addon.title)
local itemLinkFormat = '|H1:item:<<1>>:30:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:10000:0|h|h'

-- Output formatted message to chat window, if configured
function addon.Print(input, force)
    if not force and not addon.settings.verbose then
        return
    end
    local output = zo_strformat(prefix .. "<<1>>|r", input)
    d(output)
end
function addon.Debug(input, force)
    if not force and not addon.debugMode then
        return
    end
    addon.Print(input, force)
end
--Create an exmaple item link, given an item's id
local function GetItemLinkFromItemId(itemId)
    if itemId == nil or itemId == 0 then return end
    return zo_strformat(itemLinkFormat, itemId)
end
local function GetLowerNonEmptyString(stringId, ...)
    local value
    if stringId then
        value = GetString(stringId, ...)
    end
    if not value or value == "" then
        value = "***NIL***"
    else
        value = LocaleAwareToLower(value)
    end
    return value    
end
function addon:StringContainsStringIdOrDefault(searchIn, stringId, ...)
    local searchFor = LocaleAwareToLower(GetString(stringId, ...))
    local startIndex, endIndex
    if searchFor and searchFor ~= "" then
        startIndex, endIndex = string.find(searchIn, searchFor)
    end
    if startIndex or self:IsDefaultLanguageSelected() then
        return startIndex, endIndex
    end
    -- Default strings are stored at the next esostrings index higher.
    -- See localization/CreateStrings.lua for initialization logic that guarantees this.
    local defaultStringId
    if type(stringId) == "string" then
        defaultStringId = _G[stringId] + 1
    else
        defaultStringId = stringId + 1
    end
    searchFor = LocaleAwareToLower(GetString(defaultStringId, ...))
    if not searchFor or searchFor == "" then
        return string.find(searchIn, searchFor)
    end
end


function addon:StringContainsNotAtStart(searchIn, stringId, ...)
    local startIndex, endIndex = self:StringContainsStringIdOrDefault(searchIn, stringId, ...)
    if not startIndex or startIndex == 1 then return end
    return startIndex, endIndex
end

local useCallProtectedFunction = IsProtectedFunction("UseItem")

function addon:IsItemLinkUnboxable(itemLink)
  
    if not itemLink then return false end
    
    local itemType = GetItemLinkItemType(itemLink)
    if itemType ~= ITEMTYPE_CONTAINER then return false end
    
    local itemId = GetItemLinkItemId(itemLink)
    
    -- not sure why there's no item id, but return false to be safe
    if not itemId then return false end
    
    local filterMatched = false
    
    -- Do not unbox collectible containers that have already been collected
    local collectibleId = GetItemLinkContainerCollectibleId(itemLink)
    if type(collectibleId) == "number" and collectibleId > 0 then
        
        local collectibleCategoryType = GetCollectibleCategoryType(collectibleId)
        if collectibleCategoryType == COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE then
            filterMatched = "outfitstyles"
        else
            filterMatched = "runeboxes"
        end
        
        if IsCollectibleUnlocked(collectibleId) then
            return false, filterMatched
        end
    
    -- perform filtering for non-collectible containers
    else
        for filterCategory, filters in pairs(self.filters) do
            if filterCategory ~= "collectibles" then
                for settingName, subFilters in pairs(filters) do
                    if subFilters[itemId] ~= nil then
                        filterMatched = settingName
                        break
                    end
                end
                if filterMatched then
                    break
                end
            end
        end
    end
    
    -- No filters matched.  Handle special cases and catch-all...
    if not filterMatched then
        filterMatched = "other"
    end
    
    if not self.settings[filterMatched] 
       or (self.autolooting
           and (not self.settings.autoloot or not self.settings[filterMatched.."Autoloot"]))
    then
        return false, filterMatched
    end
    
    return true, filterMatched
end

function addon:IsItemUnboxable(bagId, slotIndex)
    if bagId ~= BAG_BACKPACK then return false end
    
    local itemLink = GetItemLink(bagId, slotIndex)

    local unboxable, filterMatched = self:IsItemLinkUnboxable(itemLink)
    if not unboxable then
        return false, filterMatched
    end
    
    local usable, onlyFromActionSlot = IsItemUsable(bagId, slotIndex)
    self.Debug(tostring(itemLink)..", usable: "..tostring(usable)..", onlyFromActionSlot: "..tostring(onlyFromActionSlot))
    return usable and not onlyFromActionSlot, filterMatched
end

local HudStateChange
local UnboxCurrent
local itemLink
local timeoutItemUniqueIds = {}
local updateExpected = false
local lootReceived
local filterSetting

local function AbortAction(...)
    addon.Debug("AbortAction")
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_CLOSED)
    EVENT_MANAGER:UnregisterForUpdate(addon.name)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_COLLECTIBLE_NOTIFICATION_NEW)
    HUD_SCENE:UnregisterCallback("StateChange", HudStateChange)
    if addon.originalUpdateLootWindow then
        local lootWindow = SYSTEMS:GetObject("loot")
        lootWindow.UpdateLootWindow = addon.originalUpdateLootWindow
    end
    addon.originalUpdateLootWindow = nil
    addon.running = false
    addon.autolooting = nil
    addon.slotIndex = nil
    addon.itemSlotStack = {}
    lootReceived = nil
    updateExpected = false
    filterSetting = nil
    addon.unboxingItemLink = nil
    KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
    -- Print summary
    LLS:Print()
end

local function GetInventorySlotsNeeded(inventorySlotsNeeded)
    if not inventorySlotsNeeded then
        inventorySlotsNeeded = GetNumLootItems()
    end
    if addon.settings.reservedSlots and type(addon.settings.reservedSlots) == "number" then
        inventorySlotsNeeded = inventorySlotsNeeded + addon.settings.reservedSlots
    end
    return inventorySlotsNeeded
end
local function HasEnoughSlots(inventorySlotsNeeded)
    -- For performance reasons, just assume each box has 2 items, until the box is actually open.
    -- Then we will pass in the exact number.
    if not inventorySlotsNeeded then
        inventorySlotsNeeded = 2
    end
    inventorySlotsNeeded = GetInventorySlotsNeeded(inventorySlotsNeeded)
    return CheckInventorySpaceSilently(inventorySlotsNeeded)
end
local function HasUnboxableSlots()
    local self = addon
    if not HasEnoughSlots() and BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState() == SCENE_SHOWN then 
        return false
    end
    
    -- Disable Unbox All keybind when the player is in an invalid state for opening containers
    if IsUnitInCombat("player") or IsUnitSwimming("player") or IsUnitDeadOrReincarnating("player") then
        return false
    end
    
    if #self.itemSlotStack > 0 then return false end
    
    local bagId = BAG_BACKPACK
    local bagSlots = GetBagSize(bagId) -1
    for index = 0, bagSlots do
        if self:IsItemUnboxable(bagId, index) and CanInteractWithItem(bagId, index) then return true end
    end

    return false
end

-- Scan backpack for next unboxable container and return true if found
local function GetNextItemToUnbox()
    local self = addon
    if not HasEnoughSlots() then
        self.Debug("Not enough bag space")
        return
    end
    local menuBarState = BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState()
    if menuBarState ~= SCENE_SHOWN then
        self.Debug("Backpack menu bar layout fragment not shown: "..tostring(menuBarState))
        return
    end

    local bagId = BAG_BACKPACK
    local bagSlots = GetBagSize(bagId) -1
    for index = 0, bagSlots do
        if self:IsItemUnboxable(bagId, index) and CanInteractWithItem(bagId, index) then
            return index
        end
    end
    self.Debug("No unboxable items found")
end
local function ContainsItemSetsText(search)
  
    local summerset = LocaleAwareToLower(GetZoneNameById(1011))
    if string.find(search, summerset) then return end
    
    return string.find(search, GetLowerNonEmptyString(SI_UNBOXER_ITEM_SETS))
           or string.find(search, GetLowerNonEmptyString(SI_UNBOXER_ITEM_SETS2))
end
local defaultGuildSkillLineNames = {
    "mages guild",
    "fighters guild",
    "thieves guild",
    "dark brotherhood",
    "undaunted",
    "psijic order",
}
local function ContainsGuildSkillLineName(search)
    local self = addon
    local skillType = SKILL_TYPE_GUILD
    for skillLineIndex=1, GetNumSkillLines(skillType) do
        local skillLineName = LocaleAwareToLower(GetSkillLineName(skillType, skillLineIndex))
        if string.find(search, skillLineName) then
            return true
        end
    end
    if self:IsDefaultLanguageSelected() then
        return
    end
    for _, skillLineName in ipairs(defaultGuildSkillLineNames) do
        if string.find(search, skillLineName) then
            return true
        end
    end
end
local function ContainsDailyQuestText(search)
  
    --TODO: implement
    --[[ =IFERROR(FIND("reward",LOWER(L53)),0)
    +IFERROR(FIND("daily",LOWER(L53)),0)
    +IFERROR(FIND("job",LOWER(L53)),0)
    +IFERROR(FIND("award",LOWER(L53)),0)
    +IFERROR(FIND("contract",LOWER(L53)),0) ]]
end
function addon:IsDefaultLanguageSelected()
    return GetCVar("language.2") == self.defaultLanguage
end
function addon:GetItemLinkData(itemLink)

    local itemType, specializedItemType = GetItemLinkItemType(itemLink)
    local itemId = GetItemLinkItemId(itemLink)
    local tags = {}
    for tagIndex=1,GetItemLinkNumItemTags(itemLink) do
        table.insert(tags, {GetItemLinkItemTagInfo(itemLink, tagIndex)})
    end
    local recipeIngredients = {}
    for ingredientIndex=1,GetItemLinkRecipeNumIngredients(itemLink) do
        table.insert(recipeIngredients, {GetItemLinkRecipeIngredientInfo(itemLink, ingredientIndex)})
    end
    local reagentTraits = {}
    for reagentIndex=1,3 do
        local _, reagentTraitName = GetItemLinkReagentTraitInfo(itemLink, reagentIndex)
        if reagentTraitName and reagentTraitName ~= "" then
            table.insert(reagentTraits, reagentTraitName)
        end
    end
    local icon = LocaleAwareToLower(GetItemLinkIcon(itemLink))
    local name = LocaleAwareToLower(GetItemLinkName(itemLink))
    local flavorText = LocaleAwareToLower(GetItemLinkFlavorText(itemLink))
    local filterTypeInfo = { GetItemLinkFilterTypeInfo(itemLink) }
    local setInfo = { GetItemLinkSetInfo(itemLink) }
    local hasSet, setName, _, _, _, setId = GetItemLinkSetInfo(itemLink)
    local requiredChampionPoints = GetItemLinkRequiredChampionPoints(itemLink)
    local requiredLevel = GetItemLinkRequiredLevel(itemLink)
    local quality = GetItemLinkQuality(itemLink)
    local bindType = GetItemLinkBindType(itemLink)
    
    local data = {
        ["itemId"]                 = itemId,
        ["itemLink"]               = itemLink,
        ["name"]                   = LocaleAwareToLower(GetItemLinkName(itemLink)),
        ["flavorText"]             = LocaleAwareToLower(GetItemLinkFlavorText(itemLink)),
        ["quality"]                = GetItemLinkQuality(itemLink),
        ["icon"]                   = LocaleAwareToLower(GetItemLinkIcon(itemLink)),
        ["hasSet"]                 = hasSet,
        ["setName"]                = LocaleAwareToLower(setName),
        ["setId"]                  = setId,
        ["requiredLevel"]          = GetItemLinkRequiredLevel(itemLink),
        ["requiredChampionPoints"] = GetItemLinkRequiredChampionPoints(itemLink),
        ["bindType"]               = GetItemLinkBindType(itemLink),
        ["collectibleId"]          = GetItemLinkContainerCollectibleId(itemLink),
    }
    if type(data.collectibleId) == "number" and data.collectibleId > 0 then
        data["collectibleCategoryType"] = GetCollectibleCategoryType(data.collectibleId)
        data["collectibleUnlocked"]     = IsCollectibleUnlocked(data.collectibleId)
    end
    
    local summerset = LocaleAwareToLower(GetZoneNameById(1011))
    local containerType
    if multipleLfgFound or GetItemLinkOnUseAbilityInfo(itemLink) or string.find(flavorText, " pts ")
       or ContainsItemSetsText(name)
    then
        containerType = "pts"
    elseif string.find(icon, 'housing.*book') then
        containerType = "mageGuildReprints"
    --[[ other than mages guild reprints and collectibles, the only other items containing a : colon in the name are PTS containers ]]
    elseif string.find(name, ":") then
        containerType = "pts"
    elseif setInfo[1] then
        if self:StringContainsStringIdOrDefault(name, SI_UNBOXER_EQUIPMENT_BOX_LOWER)
           or self:StringContainsStringIdOrDefault(name, SI_UNBOXER_EQUIPMENT_BOX2_LOWER)
        then
            containerType = "vendorGear"
        else
            containerType = "pts"
        end
    elseif flavorText == "" then
        if string.find(icon, "quest_container_001") 
           and quality < ITEM_QUALITY_ARTIFACT
        then
            local stringIds = { 
                SI_UNBOXER_1H_WEAPON_LOWER, SI_UNBOXER_2H_WEAPON_LOWER, SI_UNBOXER_METAL_WEAPON_LOWER,
                SI_UNBOXER_WOOD_WEAPON_LOWER, SI_UNBOXER_ACCESSORY_LOWER, SI_UNBOXER_HEAVY_ARMOR_LOWER,
                SI_UNBOXER_LIGHT_ARMOR_LOWER, SI_UNBOXER_MEDIUM_ARMOR_LOWER, SI_UNBOXER_STAFF_LOWER
            }
            for _, stringId in ipairs(stringIds) do
                if self:StringContainsStringIdOrDefault(name, stringId) then
                    containerType = "vendorGear"
                    break
                end
            end
            if not containerType then
                containerType = "zone"
            end
        else
            containerType = "pts"
        end
    elseif lfgActivity == LFG_ACTIVITY_DUNGEON then
        containerType = "dungeon"
    elseif lfgActivity == LFG_ACTIVITY_TRIAL
           or (self:StringContainsStringIdOrDefault(flavorText, SI_UNBOXER_UNDAUNTED_LOWER)
               and self:StringContainsStringIdOrDefault(flavorText, SI_UNBOXER_WEEKLY_LOWER))
    then
        containerType = "trial"
    elseif self.mostRecentInteractionType == INTERACTION_FISH then
        containerType = "fishing"
    elseif string.find(icon, 'event_')
           or (string.find(icon, 'gift') 
               and (self:StringContainsStringIdOrDefault(name, SI_UNBOXER_GIFT_LOWER)
                    or self:StringContainsStringIdOrDefault(name, SI_UNBOXER_REWARD_LOWER)
                    or self:StringContainsStringIdOrDefault(name, SI_UNBOXER_BOX_LOWER)
                    or self:StringContainsStringIdOrDefault(name, SI_UNBOXER_BOX2_LOWER))
    then
        containerType = "festival"
    elseif self:StringContainsStringIdOrDefault(name, SI_UNBOXER_RAW_MATERIAL_LOWER) then
        containerType = "materials"
    elseif bindType == BIND_TYPE_ON_PICKUP and self:StringContainsStringIdOrDefault(flavorText, SI_UNBOXER_FURNISHING_LOWER) then
        containerType = "furnisher"
    elseif self:StringContainsStringIdOrDefault(name, SI_UNBOXER_TRANSMUTATION_LOWER) then
        containerType = "transmutation"
    elseif self:StringContainsStringIdOrDefault(name, SI_UNBOXER_TREASURE_MAP_LOWER) then
        containerType = "treasureMaps"
    elseif string.find(icon, 'zonebag') 
           or self:StringContainsStringIdOrDefault(flavorText, SI_UNBOXER_RENOWNED_LOWER
           or self:StringContainsStringIdOrDefault(name, SI_UNBOXER_BATTLEGROUND_LOWER)
    then
        containerType = "vendorGear"
    elseif self:StringContainsStringIdOrDefault(flavorText, SI_UNBOXER_CRAFTED_LOWER)
           and self:StringContainsStringIdOrDefault(flavorText, SI_UNBOXER_REWARD_LOWER)
    then
        containerType = "crafting"
    elseif self:StringContainsStringIdOrDefault(flavorText, SI_UNBOXER_FISHING_LOWER) then
        containerType = "fishing"
    elseif self:StringContainsNotAtStart(name, SI_UNBOXER_JEWELRY_BOX_LOWER) then
        containerType = "vendorGear"
    elseif quality > ITEM_QUALITY_NORMAL
           and (self:StringContainsStringIdOrDefault(name, SI_UNBOXER_UNIDENTIFIED_LOWER)
                or self:StringContainsStringIdOrDefault(name, SI_UNBOXER_UNIDENTIFIED2_LOWER))
    then
        if self:StringContainsStringIdOrDefault(flavorText, SI_UNBOXER_COMMON_LOWER)
           or self:StringContainsStringIdOrDefault(flavorText, SI_UNBOXER_OFFENSIVE_LOWER) 
           or self:StringContainsStringIdOrDefault(flavorText, SI_UNBOXER_DEFENSIVE_LOWER)
        then
            containerType = "vendorGear"
        else
            containerType = "zone"
        end
    elseif self:StringContainsStringIdOrDefault(flavorText, SI_UNBOXER_CP160_ADVENTURERS_LOWER) then
        containerType = "vendorGear"
    elseif ContainsGuildSkillLineName(flavorText) then
        containerType = "zone"
    else
        containerType = "unknown"
    end
    local interactionType = addon.settings.containerDetails[itemId] and addon.settings.containerDetails[itemId]["interactionType"]
    local text = addon.settings.containerDetails[itemId] and addon.settings.containerDetails[itemId]["text"] or {}
    text[GetCVar("language.2")] = {
        ["name"] = name,
        ["bookTitle"] = GetItemLinkBookTitle(itemLink),
        ["runeName"] = {GetItemLinkEnchantingRuneName(itemLink)},
        ["flavorText"] = flavorText,
        ["tradingHouseItemSearchName"] = GetItemLinkTradingHouseItemSearchName(itemLink),
        ["setInfo"] = setInfo,
    }
    return {
        ["containerType"] = containerType,
        ["itemLink"] = itemLink,
        ["specializedItemType"] = specializedItemType,
        ["filterTypeInfo"] = filterTypeInfo,
        ["enchantId"] = GetItemLinkAppliedEnchantId(itemLink),
        ["armorRating"] = GetItemLinkArmorRating(itemLink),
        ["armorType"] = GetItemLinkArmorType(itemLink),
        ["bindType"] = bindType,
        ["collectibleEvolutionDesc"] = GetItemLinkCollectibleEvolutionDescription(itemLink),
        ["collectibleEvolutionInfo"] = {GetItemLinkCollectibleEvolutionInformation(itemLink)},
        ["comboDescription"] = GetItemLinkCombinationDescription(itemLink),
        ["condition"] = GetItemLinkCondition(itemLink),
        ["collectibleId"] = GetItemLinkContainerCollectibleId(itemLink),
        ["craftingSkillType"] = GetItemLinkCraftingSkillType(itemLink),
        ["defaultEnchantId"] = GetItemLinkDefaultEnchantId(itemLink),
        ["dyeIds"] = {GetItemLinkDyeIds(itemLink)},
        ["dyeStampId"] = GetItemLinkDyeStampId(itemLink),
        ["enchantInfo"] = {GetItemLinkEnchantInfo(itemLink)},
        ["runeClassification"] = GetItemLinkEnchantingRuneClassification(itemLink),
        ["equipType"] = GetItemLinkEquipType(itemLink),
        ["finalEnchantId"] = GetItemLinkFinalEnchantId(itemLink),
        ["furnishingLimitType"] = GetItemLinkFurnishingLimitType and GetItemLinkFurnishingLimitType(itemLink),
        ["furnitureDataId"] = GetItemLinkFurnitureDataId(itemLink),
        ["glyphMinLevels"] = {GetItemLinkGlyphMinLevels(itemLink)},
        ["recipeIndices"] = {GetItemLinkGrantedRecipeIndices(itemLink)},
        ["icon"] = icon,
        ["info"] = {GetItemLinkInfo(itemLink)},
        ["style"] = GetItemLinkItemStyle(itemLink),
        ["tags"] = tags,
        ["useType"] = GetItemLinkItemUseType(itemLink),
        ["matLevel"] = GetItemLinkMaterialLevelDescription(itemLink),
        ["maxCharges"] = GetItemLinkMaxEnchantCharges(itemLink),
        ["charges"] = GetItemLinkNumEnchantCharges(itemLink),
        ["abilities"] = {GetItemLinkOnUseAbilityInfo(itemLink)},
        ["outfitStyleId"] = GetItemLinkOutfitStyleId(itemLink),
        ["quality"] = quality,
        ["reagentTraits"] = reagentTraits,
        ["recipeCraftingSkillType"] = GetItemLinkRecipeCraftingSkillType(itemLink),
        ["recipeIngredients"] = recipeIngredients,
        ["recipeIngredientCount"] = GetItemLinkRecipeNumIngredients(itemLink),
        ["tradskillRequirementCount"] = GetItemLinkRecipeNumTradeskillRequirements(itemLink),
        ["recipeQualityRequirement"] = GetItemLinkRecipeQualityRequirement(itemLink),
        ["recipleResultItemLink"] = GetItemLinkRecipeResultItemLink(itemLink),
        ["refinedMaterialItemLink"] = GetItemLinkRefinedMaterialItemLink(itemLink),
        ["requiredChampionPoints"] = requiredChampionPoints,
        ["requiredCraftingSkillRank"] = GetItemLinkRequiredCraftingSkillRank(itemLink),
        ["requiredLevel"] = requiredLevel,
        ["sellInformation"] = GetItemLinkSellInformation(itemLink),
        ["showItemStyleInTooltip"] = GetItemLinkShowItemStyleInTooltip(itemLink),
        ["siegeMaxHP"] = GetItemLinkSiegeMaxHP(itemLink),
        ["siegeType"] = GetItemLinkSiegeType(itemLink),
        ["stacks"] = {GetItemLinkStacks(itemLink)},
        ["requiresCollectibleId"] = GetItemLinkTooltipRequiresCollectibleId(itemLink),
        ["text"] = text,
        ["traitCategory"] = GetItemLinkTraitCategory(itemLink),
        ["traitInfo"] = {GetItemLinkTraitInfo(itemLink)},
        ["traitType"] = GetItemLinkTraitType(itemLink),
        ["value"] = GetItemLinkValue(itemLink),
        ["weaponPower"] = GetItemLinkWeaponPower(itemLink),
        ["weaponType"] = GetItemLinkWeaponType(itemLink),
        ["interactionType"] = interactionType,
    }
end
local function PrintUnboxedLink()
    if not addon.unboxingItemLink then return end
    addon.Print(zo_strformat(SI_UNBOXER_UNBOXED, addon.unboxingItemLink))
    addon.unboxingItemLink = nil
end
local function UpdateInteractionType()
    local self = addon
    if GetInteractionType() > 0 and GetInteractionType() ~= 14 then
        self.mostRecentInteractionType = GetInteractionType()
        self.mostRecentInteractionTime = os.time()
    elseif self.mostRecentInteractionTime and (os.time() - self.mostRecentInteractionTime) > 5 then
        self.mostRecentInteractionType = nil
        self.mostRecentInteractionTime = nil
    end
end
local function HandleEventPlayerCombatState(eventCode, inCombat)
    if not inCombat then
        addon.Debug("Combat ended. Resume unboxing.")
        EVENT_MANAGER:UnregisterForEvent(addon.name,  EVENT_PLAYER_COMBAT_STATE)
        -- Continue unboxings
        EVENT_MANAGER:RegisterForUpdate(addon.name, addon.settings.autolootDelay * 1000, UnboxCurrent)
    end
end
local function HandleEventPlayerNotSwimming(eventCode)
    addon.Debug("Player not swimming. Resume unboxing.")
    EVENT_MANAGER:UnregisterForEvent(addon.name,  EVENT_PLAYER_NOT_SWIMMING)
    -- Continue unboxings
    EVENT_MANAGER:RegisterForUpdate(addon.name, addon.settings.autolootDelay * 1000, UnboxCurrent)
end
local function HandleEventPlayerAlive(eventCode)
    addon.Debug("Player alive again. Resume unboxing.")
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_PLAYER_ALIVE)
    -- Continue unboxings
    EVENT_MANAGER:RegisterForUpdate(addon.name, addon.settings.autolootDelay * 1000, UnboxCurrent)
end
local function HandleEventLootReceived(eventCode, receivedBy, itemLink, quantity, itemSound, lootType, lootedBySelf, isPickpocketLoot, questItemIcon, itemId)
    local self = addon
    lootReceived = true
    PrintUnboxedLink()
    if filterSetting and lootedBySelf and lootType == LOOT_TYPE_ITEM then
        if addon.settings[filterSetting .. "Summary"] then
            LLS:AddItemLink(itemLink, quantity)
        end
    end
    if GetInteractionType() > 0 and GetInteractionType() ~= 14 then
        self.mostRecentInteractionType = GetInteractionType()
        self.mostRecentInteractionTime = os.time()
    elseif self.mostRecentInteractionTime and (os.time() - self.mostRecentInteractionTime) > 5 then
        self.mostRecentInteractionType = nil
        self.mostRecentInteractionTime = nil
    end
    addon.Debug("LootReceived("..tostring(eventCode)..", "..zo_strformat("<<1>>", receivedBy)..", "..tostring(itemLink)..", "..tostring(quantity)..", "..tostring(itemSound)..", "..tostring(lootType)..", "..tostring(lootedBySelf)..", "..tostring(isPickpocketLoot)..", "..tostring(questItemIcon)..", "..tostring(itemId)..") InteractionType: "..tostring(self.mostRecentInteractionType))
end
local InventoryStateChange
local function HandleEventLootClosed(eventCode)
    addon.Debug("LootClosed("..tostring(eventCode)..")")
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_CLOSED)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_COLLECTIBLE_NOTIFICATION_NEW)
    if lootReceived then
        lootReceived = nil
        if addon.running then
            local menuBarState = BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState()
            if menuBarState == SCENE_HIDDEN then
                addon.Debug("Menu bar is hidden")
                AbortAction()
                return
            end
            if not addon.UnboxAll() then
                addon.Debug("UnboxAll returned false")
                AbortAction()
                return
            end
        end
    elseif addon.slotIndex then
        addon.Debug("lootReceived is false. attempting to loot again.")
        timeoutItemUniqueIds = {}
        table.insert(addon.itemSlotStack, addon.slotIndex)
    end
    EVENT_MANAGER:RegisterForUpdate(addon.name, 40, UnboxCurrent)
end
InventoryStateChange = function(oldState, newState)
    if newState == SCENE_SHOWING then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
    end
end
local function LootAllItemsTimeout()
    addon.Debug("LootAllItemsTimeout")
    if #timeoutItemUniqueIds == 0 then 
        addon.Debug("timeoutItemUniqueIds is empty")
        return
    end
    if not addon.slotIndex then
        addon.Debug("addon slotindex is empty")
        return
    end
    local lootingItemUniqueId = GetItemUniqueId(BAG_BACKPACK, addon.slotIndex)
    local timeoutItemUniqueId = timeoutItemUniqueIds[1]
    table.remove(timeoutItemUniqueIds, 1)
    if lootingItemUniqueId and AreId64sEqual(lootingItemUniqueId,timeoutItemUniqueId) then
        addon.Debug("Looting again, ids match")
        table.insert(timeoutItemUniqueIds, lootingItemUniqueId)
        zo_callLater(LootAllItemsTimeout, addon.settings.autolootDelay * 1000) -- If still not looted after X secs, try to loot again
        LOOT_SHARED:LootAllItems()
    end
end
local function HandleEventLootUpdated(eventCode)
    
    local self = addon
    self.Debug("LootUpdated("..tostring(eventCode)..")")
    local lootCount = GetNumLootItems()
    self.lastLootedContainers = {}
    for lootIndex = 1, lootCount do
        local lootId = GetLootItemInfo(lootIndex)
        local itemLink = GetLootItemLink(lootId)
        local itemId = GetItemLinkItemId(itemLink)
        local itemType, specializedItemType = GetItemLinkItemType(itemLink)
        if itemType == ITEMTYPE_CONTAINER then
            local targetName = GetLootTargetInfo()
            table.insert(self.lastLootedContainers, {
                    ["itemId"] = itemId,
                    ["itemLink"] = itemLink,
                    ["specializedItemType"] = specializedItemType,
                    ["lootId"] = lootId,
                    ["targetName"] = targetName
                })
        end
        self.Debug("Loot index "..tostring(lootIndex).." "..tostring(itemLink).." with target name "..tostring(targetName).." InteractionType: "..tostring(GetInteractionType()))
    end
  
    if not self.slotIndex then
        self.Debug("addon slotindex is empty")
        if addon.unboxingAll or addon.autolooting then
            EndLooting()
        end
        return
    end
    -- do a dumb check for inventory slot availability
    --[[ TODO: Be smarter, taking into account stacking slots and craft bag. 
               Maybe make a library to do this, since Postmaster could use it too.
               Could get expensive, scanning the whole bag at time of loot, though.
               Some sort of data structure / index is needed. ]]
    local inventorySlotsNeeded = GetInventorySlotsNeeded()
    if not CheckInventorySpaceAndWarn(inventorySlotsNeeded) then
        self.Debug("not enough space")
        AbortAction()
        EndLooting()
        return
    end
    table.insert(timeoutItemUniqueIds, GetItemUniqueId(BAG_BACKPACK, self.slotIndex))
    zo_callLater(LootAllItemsTimeout, self.settings.autolootDelay * 1000) -- If still not looted after X secs, try to loot again
    LOOT_SHARED:LootAllItems()
end
local function HandleEventNewCollectible(eventCode, collectibleId)
    lootReceived = true
    PrintUnboxedLink()
end
local function EndInteractWait()
    addon.Debug("Interaction wait over. Starting up unboxing again.")
    addon.interactWait = nil
    EVENT_MANAGER:UnregisterForUpdate(addon.name.."InteractWait")
    UnboxCurrent()
end
local function StartInteractWait()
    addon.Debug("Interaction ended. Waiting ".. addon.settings.autolootDelay .." seconds to try unboxing again.")
    INTERACT_WINDOW:UnregisterCallback("Hidden", HandleInteractWindowHidden)
    HUD_SCENE:UnregisterCallback("StateChange", HudStateChange)
    EVENT_MANAGER:UnregisterForUpdate(addon.name.."InteractWait")
    EVENT_MANAGER:RegisterForUpdate(addon.name.."InteractWait", addon.settings.autolootDelay * 1000, EndInteractWait)
end
local HandleInteractWindowHidden
HandleInteractWindowHidden = function()
    StartInteractWait()
end
HudStateChange = function(oldState, newState)
    if newState ~= SCENE_SHOWN then return end
    StartInteractWait()
end
local suppressLootWindow = function() end
UnboxCurrent = function()
    local self = addon
    EVENT_MANAGER:UnregisterForUpdate(self.name)
    local slotIndex
    if #self.itemSlotStack > 0 then
        slotIndex = table.remove(self.itemSlotStack)
    else
        self.Debug("No items in item slot stack")
        AbortAction()
        return
    end
    local isUnboxable
    isUnboxable, filterSetting = self:IsItemUnboxable(BAG_BACKPACK, slotIndex)
    if isUnboxable then
        if INTERACT_WINDOW:IsInteracting() then
            self.Debug("Interaction window is open.")
            if self.unboxingAll then
                AbortAction()
                PlaySound(SOUNDS.NEGATIVE_CLICK)
            else
                self.Debug("Waiting until it closes to open slotIndex "..tostring(slotIndex))
                table.insert(self.itemSlotStack, slotIndex)
                self.interactWait = true
                HUD_SCENE:RegisterCallback("StateChange", HudStateChange)
                INTERACT_WINDOW:RegisterCallback("Hidden", HandleInteractWindowHidden)
            end
            return
            
        elseif self.interactWait then
            self.Debug("Waiting for interaction timeout to handle unboxing slotIndex "..tostring(slotIndex))
            table.insert(self.itemSlotStack, slotIndex)
            return
            
         -- Fix for some containers sometimes not being interactable. Just wait a second and try again.
         -- I wonder if this happens due to a race condition with the IsInteracting() check above.
        elseif not CanInteractWithItem(BAG_BACKPACK, slotIndex) then
            self.Debug("Slot index "..tostring(slotIndex).." is not interactable right now.")
            if self.unboxingAll then
                AbortAction()
                PlaySound(SOUNDS.NEGATIVE_CLICK)
            else
                self.Debug("Waiting 1 second...")
                table.insert(self.itemSlotStack, slotIndex)
                EVENT_MANAGER:RegisterForUpdate(self.name, 1000, UnboxCurrent)
            end
            return
        
        -- If unit is in combat, then wait for combat to end and try again
        elseif IsUnitInCombat("player") then
            self.Debug("Player is in combat.")
            if self.unboxingAll then
                AbortAction()
                PlaySound(SOUNDS.NEGATIVE_CLICK)
            else
                self.Debug("Waiting for combat to end.")
                table.insert(self.itemSlotStack, slotIndex)
                EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_COMBAT_STATE, HandleEventPlayerCombatState)
            end
            return
        
        -- If unit is swimming, then wait for swimming to end and try again
        elseif IsUnitSwimming("player") then
            self.Debug("Player is swimming.")
            if self.unboxingAll then
                AbortAction()
                PlaySound(SOUNDS.NEGATIVE_CLICK)
            else
                self.Debug("Waiting for swimming to end.")
                table.insert(self.itemSlotStack, slotIndex)
                EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_NOT_SWIMMING, HandleEventPlayerNotSwimming)
            end
            return
            
        -- If unit is dead, then wait for them to res
        elseif IsUnitDeadOrReincarnating("player") then
            self.Debug("Player is dead or reincarnating..")
            if self.unboxingAll then
                AbortAction()
                PlaySound(SOUNDS.NEGATIVE_CLICK)
            else
                self.Debug("Waiting for resurecction.")
                table.insert(self.itemSlotStack, slotIndex)
                EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ALIVE, HandleEventPlayerAlive)
            end
            return
            
        elseif LOOT_SCENE.state ~= SCENE_HIDDEN or LOOT_SCENE_GAMEPAD.state ~= SCENE_HIDDEN then
            self.Debug("Loot scene is showing.")
            if self.unboxingAll then
                AbortAction()
                PlaySound(SOUNDS.NEGATIVE_CLICK)
            else
                self.Debug("Waiting for it to close to open slotIndex "..tostring(slotIndex))
                table.insert(self.itemSlotStack, slotIndex)
            end
            return
        end
        
        local remaining, duration = GetItemCooldownInfo(BAG_BACKPACK, slotIndex)
        if remaining > 0 and duration > 0 then
            self.Debug("item at slotIndex "..tostring(slotIndex).." is on cooldown for another "..tostring(remaining).." ms duration "..tostring(duration)..". wait until it is ready")
            table.insert(self.itemSlotStack, slotIndex)
            EVENT_MANAGER:RegisterForUpdate(self.name, duration, UnboxCurrent)
            return
            
        else
            self.Debug("Setting self.slotIndex = "..tostring(slotIndex))
            self.slotIndex = slotIndex
            LLS:SetPrefix(prefix)
            lootReceived = false
            EVENT_MANAGER:RegisterForEvent(self.name, EVENT_LOOT_UPDATED, HandleEventLootUpdated)
            EVENT_MANAGER:RegisterForEvent(self.name, EVENT_LOOT_CLOSED, HandleEventLootClosed)
            EVENT_MANAGER:RegisterForEvent(self.name, EVENT_COLLECTIBLE_NOTIFICATION_NEW, HandleEventNewCollectible)
            self.unboxingItemLink = GetItemLink(BAG_BACKPACK, slotIndex)
            if not self.originalUpdateLootWindow then
                local lootWindow = SYSTEMS:GetObject("loot")
                self.originalUpdateLootWindow = lootWindow.UpdateLootWindow
                self.Debug("original loot window update:"..tostring(lootWindow.UpdateLootWindow))
                self.Debug("new loot window update: "..tostring(suppressLootWindow))
                lootWindow.UpdateLootWindow = suppressLootWindow
            end
            if useCallProtectedFunction then
                if not CallSecureProtected("UseItem", BAG_BACKPACK, slotIndex) then
                    self.Debug("CallSecureProtected failed")
                        
                    -- Something more serious went wrong
                    AbortAction()
                    PlaySound(SOUNDS.NEGATIVE_CLICK)
                    self.Print(zo_strformat("Failed to unbox <<1>>", GetItemLink(BAG_BACKPACK, slotIndex)))
                    return
                end
            else
                UseItem(BAG_BACKPACK, slotIndex)
            end
        end
        return true
    else
        self.Debug("slot index "..tostring(slotIndex).." is not unboxable: "..tostring(GetItemLink(BAG_BACKPACK, slotIndex)))
        local usable, onlyFromActionSlot = IsItemUsable(BAG_BACKPACK, slotIndex)
        local canInteractWithItem = CanInteractWithItem(BAG_BACKPACK, slotIndex)
        self.Debug(tostring(itemLink).." usable: "..tostring(usable)..", onlyFromActionSlot: "..tostring(onlyFromActionSlot)..", canInteractWithItem: "..tostring(canInteractWithItem)..", filterMatched: "..tostring(filterMatched))
        -- The current item from the slot stack was not unboxable.  Move on.
        EVENT_MANAGER:RegisterForUpdate(self.name, 40, UnboxCurrent)
    end
end

function addon.UnboxAll()
    local slotIndex = GetNextItemToUnbox()
    if not slotIndex then return end
    table.insert(addon.itemSlotStack, slotIndex)
    addon.running = true
    EVENT_MANAGER:RegisterForUpdate(addon.name, 40, UnboxCurrent)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
    return true
end

function addon.UnboxAllKeybind()
   addon.unboxingAll = true
   addon.UnboxAll()
end

function addon:AddKeyBind()
    self.unboxAllKeybindButtonGroup = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = "Unbox All",
            keybind = "UNBOX_ALL",
            enabled = function() return addon.running ~= true end,
            visible = HasUnboxableSlots,
            order = 100,
            callback = Unboxer.UnboxAll,
        },
    }
    BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWN then
            KEYBIND_STRIP:AddKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
        elseif newState == SCENE_HIDING then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
        end
    end )
    INVENTORY_FRAGMENT:RegisterCallback("StateChange", InventoryStateChange)
end

local function OnInventorySingleSlotUpdate(eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
    local self = addon
    if bagId ~= BAG_BACKPACK and bagId ~= BAG_VIRTUAL then return end
    local itemType, specializedItemType = GetItemType(bagId, slotIndex)
    local itemLink = GetItemLink(bagId, slotIndex)
    UpdateInteractionType()
    self.Debug("Bag "..tostring(bagId).." slotIndex "..tostring(slotIndex).." changed by "..tostring(stackCountChange).." item link "..tostring(itemLink).." item type "..tostring(itemType).." InteractionType: "..tostring(self.mostRecentInteractionType))
    if itemType ~= ITEMTYPE_CONTAINER then return end
    
    local itemId = GetItemLinkItemId(itemLink)
    if self.settings.containerDetails[itemId] then return end
    
    local itemLinkData = self:GetItemLinkData(itemLink)
    if not itemLinkData["interactionType"] then
        itemLinkData["interactionType"] = self.mostRecentInteractionType
    end
    
    self.settings.containerDetails[itemId] = itemLinkData
    
    if self.running or not isNewItem or inventoryUpdateReason ~= INVENTORY_UPDATE_REASON_DEFAULT or bagId ~= BAG_BACKPACK then return end
    table.insert(self.itemSlotStack, slotIndex)
    addon.autolooting = true
    EVENT_MANAGER:RegisterForUpdate(self.name, 40, UnboxCurrent)
end

local function ScanQuestRewardIndex(journalQuestIndex, rewardIndex)
  local self = addon
  
  local itemId = GetJournalQuestRewardItemId(journalQuestIndex, rewardIndex)
  local itemLink = GetItemLinkFromItemId(itemId)
  
  local itemType = GetItemLinkItemType(itemLink)
  if itemType ~= ITEMTYPE_CONTAINER then return end
  
    local itemLinkData = self:GetItemLinkData(itemLink)
    local rewardType, _, _, _, _, _, rewardItemType = GetJournalQuestRewardInfo(journalQuestIndex, rewardIndex)
    local skillType, skillLineIndex = GetJournalQuestRewardSkillLine(journalQuestIndex, rewardIndex)
    local _, _, zoneIndex, poiIndex = GetJournalQuestLocationInfo(journalQuestIndex)
    local zoneId = GetZoneId(zoneIndex)
    local startingZoneIndex = GetJournalQuestStartingZone(journalQuestIndex)
    local startingZoneId = GetZoneId(startingZoneIndex)
    local poiType = GetPOIType(zoneIndex, poiIndex)
    local questType = GetJournalQuestType(journalQuestIndex)
    itemLinkData["quest"] = {
        ["journalQuestIndex"] = journalQuestIndex,
        ["questType"] = questType,
        ["rewardIndex"] = rewardIndex,
        ["rewardType"] = rewardType,
        ["rewardItemType"] = rewardItemType,
        ["instanceDisplayType"] = GetJournalQuestInstanceDisplayType(journalQuestIndex),
        ["repeatType"] = GetJournalQuestRepeatType(journalQuestIndex),
        ["skillType"] = skillType,
        ["skillLineIndex"] = skillLineIndex,
        ["storyZoneId"] = GetJournalQuestZoneStoryZoneId(journalQuestIndex),
        ["zoneId"] = zoneId,
        ["zoneIndex"] = zoneIndex,
        ["startingZoneId"] = startingZoneId,
        ["startingZoneIndex"] = startingZoneIndex,
        ["poiIndex"] = poiIndex,
        ["poiType"] = poiType,
    }
    self.settings.containerDetails[itemId] = itemLinkData
end
local function OnQuestCompleteDialog(eventCode, journalQuestIndex)
    local self = addon
    local maxRewardIndex =  GetJournalQuestNumRewards(journalQuestIndex)
    for rewardIndex = 1, maxRewardIndex do
      
        ScanQuestRewardIndex(journalQuestIndex, rewardIndex)
    end
end
local function ScanMailAttachment(mailId, attachIndex, displayName, characterName, subject, fromSystem, fromCustomerService)
    local self = addon
    
    local itemLink = GetAttachedItemLink(mailId, attachIndex)
    local itemType = GetItemLinkItemType(itemLink)
    if itemType ~= ITEMTYPE_CONTAINER then return end
    
    local itemLinkData = self:GetItemLinkData(itemLink)
    local itemId = GetItemLinkItemId(itemLink)
    local text = self.settings.containerDetails[itemId]["mail"] and self.settings.containerDetails[itemId]["mail"]["text"] or {}
    text[GetCVar("language.2")] = {
        ["senderDisplayName"] = displayName,
        ["senderCharacterName"] = characterName,
        ["subject"] = subject,
    }
    itemLinkData["mail"] = {
        ["text"] = text,
        ["fromCustomerService"] = fromCustomerService,
        ["fromSystem"] = fromSystem,
    }
    if not itemLinkData["interactionType"] then
        itemLinkData["interactionType"] = self.mostRecentInteractionType
    end
    self.settings.containerDetails[itemId] = itemLinkData
end
local function OnMailReadable(eventCode, mailId)
    local self = addon
    UpdateInteractionType()
    local senderDisplayName, senderCharacterName, subject, _, _, fromSystem, fromCustomerService, _, numAttachments = GetMailItemInfo(mailId)
    if not fromSystem and not fromCustomerService then return end
    for attachIndex = 1, numAttachments do
        ScanMailAttachment(mailId, attachIndex, senderDisplayName, senderCharacterName, subject, fromSystem, fromCustomerService)
    end
end
local function OnInventoryItemUsed(eventCode)
    local self = addon
    if not self.lastReferencedSlotIndex then
        self.Debug("Unknown item used")
        return
    end
    local itemLink = GetItemLink(BAG_BACKPACK, self.lastReferencedSlotIndex)
    local itemType, specializedItemType = GetItemLinkItemType(itemLink)
    if itemType ~= ITEMTYPE_CONTAINER then
        self.Debug("Non-container opened: "..tostring(itemLink))
        return
    end
    self.lastContainerOpened = {
          ["itemId"] = GetItemLinkItemId(itemLink),
          ["itemLink"] = itemLink,
          ["specializedItemType"] = specializedItemType
      }
    self.Debug("Container opened: "..tostring(itemLink))
end

local function HandleRequestConfirmUseItem(eventCode, bagId, slotIndex)
    local self = addon
    local itemLink = GetItemLink(bagId, slotIndex)
    self.Debug("EVENT_REQUEST_CONFIRM_USE_ITEM "..tostring(itemLink))
end
local function ScanStoreEntry(entryIndex)
    local self = addon
    local itemLink = GetStoreItemLink(entryIndex)
    local itemType = GetItemLinkItemType(itemLink)
    if itemType ~= ITEMTYPE_CONTAINER then return end
    
    local itemLinkData = self:GetItemLinkData(itemLink)
    --if itemLinkData["containerType"] ~= "unknown" then return end
    
    local _, _, stack, price, sellPrice, meetsRequirementsToBuy, meetsRequirementsToEquip, quality, questNameColor, currencyType1, currencyQuantity1,
        currencyType2, currencyQuantity2, entryType = GetStoreEntryInfo(entryIndex)
    if stack <= 0 then
        self.Debug("Not recording store for container "..tostring(itemLink).." because stack is <= 0")
        return
    end
    
    local itemId = GetItemLinkItemId(itemLink)
    local avaContainerType =  IsInCyrodiil() and "cyrodiil" or IsInImperialCity() and "imperialCity"
    if not avaContainerType then
        --self.Debug("Not recording store for container "..tostring(itemLink).." avaContainerType is nil")
        --return
    end
    
    if not itemLinkData["interactionType"] then
        itemLinkData["interactionType"] = self.mostRecentInteractionType
    end
    local zoneId, worldX, worldY, worldZ = GetUnitWorldPosition("player")
    local sellInformation = GetItemLinkSellInformation(itemLink)
    
    local text = self.settings.containerDetails[itemId] and self.settings.containerDetails[itemId]["store"] and self.settings.containerDetails[itemId]["store"]["text"] or {}
    text[GetCVar("language.2")] = {
        ["vendor"] = GetChatterOption(GetChatterOptionCount()),
    }
    itemLinkData["store"] = {
        ["entryType"] = entryType,
        ["zoneId"] = zoneId,
        ["worldPosition"] = { ["x"] = worldX, ["y"] = worldY, ["z"] = worldZ },
        ["stack"] = stack,
        ["price"] = price,
        ["sellPrice"] = sellPrice,
        ["meetsRequirementsToBuy"] = meetsRequirementsToBuy,
        ["meetsRequirementsToEquip"] = meetsRequirementsToEquip,
        ["quality"] = quality,
        ["questNameColor"] = questNameColor,
        ["currencyType1"] = currencyType1,
        ["currencyQuantity1"] = currencyQuantity1,
        ["currencyType2"] = currencyType2,
        ["currencyQuantity2"] = currencyQuantity2,
        ["sellInformation"] = sellInformation,
        ["sellInformationSortOrder"] = ZO_GetItemSellInformationCustomSortOrder(sellInformation),
        ["text"] = text
    }
    if entryType == STORE_ENTRY_TYPE_QUEST_ITEM then
        itemLinkData["questItemId"] = GetStoreEntryQuestItemId(entryIndex)
    end
    self.settings.containerDetails[itemId] = itemLinkData
end
local function OnOpenStore(eventCode)
    local self = addon
    self.Debug("EVENT_OPEN_STORE")
    UpdateInteractionType()
    for entryIndex = 1, GetNumStoreItems() do
        ScanStoreEntry(entryIndex)
    end
end
function addon:RegisterEvents()
    EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySingleSlotUpdate)
    --EVENT_MANAGER:AddFilterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK)
    --EVENT_MANAGER:AddFilterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
    --EVENT_MANAGER:AddFilterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_IS_NEW_ITEM, true)
    EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_QUEST_COMPLETE_DIALOG, OnQuestCompleteDialog)
    EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_MAIL_READABLE, OnMailReadable)
    EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_INVENTORY_ITEM_USED , OnInventoryItemUsed)
    EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_LOOT_RECEIVED , HandleEventLootReceived)
    EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_LOOT_UPDATED , HandleEventLootUpdated)
    EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_REQUEST_CONFIRM_USE_ITEM, HandleRequestConfirmUseItem)
    EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_OPEN_STORE, OnOpenStore)
end
local function OnAddonLoaded(event, name)
  
    if name ~= addon.name then return end
    local self = addon
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)

    self:AddKeyBind()
    self:SetupSettings()
    
    SLASH_COMMANDS["/ubunknown"] = function (extra)
        if not self.settings.containerDetails then
            return
        end
        for itemId, itemData in pairs(self.settings.containerDetails) do
            if itemData["containerType"] == "unknown" and itemData["filterCategory1"] ~= "pts" then
                d(tostring(itemData["itemLink"]))
            end
        end
    end
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)