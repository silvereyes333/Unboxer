Unboxer = {
    name = "Unboxer",
    title = GetString(SI_UNBOXER),
    author = "|c99CCEFsilvereyes|r",
    version = "3.0.0",
    itemSlotStack = {},
    defaultLanguage = "en",
    debugMode = false,
    classes = {},
    rules = {},
    submenuOptions = {},
}

local addon = Unboxer
local LLS = LibStub("LibLootSummary")
local prefix = zo_strformat("<<1>>|cFFFFFF: ", addon.title)
local itemLinkFormat = '|H1:item:<<1>>:30:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:10000:0|h|h'

-- Output formatted message to chat window, if configured
function addon.Print(input, force)
    if not force and not (addon.settings and addon.settings.verbose) then
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
function addon.GetItemLinkFromItemId(itemId)
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
    if not stringId then
        return
    end
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
    if searchFor and searchFor ~= "" then
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
    if itemType ~= ITEMTYPE_CONTAINER 
       and (not ITEMTYPE_CONTAINER_CURRENCY or itemType ~= ITEMTYPE_CONTAINER_CURRENCY)
    then 
        return false
    end
    
    local data = self:GetItemLinkData(itemLink)
    
    -- not sure why there's no item id, but return false to be safe
    if not data.itemId then return false end
    
    -- No rules matched
    if not data.rule then
        return false
    end
    
    local isUnboxable = data.isUnboxable and data.rule:IsEnabled()
    if isUnboxable and self.autolooting then
        isUnboxable = data.rule:IsAutolootEnabled()
    end
    
    return isUnboxable, data.rule
end

function addon:IsItemUnboxable(bagId, slotIndex)
    if bagId ~= BAG_BACKPACK then return false end
    
    local itemLink = GetItemLink(bagId, slotIndex)

    local unboxable, matchedRule = self:IsItemLinkUnboxable(itemLink)    
    local usable, onlyFromActionSlot = IsItemUsable(bagId, slotIndex)
    self.Debug(tostring(itemLink)..", unboxable: "..tostring(unboxable)..", usable: "..tostring(usable)..", onlyFromActionSlot: "..tostring(onlyFromActionSlot)..", matchedRule: "..(matchedRule and matchedRule.name or ""))
    return unboxable and usable and not onlyFromActionSlot, matchedRule
end

local HudStateChange
local UnboxCurrent
local itemLink
local timeoutItemUniqueIds = {}
local updateExpected = false
local lootReceived
local matchedRule

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
    matchedRule = nil
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

function addon:IsDefaultLanguageSelected()
    return GetCVar("language.2") == self.defaultLanguage
end

function addon:GetItemLinkData(itemLink, language)

    local itemType, specializedItemType = GetItemLinkItemType(itemLink)
    local itemId = GetItemLinkItemId(itemLink)
    local icon = LocaleAwareToLower(GetItemLinkIcon(itemLink))
    local name = LocaleAwareToLower(GetItemLinkTradingHouseItemSearchName(itemLink))
    local flavorText = LocaleAwareToLower(GetItemLinkFlavorText(itemLink))
    local setInfo = { GetItemLinkSetInfo(itemLink) }
    local hasSet, setName, _, _, _, setId = GetItemLinkSetInfo(itemLink)
    if setName == "" then setName = nil end
    local requiredChampionPoints = GetItemLinkRequiredChampionPoints(itemLink)
    local requiredLevel = GetItemLinkRequiredLevel(itemLink)
    local quality = GetItemLinkQuality(itemLink)
    local bindType = GetItemLinkBindType(itemLink)
    local data = {
        ["itemId"]                 = itemId,
        ["itemLink"]               = itemLink,
        ["bindType"]               = bindType,
        ["name"]                   = LocaleAwareToLower(GetItemLinkTradingHouseItemSearchName(itemLink)),
        ["flavorText"]             = LocaleAwareToLower(GetItemLinkFlavorText(itemLink)),
        ["quality"]                = GetItemLinkQuality(itemLink),
        ["icon"]                   = LocaleAwareToLower(GetItemLinkIcon(itemLink)),
        ["hasSet"]                 = hasSet,
        ["setName"]                = setName,
        ["setId"]                  = setId,
        ["requiredLevel"]          = GetItemLinkRequiredLevel(itemLink),
        ["requiredChampionPoints"] = GetItemLinkRequiredChampionPoints(itemLink),
        ["collectibleId"]          = GetItemLinkContainerCollectibleId(itemLink),
    }
    if type(data.collectibleId) == "number" and data.collectibleId > 0 then
        data["collectibleCategoryType"] = GetCollectibleCategoryType(data.collectibleId)
        data["collectibleUnlocked"]     = IsCollectibleUnlocked(data.collectibleId)
    end
  
    data["containerType"] = "unknown"
    for ruleIndex, rule in ipairs(self.rules) do
        local isMatch, isUnboxable = rule:Match(data)
        if isMatch then
            data["containerType"] = rule.name
            data["isUnboxable"] = isUnboxable
            data.rule = rule
            break
        end
    end
    return data
