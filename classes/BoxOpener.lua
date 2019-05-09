--[[ 
     Handles the actual box opening process.
]]--

local addon = Unboxer
local class = addon.classes
local debug = false
local suppressLootWindow = function() end
local HandleEventLootClosed, HandleEventLootReceived, HandleEventLootUpdated, HandleEventNewCollectible

class.BoxOpener = ZO_CallbackObject:Subclass()

function class.BoxOpener:New(...)
    local instance = ZO_Object.New(self)
    instance:Initialize(...)
    return instance
end
function class.BoxOpener:Initialize(slotIndex)
    self.name = addon.name .. "_BoxOpener_" .. tostring(slotIndex)
    self.slotIndex = slotIndex
    self.isUnboxable, self.matchedRule = addon:IsItemUnboxable(BAG_BACKPACK, self.slotIndex)
    self.itemLink = GetItemLink(BAG_BACKPACK, self.slotIndex)
    self.lootReceived = {}
end
function class.BoxOpener:DelayOpen(delayMilliseconds)
    EVENT_MANAGER:RegisterForUpdate(self.name, delayMilliseconds, function() self:Open(self.slotIndex) end)
end

function class.BoxOpener:Reset()
    self.lootReceived = false
    EVENT_MANAGER:UnregisterForUpdate(self.name)
    EVENT_MANAGER:UnregisterForUpdate(self.name .. "_Timeout")
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_LOOT_RECEIVED)
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_LOOT_UPDATED)
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_LOOT_CLOSED)
    if self.originalUpdateLootWindow then
        local lootWindow = SYSTEMS:GetObject("loot")
        lootWindow.UpdateLootWindow = addon.originalUpdateLootWindow
    end
end
function class.BoxOpener:Open()
    
    if not self.isUnboxable then
        return
    end
    
    if not CanInteractWithItem(BAG_BACKPACK, self.slotIndex) then
        addon.Debug("Slot index "..tostring(self.slotIndex).." is not interactable right now. Wait 1 second and try again.", debug)
        self:DelayOpen(1000)
        return true
    end
    
    local remaining, duration = GetItemCooldownInfo(BAG_BACKPACK, self.slotIndex)
    if remaining > 0 and duration > 0 then
        addon.Debug("item at slotIndex "..tostring(self.slotIndex).." is on cooldown for another "..tostring(remaining).." ms duration "..tostring(duration)..". wait until it is ready", debug)
        self:DelayOpen(remaining + 40)
        return true
    end
    
    self:Reset()
    
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_LOOT_RECEIVED, self:CreateLootReceivedHandler())
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_LOOT_UPDATED, self:CreateLootUpdatedHandler())
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_LOOT_CLOSED, self:CreateLootClosedHandler())
    --EVENT_MANAGER:RegisterForEvent(self.name, EVENT_COLLECTIBLE_NOTIFICATION_NEW, self:CreateNewCollectibleHandler())
    
    if not self.originalUpdateLootWindow then
        local lootWindow = SYSTEMS:GetObject("loot")
        self.originalUpdateLootWindow = lootWindow.UpdateLootWindow
        addon.Debug("original loot window update:"..tostring(lootWindow.UpdateLootWindow), debug)
        addon.Debug("new loot window update: "..tostring(suppressLootWindow), debug)
        lootWindow.UpdateLootWindow = suppressLootWindow
    end
    
    if CallSecureProtected("UseItem", BAG_BACKPACK, self.slotIndex) then
        return true
    end
            
    -- Something more serious went wrong
    addon.Debug("CallSecureProtected failed", debug)
    self:Reset()
    PlaySound(SOUNDS.NEGATIVE_CLICK)
    addon.Print(zo_strformat("Failed to unbox <<1>>", self.itemLink))
end
function class.BoxOpener:OnFailed()
    self:FireCallbacks("Failed", self.slotIndex, self.itemLink)
end
function class.BoxOpener:OnOpened()
    self:FireCallbacks("Opened", self.itemLink, self.lootReceived)
end

function class.BoxOpener:CreateLootReceivedHandler()
    return function(eventCode, receivedBy, itemLink, quantity, itemSound, lootType, lootedBySelf, isPickpocketLoot, questItemIcon, itemId)
        table.insert(self.lootReceived, {
                itemLink = itemLink,
                quantity = quantity, 
                lootType = lootType,
                lootedBySelf = lootedBySelf,
            })
        addon.Debug("LootReceived("..tostring(eventCode)..", "..zo_strformat("<<1>>", receivedBy)..", "..tostring(itemLink)..", "..tostring(quantity)..", "..tostring(itemSound)..", "..tostring(lootType)..", "..tostring(lootedBySelf)..", "..tostring(isPickpocketLoot)..", "..tostring(questItemIcon)..", "..tostring(itemId)..")", debug)
    end
end
function class.BoxOpener:CreateLootClosedHandler()
    return function (eventCode)
        addon.Debug("LootClosed("..tostring(eventCode)..")", debug)
        EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_LOOT_CLOSED)
        EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_LOOT_RECEIVED)
        --EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_COLLECTIBLE_NOTIFICATION_NEW)
        
        self:OnOpened()
    end
end
local function GetInventorySlotsNeeded()
    local inventorySlotsNeeded = GetNumLootItems()
    if HasCraftBagAccess() then
        for lootIndex = 1, GetNumLootItems() do
            local lootId = GetLootItemInfo(lootIndex)
            if GetLootItemType(lootId) == LOOT_TYPE_ITEM and CanItemLinkBeVirtual(GetLootItemLink(lootId)) do
                inventorySlotsNeeded = inventorySlotsNeeded - 1
            end
        end
    end
    if addon.settings.reservedSlots and type(addon.settings.reservedSlots) == "number" then
        inventorySlotsNeeded = inventorySlotsNeeded + addon.settings.reservedSlots
    end
    return inventorySlotsNeeded
end

function class.BoxOpener:RegisterLootAllItemsTimeout()
    EVENT_MANAGER:RegisterForUpdate(self.name .. "_Timeout", 1000, self:CreateLootUpdatedHandler())
end
function class.BoxOpener:CreateLootUpdatedHandler()
    return function(eventCode)  
        EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_LOOT_UPDATED)
        local inventorySlotsNeeded = GetInventorySlotsNeeded()
        if not CheckInventorySpaceAndWarn(inventorySlotsNeeded) then
            self:OnFailed("Not enough space")
            self:Reset()
            EndLooting()
            return
        end
        self:RegisterLootAllItemsTimeout()
        LOOT_SHARED:LootAllItems()
    end
end
--[[function class.BoxOpener:CreateNewCollectibleHandler()
    return function(eventCode, collectibleId)
        table.insert(self.collectiblesReceived, collectibleId)
    end
end]]