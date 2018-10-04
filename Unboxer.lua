local addon = {
    name = "Unboxer",
    title = GetString(SI_UNBOXER),
    author = "|c99CCEFsilvereyes|r",
    version = "2.6.1",
    filters = {},
    itemSlotStack = {},
    debugMode = false,
}

local LLS = LibStub("LibLootSummary")
local LibSavedVars = LibStub("LibSavedVars")
local prefix = zo_strformat("<<1>>|cFFFFFF: ", addon.title)

-- Output formatted message to chat window, if configured
function addon.Print(input, force)
    if not force and not LibSavedVars:Get(addon, "verbose") then
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
                if not LibSavedVars:Get(addon, settingName) 
                   or (addon.autolooting
                       and (not LibSavedVars:Get(addon, "autoloot") or not LibSavedVars:Get(addon, settingName.."Autoloot")))
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
        local collectibleId
        for filterName,itemIds in pairs(addon.filters.collectibles) do
            if itemIds[itemId] ~= nil then
                filterMatched = filterName
                collectibleId = itemIds[itemId]
                break
            end
        end
        if collectibleId ~= nil then -- collectibles
            if not LibSavedVars:Get(addon, filterMatched)
               or (addon.autolooting
                   and (not LibSavedVars:Get(addon, "autoloot") or not LibSavedVars:Get(addon, filterMatched.."AutoLoot")))
            then
                return false
            end
            if type(collectibleId) == "number" and IsCollectibleUnlocked(collectibleId) then
                return false
            end
        elseif not LibSavedVars:Get(addon, "other") 
               or (addon.autolooting
                   and (not LibSavedVars:Get(addon, "autoloot") or not LibSavedVars:Get(addon, "otherAutoloot")))
        then -- catch all
            return false
        else
            filterMatched = "other"
        end
    end
    
    local usable, onlyFromActionSlot = IsItemUsable(bagId, slotIndex)
    addon.Debug(tostring(itemLink)..", usable: "..tostring(usable)..", onlyFromActionSlot: "..tostring(onlyFromActionSlot))
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
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_RECEIVED)
    EVENT_MANAGER:UnregisterForUpdate(addon.name)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_UPDATED)
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
    if LibSavedVars:Get(addon, "reservedSlots") and type(LibSavedVars:Get(addon, "reservedSlots")) == "number" then
        inventorySlotsNeeded = inventorySlotsNeeded + LibSavedVars:Get(addon, "reservedSlots")
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
    if not HasEnoughSlots() and BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState() == SCENE_SHOWN then 
        return false
    end
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
    if not HasEnoughSlots() then
        addon.Debug("Not enough bag space")
        return
    end
    local menuBarState = BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState()
    if menuBarState ~= SCENE_SHOWN then
        addon.Debug("Backpack menu bar layout fragment not shown: "..tostring(menuBarState))
        return
    end

    local bagId = BAG_BACKPACK
    local bagSlots = GetBagSize(bagId) -1
    for index = 0, bagSlots do
        if IsItemUnboxable(bagId, index) and CanInteractWithItem(bagId, index) then
            return index
        end
    end
    addon.Debug("No unboxable items found")
end
local function PrintUnboxedLink()
    if not addon.unboxingItemLink then return end
    addon.Print(zo_strformat(SI_UNBOXER_UNBOXED, addon.unboxingItemLink))
    addon.unboxingItemLink = nil
end
local function HandleEventLootReceived(eventCode, receivedBy, itemLink, quantity, itemSound, lootType, lootedBySelf, isPickpocketLoot, questItemIcon, itemId)
    lootReceived = true
    PrintUnboxedLink()
    if filterSetting and lootedBySelf and lootType == LOOT_TYPE_ITEM then
        if LibSavedVars:Get(addon, filterSetting .. "Summary") then
            LLS:AddItemLink(itemLink, quantity)
        end
    end
    addon.Debug("LootReceived("..tostring(eventCode)..", "..zo_strformat("<<1>>", receivedBy)..", "..tostring(itemLink)..", "..tostring(quantity)..", "..tostring(itemSound)..", "..tostring(lootType)..", "..tostring(lootedBySelf)..", "..tostring(isPickpocketLoot)..", "..tostring(questItemIcon)..", "..tostring(itemId)..")")
