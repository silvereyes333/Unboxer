local addon = {
    name = "Unboxer",
    title = GetString(SI_UNBOXER),
    author = "|c99CCEFsilvereyes|r",
    version = "1.4.0",
    defaults =
    {
        verbose = true,
        other = true,
        
        -- Gear
        monster = true,
        armor = true,
        weapons = true,
        accessories = true,
        overworld = true,
        dungeon = true,
        trials = true,
        cyrodiil = true,
        imperialCity = true,
        battlegrounds = true,
        darkBrotherhood = true,
        nonSet = true,
        monsterSummary = false,
        armorSummary = false,
        weaponsSummary = false,
        accessoriesSummary = false,
        overworldSummary = false,
        dungeonSummary = false,
        trialsSummary = false,
        cyrodiilSummary = false,
        imperialCitySummary = false,
        battlegroundsSummary = false,
        darkBrotherhoodSummary = false,
        nonSetSummary = false,
        
        -- Loot
        potions = true,
        enchantments = true,
        giftBoxes = true,
        gunnySacks = true,
        rewards = true,
        runeBoxes = true,
        thief = false, -- Changed to false in version 1.3.0, to avoid unexpected bounties
        treasureMaps = true,
        potionsSummary = false,
        enchantmentsSummary = false,
        giftBoxesSummary = false,
        gunnySacksSummary = false,
        rewardsSummary = false,
        runeBoxesSummary = false,
        thiefSummary = false,
        treasureMapsSummary = false,
        
        -- Crafting
        alchemist = true,
        blacksmith = true,
        clothier = true,
        enchanter = true,
        provisioner = true,
        woodworker = true,
        alchemistSummary = false,
        blacksmithSummary = false,
        clothierSummary = false,
        enchanterSummary = false,
        provisionerSummary = false,
        woodworkerSummary = false,
        
        -- Housing
        furnisher = true,
        mageGuildReprints = true,
        furnisherSummary = false,
        mageGuildReprintsSummary = false,
        
        -- PTS
        ptsCollectibles = true,
        ptsConsumables = false,
        ptsCrafting = true,
        ptsCurrency = true,
        ptsGear = false,
        ptsHousing = false,
        ptsSkills = false,
        ptsOther = false,
        ptsCollectiblesSummary = false,
        ptsConsumablesSummary = false,
        ptsCraftingSummary = false,
        ptsCurrencySummary = false,
        ptsGearSummary = false,
        ptsHousingSummary = false,
        ptsSkillsSummary = false,
        ptsOtherSummary = false,
    },
    filters = {},
    filtersToSettingsMap = {},
    debugMode = false,
}

local LLS = LibStub("LibLootSummary")
local prefix = zo_strformat("<<1>>|cFFFFFF: ", addon.title)

-- Output formatted message to chat window, if configured
local function pOutput(input)
    if not addon.settings.verbose then
        return
    end
    local output = zo_strformat(prefix .. "<<1>>|r", input)
    d(output)
end
local function dbug(input)
    if not addon.debugMode then
        return
    end
    pOutput(input)
end
-- Extracting item ids from item links
local function GetItemIdFromLink(itemLink)
    local itemId = select(4, ZO_LinkHandler_ParseLink(itemLink))
    if itemId and itemId ~= "" then
        return tonumber(itemId)
    end
end
local useCallProtectedFunction = IsProtectedFunction("UseItem")
local function IsItemUnboxable(bagId, slotIndex)
    if bagId ~= BAG_BACKPACK then return false end

    local itemType = GetItemType(bagId, slotIndex)
    if itemType ~= ITEMTYPE_CONTAINER then return false end
    
    local itemId = GetItemIdFromLink(GetItemLink(bagId, slotIndex))
    
    -- not sure why there's no item id, but return false to be safe
    if not itemId then return false end
    
    -- perform filtering
    local filterMatched = false
    for filterCategory, filters in pairs(addon.filters) do
        for subcategory, subFilters in pairs(filters) do
            local settingName
            -- Unmapped settings names are the same as the subcategory name
            if not addon.filtersToSettingsMap[filterCategory] 
               or addon.filtersToSettingsMap[filterCategory][subcategory] == nil
            then
                settingName = subcategory
            -- Exclude special cases
            elseif addon.filtersToSettingsMap[filterCategory][subcategory] == false then
                settingName = nil
            -- Mapped settings names
            else
                settingName = addon.filtersToSettingsMap[filterCategory][subcategory]
            end
            if settingName and subFilters[itemId] ~= nil then
                if not addon.settings[settingName] then
                    return false
                end
                filterMatched = settingName
                break
            end
        end
        if filterMatched then
            break
        end
    end
    
    -- No filters matched.  Handle special cases and catch-all...
    if not filterMatched then
        if addon.filters.loot.runeboxes[itemId] ~= nil then -- runeboxes
            if not addon.settings.runeBoxes then
                return false
            end
            filterMatched = "runeBoxes"
            local collectibleId = addon.filters.loot.runeboxes[itemId]
            if type(collectibleId) == "number" and IsCollectibleUnlocked(collectibleId) then
                return false
            end
        elseif not addon.settings.other then -- catch all
            filterMatched = "other"
            return false
        end
    end
    
    local usable, onlyFromActionSlot = IsItemUsable(bagId, slotIndex)
    local canInteractWithItem = CanInteractWithItem(bagId, slotIndex)
    return usable and not onlyFromActionSlot and canInteractWithItem, filterMatched