end
local function PrintUnboxedLink()
    if not addon.unboxingItemLink then return end
    addon.Print(zo_strformat(SI_UNBOXER_UNBOXED, addon.unboxingItemLink))
    addon.unboxingItemLink = nil
end
local function GetAutolootDelayMS()
    local delay = math.max(40, addon.settings.autolootDelay * 1000)
    return delay
end
local function HandleEventPlayerCombatState(eventCode, inCombat)
    local self = addon
    if not inCombat then
        self.Debug("Combat ended. Resume unboxing.")
        EVENT_MANAGER:UnregisterForEvent(self.name,  EVENT_PLAYER_COMBAT_STATE)
        -- Continue unboxings
        self.Debug("RegisterForUpdate("..self.name..", "..GetAutolootDelayMS()..", UnboxCurrent)")
        EVENT_MANAGER:RegisterForUpdate(self.name, GetAutolootDelayMS(), UnboxCurrent)
    end
end
local function HandleEventPlayerNotSwimming(eventCode)
    local self = addon
    self.Debug("Player not swimming. Resume unboxing.")
    EVENT_MANAGER:UnregisterForEvent(self.name,  EVENT_PLAYER_NOT_SWIMMING)
    -- Continue unboxings
    self.Debug("RegisterForUpdate("..self.name..", "..GetAutolootDelayMS()..", UnboxCurrent)")
    EVENT_MANAGER:RegisterForUpdate(self.name, GetAutolootDelayMS(), UnboxCurrent)
end
local function HandleEventPlayerAlive(eventCode)
    local self = addon
    self.Debug("Player alive again. Resume unboxing.")
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_PLAYER_ALIVE)
    -- Continue unboxings
    self.Debug("RegisterForUpdate("..self.name..", "..GetAutolootDelayMS()..", UnboxCurrent)")
    EVENT_MANAGER:RegisterForUpdate(self.name, GetAutolootDelayMS(), UnboxCurrent)
end
local function HandleEventLootReceived(eventCode, receivedBy, itemLink, quantity, itemSound, lootType, lootedBySelf, isPickpocketLoot, questItemIcon, itemId)
    local self = addon
    lootReceived = true
    PrintUnboxedLink()
    if matchedRule and lootedBySelf and lootType == LOOT_TYPE_ITEM then
        if matchedRule:IsSummaryEnabled() then
            LLS:AddItemLink(itemLink, quantity)
        end
    end
    addon.Debug("LootReceived("..tostring(eventCode)..", "..zo_strformat("<<1>>", receivedBy)..", "..tostring(itemLink)..", "..tostring(quantity)..", "..tostring(itemSound)..", "..tostring(lootType)..", "..tostring(lootedBySelf)..", "..tostring(isPickpocketLoot)..", "..tostring(questItemIcon)..", "..tostring(itemId)..")")
end
local InventoryStateChange
local function HandleEventLootClosed(eventCode)
    local self = addon
    addon.Debug("LootClosed("..tostring(eventCode)..")")
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_LOOT_CLOSED)
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_LOOT_RECEIVED)
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_COLLECTIBLE_NOTIFICATION_NEW)
    if lootReceived then
        lootReceived = nil
        if self.running then
            local menuBarState = BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState()
            if menuBarState == SCENE_HIDDEN then
                self.Debug("Menu bar is hidden")
                AbortAction()
                return
            end
            if not addon.UnboxAll() then
                self.Debug("UnboxAll returned false")
                AbortAction()
                return
            end
        end
    elseif self.slotIndex then
        self.Debug("lootReceived is false. attempting to loot again.")
        timeoutItemUniqueIds = {}
        table.insert(self.itemSlotStack, self.slotIndex)
    end
    self.Debug("RegisterForUpdate("..self.name..", 40, UnboxCurrent)")
    EVENT_MANAGER:RegisterForUpdate(self.name, 40, UnboxCurrent)
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
        zo_callLater(LootAllItemsTimeout, GetAutolootDelayMS()) -- If still not looted after X secs, try to loot again
        LOOT_SHARED:LootAllItems()
    end