end
local InventoryStateChange
local function HandleEventLootClosed(eventCode)
    addon.Debug("LootClosed("..tostring(eventCode)..")")
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_CLOSED)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_RECEIVED)
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
        zo_callLater(LootAllItemsTimeout, 1500) -- If still not looted after 1.5 secs, try to loot again
        LOOT_SHARED:LootAllItems()
    end
end
local function HandleEventLootUpdated(eventCode)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_UPDATED)
    if not addon.slotIndex then
        addon.Debug("addon slotindex is empty")
        EndLooting()
        return
    end
    -- do a dumb check for inventory slot availability
    --[[ TODO: Be smarter, taking into account stacking slots and craft bag. 
               Maybe make a library to do this, since Postmaster could use it too.
               Could get expensive, scanning the whole bag at time of loot, though.
               Some sort of data structure / index is needed. ]]
    local inventorySlotsNeeded = GetInventorySlotsNeeded()
    if not CheckInventorySpaceAndWarn(inventorySlotsNeeded) then
        addon.Debug("not enough space")
        AbortAction()
        EndLooting()
        return
    end
    table.insert(timeoutItemUniqueIds, GetItemUniqueId(BAG_BACKPACK, addon.slotIndex))
    zo_callLater(LootAllItemsTimeout, 1500) -- If still not looted after 1.5 secs, try to loot again
    LOOT_SHARED:LootAllItems()
    addon.Debug("LootUpdated("..tostring(eventCode)..")")
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
    addon.Debug("Interaction ended. Waiting 2 seconds to try unboxing again.")
    INTERACT_WINDOW:UnregisterCallback("Hidden", HandleInteractWindowHidden)
    HUD_SCENE:UnregisterCallback("StateChange", HudStateChange)
    EVENT_MANAGER:UnregisterForUpdate(addon.name.."InteractWait")
    EVENT_MANAGER:RegisterForUpdate(addon.name.."InteractWait", 2000, EndInteractWait)
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
    EVENT_MANAGER:UnregisterForUpdate(addon.name)
    local slotIndex
    if #addon.itemSlotStack > 0 then
        slotIndex = table.remove(addon.itemSlotStack)
    else
        addon.Debug("No items in item slot stack")
        AbortAction()
        return
    end
    local isUnboxable
    isUnboxable, filterSetting = IsItemUnboxable(BAG_BACKPACK, slotIndex)
    if isUnboxable then
        if INTERACT_WINDOW:IsInteracting() then
            addon.Debug("interaction window is open. wait until it closes to open slotIndex "..tostring(slotIndex))
            table.insert(addon.itemSlotStack, slotIndex)
            addon.interactWait = true
            HUD_SCENE:RegisterCallback("StateChange", HudStateChange)
            INTERACT_WINDOW:RegisterCallback("Hidden", HandleInteractWindowHidden)
            return
        elseif addon.interactWait then
            addon.Debug("waiting for interaction timeout to handle unboxing slotIndex "..tostring(slotIndex))
            table.insert(addon.itemSlotStack, slotIndex)
            return
        end
        local remaining, duration = GetItemCooldownInfo(BAG_BACKPACK, slotIndex)
        if remaining > 0 and duration > 0 then
            addon.Debug("item at slotIndex "..tostring(slotIndex).." is on cooldown for another "..tostring(remaining).." ms duration "..tostring(duration)..". wait until it is ready")
            table.insert(addon.itemSlotStack, slotIndex)
            EVENT_MANAGER:RegisterForUpdate(addon.name, duration, UnboxCurrent)
            return
        elseif LOOT_SCENE.state ~= SCENE_HIDDEN or LOOT_SCENE_GAMEPAD.state ~= SCENE_HIDDEN then
            addon.Debug("loot scene is showing. wait for it to close to open slotIndex "..tostring(slotIndex))
            table.insert(addon.itemSlotStack, slotIndex)
            return
         -- Fix for some containers sometimes not being interactable. Just wait a second and try again.
         -- I wonder if this happens due to a race condition with the IsInteracting() check above.
        elseif not CanInteractWithItem(BAG_BACKPACK, slotIndex) then
            addon.Debug("slot index "..tostring(slotIndex).." is not interactable right now. Waiting 1 second...")
            table.insert(addon.itemSlotStack, slotIndex)
            EVENT_MANAGER:RegisterForUpdate(addon.name, 1000, UnboxCurrent)
        else
            addon.Debug("setting addon.slotIndex = "..tostring(slotIndex))
            addon.slotIndex = slotIndex
            LLS:SetPrefix(prefix)
            lootReceived = false
            EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_LOOT_RECEIVED, HandleEventLootReceived)
            EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_LOOT_UPDATED, HandleEventLootUpdated)
            EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_LOOT_CLOSED, HandleEventLootClosed)
            EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_COLLECTIBLE_NOTIFICATION_NEW, HandleEventNewCollectible)
            addon.unboxingItemLink = GetItemLink(BAG_BACKPACK, slotIndex)
            if not addon.originalUpdateLootWindow then
                local lootWindow = SYSTEMS:GetObject("loot")
                addon.originalUpdateLootWindow = lootWindow.UpdateLootWindow
                addon.Debug("original loot window update:"..tostring(lootWindow.UpdateLootWindow))
                addon.Debug("new loot window update: "..tostring(suppressLootWindow))
                lootWindow.UpdateLootWindow = suppressLootWindow
            end
            if useCallProtectedFunction then
                if not CallSecureProtected("UseItem", BAG_BACKPACK, slotIndex) then
                    addon.Debug("CallSecureProtected failed")
                    AbortAction()
                    PlaySound(SOUNDS.NEGATIVE_CLICK)
                    pOutput(zo_strformat("Failed to unbox <<1>>", GetItemLink(BAG_BACKPACK, slotIndex)))
                    return
                end
            else
                UseItem(BAG_BACKPACK, slotIndex)
            end
        end
        return true
    else
        addon.Debug("slot index "..tostring(slotIndex).." is not unboxable: "..tostring(GetItemLink(BAG_BACKPACK, slotIndex)))
        local usable, onlyFromActionSlot = IsItemUsable(BAG_BACKPACK, slotIndex)
        local canInteractWithItem = CanInteractWithItem(BAG_BACKPACK, slotIndex)
        addon.Debug(tostring(itemLink).." usable: "..tostring(usable)..", onlyFromActionSlot: "..tostring(onlyFromActionSlot)..", canInteractWithItem: "..tostring(canInteractWithItem)..", filterMatched: "..tostring(filterMatched))
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
    if addon.running then return end
    local itemType = GetItemType(bagId, slotIndex)
    if itemType ~= ITEMTYPE_CONTAINER then return end
    table.insert(addon.itemSlotStack, slotIndex)
    addon.autolooting = true
    EVENT_MANAGER:RegisterForUpdate(addon.name, 40, UnboxCurrent)
end

function addon:RegisterEvents()
    EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySingleSlotUpdate)
    EVENT_MANAGER:AddFilterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK)
    EVENT_MANAGER:AddFilterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
    EVENT_MANAGER:AddFilterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_IS_NEW_ITEM, true)
end

local function OnAddonLoaded(event, name)
    if name ~= addon.name then return end
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)


    addon:AddKeyBind()
    addon:SetupSettings()    
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

Unboxer = addon
