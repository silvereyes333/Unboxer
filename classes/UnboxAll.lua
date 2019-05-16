--[[ 
     Handles base logic and events for unboxing all containers in inventory as configured.
]]--

local addon = Unboxer
local class = addon.classes
local debug = false
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
end
local function HousingEditorModeChanged(eventCode, oldMode, newMode)
    addon.Debug("HousingEditorModeChanged("..tostring(eventCode)..", "..tostring(oldMode)..", "..tostring(newMode)..")", debug)
    addon.Debug("active? "..tostring(GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_DISABLED), debug)
end]]
function class.UnboxAll:Initialize(name)
    self.name = name or addon.name .. "_UnboxAll"
    self.states = {}
    self.eventHandlers = {}
    self.callbackHandlers = {}
    for name, config in pairs(defaultStates) do
        if config.events then
            self:RegisterPauseEvents(name, config.events.pause, config.events.unpause, config.active, config.interactionTypes, config.combatEventFilters)
        end
        if config.callbacks then
            self:RegisterPauseCallbacks(name, config.callbacks.pause, config.callbacks.unpause, config.active)
        end
    end
    --[[EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CONFIRM_INTERACT, ConfirmInteract)
    EVENT_MANAGER:RegisterForEvent(self.name.."CHB", EVENT_CHATTER_BEGIN, ChatterBegin)
    EVENT_MANAGER:RegisterForEvent(self.name.."CHE", EVENT_CHATTER_END, ChatterEnd)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLIENT_INTERACT_RESULT, ClientInteractResult)]]
    --EVENT_MANAGER:RegisterForEvent(self.name .. "HEM", EVENT_HOUSING_EDITOR_MODE_CHANGED, HousingEditorModeChanged)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, self:CreateSlotUpdateCallback())
    EVENT_MANAGER:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK)
    EVENT_MANAGER:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
    EVENT_MANAGER:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_IS_NEW_ITEM, true)
    self:Reset()
    -- TODO: Remove this before going live
    -- if debug then self:ListenForPause() end
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
        --addon.Debug("Interaction type check failed. Current interaction type: "..tostring(GetInteractionType()), debug)
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
function class.UnboxAll:CreateMountFailureHandler()
    -- If a mount failure occurs while unboxing, delay for the configured time
    return function() self:DelayStart(math.max(self:GetDelayMilliseconds(), 2000)) end
end
function class.UnboxAll:CreateOpenedCallback()
    return function(itemLink, lootReceived, rule)
        self:FireCallbacks("Opened", itemLink, lootReceived, rule)
        local milliseconds = 40
        if #self.queue > 0 then
            local slotIndex = self.queue[1].slotIndex
            local remaining, duration = GetItemCooldownInfo(BAG_BACKPACK, slotIndex)
            if remaining > 0 and duration > 0 then
                milliseconds = milliseconds + remaining
            end
        end
        self:DelayStart(milliseconds)
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
            if self.state == "stopped" and #self.queue < 2 then
                local remaining, duration = GetItemCooldownInfo(BAG_BACKPACK, self.slotIndex)
                if remaining > 0 and duration > 0 then
                    self:DelayStart(40 + remaining)
                else
                    self:DelayStart(40)
                end
            end
        end
    end
