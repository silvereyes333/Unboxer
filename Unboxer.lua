Unboxer = {
    name = "Unboxer",
    title = GetString(SI_UNBOXER),
    author = "|c99CCEFsilvereyes|r",
    version = "2.9.1",
    filters = {},
    itemSlotStack = {},
    defaultLanguage = "en",
    debugMode = false,
    classes = {},
    rules = {},
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

function addon:IsDefaultLanguageSelected()
    return GetCVar("language.2") == self.defaultLanguage
end

local function LookupOldFilterCategories(itemId)
    for filterCategory1, category1Filters in pairs(self.filters) do
        for filterCategory2, filters in pairs(category1Filters) do
            if filters[itemId] then
                return filterCategory1, filterCategory2
            end
        end
    end
end

function addon:GetItemLinkData(itemLink)

    local itemType, specializedItemType = GetItemLinkItemType(itemLink)
    local itemId = GetItemLinkItemId(itemLink)
    local icon = LocaleAwareToLower(GetItemLinkIcon(itemLink))
    local name = LocaleAwareToLower(GetItemLinkTradingHouseItemSearchName(itemLink))
    local flavorText = LocaleAwareToLower(GetItemLinkFlavorText(itemLink))
    local setInfo = { GetItemLinkSetInfo(itemLink) }
    local hasSet, setName, _, _, _, setId = GetItemLinkSetInfo(itemLink)
    local requiredChampionPoints = GetItemLinkRequiredChampionPoints(itemLink)
    local requiredLevel = GetItemLinkRequiredLevel(itemLink)
    local quality = GetItemLinkQuality(itemLink)
    local bindType = GetItemLinkBindType(itemLink)
    local filterCategory1, filterCategory2 = LookupOldFilterCategories(itemId)
    
    local data = {
        ["itemId"]                 = itemId,
        ["itemLink"]               = itemLink,
        ["name"]                   = LocaleAwareToLower(GetItemLinkTradingHouseItemSearchName(itemLink)),
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
    
  
    local containerType
    for ruleIndex, rule in ipairs(self.rules) do
        if rule:Match(data) then
            containerType = rule.name
        end
    end
    
    local interactionType = addon.settings.containerDetails[itemId] and addon.settings.containerDetails[itemId]["interactionType"]
    local text = addon.settings.containerDetails[itemId] and addon.settings.containerDetails[itemId]["text"] or {}
    text[GetCVar("language.2")] = {
        ["name"] = name,
        ["flavorText"] = flavorText,
        ["setName"] = setName,
    }
    return {
        ["containerType"] = containerType,
        ["itemLink"] = itemLink,
        ["filterCategory1"] = filterCategory1,
        ["filterCategory2"] = filterCategory2,
        ["bindType"] = bindType,
        ["collectibleId"] = GetItemLinkContainerCollectibleId(itemLink),
        ["icon"] = icon,
        ["abilities"] = GetItemLinkOnUseAbilityInfo(itemLink),
        ["quality"] = quality,
        ["requiredChampionPoints"] = requiredChampionPoints,
        ["requiredLevel"] = requiredLevel,
        ["sellInformation"] = GetItemLinkSellInformation(itemLink),
        ["text"] = text,
        ["interactionType"] = interactionType,
        ["store"] = addon.settings.containerDetails[itemId] and addon.settings.containerDetails[itemId]["store"]
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
    EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_LOOT_RECEIVED , HandleEventLootReceived)
    EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_LOOT_UPDATED , HandleEventLootUpdated)
    EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_OPEN_STORE, OnOpenStore)
end
function addon:GetRuleInsertIndex(instance)
    
    local dependencies = instance.dependencies
    
    for ruleIndex = 1, #self.rules do
        local rule = self.rules[ruleIndex]
        if rule.dependencies then
            for _, dependency in ipairs(rule.dependencies) do
                if dependency == instance.name then
                    return ruleIndex
                end
            end
        end
    end
    
    return #self.rules + 1
end
function addon:RegisterCategoryRule(class)
    if type(class) == "string" then
        class = self.classes[class]
    end
    if not class then return end
    
    local instance = class:New()
    local insertIndex = self:GetRuleInsertIndex(instance)
    table.insert(self.rules, insertIndex, instance)
end
local function OnAddonLoaded(event, name)
  
    if name ~= addon.name then return end
    local self = addon
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)

    self:AddKeyBind()
    self:RegisterCategoryRule("Runeboxes")
    self:RegisterCategoryRule("StylePages")
    self:RegisterCategoryRule("CraftingMaterials")
    self:RegisterCategoryRule("CraftingWrits")
    self:RegisterCategoryRule("Pts")
    self:RegisterCategoryRule("Dungeon")
    self:RegisterCategoryRule("Trial")
    self:RegisterCategoryRule("Zone")
    self:RegisterCategoryRule("Festival")
    self:RegisterCategoryRule("Fishing")
    self:RegisterCategoryRule("Transmutation")
    self:RegisterCategoryRule("TreasureMaps")
    self:RegisterCategoryRule("MagesGuildReprints")
    self:RegisterCategoryRule("Furnisher")
    self:RegisterCategoryRule("VendorGear")
    self:SetupSettings()
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)