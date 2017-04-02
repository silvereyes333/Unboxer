local addon = {
    name = "Unboxer",
    title = GetString(SI_UNBOXER),
    author = "|c99CCEFsilvereyes|r",
    version = "1.2.0",
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
        darkBrotherhood = true,
        nonSet = true,
        
        -- Loot
        potions = true,
        enchantments = true,
        giftBoxes = true,
        gunnySacks = true,
        rewards = true,
        runeBoxes = true,
        thief = true,
        treasureMaps = true,
        
        -- Crafting
        alchemist = true,
        blacksmith = true,
        clothier = true,
        enchanter = true,
        provisioner = true,
        woodworker = true,
        
        -- Housing
        furnisher = true,
        mageGuildReprints = true,
        
        -- PTS
        ptsCollectibles = true,
        ptsConsumables = false,
        ptsCrafting = true,
        ptsCurrency = true,
        ptsGear = false,
        ptsHousing = false,
        ptsSkills = false,
        ptsOther = false,
    },
    filters = {},
    debugMode = false,
}

-- Output formatted message to chat window, if configured
local function pOutput(input)
    if not addon.settings.verbose then
        return
    end
    local output = zo_strformat("<<1>>|cFFFFFF: <<2>>|r", addon.title, input)
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
    
    --[ CRAFTING FILTERS ]--
    if addon.filters.crafting.alchemy[itemId] then -- alchemy ingredients
        if not addon.settings.alchemist then
            return false
        end
    elseif addon.filters.crafting.blacksmithing[itemId] then -- blacksmithing mats
        if not addon.settings.blacksmith then
            return false
        end
    elseif addon.filters.crafting.clothier[itemId] then -- clothier mats
        if not addon.settings.clothier then
            return false
        end
    elseif addon.filters.crafting.enchanting[itemId] then -- enchanting mats
        if not addon.settings.enchanter then
            return false
        end
    elseif addon.filters.crafting.provisioning[itemId] then -- provisioning mats
        if not addon.settings.provisioner then
            return false
        end
    elseif addon.filters.crafting.woodworking[itemId] then -- woodworking mats
        if not addon.settings.woodworker then
            return false
        end
    
    --[ GEAR FILTERS ]--
    elseif addon.filters.gear.monster[itemId] then -- monster set containers
        if not addon.settings.monster then
            return false
        end
    elseif addon.filters.gear.armor[itemId] then -- armor
        if not addon.settings.armor then
            return false
        end
    elseif addon.filters.gear.weapons[itemId] then -- weapons
        if not addon.settings.weapons then
            return false
        end
    elseif addon.filters.gear.jewelry[itemId] then -- jewelry
        if not addon.settings.accessories then
            return false
        end
    elseif addon.filters.gear.overworld[itemId] then -- overworld set containers
        if not addon.settings.overworld then
            return false
        end
    elseif addon.filters.gear.dungeon[itemId] then -- dungeon set containers
        if not addon.settings.dungeon then
            return false
        end
    elseif addon.filters.gear.trials[itemId] then -- trials set containers
        if not addon.settings.trials then
            return false
        end
    elseif addon.filters.gear.cyrodiil[itemId] then -- cyrodiil set containers
        if not addon.settings.cyrodiil then
            return false
        end
    elseif addon.filters.gear.imperialCity[itemId] then -- imperial city gear
        if not addon.settings.imperialCity then
            return false
        end
    elseif addon.filters.gear.darkBrotherhood[itemId] then -- dark brotherhood set gear
        if not addon.settings.darkBrotherhood then
            return false
        end
    elseif addon.filters.gear.nonSet[itemId] then -- non-set equipment chests
        if not addon.settings.nonSet then
            return false
        end


    --[ LOOT ]--

    elseif addon.filters.loot.rewards[itemId] then -- daily/weekly rewards
        if not addon.settings.trials then
            return false
        end
    elseif addon.filters.loot.festival[itemId] then -- festival boxes
        if not addon.settings.giftBoxes then
            return false
        end
    elseif addon.filters.loot.generic[itemId] then  -- gunny sacks and other generic containers
        if not addon.settings.gunnySacks then
            return false
        end
    elseif addon.filters.loot.consumables[itemId] then -- consumables containers
        if not addon.settings.potions then
            return false
        end
    elseif addon.filters.loot.enchantments[itemId] then -- enchants
        if not addon.settings.enchantment then
            return false
        end
    elseif addon.filters.loot.runeboxes[itemId] ~= nil then -- runeboxes
        if not addon.settings.runeBoxes then
            return false
        end
        local collectibleId = addon.filters.loot.runeboxes[itemId]
        if type(collectibleId) == "number" and IsCollectibleUnlocked(collectibleId) then
            return false
        end
    elseif addon.filters.loot.thief[itemId] then -- stolen boxes
        if not addon.settings.thief then
            return false
        end
    elseif addon.filters.loot.treasureMaps[itemId] then -- treasure maps
        if not addon.settings.treasureMaps then
            return false
        end
        
    --[ HOUSING ]--
    elseif addon.filters.housing.furnisher[itemId] then -- furniture recipe containers
        if not addon.settings.furnisher then
            return false
        end
        
    elseif addon.filters.housing.mageGuildReprints[itemId] then -- mage's guild lorebook reprints
        if not addon.settings.mageGuildReprints then
            return false
        end
        
    --[ PTS ]--
    elseif addon.filters.pts.collectibles[itemId] then -- pts collectibles
        if not addon.settings.ptsCollectibles then
            return false
        end
    elseif addon.filters.pts.consumables[itemId] then -- pts consumables
        if not addon.settings.ptsConsumables then
            return false
        end
    elseif addon.filters.pts.crafting[itemId] then -- pts crafting items
        if not addon.settings.ptsCrafting then
            return false
        end
    elseif addon.filters.pts.currency[itemId] then -- pts currency boxes
        if not addon.settings.ptsCurrency then
            return false
        end
    elseif addon.filters.pts.gear[itemId] then -- pts gear chests
        if not addon.settings.ptsGear then
            return false
        end
    elseif addon.filters.pts.housing[itemId] then -- pts housing item boxes
        if not addon.settings.ptsHousing then
            return false
        end
    elseif addon.filters.pts.skills[itemId] then -- pts skill boosters
        if not addon.settings.ptsSkills then
            return false
        end
    elseif addon.filters.pts.other[itemId] then -- pts non-specific containers
        if not addon.settings.ptsOther then
            return false
        end
        
    else
        if not addon.settings.other then
            return false
        end
    end
    
    local usable, onlyFromActionSlot = IsItemUsable(bagId, slotIndex)
    local canInteractWithItem = CanInteractWithItem(bagId, slotIndex)
    return usable and not onlyFromActionSlot and canInteractWithItem
end

local UnboxCurrent
local itemLink
local slotIndex
local timeoutItemUniqueIds = {}
local updateExpected = false
local lootReceived = false

local function AbortAction(...)
    dbug("AbortAction")
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_CLOSED)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_RECEIVED)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_CHATTER_BEGIN)
    EVENT_MANAGER:UnregisterForUpdate(addon.name)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_UPDATED)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_COLLECTIBLE_NOTIFICATION_NEW)
    addon.running = false
    KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
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

local function HandleEventLootReceived(eventCode, receivedBy, itemName, quantity, itemSound, lootType, self, isPickpocketLoot, questItemIcon, itemId)
    lootReceived = true
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
    EVENT_MANAGER:UnregisterForUpdate(addon.name)
    if not CheckInventorySpaceSilently(2) then
        AbortAction()
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_INVENTORY_ERROR_INVENTORY_FULL)
        dbug("not enough space")
        return false
    end
    local remaining = GetItemCooldownInfo(BAG_BACKPACK, slotIndex)
    if IsItemUnboxable(BAG_BACKPACK, slotIndex) then
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
