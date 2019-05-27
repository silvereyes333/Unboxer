Unboxer = {
    name = "Unboxer",
    title = GetString(SI_UNBOXER),
    author = "silvereyes",
    version = "3.2.0",
    itemSlotStack = {},
    defaultLanguage = "en",
    debugMode = false,
    classes = {
        rules = {},
    },
    rules = {},
    submenuOptions = {},
    containerItemTypes = {
        [ITEMTYPE_CONTAINER]          = true,
        [ITEMTYPE_CONTAINER_CURRENCY] = true,
    },
    slotTypes = {
        [SLOT_TYPE_ITEM]                       = true,
        [SLOT_TYPE_EQUIPMENT]                  = true,
        [SLOT_TYPE_BANK_ITEM]                  = true,
        [SLOT_TYPE_GUILD_BANK_ITEM]            = true,
        [SLOT_TYPE_MY_TRADE]                   = true,
        [SLOT_TYPE_MAIL_QUEUED_ATTACHMENT]     = true,
        [SLOT_TYPE_TRADING_HOUSE_POST_ITEM]    = true,
        [SLOT_TYPE_REPAIR]                     = true,
        [SLOT_TYPE_CRAFTING_COMPONENT]         = true,
        [SLOT_TYPE_PENDING_CRAFTING_COMPONENT] = true,
        [SLOT_TYPE_DYEABLE_EQUIPMENT]          = true,
        [SLOT_TYPE_GUILD_SPECIFIC_ITEM]        = true,
        [SLOT_TYPE_GAMEPAD_INVENTORY_ITEM]     = true,
        [SLOT_TYPE_CRAFT_BAG_ITEM]             = true,
        [SLOT_TYPE_PENDING_RETRAIT_ITEM]       = true,
    },
}

local addon = Unboxer
local LCM = LibCustomMenu or LibStub("LibCustomMenu")

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

function addon:IsItemLinkUnboxable(itemLink, slotData, autolooting)
  
    if not itemLink then return false end
    
    local itemType = GetItemLinkItemType(itemLink)
    if not self.containerItemTypes[itemType] then 
        return false
    end
    
    local data = self:GetItemLinkData(itemLink, nil, slotData)
    
    -- not sure why there's no item id, but return false to be safe
    if not data.itemId then return false end
    
    -- No rules matched
    if not data.rule then
        return false
    end
    
    local isUnboxable = data.isUnboxable and data.rule:IsEnabled()
    if isUnboxable then
        if autolooting then
            isUnboxable = data.rule:IsAutolootEnabled()
        end
        -- Check inventory for any known unique items that the container contains
        if isUnboxable and self.settings.containerUniqueItemIds[data.itemId] then
            local slotUniqueItemIds = {}
            
            for bagId, itemIds in pairs(self.unboxAll.uniqueItemSlotIndexes) do
                for _, slotUniqueItemId in pairs(itemIds) do
                    slotUniqueItemIds[slotUniqueItemId] = true
                end
            end
            for uniqueItemId, _ in pairs(addon.settings.containerUniqueItemIds[data.itemId]) do
                if slotUniqueItemIds[uniqueItemId] then
                    isUnboxable = false
                    break
                end
            end
        end
    end
    
    return isUnboxable, data.rule
end

function addon:IsItemUnboxable(bagId, slotIndex, autolooting)
    if bagId ~= BAG_BACKPACK then return false end
    
    local itemLink = GetItemLink(bagId, slotIndex)
    local slotData = SHARED_INVENTORY:GenerateSingleSlotData(bagId, slotIndex)

    local unboxable, matchedRule = self:IsItemLinkUnboxable(itemLink, slotData, autolooting)    
    local usable, onlyFromActionSlot = IsItemUsable(bagId, slotIndex)
    self.Debug(tostring(itemLink)..", unboxable: "..tostring(unboxable)..", usable: "..tostring(usable)..", onlyFromActionSlot: "..tostring(onlyFromActionSlot)..", matchedRule: "..(matchedRule and matchedRule.name or ""))
    return unboxable and usable and not onlyFromActionSlot, matchedRule
end
function addon:IsDefaultLanguageSelected()
    return GetCVar("language.2") == self.defaultLanguage
end