end
local function HandleEventLootUpdated(eventCode)  
    local self = addon
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_LOOT_UPDATED)
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
    zo_callLater(LootAllItemsTimeout, GetAutolootDelayMS()) -- If still not looted after X secs, try to loot again
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
local HandleInteractWindowHidden
local function StartInteractWait()
    addon.Debug("Interaction ended. Waiting ".. addon.settings.autolootDelay .." seconds to try unboxing again.")
    INTERACT_WINDOW:UnregisterCallback("Hidden", HandleInteractWindowHidden)
    HUD_SCENE:UnregisterCallback("StateChange", HudStateChange)
    EVENT_MANAGER:UnregisterForUpdate(addon.name.."InteractWait")
    EVENT_MANAGER:RegisterForUpdate(addon.name.."InteractWait", GetAutolootDelayMS(), EndInteractWait)
end
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
    self.Debug("UnregisterForUpdate("..self.name..")")
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
    isUnboxable, matchedRule = self:IsItemUnboxable(BAG_BACKPACK, slotIndex)
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
                self.Debug("RegisterForUpdate("..self.name..", 1000, UnboxCurrent)")
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
            self.Debug("RegisterForUpdate("..self.name..", "..duration..", UnboxCurrent)")
            EVENT_MANAGER:RegisterForUpdate(self.name, duration, UnboxCurrent)
            return
            
        else
            self.Debug("Setting self.slotIndex = "..tostring(slotIndex))
            self.slotIndex = slotIndex
            LLS:SetPrefix(prefix)
            EVENT_MANAGER:RegisterForEvent(self.name, EVENT_LOOT_RECEIVED, HandleEventLootReceived)
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
        self.Debug(tostring(itemLink).." usable: "..tostring(usable)..", onlyFromActionSlot: "..tostring(onlyFromActionSlot)..", canInteractWithItem: "..tostring(canInteractWithItem)..", matchedRule: "..tostring(matchedRule and matchedRule.name))
        -- The current item from the slot stack was not unboxable.  Move on.
        self.Debug("RegisterForUpdate("..self.name..", 40, UnboxCurrent)")
        EVENT_MANAGER:RegisterForUpdate(self.name, 40, UnboxCurrent)
    end
end

function addon.UnboxAll()
    local self = addon
    local slotIndex = GetNextItemToUnbox()
    if not slotIndex then return end
    table.insert(self.itemSlotStack, slotIndex)
    self.running = true
    self.Debug("RegisterForUpdate("..self.name..", 40, UnboxCurrent)")
    EVENT_MANAGER:RegisterForUpdate(self.name, 40, UnboxCurrent)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.unboxAllKeybindButtonGroup)
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
    if self.running then return end
    local itemType = GetItemType(bagId, slotIndex)
    if itemType ~= ITEMTYPE_CONTAINER
       and (not ITEMTYPE_CONTAINER_CURRENCY or itemType ~= ITEMTYPE_CONTAINER_CURRENCY)
    then
        self.Debug("Item isn't a container. Not going to autoloot.")
        return
    end
    table.insert(self.itemSlotStack, slotIndex)
    addon.autolooting = true
    self.Debug("RegisterForUpdate("..self.name..", "..GetAutolootDelayMS()..", UnboxCurrent)")
    EVENT_MANAGER:RegisterForUpdate(self.name, GetAutolootDelayMS(), UnboxCurrent)
end
function addon:RegisterEvents()
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySingleSlotUpdate)
    EVENT_MANAGER:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK)
    EVENT_MANAGER:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
    EVENT_MANAGER:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_IS_NEW_ITEM, true)
end
function addon:GetRuleInsertIndex(instance)
    
    for ruleIndex = 1, #self.rules do
        local rule = self.rules[ruleIndex]
        if rule:IsDependentUpon(instance) then
            return ruleIndex
        end
    end
    
    return #self.rules + 1
