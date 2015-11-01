local addon = {
	name = "Unboxer",
	title = "Unboxer",
	defaults =
	{
		gunnySacks = false,
		weaponChests = false,
		metalWeaponBoxes = false,
		staffBoxes = false,
		armorChests = false,
		lightArmorChests = false,
		mediumArmorChests = false,
		heavyArmorChests = false,
		accessoryChests = false,
		treasureMapChests = false,
		undauntedChests = false,
		enchanterCoffers = false,
		woodworkerCases = false,
		clothierSachels = false,
		blacksmithCrates = false,
		alchemistVessels = false,
		cookingSupplies = false,
		provisionerPacks = false,
		brewingChests = false,
		potionSachels = false,
		leatherWorkerChests =false,
		ptsGearBoxes = false,
		equipmentChests = false,
		nirnhonedCoffers = false,
		trialsGearChests = false,
		bookChests = false,
		artBoxes = false,
		jewelryBoxes,
	}
}

local stats

------------ Filleting a fish ----------------
local useCallProtectedFunction = IsProtectedFunction("UseItem")
local function IsItemFish(bagId, slotIndex)
	if bagId ~= BAG_BACKPACK then return false end

	local itemType = GetItemType(bagId, slotIndex)
	if ITEMTYPE_FISH == itemType then
		local usable, onlyFromActionSlot = IsItemUsable(bagId, slotIndex)
		local canInteractWithItem = CanInteractWithItem(bagId, slotIndex)
		return usable and not onlyFromActionSlot and canInteractWithItem
	end
	return false
end

local FiletFish
local count = 0
local roeCount = 0
local itemLink
local slotIndex
local updateExpected = false
local filletAllStacks = false

local function CountPerfectRoe()
	local git = GetItemLink
	local gii = GetItemInfo
	local zpi = ZO_LinkHandler_ParseLink
	local sum = 0
	local _, count
	local bagId = BAG_BACKPACK
	local bagSlots = GetBagSize(BAG_BACKPACK) -1
	for index = 0, bagSlots do
		local itemId = select(4, zpi(git(bagId, index)))
		if itemId == "64222" then
			_, count = gii(bagId, index)
			sum = sum + count
		end
	end
	return sum
end

local function AbortAction(...)
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_INVENTORY_FULL_UPDATE)
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
	EVENT_MANAGER:UnregisterForUpdate(addon.name)
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_INVENTORY_ITEM_USED)
	-- Count "Perfect Roe" afterwards and add diff to stats
	local newCount = CountPerfectRoe()
	stats.perfectRoe = stats.perfectRoe +(newCount - roeCount)
	roeCount = newCount
	addon.running = false
	KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.allStacksKeybindButtonGroup)
	ShowMouse()
end

local function InventoryStateChange(oldState, newState)
	if newState == SCENE_HIDING then
		count = 0
		AbortAction()
		INVENTORY_FRAGMENT:UnregisterCallback("StateChange", InventoryStateChange)
	end
end

local function EndAction(...)
	AbortAction()
	INVENTORY_FRAGMENT:UnregisterCallback("StateChange", InventoryStateChange)
end

local function HasFishSlots()
	if not(CheckInventorySpaceSilently(2) and BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState() == SCENE_SHOWN) then return false end

	local bagId = BAG_BACKPACK
	local bagSlots = GetBagSize(bagId) -1
	local count = 0
	for index = 0, bagSlots do
		if IsItemFish(bagId, index) then
			count = count + 1
			if count > 1 then return true end
		end
	end

	return false
end

-- Scan backpack for next fish and use it if found.
local function UseNextFishSlot()
	if not(filletAllStacks and CheckInventorySpaceSilently(2) and BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState() == SCENE_SHOWN) then return false end

	local bagId = BAG_BACKPACK
	local bagSlots = GetBagSize(bagId) -1
	for index = 0, bagSlots do
		if IsItemFish(bagId, index) then
			slotIndex = index
			itemLink = GetItemLink(bagId, slotIndex)
			local _, stack = GetItemInfo(bagId, slotIndex)
			count = stack
			return true
		end
	end

	return false
end

local function SlotUpdate(eventCode, bagId, slotId, isNew, itemSoundCategory, updateReason)
	if bagId ~= BAG_BACKPACK or updateReason ~= INVENTORY_UPDATE_REASON_DEFAULT then return end

	if isNew and updateExpected then
		local itemId = select(4, ZO_LinkHandler_ParseLink(GetItemLink(bagId, slotId)))
		if itemId == "33753" then
			count = count - 1
			stats.fishes = stats.fishes + 1
			updateExpected = false
			if count > 0 then
				-- Not zo_callLater: if there is a delay already, it will not registered twice
				EVENT_MANAGER:RegisterForUpdate(addon.name, 500, FiletFish)
			elseif UseNextFishSlot() then
				EVENT_MANAGER:RegisterForUpdate(addon.name, 500, FiletFish)
			else
				EndAction()
			end
		end
	end
end

local function NextFish()
	updateExpected = true
end

