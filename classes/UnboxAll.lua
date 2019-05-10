--[[ 
     Handles base logic and events for unboxing all containers in inventory as configured.
]]--

local addon = Unboxer
local class = addon.classes
local debug = false
local defaultStates = {}
local LLS = LibStub("LibLootSummary")

class.Manual = ZO_CallbackObject:Subclass()

function class.UnboxAll:New(...)
    local instance = ZO_Object.New(self)
    instance:Initialize(...)
    return instance
end

function class.UnboxAll:Initialize(name)
    self.name = name or addon.name .. "_UnboxAll"
    self:Reset()
    self.states = {}
    self.eventHandlers = {}
    self.callbackHandlers = {}
    for name, config in pairs(defaultStates) do
        if config.events then
            self:RegisterPauseEvents(name, config.events.pause, config.events.unpause, config.stateParameter, config.active)
        end
        if config.callbacks then
            self:RegisterPauseCallbacks(name, config.callbacks.pause, config.callbacks.unpause, config.active)
        end
    end
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, self:CreateSlotUpdateCallback())
    EVENT_MANAGER:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK)
    EVENT_MANAGER:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
    EVENT_MANAGER:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_IS_NEW_ITEM, true)
end
function class.UnboxAll:CreateFailedCallback()
    return function(slotIndex, itemLink, reason)
        addon.Debug("Failed to unbox " .. tostring(itemLink), debug)
        if reason then
            addon.Debug(tostring(reason), true)
        end
        self:FireCallbacks("Failed", slotIndex, itemLink, reason)
        EVENT_MANAGER:RegisterForUpdate(self.name .. "_Start", 40, function() self:Start() end)
    end
end
function class.UnboxAll:CreateOpenedCallback()
    return function(itemLink, lootReceived, rule)
        addon.PrintUnboxedLink(itemLink)
        if not rule or not rule:IsSummaryEnabled() then
            return
        end
        for _, loot in ipairs(lootReceived) do
            if loot.lootedBySelf and loot.lootType == LOOT_TYPE_ITEM then
                LLS:AddItemLink(loot.itemLink, loot.quantity)
            end
        end
        self:FireCallbacks("Opened", itemLink, lootReceived, rule)
        EVENT_MANAGER:RegisterForUpdate(self.name .. "_Start", 40, function() self:Start() end)
    end
end