end
function class.UnboxAll:DelayStart(milliseconds)
    self.state = "delayed_start"
    if not milliseconds then
        milliseconds = self:GetDelayMilliseconds()
    end
    addon.Debug("Delay starting unbox for "..tostring(milliseconds).." ms", debug)
    self:FireCallbacks("DelayStart")
    EVENT_MANAGER:RegisterForUpdate(self.name .. "_Start", milliseconds, function() self:Start() end)
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
    if self.listeningForPause then
        return
    end
    self.listeningForPause = true
    for name, handlers in pairs(self.eventHandlers) do
        local pause = handlers.pause
        if pause then
            local events = type(pause.events) == "table" and pause.events or { pause.events }
            for _, event in ipairs(events) do
                local scope = self.name .. "_" .. name .. "_pause"
                EVENT_MANAGER:RegisterForEvent(scope, event, pause.handler)
                addon.Debug("Listening for event " .. tostring(event) .. " " .. scope, debug)
                if pause.combatEventFilters then
                    if event == EVENT_COMBAT_EVENT then
                        for filterType, filterParameter in pairs(pause.combatEventFilters) do
                            addon.Debug("Adding combat event filter " .. tostring(filterType) .. " " .. tostring(filterParameter) 
                                        .. " for event " .. scope, debug)
                            EVENT_MANAGER:AddFilterForEvent(scope,  event, filterType, filterParameter)
                        end
                    else
                        addon.Debug("Event " .. scope .. " does not match "
                                     ..tostring(EVENT_COMBAT_EVENT).. ". it is "..tostring(event), debug)
                    end
                end
            end
        end
    end
    for name, callbackHandler in pairs(self.callbackHandlers) do
        if callbackHandler.pause then
            for _, pause in ipairs(callbackHandler.pause) do
                local scope = pause.name .. "_pause"
                pause.target:RegisterCallback(scope,  pause.callback)
            end
        end
    end
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_MOUNT_FAILURE, self:CreateMountFailureHandler())
end
function class.UnboxAll:IsActive()
    return #self.queue > 0 or self.state ~= "stopped"
end
function class.UnboxAll:OnPausedEvent(name, combatEventFilters)
    local unpause, events
    local handlers = self.eventHandlers[self.state]
    if self.state == name then
        return
    elseif handlers then
        unpause = handlers.unpause
        events = type(unpause.events) == "table" and unpause.events or { unpause.events }
        addon.Debug("Unregistering unpause event(s) for " .. self.state, debug)
        for _, event in ipairs(events) do
            local scope = self.name .. "_" .. self.state .. "_unpause"
            EVENT_MANAGER:UnregisterForEvent(scope, event)
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
            local scope = self.name .. "_" .. name .. "_unpause"
            EVENT_MANAGER:RegisterForEvent(scope,  event, unpause.handler)
            if event == COMBAT_EVENT_COMBAT and unpause.combatEventFilters then
                for filterType, filterParameter in pairs(unpause.combatEventFilters) do
                    EVENT_MANAGER:AddFilterForEvent(scope,  event, filterType, filterParameter)
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
        local scope = self.name .. "_" .. name .. "_unpause"
        local events = type(unpause.events) == "table" and unpause.events or { unpause.events }
        for _, event in ipairs(events) do
            EVENT_MANAGER:UnregisterForEvent(scope, event)
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
    if not self.callbackHandlers[name] or self.state == name then
        return
    end
    local handlers = self.callbackHandlers[name].unpause
    if handlers then
        for _, unpause in ipairs(handlers) do
            local scope = unpause.name .. "_unpause"
            unpause.target:RegisterCallback(scope,  unpause.callback)
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
            local scope = unpause.name .. "_unpause"
            unpause.target:UnregisterCallback(unpause,  unpause.callback)
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
                local scope = self.name .. "_" .. name .. "_unpause"
                EVENT_MANAGER:UnregisterForEvent(scope, event)
            end
        end
    end
    for _, handlers in pairs(self.callbackHandlers) do
        if handlers.unpause then
            for _, unpause in ipairs(handlers.unpause) do
                local scope = unpause.name .. "_unpause"
                unpause.target:UnregisterCallback(scope, unpause.callback)
            end
        end
    end
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_MOUNT_FAILURE)
end
function class.UnboxAll:RegisterPauseEvents(name, pauseEvents, unpauseEvents, activeFunc, interactionTypes, combatEventFilters)
    if not activeFunc and interactionTypes then
        activeFunc = self:CreateInteractionTypesCheck(interactionTypes)
    end
    self.states[name] = {
        events = { pause = pauseEvents, unpause = unpauseEvents },
        active = activeFunc,
        combatEventFilters = combatEventFilters,
    }
    local handlers = { }
    if pauseEvents then
        handlers.pause   = {
            events  = pauseEvents,
            handler = function(...)
                          if not activeFunc() then return end
                          self:OnPausedEvent(name)
                      end,
            combatEventFilters = combatEventFilters and combatEventFilters.pause or nil,
        }
    end
    if unpauseEvents then
        handlers.unpause = {
            events  = unpauseEvents,
            handler = function(...)
                          if activeFunc() then return end
                          self:OnUnpausedEvent(name, combatEventFilters and combatEventFilters.unpause)
                      end,
            combatEventFilters = combatEventFilters and combatEventFilters.unpause or nil,
        }
    end
    self.eventHandlers[name] = handlers
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
                    target    = callback.target,
                    name      = callback.name,
                    callback  = function(...)
                                    if not activeFunc() then return end
                                    self:OnUnpausedCallback(name)
                                end
                }
            )
        end
    end
    if unpauseCallbacks then
        for _, callback in ipairs(unpauseCallbacks) do
            table.insert(self.callbackHandlers[name].unpause,
                {
                    target    = callback.target,
                    name      = callback.name,
                    callback  = function(...)
                                    if activeFunc() then return end
                                    self:OnUnpausedCallback(name)
                                end
                }
            )
        end
    end