-- After reorg of the inventory, e.g. after new entry "fish", find the stack again
local function SlotFullUpdate(eventCode, bagId, ...)
	if bagId ~= BAG_BACKPACK then return end

	if IsItemFish(bagId, slotIndex) then
		SlotUpdate(eventCode, BAG_BACKPACK, slotIndex, true, nil, INVENTORY_UPDATE_REASON_DEFAULT)
		return
	end

	local bagSlots = GetBagSize(bagId) -1
	local found = false
	local git = GetItemLink
	local gii = GetItemInfo
	for index = 0, bagSlots do
		if itemLink == git(bagId, index) then
			found = true
			slotIndex = index
			local _, stack = gii(bagId, slotIndex)
			if stack ==(count - 1) then break end
		end
	end
	if found then
		SlotUpdate(eventCode, BAG_BACKPACK, slotIndex, true, nil, INVENTORY_UPDATE_REASON_DEFAULT)
	else
		EndAction()
	end
end

FiletFish = function()
	addon.running = true
	EVENT_MANAGER:UnregisterForUpdate(addon.name)
	if not CheckInventorySpaceSilently(2) then
		EndAction()
		ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_INVENTORY_ERROR_INVENTORY_FULL)
		return false
	end
	local remaining = GetItemCooldownInfo(BAG_BACKPACK, slotIndex)
	if remaining > 0 then
		EVENT_MANAGER:RegisterForUpdate(addon.name, remaining, FiletFish)
		return
	end

	if IsItemFish(BAG_BACKPACK, slotIndex) then
		EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_INVENTORY_FULL_UPDATE, SlotFullUpdate)
		EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, SlotUpdate)
		EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_INVENTORY_ITEM_USED, NextFish)

		if useCallProtectedFunction then
			if not CallSecureProtected("UseItem", BAG_BACKPACK, slotIndex) then
				EndAction()
				PlaySound(SOUNDS.NEGATIVE_CLICK)
				return false
			end
		else
			UseItem(BAG_BACKPACK, slotIndex)
		end
		-- inventorySlot is unvalid afterwards, because the position could have changed due to the new entry "fish"
	else
		EndAction()
	end
	return false
end

local function UseInventorySlot(inventorySlot, slotActions)
	local bagId, _
	bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)

	filletAllStacks = addon.settings.filletAllStacks
	if IsItemFish(bagId, slotIndex) then
		_, count = GetItemInfo(bagId, slotIndex)
		-- Count "Perfect Roe" before
		roeCount = CountPerfectRoe()
		if count > 0 then
			addon.running = true
			itemLink = GetItemLink(bagId, slotIndex)
			INVENTORY_FRAGMENT:RegisterCallback("StateChange", InventoryStateChange)
			EVENT_MANAGER:RegisterForUpdate(addon.name, 40, FiletFish)
			slotActions:Clear()
			ClearCursor()
			ClearMenu()
			HideMouse()
			KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.allStacksKeybindButtonGroup)
			return true
		else
			itemLink = ""
			EndAction()
		end
	end
	return false
end

local function IsPlayerAlive()
	return not IsUnitDead("player")
end

local function AddSlotAction(self, actionStringId, actionCallback, actionType)
	local actionName = GetString(actionStringId)
	local options = { visibleWhenDead = false }

	table.insert(self.m_slotActions, { actionName, actionCallback, actionType, IsPlayerAlive, options })
	self.m_hasActions = true

	if self.m_contextMenuMode and IsPlayerAlive() then
		AddCustomMenuItem(actionName, actionCallback)
		self.m_numContextMenuActions = self.m_numContextMenuActions + 1
	end
end


local function AddFiletAll(inventorySlot, slotActions)
	local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
	if IsItemFish(bagId, slotIndex) and CheckInventorySpaceSilently(2) and BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState() == SCENE_SHOWN then
		AddSlotAction(slotActions, addon.settings.filletAllStacks and SI_BINDING_NAME_VOTANS_FISH_FILLET_ALL_STACKS or SI_VOTANS_FILET_FISH_ALL, function(...)
			return UseInventorySlot(inventorySlot, slotActions)
		end ,
		"primary")
	end
	return false
end

ZO_PreHook("ZO_InventorySlot_DiscoverSlotActionsFromActionList", AddFiletAll)

local function DoAllStacks()
	filletAllStacks = true
	if UseNextFishSlot() then
		local bagId = BAG_BACKPACK
		local _
		_, count = GetItemInfo(bagId, slotIndex)
		-- Count "Perfect Roe" before
		roeCount = CountPerfectRoe()
		if count > 0 then
			addon.running = true
			itemLink = GetItemLink(bagId, slotIndex)
			INVENTORY_FRAGMENT:RegisterCallback("StateChange", InventoryStateChange)
			EVENT_MANAGER:RegisterForUpdate(addon.name, 40, FiletFish)
			HideMouse()
			KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.allStacksKeybindButtonGroup)
			return true
		else
			itemLink = ""
			EndAction()
		end
	end
	return false
end

