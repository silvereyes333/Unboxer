local addon = {
    name = "Unboxer",
    title = GetString(SI_UNBOXER),
    author = "|c99CCEFsilvereyes|r",
    version = "2.0.0",
    filters = {},
    itemSlotStack = {},
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
addon.d = pOutput
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
    
    local itemLink = GetItemLink(bagId, slotIndex)
    if not itemLink then return false end
    
    local itemId = GetItemIdFromLink(itemLink)
    
    -- not sure why there's no item id, but return false to be safe
    if not itemId then return false end
    
    -- perform filtering
    local filterMatched = false
    for filterCategory, filters in pairs(addon.filters) do
        for settingName, subFilters in pairs(filters) do
            if settingName ~= "runeBoxes" and subFilters[itemId] ~= nil then
                if not addon.settings[settingName] 
                   or (addon.autolooting
                       and (not addon.settings.autoloot or not addon.settings[settingName.."Autoloot"]))
                then
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
            if not addon.settings.runeBoxes
               or (addon.autolooting
                   and (not addon.settings.autoloot or not addon.settings.runeBoxesAutoloot))
            then
                return false
            end
            filterMatched = "runeBoxes"
            local collectibleId = addon.filters.loot.runeboxes[itemId]
            if type(collectibleId) == "number" and IsCollectibleUnlocked(collectibleId) then
                return false
            end
        elseif not addon.settings.other 
               or (addon.autolooting
                   and (not addon.settings.autoloot or not addon.settings.otherAutoloot))
        then -- catch all
            return false
        else
            filterMatched = "other"
        end
    end
    
    local usable, onlyFromActionSlot = IsItemUsable(bagId, slotIndex)
    dbug(tostring(itemLink)..", usable: "..tostring(usable)..", onlyFromActionSlot: "..tostring(onlyFromActionSlot))
    return usable and not onlyFromActionSlot, filterMatched
end

local UnboxCurrent
local itemLink
local timeoutItemUniqueIds = {}
local updateExpected = false
local lootReceived
local filterSetting

local function AbortAction(...)
    dbug("AbortAction")
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_CLOSED)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_RECEIVED)
    EVENT_MANAGER:UnregisterForUpdate(addon.name)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_UPDATED)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_COLLECTIBLE_NOTIFICATION_NEW)
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
    KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
    -- Print summary
    if LLS then
        LLS:Print()
    end
end


local function HasUnboxableSlots()
    if not(CheckInventorySpaceSilently(2) and BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState() == SCENE_SHOWN) then return false end
    if #addon.itemSlotStack > 0 then return false end
    local bagId = BAG_BACKPACK
    local bagSlots = GetBagSize(bagId) -1
    for index = 0, bagSlots do
        if IsItemUnboxable(bagId, index) and CanInteractWithItem(bagId, index) then return true end
    end

    return false
end

-- Scan backpack for next unboxable container and return true if found
local function GetNextItemToUnbox()
    if not CheckInventorySpaceSilently(2) then
        dbug("Not enough bag space")
        return
    end
    local menuBarState = BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState()
    if menuBarState ~= SCENE_SHOWN then
        dbug("Backpack menu bar layout fragment not shown: "..tostring(menuBarState))
        return
    end

    local bagId = BAG_BACKPACK
    local bagSlots = GetBagSize(bagId) -1
    for index = 0, bagSlots do
        if IsItemUnboxable(bagId, index) and CanInteractWithItem(bagId, index) then
            return index
        end
    end
    dbug("No unboxable items found")
end
local function HandleEventLootReceived(eventCode, receivedBy, itemLink, quantity, itemSound, lootType, lootedBySelf, isPickpocketLoot, questItemIcon, itemId)
    lootReceived = true
    if LLS and filterSetting and lootedBySelf and lootType == LOOT_TYPE_ITEM then
        if addon.settings[filterSetting .. "Summary"] then
            LLS:AddItemLink(itemLink, quantity)
        end
    end
    dbug("LootReceived("..tostring(eventCode)..", "..zo_strformat("<<1>>", receivedBy)..", "..tostring(itemLink)..", "..tostring(quantity)..", "..tostring(itemSound)..", "..tostring(lootType)..", "..tostring(lootedBySelf)..", "..tostring(isPickpocketLoot)..", "..tostring(questItemIcon)..", "..tostring(itemId)..")")