end

local UnboxCurrent
local itemLink
local slotIndex
local timeoutItemUniqueIds = {}
local updateExpected = false
local lootReceived = false
local filterSetting

local function AbortAction(...)
    dbug("AbortAction")
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_CLOSED)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_RECEIVED)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_CHATTER_BEGIN)
    EVENT_MANAGER:UnregisterForUpdate(addon.name)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_UPDATED)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_COLLECTIBLE_NOTIFICATION_NEW)
    addon.running = false
    lootReceived = false
    updateExpected = false
    filterSetting = nil
    KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
    -- Print summary
    if LLS then
        LLS:Print()
    end
end


local function HasUnboxableSlots()
    if not(CheckInventorySpaceSilently(2) and BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState() == SCENE_SHOWN) then return false end

    local bagId = BAG_BACKPACK
    local bagSlots = GetBagSize(bagId) -1
    for index = 0, bagSlots do
        if IsItemUnboxable(bagId, index) then return true end
    end

    return false
end

-- Scan backpack for next unboxable container and return true if found
local function GetNextItemToUnbox()
    if not CheckInventorySpaceSilently(2) then
        dbug("Not enough bag space")
        return false
    end
    local menuBarState = BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState()
    if menuBarState ~= SCENE_SHOWN then
        dbug("Backpack menu bar layout fragment not shown: "..tostring(menuBarState))
        return false
    end

    local bagId = BAG_BACKPACK
    local bagSlots = GetBagSize(bagId) -1
    for index = 0, bagSlots do
        if IsItemUnboxable(bagId, index) then
            slotIndex = index
            itemLink = GetItemLink(bagId, slotIndex)
            return true
        end
    end
    dbug("No unboxable items found")
    
    return false
end
local function HandleEventLootReceived(eventCode, receivedBy, itemLink, quantity, itemSound, lootType, lootedBySelf, isPickpocketLoot, questItemIcon, itemId)
    lootReceived = true
    if LLS and filterSetting and lootedBySelf and lootType == LOOT_TYPE_ITEM then
        if addon.settings[filterSetting .. "Summary"] then
            LLS:AddItemLink(itemLink, quantity)
        end
    end
    dbug("LootReceived("..tostring(eventCode)..", "..tostring(receivedBy)..", "..tostring(itemName)..", "..tostring(quantity)..", "..tostring(itemSound)..", "..tostring(lootType)..", "..tostring(self)..", "..tostring(isPickpocketLoot)..", "..tostring(questItemIcon)..", "..tostring(itemId)..")")
end
local HandleInteractWindowShown
local InventoryStateChange
local unboxAllOnInventoryOpen = false
local function OpenInventory()
    local mainMenu = SYSTEMS:GetObject("mainMenu")
    dbug("OpenInventory")
    mainMenu:ShowCategory(MENU_CATEGORY_INVENTORY)
end
local function HandleEventLootClosed(eventCode)
    dbug("LootClosed("..tostring(eventCode)..")")
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_CLOSED)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_RECEIVED)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_COLLECTIBLE_NOTIFICATION_NEW)
    INTERACT_WINDOW:UnregisterCallback("Shown", HandleInteractWindowShown)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_CHATTER_END)
    local menuBarState = BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState()
    if menuBarState == SCENE_HIDDEN then
        unboxAllOnInventoryOpen = true
        OpenInventory()
        return
    end
    if lootReceived then
        lootReceived = false
        if not addon.UnboxAll() then
            dbug("UnboxAll returned false")
            AbortAction()
        end
    else
        dbug("lootReceived is false")
        AbortAction()
    end
end
InventoryStateChange = function(oldState, newState)
    if newState == SCENE_SHOWING then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
    elseif unboxAllOnInventoryOpen and newState == SCENE_SHOWN then
        unboxAllOnInventoryOpen = false
        HandleEventLootClosed()
    end