end
local function tableMultiInsertSorted(targetTable, newEntry, key, startIndex, endIndex, compareIndexOffset)
    local self = addon
    if not compareIndexOffset then
        compareIndexOffset = 1
    end
    local step = #newEntry
    local insertAtIndex
    for optionIndex = startIndex + compareIndexOffset - 1, endIndex, step do
        local entry = targetTable[optionIndex]
        if entry[key] > newEntry[compareIndexOffset][key] then
            insertAtIndex = optionIndex - compareIndexOffset + 1
            break
        end
    end
    if not insertAtIndex then
        insertAtIndex = endIndex + 1
    end
    for i = 1, step do
        local option = newEntry[i]
        self.Debug("Adding "..tostring(option.type)..(option.name and " with name "..tostring(option.name) or "").." at index "..tostring(insertAtIndex + i - 1))
        table.insert(targetTable, insertAtIndex + i - 1, newEntry[i])
    end
end
function addon:RegisterCategoryRule(class)
    if type(class) == "string" then
        class = self.classes[class]
    end
    if not class then return end
    
    -- Create the new rule
    local rule = class:New()
    
    -- Get the index the new rule needs to be inserted at in
    -- order to satisfy existing rule dependencies on it.
    local insertIndex = self:GetRuleInsertIndex(rule)
    
    -- Detect rules that the new rule is dependent upon that need
    -- shifted up in priority to satisfy the dependency
    local rulesToMove = {}
    for ruleIndex=insertIndex + 1, #self.rules do
        local compareToRule = self.rules[ruleIndex]
        if rule:IsDependentUpon(compareToRule) then
            table.insert(rulesToMove, ruleIndex)
        end
    end
    
    -- Move the existing rules that need to be moved
    for _, ruleIndex in ipairs(rulesToMove) do
        local ruleToMove = table.remove(self.rules, ruleIndex)
        table.insert(self.rules, insertIndex, ruleToMove)
        insertIndex = insertIndex + 1
    end
    
    -- Register the new rule
    table.insert(self.rules, insertIndex, rule)
    
    -- The remaining logic pertains to creating LAM options.
    -- Skip if the rule is marked hidden.
    if rule.hidden then return end
    
    local sub
    
    -- If this is the first rule in its sub-menu, initialize it
    if not self.submenuOptions[rule.submenu] then
        self.submenuOptions[rule.submenu] = {}
        local submenu = { type = "submenu", name = rule.submenu, controls = self.submenuOptions[rule.submenu] }
        tableMultiInsertSorted(self.optionsTable, { submenu }, "name", self.firstSubmenuOptionIndex, #self.optionsTable)
    end
    
    -- Create the new sub-menu option control config
    local ruleSubmenuOption = rule:CreateLAM2Options()
    local compareIndexOffset
    for i, option in ipairs(ruleSubmenuOption) do
        if option.name == rule.title then
            compareIndexOffset = i
            break
        end
    end
    
    -- Insert the new sub-menu option config into its sub-menu's "controls" table.
    tableMultiInsertSorted(self.submenuOptions[rule.submenu], ruleSubmenuOption, "name", 1, #self.submenuOptions[rule.submenu], compareIndexOffset)
end
local function OnAddonLoaded(event, name)
  
    if name ~= addon.name then return end
    local self = addon
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)

    self:AddKeyBind()
    self:SetupSettings()
    
    self:RegisterCategoryRule(self.classes.Pts)
    self:RegisterCategoryRule(self.classes.CraftingRewards)
    self:RegisterCategoryRule(self.classes.Dungeon)
    self:RegisterCategoryRule(self.classes.Festival)
    self:RegisterCategoryRule(self.classes.Fishing)
    self:RegisterCategoryRule(self.classes.Furnisher)
    self:RegisterCategoryRule(self.classes.Legerdemain)
    self:RegisterCategoryRule(self.classes.LoreLibraryReprints)
    self:RegisterCategoryRule(self.classes.Materials)
    self:RegisterCategoryRule(self.classes.Runeboxes)
    self:RegisterCategoryRule(self.classes.Solo)
    self:RegisterCategoryRule(self.classes.SoloRepeatable)
    self:RegisterCategoryRule(self.classes.StylePages)
    self:RegisterCategoryRule(self.classes.TelVar)
    self:RegisterCategoryRule(self.classes.Transmutation)
    self:RegisterCategoryRule(self.classes.TreasureMaps)
    self:RegisterCategoryRule(self.classes.Trial)
    self:RegisterCategoryRule(self.classes.VendorGear)
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
