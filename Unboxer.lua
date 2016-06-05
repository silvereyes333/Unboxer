local addon = {
	name = "Unboxer",
	title = GetString(SI_UNBOXER),
	author = "nobody",
	version = "1.0.2",
	defaults =
	{
		verbose = true,
		gunnySacks = false,
		enchantments = false,
		weapons = false,
		armor = false,
		potions = false,
		accessories = false,
		rewards = false,
		alchemist = false,
		blacksmith = false,
		clothier = false,
		enchanter = false,
		provisioner = false,
		woodworker = false,
		other = false
	}
}


-- Output formatted message to chat window, if configured
local function pOutput(input)
	if not addon.settings.verbose then
		return
	end
	local output = zo_strformat("<<1>>|cFFFFFF: <<2>>|r", addon.title, input)
	d(output)
end


local useCallProtectedFunction = IsProtectedFunction("UseItem")
local function IsItemUnboxable(bagId, slotIndex)
	if bagId ~= BAG_BACKPACK then return false end

	local itemType = GetItemType(bagId, slotIndex)
	if itemType ~= ITEMTYPE_CONTAINER then return false end
	
	local name = string.lower(GetItemName(bagId, slotIndex))
	if name == "wet gunny sack" then
		if not addon.settings.gunnySacks then
			return false
		end
	elseif string.find(name, "enchantment") ~= nil then
		if not addon.settings.enchantment then
			return false
		end
	elseif string.find(name, "weapon") ~= nil or string.find(name, "staff") ~= nil then
		if not addon.settings.weapons then
			return false
		end
	elseif string.find(name, "armor") ~= nil then
		if not addon.settings.armor then
			return false
		end
	elseif string.find(name, "dragonstar") ~= nil or string.find(name, "undaunted") ~= nil or string.find(name, "mage") ~= nil or string.find(name, "warrior") ~= nil or string.find(name, "serpent") ~= nil then
		if not addon.settings.trials then
			return false
		end
	elseif string.find(name, "alchemist's vessel") ~= nil then
		if not addon.settings.alchemist then
			return false
		end
	elseif string.find(name, "alchemist") ~= nil then
		if not addon.settings.potions then
			return false
		end
	elseif string.find(name, "blacksmith") ~= nil then
		if not addon.settings.blacksmith then
			return false
		end
	elseif string.find(name, "clothier") ~= nil then
		if not addon.settings.clothier then
			return false
		end
	elseif string.find(name, "enchanter") ~= nil then
		if not addon.settings.enchanter then
			return false
		end
	elseif string.find(name, "woodworker") ~= nil then
		if not addon.settings.woodworker then
			return false
		end
	elseif string.find(name, "brewer") ~= nil or string.find(name, "cooking") ~= nil or string.find(name, "provisioner") ~= nil  then
		if not addon.settings.provisioner then
			return false
		end
	elseif string.find(name, "accessory") ~= nil or string.find(name, "jewelry") ~= nil  then
		if not addon.settings.accessories then
			return false
		end
	else
		if not addon.settings.other then
			return false
		end
	end
	
	local usable, onlyFromActionSlot = IsItemUsable(bagId, slotIndex)
	local canInteractWithItem = CanInteractWithItem(bagId, slotIndex)
	return usable and not onlyFromActionSlot and canInteractWithItem
end

local UnboxCurrent
local itemLink
local slotIndex
local updateExpected = false

local function AbortAction(...)
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_INVENTORY_FULL_UPDATE)
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
	EVENT_MANAGER:UnregisterForUpdate(addon.name)
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_INVENTORY_ITEM_USED)
	addon.running = false
	KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
end

local function InventoryStateChange(oldState, newState)
	if newState == SCENE_HIDING then
		AbortAction()
		INVENTORY_FRAGMENT:UnregisterCallback("StateChange", InventoryStateChange)
	end
end

local function EndAction(...)
	AbortAction()
	INVENTORY_FRAGMENT:UnregisterCallback("StateChange", InventoryStateChange)
end

local function HasUnboxableSlots()
	if not(CheckInventorySpaceSilently(2) and BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState() == SCENE_SHOWN) then return false end

	local bagId = BAG_BACKPACK
	local bagSlots = GetBagSize(bagId) -1
	for index = 0, bagSlots do
		if IsItemUnboxable(bagId, index) then return true end
	end

	return false
end

-- Scan backpack for next unboxable container and return true if found
local function GetNextItemToUnbox()
	if not(CheckInventorySpaceSilently(2) and BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState() == SCENE_SHOWN) then return false end

	local bagId = BAG_BACKPACK
	local bagSlots = GetBagSize(bagId) -1
	for index = 0, bagSlots do
		if IsItemUnboxable(bagId, index) then
			slotIndex = index
			itemLink = GetItemLink(bagId, slotIndex)
			return true
		end
	end

	return false
end