end
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
    if lootReceived then
        lootReceived = nil
        if addon.running then
            local menuBarState = BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState()
            if menuBarState == SCENE_HIDDEN then
                unboxAllOnInventoryOpen = true
                lootReceived = true
                OpenInventory()
                return
            end
            if not addon.UnboxAll() then
                dbug("UnboxAll returned false")
                AbortAction()
                return
            end
        end
    elseif addon.slotIndex then
        dbug("lootReceived is false. attempting to loot again.")
        timeoutItemUniqueIds = {}
        table.insert(addon.itemSlotStack, addon.slotIndex)
    end
    EVENT_MANAGER:RegisterForUpdate(addon.name, 40, UnboxCurrent)
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
    if #timeoutItemUniqueIds == 0 then 
        dbug("timeoutItemUniqueIds is empty")
        return
    end
    if not addon.slotIndex then
        dbug("addon slotindex is empty")
        return
    end
    local lootingItemUniqueId = GetItemUniqueId(BAG_BACKPACK, addon.slotIndex)
    local timeoutItemUniqueId = timeoutItemUniqueIds[1]
    table.remove(timeoutItemUniqueIds, 1)
    if lootingItemUniqueId and AreId64sEqual(lootingItemUniqueId,timeoutItemUniqueId) then
        dbug("Looting again, ids match")
        table.insert(timeoutItemUniqueIds, lootingItemUniqueId)
        zo_callLater(LootAllItemsTimeout, 1500) -- If still not looted after 1.5 secs, try to loot again
        LOOT_SHARED:LootAllItems()
    end
end
local function HandleEventLootUpdated(eventCode)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_UPDATED)
    if not addon.slotIndex then
        dbug("addon slotindex is empty")
        return
    end
    table.insert(timeoutItemUniqueIds, GetItemUniqueId(BAG_BACKPACK, addon.slotIndex))
    zo_callLater(LootAllItemsTimeout, 1500) -- If still not looted after 1.5 secs, try to loot again
    LOOT_SHARED:LootAllItems()
    dbug("LootUpdated("..tostring(eventCode)..")")
end
local function HandleEventNewCollectible(eventCode, collectibleId)
    lootReceived = true
    HandleEventLootClosed(eventCode)
end
local HandleInteractWindowHidden
HandleInteractWindowHidden = function()
    INTERACT_WINDOW:UnregisterCallback("Hidden", HandleInteractWindowHidden)
    EVENT_MANAGER:RegisterForUpdate(addon.name, 40, UnboxCurrent)