function class.UnboxAll:CreateSlotUpdateCallback()
    return function(eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
        local itemType = GetItemType(bagId, slotIndex)
        if itemType ~= ITEMTYPE_CONTAINER
           and (not ITEMTYPE_CONTAINER_CURRENCY or itemType ~= ITEMTYPE_CONTAINER_CURRENCY)
        then
            addon.Debug("Item isn't a container. Not going to autoloot.", debug)
            return
        end
        if self:GetAutoQueue() then
            self:Queue({ slotIndex = slotIndex, itemLink = GetItemLink(bagId, slotIndex) })
            if self.state == "stopped" then
                self:DelayStart()
            end
        end
    end
end
function class.UnboxAll:DelayStart(item)
    if item then
        table.insert(self.queue, item)
    end
    self.state = "delayed_start"
    self:FireCallbacks("DelayStart", item)
    EVENT_MANAGER:RegisterForUpdate(self.name "_Start", self:GetDelayMilliseconds(), function() self:Start() end)
end
function class.UnboxAll:GetAutoQueue(value)
    return addon.settings.autoloot or self.autoQueue
end
function class.UnboxAll:GetDelayMilliseconds()
    local delay = math.max(40, addon.settings.autolootDelay * 1000)
    return delay
end
function class.UnboxAll:GetInventorySlotsNeeded(inventorySlotsNeeded)
    if not inventorySlotsNeeded then
        inventorySlotsNeeded = GetNumLootItems()
        if HasCraftBagAccess() then
            for lootIndex = 1, GetNumLootItems() do
                local lootId = GetLootItemInfo(lootIndex)
                if GetLootItemType(lootId) == LOOT_TYPE_ITEM and CanItemLinkBeVirtual(GetLootItemLink(lootId)) do
                    inventorySlotsNeeded = inventorySlotsNeeded - 1
                end
            end
        end
    end
    if addon.settings.reservedSlots and type(addon.settings.reservedSlots) == "number" then
        inventorySlotsNeeded = inventorySlotsNeeded + addon.settings.reservedSlots
    end
    return inventorySlotsNeeded
end
-- Scan backpack for next unboxable container and return true if found
function class.UnboxAll:GetNextItemToUnbox()
    if not self:HasEnoughSlots() then
        addon.Debug("Not enough bag space", debug)
        return
    end

    local bagId = BAG_BACKPACK
    local bagSlots = GetBagSize(bagId) -1
    for index = 0, bagSlots do
        if self:IsItemUnboxable(bagId, index) and CanInteractWithItem(bagId, index) then
            return index
        end
    end
    self.Debug("No unboxable items found", debug)
end
function class.UnboxAll:HasEnoughSlots(inventorySlotsNeeded)
    -- For performance reasons, just assume each box has 2 items, until the box is actually open.
    -- Then we will pass in the exact number.
    if not inventorySlotsNeeded then
        inventorySlotsNeeded = 2
    end
    inventorySlotsNeeded = self:GetInventorySlotsNeeded(inventorySlotsNeeded)
    return CheckInventorySpaceSilently(inventorySlotsNeeded)
end
function class.UnboxAll:HasUnboxableSlots()
  
    if not self:HasEnoughSlots() then 
        return false
    end
    
    for state, config in pairs(self.states) do
        if state.active() then
            return false
        end
    end
    
    if #self.queue > 0 then return false end
    
    local bagId = BAG_BACKPACK
    local bagSlots = GetBagSize(bagId) -1
    for index = 0, bagSlots do
        if self:IsItemUnboxable(bagId, index) and CanInteractWithItem(bagId, index) then return true end
    end

    return false
end
function class.UnboxAll:ListenForPause()
    for _, events in pairs(self.eventHandlers) do
        EVENT_MANAGER:RegisterForEvent(self.name, events.pause.event, events.pause.handler)
    end
    for _, pause in ipairs(self.callbackHandlers[name].pause) do
        pause.target:RegisterCallback(pause.name,  pause.callback)
    end
end
function class.UnboxAll:OnPausedEvent(name)
    local unpause = self.eventHandlers[name].unpause
    EVENT_MANAGER:RegisterForEvent(self.name .. "_" .. name,  unpause.event, unpause.handler)
    self.state = name
    self:FireCallbacks("Paused", name)
    EVENT_MANAGER:UnregisterForUpdate(self.name "_Start")
end
function class.UnboxAll:OnUnpausedEvent(name)
    local unpause = self.eventHandlers[name].unpause
    EVENT_MANAGER:UnregisterForEvent(self.name .. "_" .. name,  unpause.event)
    self.state = "stopped"
    self:FireCallbacks("Unpaused", name)
    if #self.queue then
        self:DelayStart()
    end
end
function class.UnboxAll:OnPausedCallback(name)
    for _, unpause in ipairs(self.callbackHandlers[name].unpause) do
        unpause.target:RegisterCallback(unpause.name,  unpause.callback)
    end
    self.state = name
    self:FireCallbacks("Paused", name)
    EVENT_MANAGER:UnregisterForUpdate(self.name "_Start")
end
function class.UnboxAll:OnUnpausedEvent(name)
    for _, unpause in ipairs(self.callbackHandlers[name].unpause) do
        unpause.target:UnregisterCallback(unpause.name,  unpause.callback)
    end
    self.state = "stopped"
    self:FireCallbacks("Unpaused", name)
    if #self.queue then
        self:DelayStart()
    end
end
function class.UnboxAll:Queue(item)
    table.insert(self.queue, item)
end
function class.UnboxAll:QueueAllInBackpack()
    local bagId = BAG_BACKPACK
    local bagSlots = GetBagSize(bagId) - 1
    for slotIndex = 0, bagSlots do
        if self:IsItemUnboxable(bagId, slotIndex) and CanInteractWithItem(bagId, slotIndex) then
            self:Queue({slotIndex = slotIndex, itemLink = GetItemLink(bagId, slotIndex)})
        end
    end
end
function class.UnboxAll:RefreshState()
    for name, state in pairs(self.states) do
        if state.active() then
            if state.events then
                self:OnPausedEvent(name)
            end
            return
        end
    end
end
function class.UnboxAll:Reset()
    self.state = "stopped"
    self.queue = {}
    self.autoQueue = nil
    EVENT_MANAGER:UnregisterForUpdate(self.name "_Start")
    for eventName, events in pairs(self.eventHandlers) do
        local unpause = events.unpause
        EVENT_MANAGER:UnregisterForEvent(self.name .. "_" .. eventName,  unpause.event)
    end
    for _, handlers in pairs(self.callbackHandlers) do
        for _, unpause in ipairs(handlers.unpause) do
            unpause.target:UnregisterCallback(unpause.name, unpause.callback)
        end
    end
end
function class.UnboxAll:RegisterPauseEvents(name, pauseEvent, unpauseEvent, stateParameter, activeFunc)
    self.states[name] = {
        events = { pause = pauseEvent, unpause = unpauseEvent },
        stateParameter = stateParameter,
        active = activeFunc,
    }
    self.eventHandlers[name] = {
        pause   = {
            event   = pauseEvent,
            handler = function(...)
                          if stateParameter then
                              local params = unpack(...)
                              local value = params[stateParameter.index]
                              if value == stateParameter.pauseValue then
                                  self:OnPausedEvent(name)
                              end
                              return
                          end
                          self:OnPausedEvent(name)
                      end,
        },
        unpause = {
            event   = unpauseEvent,
            handler = function(...)
                          if stateParameter then
                              local params = unpack(...)
                              local value = params[stateParameter.index]
                              if value == stateParameter.unpauseValue then
                                  self:OnUnpausedEvent(name)
                              end
                              return
                          end
                          self:OnUnpausedEvent(name)
                      end
        },
    }
end
function class.UnboxAll:RegisterPauseCallbacks(name, pauseCallbacks, unpauseCallbacks, activeFunc)
    self.states[name] = {
        callbacks = {
            pause = pauseCallbacks,
            unpauseCallbacks = unpauseCallbacks,
        },
        active = activeFunc,
    }
    self.callbackHandlers[name] = {
        pause   = {},
        unpause = {},
    }
    for _, callback in ipairs(pauseCallbacks) do
        table.insert(self.callbackHandlers[name].pause,
            {
                target = callback.target,
                name = callback.name,
                callback = function(...)
                    if callback.stateParameter then
                        local params = unpack(...)
                        local value = params[callback.stateParameter.index]
                        if value == callback.stateParameter.pauseValue then
                            self:OnPausedCallback(name)
                        end
                        return
                    end
                    self:OnPausedCallback(name)
                end,
            }
        )
    end
    for _, callback in ipairs(unpauseCallbacks) do
        table.insert(self.callbackHandlers[name].unpause,
            {
                target = callback.target,
                name = callback.name,
                callback = function(...)
                    if callback.stateParameter then
                        local params = unpack(...)
                        local value = params[callback.stateParameter.index]
                        if value == callback.stateParameter.pauseValue then
                            self:OnUnpausedCallback(name)
                        end
                        return
                    end
                    self:OnUnpausedCallback(name)
                end,
            }
        )
    end
end
function class.UnboxAll:SetAutoQueue(value)
    self.autoQueue = value
end
function class.UnboxAll:Start(item)
    if item then
        table.insert(self.queue, item)
    end
    self:FireCallbacks("Start", item)
    
    if #self.queue == 0 then
        self:Reset()
        self:FireCallbacks("Stopped")
        -- Print summary
        LLS:SetPrefix(addon.prefix)
        LLS:Print()
        return
    end
    
    self:RefreshState()
    
    if self.state ~= "stopped" and self.state ~= "delayed_start" then
        return
    end
    
    local itemToUnbox = table.remove(self.queue, 1)
    
    self:ListenForPause()
    self:FireCallbacks("BeforeOpen", itemToUnbox)
    
    local opener = class.BoxOpener:New(itemToUnbox.slotIndex)
    local failedCallback = self:CreateFailedCallback()
    opener:RegisterCallback("Failed", failedCallback)
    opener:RegisterCallback("Opened", self:CreateOpenedCallback())
    if opener:Open() then
        return
    end
    
    local reason
    if opener.rule then
        reason = "Container type " .. opener.rule.name .. " was not configured for unboxing in settings."
    else
        reason = "Unknown container type"
    end
    failedCallback(item.slotIndex, item.itemLink, reason)
end
    
--[[ TODO: figure out a way to deal with loot scene changes.  Pause and resume, but without delay?
if LOOT_SCENE.state ~= SCENE_HIDDEN or LOOT_SCENE_GAMEPAD.state ~= SCENE_HIDDEN then
    self.Debug("Loot scene is showing.", debug)
    if self.unboxingAll then
        AbortAction()
        PlaySound(SOUNDS.NEGATIVE_CLICK)
    else
        self.Debug("Waiting for it to close to open slotIndex "..tostring(slotIndex))
        table.insert(self.itemSlotStack, slotIndex)
    end
    return
end ]]--

defaultStates = {
  inCombat = {
      events = { pause = EVENT_PLAYER_COMBAT_STATE, unpause = EVENT_PLAYER_COMBAT_STATE, },
      stateParameter = {
          index = 2,
          pauseValue = true,
          unpauseValue = false,
      },
      active = function() return IsUnitInCombat("player") end,
  },
  swimming = {
      events = {
          { pause = EVENT_PLAYER_SWIMMING, unpause = EVENT_PLAYER_NOT_SWIMMING, }
      },
      active = function() return IsUnitSwimming("player") end,
  },
  dead = {
      events = {
          { pause = EVENT_PLAYER_DEAD, unpause = EVENT_PLAYER_ALIVE, },
      },
      active = function() return IsUnitDeadOrReincarnating("player") end,
  },
  interacting = {
      callbacks = {
          pause = {
              { target = INTERACT_WINDOW, name = "Shown" },
          },
          unpause = {
              { target = INTERACT_WINDOW, name = "Hidden" },
              { target = HUD_SCENE, name = "Shown", stateParameter = { index = 2, value = SCENE_SHOWN } },
          }
      }
      active = function() return INTERACT_WINDOW:IsInteracting() end,
  }
}