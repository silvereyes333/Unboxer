--[[ 
     Handles all auto-unpacking logic and events.
]]--

local addon = Unboxer
local class = addon.classes
local debug = false
local defaultStates = {}
local LLS = LibStub("LibLootSummary")

class.Automatic = ZO_CallbackObject:Subclass()

function class.Automatic:New(...)
    local instance = ZO_Object.New(self)
    instance:Initialize(...)
    return instance
end

function class.Automatic:Initialize()
    self.name = addon.name .. "_Automatic"
    self.queue = {}
    self.states = {}
    self.eventHandlers = {}
    self.callbackHandlers = {}
    self.state = "stopped"
    for name, config in pairs(defaultStates) do
        if config.events then
            self:RegisterPauseEvents(name, config.events.pause, config.events.unpause, config.stateParameter, config.active)
        end
        if config.callbacks then
            self:RegisterPauseCallbacks(name, config.callbacks.pause, config.callbacks.unpause, config.active)
        end
    end
end
function class.Automatic:Reset()
    self.state = "stopped"
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
function class.Automatic:DelayStart(item)
    if item then
        table.insert(self.queue, item)
    end
    self.state = "delayed_start"
    self:FireCallbacks("DelayStart", item)
    EVENT_MANAGER:RegisterForUpdate(self.name "_Start", self:GetDelayMilliseconds(), function() self:Start() end)
end
function class.Automatic:GetDelayMilliseconds()
    local delay = math.max(40, addon.settings.autolootDelay * 1000)
    return delay
end
function class.Automatic:RegisterPauseEvents(name, pauseEvent, unpauseEvent, stateParameter, activeFunc)
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
function class.Automatic:RegisterPauseCallbacks(name, pauseCallbacks, unpauseCallbacks, activeFunc)
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
function class.Automatic:OnPausedEvent(name)
    local unpause = self.eventHandlers[name].unpause
    EVENT_MANAGER:RegisterForEvent(self.name .. "_" .. name,  unpause.event, unpause.handler)
    self.state = name
    self:FireCallbacks("Paused", name)
    EVENT_MANAGER:UnregisterForUpdate(self.name "_Start")
end
function class.Automatic:OnUnpausedEvent(name)
    local unpause = self.eventHandlers[name].unpause
    EVENT_MANAGER:UnregisterForEvent(self.name .. "_" .. name,  unpause.event)
    self.state = "stopped"
    self:FireCallbacks("Unpaused", name)
    if #self.queue then
        self:DelayStart()
    end
end
function class.Automatic:OnPausedCallback(name)
    for _, unpause in ipairs(self.callbackHandlers[name].unpause) do
        unpause.target:RegisterCallback(unpause.name,  unpause.callback)
    end
    self.state = name
    self:FireCallbacks("Paused", name)
    EVENT_MANAGER:UnregisterForUpdate(self.name "_Start")
end
function class.Automatic:OnUnpausedEvent(name)
    for _, unpause in ipairs(self.callbackHandlers[name].unpause) do
        unpause.target:UnregisterCallback(unpause.name,  unpause.callback)
    end
    self.state = "stopped"
    self:FireCallbacks("Unpaused", name)
    if #self.queue then
        self:DelayStart()
    end
end
function class.Automatic:RefreshState()
    for name, state in pairs(self.states) do
        if state.active() then
            if state.events then
                self:OnPausedEvent(name)
            end
            return
        end
    end
end
local function PrintUnboxedLink(itemLink)
    if not itemLink then return end
    addon.Print(zo_strformat(SI_UNBOXER_UNBOXED, itemLink))
end

function class.Automatic:CreateFailedCallback()
    return function(slotIndex, itemLink, reason)
        addon.Debug("Failed to unbox " .. tostring(itemLink), debug)
        if reason then
            addon.Debug(tostring(reason), true)
        end
        EVENT_MANAGER:RegisterForUpdate(self.name "_Start", 40, function() self:Start() end)
    end
end
function class.Automatic:CreateOpenedCallback()
    return function(itemLink, lootReceived, rule)
        PrintUnboxedLink(itemLink)
        if not rule or not rule:IsSummaryEnabled() then
            return
        end
        for _, loot in ipairs(lootReceived) do
            if loot.lootedBySelf and loot.lootType == LOOT_TYPE_ITEM then
                LLS:AddItemLink(loot.itemLink, loot.quantity)
            end
        end
        EVENT_MANAGER:RegisterForUpdate(self.name "_Start", 40, function() self:Start() end)
    end
end

function class.Automatic:Start(item)
    if item then
        table.insert(self.queue, item)
    end
    self:FireCallbacks("Start", item)
    
    if #self.queue == 0 then
        self:Reset()
        self:FireCallbacks("Stopped")
        -- Print summary
        LLS:Print()
        return
    end
    
    self:RefreshState()
    
    if self.state ~= "stopped" and self.state ~= "delayed_start" then
        return
    end
    
    for _, events in pairs(self.eventHandlers) do
        EVENT_MANAGER:RegisterForEvent(self.name, events.pause.event, events.pause.handler)
    end
    for _, callbacks in pairs(self.callbackHandlers) do
      
    end
    
    local opener = class.BoxOpener:New(item.slotIndex)
    opener:RegisterCallback("Failed", self:CreateFailedCallback())
    opener:RegisterCallback("Opened", self:CreateOpenedCallback())
    opener:Open()
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