end
local function LootAllItemsTimeout()
    dbug("LootAllItemsTimeout")
    if not addon.running then
        dbug("addon not running")
        return
    end
    if #timeoutItemUniqueIds == 0 then 
        dbug("timeoutItemUniqueIds is empty")
        return
    end
    local lootingItemUniqueId = GetItemUniqueId(BAG_BACKPACK, slotIndex)
    local timeoutItemUniqueId = timeoutItemUniqueIds[1]
    table.remove(timeoutItemUniqueIds, 1)
    if lootingItemUniqueId and AreId64sEqual(lootingItemUniqueId,timeoutItemUniqueId) then
        dbug("Looting again, ids match")
        table.insert(timeoutItemUniqueIds, lootingItemUniqueId)
        zo_callLater(LootAllItemsTimeout, 1500) -- If still not looted after 1.5 secs, try to loot again
        LOOT_SHARED:LootAllItems()
    end
end
local function HandleMasterWritQuestRejected(eventCode)
    OpenInventory()
end
local function CloseInteractionWindow()
    local obj = SYSTEMS:GetObjectBasedOnCurrentScene(ZO_INTERACTION_SYSTEM_NAME)
    obj:CloseChatter()
end
HandleInteractWindowShown = function()
    -- Stop listening for quest offering
    INTERACT_WINDOW:UnregisterCallback("Shown", HandleInteractWindowShown)
    unboxAllOnInventoryOpen = true
    -- Listen for interaction window closed event
    EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_CHATTER_END, HandleMasterWritQuestRejected)
    -- Reject the master writ quest
    CloseInteractionWindow()
end
local function HandleEventLootUpdated(eventCode)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_UPDATED)
    INTERACT_WINDOW:RegisterCallback("Shown", HandleInteractWindowShown)
    table.insert(timeoutItemUniqueIds, GetItemUniqueId(BAG_BACKPACK, slotIndex))
    zo_callLater(LootAllItemsTimeout, 1500) -- If still not looted after 1.5 secs, try to loot again
    LOOT_SHARED:LootAllItems()
    dbug("LootUpdated("..tostring(eventCode)..")")
end
local function HandleEventNewCollectible(eventCode, collectibleId)
    lootReceived = true
    HandleEventLootClosed(eventCode)
end
UnboxCurrent = function()
    addon.running = true
    if LLS then
        LLS:SetPrefix(prefix)
    end
    EVENT_MANAGER:UnregisterForUpdate(addon.name)
    if not CheckInventorySpaceSilently(2) then
        AbortAction()
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_INVENTORY_ERROR_INVENTORY_FULL)
        dbug("not enough space")
        return false
    end
    local remaining = GetItemCooldownInfo(BAG_BACKPACK, slotIndex)
    local isUnboxable
    isUnboxable, filterSetting = IsItemUnboxable(BAG_BACKPACK, slotIndex)
    if isUnboxable then
        if remaining > 0 then
            EVENT_MANAGER:RegisterForUpdate(addon.name, remaining, UnboxCurrent)
        else
            lootReceived = false
            EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_LOOT_RECEIVED, HandleEventLootReceived)
            EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_LOOT_UPDATED, HandleEventLootUpdated)
            EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_LOOT_CLOSED, HandleEventLootClosed)
            EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_COLLECTIBLE_NOTIFICATION_NEW, HandleEventNewCollectible)
            if useCallProtectedFunction then
                if not CallSecureProtected("UseItem", BAG_BACKPACK, slotIndex) then
                    AbortAction()
                    PlaySound(SOUNDS.NEGATIVE_CLICK)
                    pOutput(zo_strformat("Failed to unbox <<1>>", itemLink))
                    return
                end
            else
                UseItem(BAG_BACKPACK, slotIndex)
            end
            pOutput(zo_strformat("Unboxed <<1>>", itemLink))
        end
        return true
    else
        AbortAction()
    end
end

local function IsPlayerAlive()
    return not IsUnitDead("player")
end

function addon.UnboxAll()
    if GetNextItemToUnbox() then
        local bagId = BAG_BACKPACK
        addon.running = true
        itemLink = GetItemLink(bagId, slotIndex)
        dbug("Getting "..tostring(itemLink))
        EVENT_MANAGER:RegisterForUpdate(addon.name, 40, UnboxCurrent)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
        return true
    end
    return false
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


local function OnAddonLoaded(event, name)
    if name ~= addon.name then return end
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

    addon.settings = ZO_SavedVars:NewAccountWide("Unboxer_Data", 1, nil, addon.defaults)

    addon:AddKeyBind()
    addon:SetupSettings()
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

Unboxer = addon