local function SlotUpdate(eventCode, bagId, slotId, isNew, itemSoundCategory, updateReason)
	if bagId ~= BAG_BACKPACK or updateReason ~= INVENTORY_UPDATE_REASON_DEFAULT then return end

	if isNew and updateExpected then
		updateExpected = false
		if GetNextItemToUnbox() then
			EVENT_MANAGER:RegisterForUpdate(addon.name, 500, UnboxCurrent)
		else
			EndAction()
		end
	end
end

local function NextUnboxableItem()
	updateExpected = true
end

-- After reorg of the inventory, unbox the next item
local function SlotFullUpdate(eventCode, bagId, ...)
	if bagId ~= BAG_BACKPACK then return end

	if updateExpected then
		updateExpected = false
		if GetNextItemToUnbox() then
			EVENT_MANAGER:RegisterForUpdate(addon.name, 500, UnboxCurrent)
		else
			EndAction()
		end
	end
end

UnboxCurrent = function()
	addon.running = true
	EVENT_MANAGER:UnregisterForUpdate(addon.name)
	if not CheckInventorySpaceSilently(2) then
		EndAction()
		ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_INVENTORY_ERROR_INVENTORY_FULL)
		return false
	end
	local remaining = GetItemCooldownInfo(BAG_BACKPACK, slotIndex)
	if remaining > 0 then
		EVENT_MANAGER:RegisterForUpdate(addon.name, remaining, UnboxCurrent)
		return
	end

	if IsItemUnboxable(BAG_BACKPACK, slotIndex) then
		EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_INVENTORY_FULL_UPDATE, SlotFullUpdate)
		EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, SlotUpdate)
		EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_INVENTORY_ITEM_USED, NextUnboxableItem)

		if useCallProtectedFunction then
			if not CallSecureProtected("UseItem", BAG_BACKPACK, slotIndex) then
				EndAction()
				PlaySound(SOUNDS.NEGATIVE_CLICK)
				pOutput(zo_strformat("Failed to unbox <<1>>", itemLink))
				return false
			end
		else
			UseItem(BAG_BACKPACK, slotIndex)
		end
		pOutput(zo_strformat("Unboxed <<1>>", itemLink))
		-- inventorySlot is unvalid afterwards, because the position could have changed due to the new entry "fish"
	else
		EndAction()
	end
	return false
end

local function UseInventorySlot(inventorySlot, slotActions)
	local bagId
	bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)

	if IsItemUnboxable(bagId, slotIndex) then
		addon.running = true
		itemLink = GetItemLink(bagId, slotIndex)
		INVENTORY_FRAGMENT:RegisterCallback("StateChange", InventoryStateChange)
		EVENT_MANAGER:RegisterForUpdate(addon.name, 40, UnboxCurrent)
		slotActions:Clear()
		ClearCursor()
		ClearMenu()
		KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
		return true
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


local function AddUnboxAll(inventorySlot, slotActions)
	local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
	if IsItemUnboxable(bagId, slotIndex) and CheckInventorySpaceSilently(2) and BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:GetState() == SCENE_SHOWN then
		AddSlotAction(slotActions, SI_UNBOXER_UNBOXALL, function(...)
			return UseInventorySlot(inventorySlot, slotActions)
		end ,
		"primary")
	end
	return false
end

ZO_PreHook("ZO_InventorySlot_DiscoverSlotActionsFromActionList", AddUnboxAll)

function addon.UnboxAll()
	if GetNextItemToUnbox() then
		local bagId = BAG_BACKPACK
		addon.running = true
		itemLink = GetItemLink(bagId, slotIndex)
		INVENTORY_FRAGMENT:RegisterCallback("StateChange", InventoryStateChange)
		EVENT_MANAGER:RegisterForUpdate(addon.name, 40, UnboxCurrent)
		KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.unboxAllKeybindButtonGroup)
		return true
	end
	return false
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
end



