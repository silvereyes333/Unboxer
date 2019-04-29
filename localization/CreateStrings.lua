
-- Locale-specific strings
UNBOXER_STRINGS["SI_UNBOXER_BATTLEGROUND_LOWER"]  = LocaleAwareToLower(GetString("SI_INSTANCEDISPLAYTYPE", INSTANCE_DISPLAY_TYPE_BATTLEGROUND))
UNBOXER_STRINGS["SI_UNBOXER_TRIAL_LOWER"]         = LocaleAwareToLower(GetString("SI_LFGACTIVITY", LFG_ACTIVITY_TRIAL))
UNBOXER_STRINGS["SI_UNBOXER_UNDAUNTED_LOWER"]     = LocaleAwareToLower(GetString("SI_VISUALARMORTYPE", VISUAL_ARMORTYPE_UNDAUNTED))
UNBOXER_STRINGS["SI_UNBOXER_WEEKLY_LOWER"]        = LocaleAwareToLower(GetString(SI_RAID_LEADERBOARDS_WEEKLY))
UNBOXER_STRINGS["SI_UNBOXER_DAILY_LOWER"]         = LocaleAwareToLower(GetString("SI_QUESTREPEATABLETYPE", QUEST_REPEAT_DAILY))
UNBOXER_STRINGS["SI_UNBOXER_CRAFTED_LOWER"]       = LocaleAwareToLower(GetString(SI_ITEM_FORMAT_STR_CRAFTED))
if not UNBOXER_STRINGS["SI_UNBOXER_REWARD_LOWER"] then
    UNBOXER_STRINGS["SI_UNBOXER_REWARD_LOWER"]    = LocaleAwareToLower(GetString(SI_LEVEL_UP_REWARDS_GAMEPAD_REWARD_SECTION_HEADER_SINGULAR))
end
UNBOXER_STRINGS["SI_UNBOXER_GIFT_LOWER"]          = LocaleAwareToLower(GetString(SI_GIFT_INVENTORY_KEYBOARD_HEADER_NAME))
UNBOXER_STRINGS["SI_UNBOXER_TRANSMUTATION_LOWER"] = LocaleAwareToLower(GetString(SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES211))
UNBOXER_STRINGS["SI_UNBOXER_TREASURE_MAP_LOWER"]  = LocaleAwareToLower(GetString("SI_SPECIALIZEDITEMTYPE", SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP))
UNBOXER_STRINGS["SI_UNBOXER_RAW_MATERIAL_LOWER"]  = LocaleAwareToLower(GetString("SI_ITEMTYPE", ITEMTYPE_RAW_MATERIAL))
UNBOXER_STRINGS["SI_UNBOXER_FURNISHING_LOWER"]    = LocaleAwareToLower(GetString("SI_ITEMTYPE", ITEMTYPE_FURNISHING))
UNBOXER_STRINGS["SI_UNBOXER_STOLEN_LOWER"]        = LocaleAwareToLower(GetString(SI_GAMEPAD_ITEM_STOLEN_LABEL))
UNBOXER_STRINGS["SI_UNBOXER_ENCHANTMENT_LOWER"]   = LocaleAwareToLower(GetString(SI_ITEM_FORMAT_STR_AUGMENT_ITEM_TYPE))
UNBOXER_STRINGS["SI_UNBOXER_CYRODIIL_LOWER"]      = LocaleAwareToLower(GetZoneNameById(181))



for stringId, defaultValue in pairs(UNBOXER_DEFAULT_STRINGS) do
    local value = UNBOXER_STRINGS[stringId] or defaultValue
    ZO_CreateStringId(stringId, value)
    ZO_CreateStringId(stringId .. "_DEFAULT", defaultValue)
end
UNBOXER_STRINGS = nil
UNBOXER_DEFAULT_STRINGS = nil