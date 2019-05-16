Unboxer = {
    name = "Unboxer",
    title = GetString(SI_UNBOXER),
    author = "silvereyes",
    version = "3.0.0",
    itemSlotStack = {},
    defaultLanguage = "en",
    debugMode = false,
    classes = {
        rules = {},
    },
    rules = {},
    submenuOptions = {},
}

local addon = Unboxer
local LLS = LibStub("LibLootSummary")

-- Output formatted message to chat window, if configured
function addon.Print(input)
    local self = addon
    local output = self.prefix .. input .. self.suffix
    d(output)
end
function addon.Debug(input, force)
    if not force and not addon.debugMode then
        return
    end
    addon.Print(input)
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
local localeUsesDifferentPunctuationColon = GetString(SI_UNBOXER_PUNCTUATION_COLON) ~= ":"
function addon:StringContainsPunctuationColon(searchIn)
    if string.find(searchIn, ":") then
        return true
    end
    if localeUsesDifferentPunctuationColon 
       and string.find(searchIn, GetString(SI_UNBOXER_PUNCTUATION_COLON))
    then
        return true
    end
end
function addon:StringContainsNotAtStart(searchIn, stringId, ...)
    local startIndex, endIndex = self:StringContainsStringIdOrDefault(searchIn, stringId, ...)
    if not startIndex or startIndex == 1 then return end
    return startIndex, endIndex
end

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
function addon.PrintUnboxedLink(itemLink)
    local self = addon
    if not itemLink 
       or not self.settings 
       or not self.settings.chatContainerOpen
    then
        return
    end
    self.Print(zo_strformat(SI_UNBOXER_UNBOXED, itemLink))
end
local function InventoryStateChange(oldState, newState)
    if newState == SCENE_SHOWING then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
    end
end
function addon:GetKeybindName()
    if self.unboxAll:IsActive() then
        return GetString(SI_UNBOXER_CANCEL)
    else
        return GetString(SI_UNBOXER_UNBOX_ALL)
    end
end
local function RefreshUnboxAllKeybind()
    local self = addon
    self.unboxAllKeybindButton.name = self:GetKeybindName()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.unboxAllKeybindButtonGroup)
end
local function OnContainerOpened(itemLink, lootReceived, rule)
    local self = addon
    self.PrintUnboxedLink(itemLink)
    if not rule then
        self.Debug("No match rule passed to 'Opened' callback")
    elseif not addon.settings.chatContentsSummary then
        self.Debug("All chat summaries are disabled.")
    elseif not rule:IsSummaryEnabled() then
        self.Debug("Rule "..rule.name.." is not configured to output summaries.")
    else
        if #lootReceived == 0 then
            self.Debug("'Opened' callback parameter 'lootReceived' contains no items.")
        end
        for _, loot in ipairs(lootReceived) do
            if loot.lootedBySelf and loot.lootType == LOOT_TYPE_ITEM then
                LLS:AddItemLink(loot.itemLink, loot.quantity)
            end
        end
    end
    addon.Debug("Opened " .. tostring(itemLink) .. " containing " .. tostring(#lootReceived) .. " items. Matched rule "
                .. (rule and rule.name or ""))
    RefreshUnboxAllKeybind()
end
function addon.CancelUnboxAll()
    local self = addon
    self.unboxAll:Reset()
    self.unboxAll:ListenForPause()
    RefreshUnboxAllKeybind()
    -- Print summary
    LLS:SetPrefix(self.prefix)
    LLS:SetSuffix(self.suffix)
    LLS:Print()
    return true
end
function addon.UnboxAll()
    local self = addon
    
    if self.unboxAll:IsActive() then
        return self.CancelUnboxAll()
    end
    
    self.unboxAll:QueueAllInBackpack()
    
    if #self.unboxAll.queue == 0 then
        return false
    end
    
    self.unboxAll:SetAutoQueue(true)
    self.unboxAll:RegisterCallback("Stopped", self.CancelUnboxAll)
    self.unboxAll:RegisterCallback("Opened", OnContainerOpened)
    self.unboxAll:RegisterCallback("BeforeOpen", RefreshUnboxAllKeybind)
    --self.unboxAll:StopListeningForPause()
    self.unboxAll:Start()
    return true
    
end

function addon:AddKeyBind()
    self.unboxAllKeybindButton = {
        keybind = "UNBOX_ALL",
        enabled = true,
        visible = function() return self.unboxAll:HasUnboxableSlots() end,
        order = 100,
        callback = self.UnboxAll,
    }
    self.unboxAllKeybindButtonGroup = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        self.unboxAllKeybindButton
    }
    BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWN then
            self.unboxAllKeybindButton.name = self:GetKeybindName()
            KEYBIND_STRIP:AddKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
        elseif newState == SCENE_HIDING then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
        end
    end )
    INVENTORY_FRAGMENT:RegisterCallback("StateChange", InventoryStateChange)
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
function addon:Namespace(ns)
    local nsTable = self.classes
    for scope in string.gmatch(ns, "%w+") do
        if not nsTable[scope] then
            nsTable[scope] = {}
        end
        nsTable = nsTable[scope]
    end
    return nsTable
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
    
    local rules = self.classes.rules
    self:RegisterCategoryRule(rules.Pts)
    self:RegisterCategoryRule(rules.collectibles.Runeboxes)
    self:RegisterCategoryRule(rules.collectibles.StylePages)
    self:RegisterCategoryRule(rules.crafting.CraftingRewards)
    self:RegisterCategoryRule(rules.crafting.Materials)
    self:RegisterCategoryRule(rules.currency.TelVar)
    self:RegisterCategoryRule(rules.currency.Transmutation)
    self:RegisterCategoryRule(rules.general.Festival)
    self:RegisterCategoryRule(rules.general.Fishing)
    self:RegisterCategoryRule(rules.general.Legerdemain)
    self:RegisterCategoryRule(rules.general.TreasureMaps)
    self:RegisterCategoryRule(rules.rewards.Dungeon)
    self:RegisterCategoryRule(rules.rewards.Solo)
    self:RegisterCategoryRule(rules.rewards.SoloRepeatable)
    self:RegisterCategoryRule(rules.rewards.Trial)
    self:RegisterCategoryRule(rules.vendor.Furnisher)
    self:RegisterCategoryRule(rules.vendor.LoreLibraryReprints)
    self:RegisterCategoryRule(rules.vendor.VendorGear)
    
    self.unboxAll = self.classes.UnboxAll:New()
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