----------------- Settings -----------------------
function addon:SetupSettings()
	local LAM2 = LibStub("LibAddonMenu-2.0")
	if not LAM2 then return end

	local panelData = {
		type = "panel",
		name = addon.title,
		displayName = addon.title,
		author = addon.author,
		version = addon.version,
		slashCommand = "/unboxer",
		-- registerForRefresh = true,
		registerForDefaults = true,
	}
	LAM2:RegisterAddonPanel(addon.name, panelData)

	local optionsTable = {
		{
			type = "checkbox",
			name = GetString(SI_UNBOXER_VERBOSE),
			tooltip = GetString(SI_UNBOXER_VERBOSE_TOOLTIP),
			getFunc = function() return addon.settings.verbose end,
			setFunc = function(value) addon.settings.verbose = value end,
			default = self.defaults.verbose,
		},
		{
			type = "checkbox",
			name = GetString(SI_UNBOXER_ARMOR),
			tooltip = GetString(SI_UNBOXER_ARMOR_TOOLTIP),
			getFunc = function() return addon.settings.armor end,
			setFunc = function(value) addon.settings.armor = value end,
			default = self.defaults.armor,
		},
		{
			type = "checkbox",
			name = GetString(SI_UNBOXER_WEAPONS),
			tooltip = GetString(SI_UNBOXER_WEAPONS_TOOLTIP),
			getFunc = function() return addon.settings.weapons end,
			setFunc = function(value) addon.settings.weapons = value end,
			default = self.defaults.weapons,
		},
		{
			type = "checkbox",
			name = GetString(SI_UNBOXER_REWARDS),
			tooltip = GetString(SI_UNBOXER_REWARDS_TOOLTIP),
			getFunc = function() return addon.settings.rewards end,
			setFunc = function(value) addon.settings.rewards = value end,
			default = self.defaults.rewards,
		},
		{
			type = "checkbox",
			name = GetString(SI_UNBOXER_ACCESSORIES),
			tooltip = GetString(SI_UNBOXER_ACCESSORIES_TOOLTIP),
			getFunc = function() return addon.settings.accessories end,
			setFunc = function(value) addon.settings.accessories = value end,
			default = self.defaults.accessories,
		},
		{
			type = "checkbox",
			name = GetString(SI_UNBOXER_GUNNYSACKS),
			tooltip = GetString(SI_UNBOXER_GUNNYSACKS_TOOLTIP),
			getFunc = function() return addon.settings.gunnySacks end,
			setFunc = function(value) addon.settings.gunnySacks = value end,
			default = self.defaults.gunnySacks,
		},
		{
			type = "checkbox",
			name = GetString(SI_UNBOXER_ENCHANTMENTS),
			tooltip = GetString(SI_UNBOXER_ENCHANTMENTS_TOOLTIP),
			getFunc = function() return addon.settings.enchantments end,
			setFunc = function(value) addon.settings.enchantments = value end,
			default = self.defaults.enchantments,
		},
		{
			type = "checkbox",
			name = GetString(SI_UNBOXER_POTIONS),
			tooltip = GetString(SI_UNBOXER_POTIONS_TOOLTIP),
			getFunc = function() return addon.settings.potions end,
			setFunc = function(value) addon.settings.potions = value end,
			default = self.defaults.potions,
		},
		{
			type = "checkbox",
			name = GetString(SI_UNBOXER_ALCHEMIST),
			tooltip = GetString(SI_UNBOXER_ALCHEMIST_TOOLTIP),
			getFunc = function() return addon.settings.alchemist end,
			setFunc = function(value) addon.settings.alchemist = value end,
			default = self.defaults.alchemist,
		},
		{
			type = "checkbox",
			name = GetString(SI_UNBOXER_BLACKSMITH),
			tooltip = GetString(SI_UNBOXER_BLACKSMITH_TOOLTIP),
			getFunc = function() return addon.settings.blacksmith end,
			setFunc = function(value) addon.settings.blacksmith = value end,
			default = self.defaults.blacksmith,
		},
		{
			type = "checkbox",
			name = GetString(SI_UNBOXER_CLOTHIER),
			tooltip = GetString(SI_UNBOXER_CLOTHIER_TOOLTIP),
			getFunc = function() return addon.settings.clothier end,
			setFunc = function(value) addon.settings.clothier = value end,
			default = self.defaults.clothier,
		},
		{
			type = "checkbox",
			name = GetString(SI_UNBOXER_ENCHANTER),
			tooltip = GetString(SI_UNBOXER_ENCHANTER_TOOLTIP),
			getFunc = function() return addon.settings.enchanter end,
			setFunc = function(value) addon.settings.enchanter = value end,
			default = self.defaults.enchanter,
		},
		{
			type = "checkbox",
			name = GetString(SI_UNBOXER_PROVISIONER),
			tooltip = GetString(SI_UNBOXER_PROVISIONER_TOOLTIP),
			getFunc = function() return addon.settings.provisioner end,
			setFunc = function(value) addon.settings.provisioner = value end,
			default = self.defaults.provisioner,
		},
		{
			type = "checkbox",
			name = GetString(SI_UNBOXER_WOODWORKER),
			tooltip = GetString(SI_UNBOXER_WOODWORKER_TOOLTIP),
			getFunc = function() return addon.settings.woodworker end,
			setFunc = function(value) addon.settings.woodworker = value end,
			default = self.defaults.woodworker,
		},
		{
			type = "checkbox",
			name = GetString(SI_UNBOXER_OTHER),
			tooltip = GetString(SI_UNBOXER_OTHER_TOOLTIP),
			getFunc = function() return addon.settings.other end,
			setFunc = function(value) addon.settings.other = value end,
			default = self.defaults.other,
		},
	}
	LAM2:RegisterOptionControls(addon.name, optionsTable)
end

--------------- End Settings ---------------------


local function OnAddonLoaded(event, name)
	if name ~= addon.name then return end
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon.settings = ZO_SavedVars:NewAccountWide("Unboxer_Data", 1, nil, addon.defaults)

	addon:AddKeyBind()
	addon:SetupSettings()
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

Unboxer = addon