function addon:AddKeyBind()
	self.allStacksKeybindButtonGroup = {
		alignment = KEYBIND_STRIP_ALIGN_LEFT,
		{
			name = GetString(SI_BINDING_NAME_VOTANS_FISH_FILLET_ALL_STACKS),
			keybind = "VOTANS_FISH_FILLET_ALL_STACKS",
			enabled = function() return addon.running ~= true end,
			visible = HasFishSlots,
			order = 100,
			callback = DoAllStacks,
		},
	}
	BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_SHOWN and self.settings.showAllStacks then
			KEYBIND_STRIP:AddKeybindButtonGroup(addon.allStacksKeybindButtonGroup)
		elseif newState == SCENE_HIDING then
			KEYBIND_STRIP:RemoveKeybindButtonGroup(addon.allStacksKeybindButtonGroup)
		end
	end )
end

------------ End Filleting a fish ----------------

---------------- tooltip stats -------------------

function addon:ModifyTooltip(tooltip, itemLink)
	local itemType = GetItemLinkItemType(itemLink)
	if itemType == ITEMTYPE_INGREDIENT then
		if itemLink:find(":item:64222:") == nil then return end
	elseif itemType ~= ITEMTYPE_FISH then
		return
	end
	tooltip:AddVerticalPadding(10)
	if stats.fishes > 0 then
		tooltip:AddLine(zo_strjoin(nil, addon.perfectRoeName, ": ", stats.perfectRoe, "/", stats.fishes, " (", math.floor(stats.perfectRoe * 10000 / stats.fishes) / 100, "%)"))
	else
		tooltip:AddLine(zo_strjoin(nil, addon.perfectRoeName, ": 0/0 (-)"))
	end
end

local function TooltipHook(tooltipControl, method, linkFunc, equipped)
	local origMethod = tooltipControl[method]

	tooltipControl[method] = function(self, ...)
		origMethod(self, ...)
		addon:ModifyTooltip(self, linkFunc(...))
	end
end

local function ReturnItemLink(itemLink)
	return itemLink
end

------------- end tooltip stats ------------------

----------------- Settings -----------------------
function addon:SetupSettings()
	local LAM2 = LibStub("LibAddonMenu-2.0")
	if not LAM2 then return end

	local panelData = {
		type = "panel",
		name = addon.title,
		displayName = addon.title,
		author = "votan",
		version = "1.2.0",
		-- slashCommand = "",
		-- registerForRefresh = true,
		registerForDefaults = true,
	}
	LAM2:RegisterAddonPanel(addon.name, panelData)

	local optionsTable = {
		{
			type = "checkbox",
			name = GetString(SI_VOTANS_FILET_OPT_ALLSTACKS),
			tooltip = GetString(SI_VOTANS_FILET_OPT_ALLSTACKS_TOOLTIP),
			getFunc = function() return addon.settings.showAllStacks end,
			setFunc = function(value) addon.settings.showAllStacks = value end,
			default = self.defaults.showAllStacks,
		},
		{
			type = "checkbox",
			name = GetString(SI_VOTANS_FILET_OPT_ALLSTACKS_ALWAYS),
			tooltip = GetString(SI_VOTANS_FILET_OPT_ALLSTACKS_ALWAYS_TOOLTIP),
			getFunc = function() return addon.settings.filletAllStacks end,
			setFunc = function(value) addon.settings.filletAllStacks = value end,
			default = self.defaults.filletAllStacks,
		},
	}
	LAM2:RegisterOptionControls(addon.name, optionsTable)
end

--------------- End Settings ---------------------

-- Add stats for perfect roe
-- [64221] = "Psijik-Ambrosia^ns",
-- [64222] = "perfekter Rogen^ms",
-- [64223] = "Rezept: Psijik-Ambrosia^n:ns",

function addon:SlashCommand()
	SLASH_COMMANDS["/roestats"] = function()
		ZO_PopupTooltip_SetLink(addon.roeItemLink)
	end
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then return end
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon.settings = ZO_SavedVars:NewAccountWide("VotanFishFillet_Data", 1, nil, addon.defaults)
	stats = addon.settings.stats

	addon.perfectRoeName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(addon.roeItemLink))

	TooltipHook(ItemTooltip, "SetBagItem", GetItemLink)
	TooltipHook(ItemTooltip, "SetTradeItem", GetTradeItemLink)
	TooltipHook(ItemTooltip, "SetBuybackItem", GetBuybackItemLink)
	TooltipHook(ItemTooltip, "SetStoreItem", GetStoreItemLink)
	TooltipHook(ItemTooltip, "SetAttachedMailItem", GetAttachedItemLink)
	TooltipHook(ItemTooltip, "SetLootItem", GetLootItemLink)
	TooltipHook(ItemTooltip, "SetTradingHouseItem", GetTradingHouseSearchResultItemLink)
	TooltipHook(ItemTooltip, "SetTradingHouseListing", GetTradingHouseListingItemLink)
	TooltipHook(ItemTooltip, "SetLink", ReturnItemLink)

	TooltipHook(PopupTooltip, "SetLink", ReturnItemLink)

	addon:SlashCommand()
	addon:AddKeyBind()
	addon:SetupSettings()
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

VOTANS_FISH_FILLET = addon