function addon:GetItemLinkData(itemLink, language, slotData)
    
    local itemId = GetItemLinkItemId(itemLink)
    local itemType, specializedItemType
    if slotData then
        itemType = slotData.itemType
        specializedItemType = slotData.specializedItemType
        if not slotData.bindType then
            slotData.bindType = GetItemLinkBindType(itemLink)
        end
        if not slotData.flavorText then
            slotData.flavorText = GetItemLinkFlavorText(itemLink)
        end
        if not slotData.collectibleId then
            slotData.collectibleId = GetItemLinkContainerCollectibleId(itemLink)
        end
    else
        slotData = {}
        itemType, specializedItemType = GetItemLinkItemType(itemLink)
    end
    local icon = LocaleAwareToLower(slotData.iconFile or GetItemLinkIcon(itemLink))
    local name = LocaleAwareToLower(slotData.name or GetItemLinkTradingHouseItemSearchName(itemLink))
    local quality = slotData.quality or GetItemLinkQuality(itemLink)
    local flavorText = LocaleAwareToLower(slotData.flavorText or GetItemLinkFlavorText(itemLink))
    local bindType = slotData.bindType or GetItemLinkBindType(itemLink)
    local collectibleId = slotData.collectibleId or GetItemLinkContainerCollectibleId(itemLink)
    if type(collectibleId) == "number" and collectibleId > 0 and not slotData.collectibleCategoryType then
        slotData["collectibleCategoryType"] = GetCollectibleCategoryType(collectibleId)
        slotData["collectibleUnlocked"]     = IsCollectibleUnlocked(collectibleId)
    end
    local data = {
        ["itemId"]                  = itemId,
        ["itemLink"]                = itemLink,
        ["bindType"]                = bindType,
        ["name"]                    = name,
        ["flavorText"]              = flavorText,
        ["quality"]                 = quality,
        ["icon"]                    = icon,
        ["collectibleId"]           = collectibleId,
        ["collectibleCategoryType"] = slotData["collectibleCategoryType"],
        ["collectibleUnlocked"]     = slotData["collectibleUnlocked"]
    }
  
    data["containerType"] = "unknown"
    for _, rule in ipairs(self.rules) do
        if rule:MatchKnownIds(data) then
            data["containerType"] = rule.name
            data["isUnboxable"] = slotData["collectibleUnlocked"] == nil or slotData["collectibleUnlocked"]
            data.rule = rule
            break
        end
    end
    if not data.rule then
        for _, rule in ipairs(self.rules) do
            if rule:Match(data) then
                data["containerType"] = rule.name
                data["isUnboxable"] = slotData["collectibleUnlocked"] == nil or slotData["collectibleUnlocked"]
                data.rule = rule
                break
            end
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
                LibLootSummary:AddItemLink(loot.itemLink, loot.quantity)
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
    RefreshUnboxAllKeybind()
    -- Print summary
    LibLootSummary:SetPrefix(self.prefix)
    LibLootSummary:SetSuffix(self.suffix)
    LibLootSummary:Print()
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

local function AddContextMenu(inventorySlot, slotActions)
    local self = addon
    if not self.slotTypes[ZO_InventorySlot_GetType(inventorySlot)] then
        return
    end
    local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if not bagId or not slotIndex then
        return
    end
    local slotData = SHARED_INVENTORY:GenerateSingleSlotData(bagId, slotIndex)
    if not self.containerItemTypes[slotData.itemType] then
        return
    end
    
    local itemLink = GetItemLink(bagId, slotIndex)
    
    local data = addon:GetItemLinkData(itemLink, nil, slotData)
    if not data.rule or data.rule.hidden then
        return
    end
    
    local toggleRule = function() 
        self.settings[data.rule.name] = not self.settings[data.rule.name]
        RefreshUnboxAllKeybind()
    end
    local subMenu = {
        {
            label = "  " .. data.rule.title,
            callback = toggleRule,
            checked = function() return self.settings[data.rule.name] end,
            itemType = MENU_ADD_OPTION_CHECKBOX,
        }
    }
    
    AddCustomSubMenuItem(self.title, subMenu)
end

local function OnAddonLoaded(event, name)
  
    if name ~= addon.name then return end
    local self = addon
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)

    self:AddKeyBind()
    self:SetupSettings()
    
    local rules = self.classes.rules
    self:RegisterCategoryRule(rules.hidden.Excluded)
    self:RegisterCategoryRule(rules.hidden.Excluded2)
    self:RegisterCategoryRule(rules.hidden.Pts)
    self:RegisterCategoryRule(rules.collectibles.Runeboxes)
    self:RegisterCategoryRule(rules.collectibles.StylePages)
    self:RegisterCategoryRule(rules.crafting.CraftingRewards)
    self:RegisterCategoryRule(rules.crafting.Materials)
    self:RegisterCategoryRule(rules.currency.TelVar)
    self:RegisterCategoryRule(rules.currency.Transmutation)
    self:RegisterCategoryRule(rules.general.Festival)
    self:RegisterCategoryRule(rules.general.Fishing)
    self:RegisterCategoryRule(rules.general.Legerdemain)
    self:RegisterCategoryRule(rules.general.ShadowySupplier)
    self:RegisterCategoryRule(rules.general.TreasureMaps)
    self:RegisterCategoryRule(rules.rewards.Dragons)
    self:RegisterCategoryRule(rules.rewards.Dungeon)
    self:RegisterCategoryRule(rules.rewards.PvP)
    self:RegisterCategoryRule(rules.rewards.Solo)
    self:RegisterCategoryRule(rules.rewards.SoloRepeatable)
    self:RegisterCategoryRule(rules.rewards.Trial)
    self:RegisterCategoryRule(rules.vendor.Furnisher)
    self:RegisterCategoryRule(rules.vendor.LoreLibraryReprints)
    self:RegisterCategoryRule(rules.vendor.VendorGear)
    
    self.unboxAll = self.classes.UnboxAll:New()
    self.unboxAll:RegisterCallback("Stopped", self.CancelUnboxAll)
    self.unboxAll:RegisterCallback("Opened", OnContainerOpened)
    self.unboxAll:RegisterCallback("BeforeOpen", RefreshUnboxAllKeybind)
    
    
    LCM:RegisterContextMenu(AddContextMenu, LCM.CATEGORY_LATE)
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
