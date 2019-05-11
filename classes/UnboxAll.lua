--[[ 
     Handles base logic and events for unboxing all containers in inventory as configured.
]]--

local addon = Unboxer
local class = addon.classes
local debug = true
local defaultStates = {}
local LLS = LibStub("LibLootSummary")

class.UnboxAll = ZO_CallbackObject:Subclass()

function class.UnboxAll:New(...)
    local instance = ZO_CallbackObject.New(self)
    instance:Initialize(...)
    return instance
end
--[[local function ClientInteractResult(eventCode, result, interactTargetName)
    addon.Debug("ClientInteractResult("..tostring(eventCode)..", "..tostring(result)..", '"..tostring(interactTargetName).."')", debug)
end
local function ConfirmInteract(eventCode, dialogTitle, dialogBody, acceptText, cancelText)
    addon.Debug("ConfirmInteract("..tostring(eventCode)..", '"..tostring(dialogTitle).."', '"..tostring(dialogBody).."', '"..tostring(acceptText).."', '"..tostring(cancelText).."')", debug)
end
local function ChatterBegin(eventCode, optionCount)
    addon.Debug("ChatterBegin("..tostring(eventCode)..", "..tostring(optionCount)..")", debug)
end
local function ChatterEnd(eventCode)
    addon.Debug("ChatterEnd("..tostring(eventCode)..")", debug)
end]]
function class.UnboxAll:Initialize(name)
    self.name = name or addon.name .. "_UnboxAll"
    self.states = {}
    self.eventHandlers = {}
    self.callbackHandlers = {}
    for name, config in pairs(defaultStates) do
        if config.events then
            self:RegisterPauseEvents(name, config.events.pause, config.events.unpause, config.stateParameter, config.active, config.interactionTypes, config.combatEventFilters)
        end
        if config.callbacks then
            self:RegisterPauseCallbacks(name, config.callbacks.pause, config.callbacks.unpause, config.active)
        end
    end
    --[[EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CONFIRM_INTERACT, ConfirmInteract)
    EVENT_MANAGER:RegisterForEvent(self.name.."CHB", EVENT_CHATTER_BEGIN, ChatterBegin)
    EVENT_MANAGER:RegisterForEvent(self.name.."CHE", EVENT_CHATTER_END, ChatterEnd)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLIENT_INTERACT_RESULT, ClientInteractResult)]]
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, self:CreateSlotUpdateCallback())
    EVENT_MANAGER:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK)
    EVENT_MANAGER:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
    EVENT_MANAGER:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_IS_NEW_ITEM, true)
    self:Reset()
    self:ListenForPause()
end
function class.UnboxAll:CreateFailedCallback()
    return function(slotIndex, itemLink, reason)
        addon.Debug("Failed "..tostring(itemLink).." ("..tostring(slotIndex)..") "..tostring(reason), debug)
        self:FireCallbacks("Failed", slotIndex, itemLink, reason)
        EVENT_MANAGER:RegisterForUpdate(self.name .. "_Start", 40, function() self:Start() end)
    end
end
function class.UnboxAll:CreateInteractionTypesCheck(interactionTypes)
    return function()
        local interactionType = GetInteractionType()
        if ZO_IsElementInNumericallyIndexedTable(interactionTypes, interactionType) then
            return true
        end
        addon.Debug("Interaction type check failed. Current interaction type: "..tostring(GetInteractionType()), debug)
    end
end
function class.UnboxAll:CreateInteractSceneHiddenCallback(scene, name)
    return function(oldState, newState)
        if newState ~= SCENE_HIDDEN then
            return
        end
        self:OnUnpausedEvent(name)
    end
