local strings = {
    ["SI_UNBOXER"] =                         "|c00AAFFUn|cAADDFFboxer|r",
    ["SI_BINDING_NAME_UNBOX_ALL"] =          "Unbox All",
    ["SI_UNBOXER_TOOLTIP_EXAMPLE"] =         "\nExample: |H0:item:%u:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h",
    ["SI_UNBOXER_AUTOLOOT_GLOBAL"] =         "Enable Autoloot",
    ["SI_UNBOXER_AUTOLOOT_GLOBAL_TOOLTIP"] = "Opens containers automatically as soon as they arrive in your bag for all container types with a + Autoloot option enabled below.",
    ["SI_UNBOXER_VERBOSE"] =                 "Show Chat Messages",
    ["SI_UNBOXER_VERBOSE_TOOLTIP"] =         "Displays unbox command results in the chat window.",
    ["SI_UNBOXER_AUTOLOOT"] =                "+ Autoloot",
    ["SI_UNBOXER_AUTOLOOT_TOOLTIP"] =        "Containers from the category above will be automatically opened as soon as they arrive in your bag.",
    ["SI_UNBOXER_SUMMARY"] =                 "+ "..GetString(SI_JOURNAL_PROGRESS_SUMMARY),
    ["SI_UNBOXER_SUMMARY_TOOLTIP"] =         "A summary of items unboxed from the category above will be printed to chat when Unbox All is done.",
    ["SI_UNBOXER_ARMOR"] =                   "Gear: Armor Chests",
    ["SI_UNBOXER_ARMOR_TOOLTIP"] =           "Open containers that contain only armor items.",
    ["SI_UNBOXER_WEAPONS"] =                 "Gear: Weapon Chests",
    ["SI_UNBOXER_WEAPONS_TOOLTIP"] =         "Open containers that contain only weapon items.",
    ["SI_UNBOXER_JEWELRY"] =                 "Gear: Jewelry Chests",
    ["SI_UNBOXER_JEWELRY_TOOLTIP"] =         "Open containers that contain only jewelry items.",
    ["SI_UNBOXER_REWARDS"] =                 "Gear: Rewards Chests",
    ["SI_UNBOXER_REWARDS_TOOLTIP"] =         "Open chests earned as rewards for completing daily or weekly repeatable quests.",
    ["SI_UNBOXER_OVERWORLD"] =               "Gear: Overworld Sets",
    ["SI_UNBOXER_OVERWORLD_TOOLTIP"] =       "Open overworld set containers that drop a mix of equipment.",
    ["SI_UNBOXER_DUNGEON"] =                 "Gear: Dungeon Sets",
    ["SI_UNBOXER_DUNGEON_TOOLTIP"] =         "Open dungeon set containers that drop a mix of equipment.",
    ["SI_UNBOXER_TRIALS"] =                  "Gear: Trials Sets",
    ["SI_UNBOXER_TRIALS_TOOLTIP"] =          "Open trials set containers that drop a mix of equipment.",
    ["SI_UNBOXER_CYRODIIL"] =                "Gear: Cyrodiil Sets",
    ["SI_UNBOXER_CYRODIIL_TOOLTIP"] =        "Open Cyrodiil set containers that drop a mix of equipment.",
    ["SI_UNBOXER_NONSET"] =                  "Gear: Non-set Equipment Boxes",
    ["SI_UNBOXER_NONSET_TOOLTIP"] =          "Open containers that drop a mix of non-set equipment.",
    ["SI_UNBOXER_IMPERIALCITY"] =            "Gear: Imperial City Equipment Boxes",
    ["SI_UNBOXER_IMPERIALCITY_TOOLTIP"] =    "Open Imperial City set equipment lockboxes.",
    ["SI_UNBOXER_DARKBROTHERHOOD"] =         "Gear: Dark Brotherhood Equipment Boxes",
    ["SI_UNBOXER_DARKBROTHERHOOD_TOOLTIP"] = "Open Dark Brotherhood set containers that drop a mix of equipment.",
    ["SI_UNBOXER_BATTLEGROUNDS"] =           "Gear: Battlegrounds Equipment Boxes",
    ["SI_UNBOXER_BATTLEGROUNDS_TOOLTIP"] =   "Open gear set containers purchased from the Battlegrounds merchant.",
    ["SI_UNBOXER_FESTIVAL"] =                "Loot: Festival Boxes",
    ["SI_UNBOXER_FESTIVAL_TOOLTIP"] =        "Open festival loot containers.",
    ["SI_UNBOXER_RUNEBOXES"] =               "Loot: Collectible Rune Boxes",
    ["SI_UNBOXER_RUNEBOXES_TOOLTIP"] =       "Open runeboxes containing collectible items.",
    ["SI_UNBOXER_GENERIC"] =                 "Loot: Generic Bags",
    ["SI_UNBOXER_GENERIC_TOOLTIP"] =         "Open generic bags, including Wet Gunny Sacks.",
    ["SI_UNBOXER_ENCHANTMENTS"] =            "Loot: Enchantments Chests",
    ["SI_UNBOXER_ENCHANTMENTS_TOOLTIP"] =    "Open weapon and armor enchantment chests.",
    ["SI_UNBOXER_CONSUMABLES"] =             "Loot: Consumables Bags",
    ["SI_UNBOXER_CONSUMABLES_TOOLTIP"] =     "Open containers that drop a mix of consumable items.",
    ["SI_UNBOXER_TREASUREMAPS"] =            "Loot: Treasure Maps Chests",
    ["SI_UNBOXER_TREASUREMAPS_TOOLTIP"] =    "Open containers that hold one or more treasure maps",
    ["SI_UNBOXER_TRANSMUTATION"] =           "Loot: Transmutation Geodes",
    ["SI_UNBOXER_TRANSMUTATION_TOOLTIP"] =   "Open cracked and uncracked transmutation geodes.",
    ["SI_UNBOXER_THIEF"] =                   "Loot: Stolen and Laundered Shipments",
    ["SI_UNBOXER_THIEF_TOOLTIP"] =           "Open stolen shipment and laundered shipment boxes.",
    ["SI_UNBOXER_ALCHEMY"] =                 "Crafting: Alchemist's Vessels",
    ["SI_UNBOXER_ALCHEMY_TOOLTIP"] =         "Open alchemy writ reward containers.",
    ["SI_UNBOXER_BLACKSMITHING"] =           "Crafting: Blacksmith's Crates and Shipments",
    ["SI_UNBOXER_BLACKSMITHING_TOOLTIP"] =   "Open blacksmithing writ reward containers.",
    ["SI_UNBOXER_CLOTHIER"] =                "Crafting: Clothier's Sachels and Shipments",
    ["SI_UNBOXER_CLOTHIER_TOOLTIP"] =        "Open clothing writ reward containers.",
    ["SI_UNBOXER_ENCHANTING"] =              "Crafting: Enchanter's Coffers",
    ["SI_UNBOXER_ENCHANTING_TOOLTIP"] =      "Open enchanting writ reward containers.",
    ["SI_UNBOXER_PROVISIONING"] =            "Crafting: Provisioner's Packs",
    ["SI_UNBOXER_PROVISIONING_TOOLTIP"] =    "Open provisioning writ reward containers.",
    ["SI_UNBOXER_WOODWORKING"] =             "Crafting: Woodworker's Cases and Shipments",
    ["SI_UNBOXER_WOODWORKING_TOOLTIP"] =     "Open woodworking writ reward containers.",
    ["SI_UNBOXER_FURNISHER"] =               "Housing: Furniture Recipe Containers",
    ["SI_UNBOXER_FURNISHER_TOOLTIP"] =       "Open furniture recipe containers.",
    ["SI_UNBOXER_MAGEGUILDREPRINTS"] =       "Housing: Mage's Guild Reprints",
    ["SI_UNBOXER_MAGEGUILDREPRINTS_TOOLTIP"] = "Open containers purchased from a Mystic containing full reprints of lorebooks.",
    ["SI_UNBOXER_PTSCOLLECTIBLES"] =         "PTS: Collectibles",
    ["SI_UNBOXER_PTSCOLLECTIBLES_TOOLTIP"] = "Open PTS template boxes containing collectibles.",
    ["SI_UNBOXER_PTSCONSUMABLES"] =          "PTS: Consumables",
    ["SI_UNBOXER_PTSCONSUMABLES_TOOLTIP"] =  "Open PTS template boxes containing consumables.",
    ["SI_UNBOXER_PTSCRAFTING"] =             "PTS: Crafting",
    ["SI_UNBOXER_PTSCRAFTING_TOOLTIP"] =     "Open PTS template boxes containing crafting materials.",
    ["SI_UNBOXER_PTSCURRENCY"] =             "PTS: Currency",
    ["SI_UNBOXER_PTSCURRENCY_TOOLTIP"] =     "Open PTS template boxes containing currency.",
    ["SI_UNBOXER_PTSGEAR"] =                 "PTS: Gear",
    ["SI_UNBOXER_PTSGEAR_TOOLTIP"] =         "Open PTS template boxes containing equipable gear.",
    ["SI_UNBOXER_PTSHOUSING"] =              "PTS: Housing",
    ["SI_UNBOXER_PTSHOUSING_TOOLTIP"] =      "Open PTS template boxes containing housing related items.",
    ["SI_UNBOXER_PTSSKILLS"] =               "PTS: Skills / Training",
    ["SI_UNBOXER_PTSSKILLS_TOOLTIP"] =       "Open PTS template boxes containing skill line, research and training boosters.",
    ["SI_UNBOXER_PTSOTHER"] =                "PTS: Other",
    ["SI_UNBOXER_PTSOTHER_TOOLTIP"] =        "Open PTS template boxes that don't fit into the above categories.",
    ["SI_UNBOXER_OTHER"] =                   "Unbox Other Containers",
    ["SI_UNBOXER_OTHER_TOOLTIP"] =           "Open all other non-specific containers.",
}

-- Overwrite English strings
for stringId, value in pairs(strings) do
    UNBOXER_STRINGS[stringId] = value
end