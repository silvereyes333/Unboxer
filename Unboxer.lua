local addon = {
    name = "Unboxer",
    title = GetString(SI_UNBOXER),
    author = "|c99CCEFsilvereyes|r",
    version = "1.1.0",
    defaults =
    {
        verbose = true,
        gunnySacks = false,
        enchantments = false,
        weapons = false,
        armor = false,
        potions = false,
        accessories = false,
        rewards = false,
        alchemist = false,
        blacksmith = false,
        clothier = false,
        enchanter = false,
        provisioner = false,
        woodworker = false,
        giftBoxes = false,
        ptsCrafting = false,
        other = false
    },
    debugMode = false
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

local useCallProtectedFunction = IsProtectedFunction("UseItem")
local function IsItemUnboxable(bagId, slotIndex)
    if bagId ~= BAG_BACKPACK then return false end

    local itemType = GetItemType(bagId, slotIndex)
    if itemType ~= ITEMTYPE_CONTAINER then return false end
    
    local name = string.lower(GetItemName(bagId, slotIndex))
    if name == "wet gunny sack" then
        if not addon.settings.gunnySacks then
            return false
        end
    elseif string.find(name, "enchantment") ~= nil then
        if not addon.settings.enchantment then
            return false
        end
    elseif string.find(name, "weapon") ~= nil or string.find(name, "staff") ~= nil then
        if not addon.settings.weapons then
            return false
        end
    elseif string.find(name, "armor") ~= nil then
        if not addon.settings.armor then
            return false
        end
    elseif string.find(name, "dragonstar") ~= nil or string.find(name, "undaunted") ~= nil or string.find(name, "mage") ~= nil or string.find(name, "warrior") ~= nil or string.find(name, "serpent") ~= nil then
        if not addon.settings.trials then
            return false
        end
    elseif string.find(name, "the crafter's") ~= nil or string.find(name, "the traveled") ~= nil or string.find(name, "the alchemist's") ~= nil  then
        if not addon.settings.ptsCrafter then
            return false
        end
    elseif string.find(name, "alchemist's vessel") ~= nil then
        if not addon.settings.alchemist then
            return false
        end
    elseif string.find(name, "alchemist") ~= nil then
        if not addon.settings.potions then
            return false
        end
    elseif string.find(name, "blacksmith") ~= nil or string.find(name, "ingot") ~= nil then
        if not addon.settings.blacksmith then
            return false
        end
    elseif string.find(name, "cloth") then
        if not addon.settings.clothier then
            return false
        end
    elseif string.find(name, "enchanter") ~= nil then
        if not addon.settings.enchanter then
            return false
        end
    elseif string.find(name, "woodworker") ~= nil or string.find(name, "shipment") then
        if not addon.settings.woodworker then
            return false
        end
    elseif string.find(name, "brewer") ~= nil or string.find(name, "cooking") ~= nil or string.find(name, "provisioner") ~= nil  then
        if not addon.settings.provisioner then
            return false
        end
    elseif string.find(name, "accessory") ~= nil or string.find(name, "jewelry") ~= nil  then
        if not addon.settings.accessories then
            return false
        end
    elseif string.find(name, "gift") ~= nil then
        if not addon.settings.giftBoxes then
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
    EVENT_MANAGER:UnregisterForUpdate(addon.name)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_UPDATED)
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
local function HandleEventLootUpdated(eventCode)
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_UPDATED)
    table.insert(timeoutItemUniqueIds, GetItemUniqueId(BAG_BACKPACK, slotIndex))
    zo_callLater(LootAllItemsTimeout, 1500) -- If still not looted after 1.5 secs, try to loot again
    LOOT_SHARED:LootAllItems()
    dbug("LootUpdated("..tostring(eventCode)..")")
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
    
    -- Disable the autoloot functionality of Dolgubon's Lazy Writ Crafter
    if WritCreater then
        EVENT_MANAGER:UnregisterForEvent(WritCreater.name, EVENT_LOOT_UPDATED )
    end
end