end
function class.UnboxAll:CreateOpenedCallback()
    return function(itemLink, lootReceived, rule)
        addon.PrintUnboxedLink(itemLink)
        if rule and rule:IsSummaryEnabled() then
            if #lootReceived == 0 then
                addon.Debug("'Opened' callback parameter 'lootReceived' contains no items.", debug)
            end
            for _, loot in ipairs(lootReceived) do
                if loot.lootedBySelf and loot.lootType == LOOT_TYPE_ITEM then
                    LLS:AddItemLink(loot.itemLink, loot.quantity)
                end
            end
        elseif not rule then
            addon.Debug("No match rule passed to 'Opened' callback", debug)
        else
            addon.Debug("Rule "..rule.name.." is not configured to output summaries.", debug)
        end
        addon.Debug("Opened " .. tostring(itemLink) .. " containing " .. tostring(#lootReceived) .. " items. Matched rule "
                    .. (rule and rule.name or ""), debug)
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
    addon.Debug("Delay starting unbox for "..tostring(self:GetDelayMilliseconds()).." ms", debug)
    self:FireCallbacks("DelayStart", item)
    EVENT_MANAGER:RegisterForUpdate(self.name .. "_Start", self:GetDelayMilliseconds(), function() self:Start() end)
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
                if GetLootItemType(lootId) == LOOT_TYPE_ITEM and CanItemLinkBeVirtual(GetLootItemLink(lootId)) then
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
    
    for state, config in pairs(self.states) do
        if config.active() then
            return false
        end
    end
    
    if #self.queue > 0 then return true end
    
    local bagId = BAG_BACKPACK
    local bagSlots = GetBagSize(bagId) -1
    for slotIndex = 0, bagSlots do
        if addon:IsItemUnboxable(bagId, slotIndex) 
           and CanInteractWithItem(bagId, slotIndex) 
           and select(4,GetItemInfo(bagId, slotIndex)) -- meets usage requirement
        then
            return true
        end
    end

    return false
end
function class.UnboxAll:ListenForPause()
    for name, handlers in pairs(self.eventHandlers) do
        local pause = handlers.pause
        if pause then
            local events = type(pause.events) == "table" and pause.events or { pause.events }
            for _, event in ipairs(events) do
                EVENT_MANAGER:RegisterForEvent(self.name .. "_" .. name, event, pause.handler)
                if pause.combatEventFilters then
                    if event == EVENT_COMBAT_EVENT then
                        for filterType, filterParameter in pairs(pause.combatEventFilters) do
                            addon.Debug("Adding combat event filter " .. tostring(filterType) .. " " .. tostring(filterParameter) 
                                        .. " for event " .. self.name .. "_" .. name, debug)
                            EVENT_MANAGER:AddFilterForEvent(self.name .. "_" .. name,  event, filterType, filterParameter)
                        end
                    else
                        addon.Debug("Event " .. self.name .. "_" .. name .. " does not match "
                                     ..tostring(EVENT_COMBAT_EVENT).. ". it is "..tostring(event), debug)
                    end
                end
            end
        end
    end
    for name, callbackHandler in pairs(self.callbackHandlers) do
        if callbackHandler.pause then
            for _, pause in ipairs(callbackHandler.pause) do
                pause.target:RegisterCallback(pause.name,  pause.callback)
            end
        end
    end
end
function class.UnboxAll:OnPausedEvent(name, combatEventFilters)
    local unpause, events
    local handlers = self.eventHandlers[self.state]
    if self.state ~= name and handlers then
        unpause = handlers.unpause
        events = type(unpause.events) == "table" and unpause.events or { unpause.events }
        addon.Debug("Unregistering unpause event(s) for " .. self.state, debug)
        for _, event in ipairs(events) do
            EVENT_MANAGER:UnregisterForEvent(self.name .. "_" .. self.state, event)
        end
    end
    handlers = self.eventHandlers[name]
    if not handlers then
        return
    end
    unpause = handlers.unpause
    if unpause then
        events = type(unpause.events) == "table" and unpause.events or { unpause.events }
        for _, event in ipairs(events) do
            EVENT_MANAGER:RegisterForEvent(self.name .. "_" .. name,  event, unpause.handler)
            if event == COMBAT_EVENT_COMBAT and unpause.combatEventFilters then
                for filterType, filterParameter in pairs(unpause.combatEventFilters) do
                    EVENT_MANAGER:AddFilterForEvent(self.name .. "_" .. name,  event, filterType, filterParameter)
                end
            end
        end
    
    -- Fix for retrait station having no close event
    elseif SCENE_MANAGER.currentScene and getmetatable(SCENE_MANAGER.currentScene) == ZO_InteractScene then
        self.sceneStateChange = {
            scene = SCENE_MANAGER.currentScene,
            callback = self:CreateInteractSceneHiddenCallback(SCENE_MANAGER.currentScene, name)
        }
        self.sceneStateChange.scene:RegisterCallback("StateChange", self.sceneStateChange.callback)
    end
    self.state = name
    addon.Debug("Paused ("..tostring(name)..")", debug)
    self:FireCallbacks("Paused", name)
    EVENT_MANAGER:UnregisterForUpdate(self.name .. "_Start")
end
function class.UnboxAll:OnUnpausedEvent(name)
    if not self.eventHandlers[name] then
        return
    end
    local unpause = self.eventHandlers[name].unpause
    if unpause then
        local events = type(unpause.events) == "table" and unpause.events or { unpause.events }
        for _, event in ipairs(events) do
            EVENT_MANAGER:UnregisterForEvent(self.name .. "_" .. name, event)
        end
    end
    -- Fix for retrait station having no close event
    if self.sceneStateChange then
        self.sceneStateChange.scene:UnregisterCallback("StateChange", self.sceneStateChange.callback)
        self.sceneStateChange = nil
    end
    if self.state ~= name then
        addon.Debug("Not unpausing ("..tostring(name)..") because current state is " .. self.state, debug)
        return
    end
    self.state = "stopped"
    addon.Debug("Unpaused ("..tostring(name)..")", debug)
    self:FireCallbacks("Unpaused", name)
    if #self.queue then
        self:DelayStart()
    end
end
function class.UnboxAll:OnPausedCallback(name)
    if not self.callbackHandlers[name] then
        return
    end
    local handlers = self.callbackHandlers[name].unpause
    if handlers then
        for _, unpause in ipairs(handlers) do
            unpause.target:RegisterCallback(unpause.name,  unpause.callback)
        end
    end
    self.state = name
    addon.Debug("Paused ("..tostring(name)..")", debug)
    self:FireCallbacks("Paused", name)
    EVENT_MANAGER:UnregisterForUpdate(self.name .. "_Start")
end
function class.UnboxAll:OnUnpausedCallback(name)
    if not self.callbackHandlers[name] then
        return
    end
    local handlers = self.callbackHandlers[name].unpause
    if handlers then
        for _, unpause in ipairs(handlers) do
            unpause.target:UnregisterCallback(unpause.name,  unpause.callback)
        end
    end
    if self.state ~= name then
        addon.Debug("Not unpausing ("..tostring(name)..") because current state is " .. self.state, debug)
        return
    end
    self.state = "stopped"
    addon.Debug("Unpaused ("..tostring(name)..")", debug)
    self:FireCallbacks("Unpaused", name)
    if #self.queue then
        self:DelayStart()
    end
end
function class.UnboxAll:Queue(item)
    table.insert(self.queue, item)
    addon.Debug("Queued item "..tostring(item.itemLink).." ("..tostring(item.slotIndex)..")", debug)
end
function class.UnboxAll:QueueAllInBackpack()
    local bagId = BAG_BACKPACK
    local bagSlots = GetBagSize(bagId) - 1
    for slotIndex = 0, bagSlots do
        if addon:IsItemUnboxable(bagId, slotIndex) 
           and CanInteractWithItem(bagId, slotIndex) 
           and select(4,GetItemInfo(bagId, slotIndex)) -- meets usage requirement
        then
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
    EVENT_MANAGER:UnregisterForUpdate(self.name .. "_Start")
    for name, handlers in pairs(self.eventHandlers) do
        local unpause = handlers.unpause
        if unpause then
            local events = type(unpause.events) == "table" and unpause.events or { unpause.events }
            for _, event in ipairs(events) do
                EVENT_MANAGER:UnregisterForEvent(self.name .. "_" .. name,  event)
            end
        end
    end
    for _, handlers in pairs(self.callbackHandlers) do
        if handlers.unpause then
            for _, unpause in ipairs(handlers.unpause) do
                unpause.target:UnregisterCallback(unpause.name, unpause.callback)
            end
        end
    end
end
function class.UnboxAll:RegisterPauseEvents(name, pauseEvents, unpauseEvents, stateParameter, activeFunc, interactionTypes, combatEventFilters)
    if not activeFunc and interactionTypes then
        activeFunc = self:CreateInteractionTypesCheck(interactionTypes)
    end
    self.states[name] = {
        events = { pause = pauseEvents, unpause = unpauseEvents },
        stateParameter = stateParameter,
        active = activeFunc,
        combatEventFilters = combatEventFilters,
    }
    local handlers = { }
    if pauseEvents then
        handlers.pause   = {
            events  = pauseEvents,
            handler = function(...)
                          if not activeFunc() then
                              return
                          end
                          if stateParameter then
                              local params = {...}
                              local value = params[stateParameter.index]
                              if value == stateParameter.pauseValue then
                                  self:OnPausedEvent(name)
                              end
                              return
                          end
                          self:OnPausedEvent(name)
                      end,
            combatEventFilters = combatEventFilters and combatEventFilters.pause or nil,
        }
    end
    if unpauseEvents then
        handlers.unpause = {
            events  = unpauseEvents,
            handler = function(...)
                          if stateParameter then
                              local params = {...}
                              local value = params[stateParameter.index]
                              if value == stateParameter.unpauseValue then
                                  self:OnUnpausedEvent(name, combatEventFilters and combatEventFilters.unpause)
                              end
                              return
                          end
                          self:OnUnpausedEvent(name, combatEventFilters and combatEventFilters.unpause)
                      end,
            combatEventFilters = combatEventFilters and combatEventFilters.unpause or nil,
        }
    end
    self.eventHandlers[name] = handlers
end
function class.UnboxAll:GeneratePauseCallback(callback, name)
    return function(...)
        local activeFunc = self.states[name].active
        if not activeFunc() then
            return
        end
        if callback.stateParameter then
            local params = {...}
            local value = params[callback.stateParameter.index]
            if value == callback.stateParameter.pauseValue then
                self:OnPausedCallback(name)
            end
            return
        end
        self:OnPausedCallback(name)
    end
end
function class.UnboxAll:GenerateUnpauseCallback(callback, name)
    return function(...)
        if callback.stateParameter then
            local params = {...}
            local value = params[callback.stateParameter.index]
            if value == callback.stateParameter.pauseValue then
                self:OnUnpausedCallback(name)
            end
            return
        end
        self:OnUnpausedCallback(name)
    end
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
    if pauseCallbacks then
        for _, callback in ipairs(pauseCallbacks) do
            table.insert(self.callbackHandlers[name].pause,
                {
                    target = callback.target,
                    name = callback.name,
                    callback = self:GeneratePauseCallback(callback, name),
                }
            )
        end
    end
    if unpauseCallbacks then
        for _, callback in ipairs(unpauseCallbacks) do
            table.insert(self.callbackHandlers[name].unpause,
                {
                    target = callback.target,
                    name = callback.name,
                    callback = self:GenerateUnpauseCallback(callback, name),
                }
            )
        end
    end
end
function class.UnboxAll:SetAutoQueue(value)
    self.autoQueue = value
end
function class.UnboxAll:Start(item)
    EVENT_MANAGER:UnregisterForUpdate(self.name .. "_Start")
    if item then
        table.insert(self.queue, item)
    end
    if item then
        addon.Debug("Start " .. tostring(item.itemLink) .. " (" .. tostring(item.slotIndex) .. ")", debug)
    else
        addon.Debug("Start", debug)
    end
    self:FireCallbacks("Start", item)
    
    if #self.queue == 0 then
        self:Reset()
        addon.Debug("Stopped. Queue is empty.", debug)
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
    addon.Debug("BeforeOpen " .. tostring(itemToUnbox.itemLink) .. " (" .. tostring(itemToUnbox.slotIndex) .. ")", debug)
    self:FireCallbacks("BeforeOpen", itemToUnbox)
    
    local opener = class.BoxOpener:New(itemToUnbox.slotIndex)
    local failedCallback = self:CreateFailedCallback()
    opener:RegisterCallback("Failed", failedCallback)
    opener:RegisterCallback("Opened", self:CreateOpenedCallback())
    self:RegisterCallback("Paused", function() opener:Reset() end)
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
      events = { pause = EVENT_PLAYER_COMBAT_STATE, unpause = EVENT_PLAYER_COMBAT_STATE },
      stateParameter = {
          index = 2,
          pauseValue = true,
          unpauseValue = false,
      },
      active = function() return IsUnitInCombat("player") end,
  },
  swimming = {
      events = { pause = EVENT_PLAYER_SWIMMING, unpause = EVENT_PLAYER_NOT_SWIMMING },
      active = function() return IsUnitSwimming("player") end,
  },
  dead = {
      events = { pause = EVENT_PLAYER_DEAD, unpause = EVENT_PLAYER_ALIVE },
      active = function() return IsUnitDeadOrReincarnating("player") end,
  },
  mail = {
      events = { pause = EVENT_MAIL_OPEN_MAILBOX, unpause = EVENT_MAIL_CLOSE_MAILBOX },
      interactionTypes = { INTERACTION_MAIL },
  },
  crafting = {
      events = { pause = EVENT_CRAFTING_STATION_INTERACT, unpause = EVENT_END_CRAFTING_STATION_INTERACT },
      interactionTypes = { INTERACTION_CRAFT },
  },
  retrait = {
      events = { pause = EVENT_RETRAIT_STATION_INTERACT_START  },
      interactionTypes = { INTERACTION_RETRAIT },
  },
  dyeing = {
      events = { pause = EVENT_DYEING_STATION_INTERACT_START, unpause = EVENT_DYEING_STATION_INTERACT_END },
      interactionTypes = { INTERACTION_DYE_STATION },
  },
  reading = {
      events = { pause = EVENT_SHOW_BOOK, unpause = EVENT_HIDE_BOOK },
      interactionTypes = { INTERACTION_BOOK },
  },
  bank = {
      events = { pause = EVENT_OPEN_BANK, unpause = EVENT_CLOSE_BANK },
      interactionTypes = { INTERACTION_BANK },
  },
  guildBank = {
      events = { pause = EVENT_OPEN_GUILD_BANK, unpause = EVENT_CLOSE_GUILD_BANK },
      interactionTypes = { INTERACTION_GUILDBANK },
  },
  tradingHouse = {
      events = { pause = EVENT_OPEN_TRADING_HOUSE, unpause = EVENT_CLOSE_TRADING_HOUSE },
      interactionTypes = { INTERACTION_TRADINGHOUSE },
  },
  conversation = {
      events = { pause = EVENT_CHATTER_BEGIN, unpause = EVENT_CHATTER_END },
      interactionTypes = { INTERACTION_CONVERSATION, INTERACTION_GUILDKIOSK_BID, INTERACTION_BUY_BAG_SPACE, INTERACTION_HIDEYHOLE },
  },
  vendor = {
      events = { pause = EVENT_OPEN_STORE, unpause = EVENT_CLOSE_STORE },
      interactionTypes = { INTERACTION_VENDOR },
  },
  wayshrine = {
      events = { pause = EVENT_START_FAST_TRAVEL_INTERACTION, unpause = EVENT_END_FAST_TRAVEL_INTERACTION },
      interactionTypes = { INTERACTION_FAST_TRAVEL },
  },
  fastTravelKeep = {
      events = { pause = EVENT_START_FAST_TRAVEL_KEEP_INTERACTION , unpause = EVENT_END_FAST_TRAVEL_KEEP_INTERACTION },
      interactionTypes = { INTERACTION_FAST_TRAVEL_KEEP },
  },
  lockpick = {
      events = { pause =  EVENT_BEGIN_LOCKPICK, unpause = { EVENT_LOCKPICK_FAILED, EVENT_LOCKPICK_SUCCESS } },
      interactionTypes = { INTERACTION_LOCKPICK },
  },
  stable = {
      events = { pause =  EVENT_STABLE_INTERACT_START, unpause = EVENT_STABLE_INTERACT_END },
      interactionTypes = { INTERACTION_STABLE },
  },
  siege = {
      events = { pause =  EVENT_BEGIN_SIEGE_CONTROL, unpause = EVENT_END_SIEGE_CONTROL },
      interactionTypes = { INTERACTION_SIEGE },
  },
  hideyHole = {
      events = { pause =  EVENT_CLIENT_INTERACT_RESULT, unpause = EVENT_CHATTER_END },
      active = function() return GetGameCameraInteractableActionInfo() == GetString(SI_GAMECAMERAACTIONTYPE24) end,
      --[[events = { pause =  EVENT_COMBAT_EVENT, unpause = EVENT_CHATTER_END },
      interactionTypes = { INTERACTION_HIDEYHOLE },
      combatEventFilters = {
          pause = {
              [REGISTER_FILTER_COMBAT_RESULT] = ACTION_RESULT_IN_HIDEYHOLE,
          }
      },]]
  },
  
  --[[ Other scenes/actions that do not interrupt or get interrupted by opening containers:
  
       * Champion Point assignment
       * Quest journal
       * Crown store
       * Map
       * Port to friend/guildie
       * Port to wayshrine from map
       * Guild management
       * Group finder
       * Friends list
  ]]--
  --[[interacting = {
      callbacks = {
          pause = {
              { target = INTERACT_WINDOW, name = "Shown" },
          },
          unpause = {
              { target = INTERACT_WINDOW, name = "Hidden" },
              { target = HUD_SCENE, name = "Shown", stateParameter = { index = 2, value = SCENE_SHOWN } },
          }
      },
      active = function() return INTERACT_WINDOW:IsInteracting() end,
  }]]--
}