end
function class.UnboxAll:SetAutoQueue(value)
    self.autoQueue = value
end
function class.UnboxAll:Start()
    EVENT_MANAGER:UnregisterForUpdate(self.name .. "_Start")
    addon.Debug("Start", debug)
    
    self:FireCallbacks("Start")
    
    if #self.queue == 0 then
        self:Reset()
        addon.Debug("Stopped. Queue is empty.", debug)
        self:FireCallbacks("Stopped")
        return
    end
    
    self:RefreshState()
    
    if self.state ~= "stopped" and self.state ~= "delayed_start" then
        return
    end
    
    local item = table.remove(self.queue, 1)
    
    self:ListenForPause()
    
    addon.Debug("BeforeOpen " .. tostring(item.itemLink) .. " (" .. tostring(item.slotIndex) .. ")", debug)
    self:FireCallbacks("BeforeOpen", item)
    
    local opener = class.BoxOpener:New(item.slotIndex)
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
function class.UnboxAll:StopListeningForPause()
    if not self.listeningForPause then
        return
    end
    self.listeningForPause = nil
    for name, handlers in pairs(self.eventHandlers) do
        local pause = handlers.pause
        if pause then
            local events = type(pause.events) == "table" and pause.events or { pause.events }
            for _, event in ipairs(events) do
                local scope = self.name .. "_" .. name .. "_pause"
                EVENT_MANAGER:UnregisterForEvent(scope, event)
                addon.Debug("Stop listening for event " .. tostring(event) .. " " .. scope, debug)
            end
        end
    end
    for name, callbackHandler in pairs(self.callbackHandlers) do
        if callbackHandler.pause then
            for _, pause in ipairs(callbackHandler.pause) do
                local scope = pause.name .. "_pause"
                pause.target:UnregisterCallback(scope,  pause.callback)
            end
        end
    end
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_MOUNT_FAILURE, self:CreateMountFailureHandler())
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
  housing = {
      events = { pause = EVENT_HOUSING_EDITOR_MODE_CHANGED, unpause = EVENT_HOUSING_EDITOR_MODE_CHANGED },
      active = function() return GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_DISABLED end,
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
  
  --[[ Still to add/test
  
       * pause and cancel keybinds
       * Fence
       * Repair
       * Harvest
       * Animations before chatter (e.g. respec shrine)
       * Siege repair
       * Structure repair
       * Quick slot
  ]]--
  
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
       * Attribute respec scroll
       * Skill respec scroll
       * Cutscene / kill cam / blade of woe
       * 
  ]]--
  --[[interacting = {
      callbacks = {
          pause = {
              { target = INTERACT_WINDOW, name = "Shown" },
          },
          unpause = {
              { target = INTERACT_WINDOW, name = "Hidden" },
              { target = HUD_SCENE, name = "Shown" },
          }
      },
      active = function() return INTERACT_WINDOW:IsInteracting() end,
  }]]--
}