----------------- Settings -----------------------
function addon:SetupSettings()
    local LAM2 = LibStub("LibAddonMenu-2.0")
    if not LAM2 then return end

    local panelData = {
        type = "panel",
        name = addon.title,
        displayName = addon.title,
        author = addon.author,
        version = addon.version,
        slashCommand = "/unboxer",
        -- registerForRefresh = true,
        registerForDefaults = true,
    }
    LAM2:RegisterAddonPanel(addon.name, panelData)

    local optionsTable = {
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_VERBOSE),
            tooltip = GetString(SI_UNBOXER_VERBOSE_TOOLTIP),
            getFunc = function() return addon.settings.verbose end,
            setFunc = function(value) addon.settings.verbose = value end,
            default = self.defaults.verbose,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_ARMOR),
            tooltip = GetString(SI_UNBOXER_ARMOR_TOOLTIP),
            getFunc = function() return addon.settings.armor end,
            setFunc = function(value) addon.settings.armor = value end,
            default = self.defaults.armor,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_WEAPONS),
            tooltip = GetString(SI_UNBOXER_WEAPONS_TOOLTIP),
            getFunc = function() return addon.settings.weapons end,
            setFunc = function(value) addon.settings.weapons = value end,
            default = self.defaults.weapons,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_REWARDS),
            tooltip = GetString(SI_UNBOXER_REWARDS_TOOLTIP),
            getFunc = function() return addon.settings.rewards end,
            setFunc = function(value) addon.settings.rewards = value end,
            default = self.defaults.rewards,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_ACCESSORIES),
            tooltip = GetString(SI_UNBOXER_ACCESSORIES_TOOLTIP),
            getFunc = function() return addon.settings.accessories end,
            setFunc = function(value) addon.settings.accessories = value end,
            default = self.defaults.accessories,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_GIFTBOXES),
            tooltip = GetString(SI_UNBOXER_GIFTBOXES_TOOLTIP),
            getFunc = function() return addon.settings.giftBoxes end,
            setFunc = function(value) addon.settings.giftBoxes = value end,
            default = self.defaults.giftBoxes,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_GUNNYSACKS),
            tooltip = GetString(SI_UNBOXER_GUNNYSACKS_TOOLTIP),
            getFunc = function() return addon.settings.gunnySacks end,
            setFunc = function(value) addon.settings.gunnySacks = value end,
            default = self.defaults.gunnySacks,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_ENCHANTMENTS),
            tooltip = GetString(SI_UNBOXER_ENCHANTMENTS_TOOLTIP),
            getFunc = function() return addon.settings.enchantments end,
            setFunc = function(value) addon.settings.enchantments = value end,
            default = self.defaults.enchantments,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_POTIONS),
            tooltip = GetString(SI_UNBOXER_POTIONS_TOOLTIP),
            getFunc = function() return addon.settings.potions end,
            setFunc = function(value) addon.settings.potions = value end,
            default = self.defaults.potions,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_ALCHEMIST),
            tooltip = GetString(SI_UNBOXER_ALCHEMIST_TOOLTIP),
            getFunc = function() return addon.settings.alchemist end,
            setFunc = function(value) addon.settings.alchemist = value end,
            default = self.defaults.alchemist,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_BLACKSMITH),
            tooltip = GetString(SI_UNBOXER_BLACKSMITH_TOOLTIP),
            getFunc = function() return addon.settings.blacksmith end,
            setFunc = function(value) addon.settings.blacksmith = value end,
            default = self.defaults.blacksmith,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_CLOTHIER),
            tooltip = GetString(SI_UNBOXER_CLOTHIER_TOOLTIP),
            getFunc = function() return addon.settings.clothier end,
            setFunc = function(value) addon.settings.clothier = value end,
            default = self.defaults.clothier,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_ENCHANTER),
            tooltip = GetString(SI_UNBOXER_ENCHANTER_TOOLTIP),
            getFunc = function() return addon.settings.enchanter end,
            setFunc = function(value) addon.settings.enchanter = value end,
            default = self.defaults.enchanter,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_PROVISIONER),
            tooltip = GetString(SI_UNBOXER_PROVISIONER_TOOLTIP),
            getFunc = function() return addon.settings.provisioner end,
            setFunc = function(value) addon.settings.provisioner = value end,
            default = self.defaults.provisioner,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_WOODWORKER),
            tooltip = GetString(SI_UNBOXER_WOODWORKER_TOOLTIP),
            getFunc = function() return addon.settings.woodworker end,
            setFunc = function(value) addon.settings.woodworker = value end,
            default = self.defaults.woodworker,
        },
        {
            type = "checkbox",
            name = "Crafting: PTS Template Materials",
            getFunc = function() return addon.settings.ptsCrafting end,
            setFunc = function(value) addon.settings.ptsCrafting = value end,
            default = self.defaults.ptsCrafting,
        },
        {
            type = "checkbox",
            name = GetString(SI_UNBOXER_OTHER),
            tooltip = GetString(SI_UNBOXER_OTHER_TOOLTIP),
            getFunc = function() return addon.settings.other end,
            setFunc = function(value) addon.settings.other = value end,
            default = self.defaults.other,
        },
    }
    LAM2:RegisterOptionControls(addon.name, optionsTable)
end

--------------- End Settings ---------------------


local function OnAddonLoaded(event, name)
    if name ~= addon.name then return end
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

    addon.settings = ZO_SavedVars:NewAccountWide("Unboxer_Data", 1, nil, addon.defaults)

    addon:AddKeyBind()
    addon:SetupSettings()
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

Unboxer = addon