end
local suppressLootWindow = function() end
UnboxCurrent = function()
    EVENT_MANAGER:UnregisterForUpdate(addon.name)
    local slotIndex
    if #addon.itemSlotStack > 0 then
        slotIndex = table.remove(addon.itemSlotStack)
    else
        dbug("No items in item slot stack")
        AbortAction()
        return
    end
    if not CheckInventorySpaceSilently(2) then
        dbug("not enough space")
        AbortAction()
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_INVENTORY_ERROR_INVENTORY_FULL)
        return false
    end
    local remaining, duration = GetItemCooldownInfo(BAG_BACKPACK, slotIndex)
    if remaining > 0 and duration > 0 then
        dbug("item at slotIndex "..tostring(slotIndex).." is on cooldown for another "..tostring(remaining).." ms duration "..tostring(duration)..". wait until it is ready")
        table.insert(addon.itemSlotStack, slotIndex)
        EVENT_MANAGER:RegisterForUpdate(addon.name, duration, UnboxCurrent)
        return
    end
    local isUnboxable
    isUnboxable, filterSetting = IsItemUnboxable(BAG_BACKPACK, slotIndex)
    if isUnboxable then
        if INTERACT_WINDOW:IsInteracting() then
            dbug("interaction window is open. wait until it closes to open slotIndex "..tostring(slotIndex))
            table.insert(addon.itemSlotStack, slotIndex)
            INTERACT_WINDOW:RegisterCallback("Hidden", HandleInteractWindowHidden)
            return
        elseif LOOT_SCENE.state ~= SCENE_HIDDEN or LOOT_SCENE_GAMEPAD.state ~= SCENE_HIDDEN then
            dbug("loot scene is showing. wait for it to close to open slotIndex "..tostring(slotIndex))
            table.insert(addon.itemSlotStack, slotIndex)
            return
         -- Fix for some containers sometimes not being interactable. Just wait a second and try again.
         -- I wonder if this happens due to a race condition with the IsInteracting() check above.
        elseif not CanInteractWithItem(BAG_BACKPACK, slotIndex) then
            dbug("slot index "..tostring(slotIndex).." is not interactable right now. Waiting 1 second...")
            table.insert(addon.itemSlotStack, slotIndex)
            EVENT_MANAGER:RegisterForUpdate(addon.name, 1000, UnboxCurrent)
        else
            dbug("setting addon.slotIndex = "..tostring(slotIndex))
            addon.slotIndex = slotIndex
            if LLS then
                LLS:SetPrefix(prefix)
            end
            lootReceived = false
            EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_LOOT_RECEIVED, HandleEventLootReceived)
            EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_LOOT_UPDATED, HandleEventLootUpdated)
            EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_LOOT_CLOSED, HandleEventLootClosed)
            EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_COLLECTIBLE_NOTIFICATION_NEW, HandleEventNewCollectible)
            if not addon.originalUpdateLootWindow then
                local lootWindow = SYSTEMS:GetObject("loot")
                addon.originalUpdateLootWindow = lootWindow.UpdateLootWindow
                dbug("original loot window update:"..tostring(lootWindow.UpdateLootWindow))
                dbug("new loot window update: "..tostring(suppressLootWindow))
                lootWindow.UpdateLootWindow = suppressLootWindow
            end
            if useCallProtectedFunction then
                if not CallSecureProtected("UseItem", BAG_BACKPACK, slotIndex) then
                    dbug("CallSecureProtected failed")
                    AbortAction()
                    PlaySound(SOUNDS.NEGATIVE_CLICK)
                    pOutput(zo_strformat("Failed to unbox <<1>>", GetItemLink(BAG_BACKPACK, slotIndex)))
                    return
                end
            else
                UseItem(BAG_BACKPACK, slotIndex)
            end
            pOutput(zo_strformat("Unboxed <<1>>", GetItemLink(BAG_BACKPACK, slotIndex)))
        end
        return true
    else
        dbug("slot index "..tostring(slotIndex).." is not unboxable: "..tostring(GetItemLink(BAG_BACKPACK, slotIndex)))
        local usable, onlyFromActionSlot = IsItemUsable(BAG_BACKPACK, slotIndex)
        local canInteractWithItem = CanInteractWithItem(BAG_BACKPACK, slotIndex)
        dbug(tostring(itemLink).." usable: "..tostring(usable)..", onlyFromActionSlot: "..tostring(onlyFromActionSlot)..", canInteractWithItem: "..tostring(canInteractWithItem)..", filterMatched: "..tostring(filterMatched))
        AbortAction()
    end
end

local function IsPlayerAlive()
    return not IsUnitDead("player")
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
    local itemType = GetItemType(bagId, slotIndex)
    if itemType ~= ITEMTYPE_CONTAINER then return end
    table.insert(addon.itemSlotStack, slotIndex)
    addon.autolooting = true
    EVENT_MANAGER:RegisterForUpdate(addon.name, 40, UnboxCurrent)
end
local function OnAddonLoaded(event, name)
    if name ~= addon.name then return end
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)


    addon:AddKeyBind()
    addon:SetupSettings()
    
    
    EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySingleSlotUpdate)
    EVENT_MANAGER:AddFilterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK)
    EVENT_MANAGER:AddFilterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
    EVENT_MANAGER:AddFilterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_IS_NEW_ITEM, true)
    
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

Unboxer = addon
