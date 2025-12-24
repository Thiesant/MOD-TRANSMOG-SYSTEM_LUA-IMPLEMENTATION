local ADDON_NAME, Transmog = ...

-- English (US) Localization - Default
Transmog.L = Transmog.L or {}
local L = Transmog.L




-- UI Strings
L["ADDON_TITLE"] = "Transmogrification"
L["INSTRUCTIONS"] = "" -- "|cff00ff00Left Mouse:|r rotate  |  |cff00ff00Right Mouse:|r pan  |  |cff00ff00Wheel:|r zoom"
L["RESET"] = "Reset"
L["UNDRESS"] = "Undress"
L["PAGE"] = "Page %d/%d"
L["TAB_NAME"] = "Transmogrification"
L["APPLY"] = "Apply"
L["APPLY_APPEARANCE_SHIFT_CLICK"] = "|cff00ff00Shift+Click:|r Apply appearance"
L["PREVIEW_APPEARANCE_CLICK"] = "|cff00ff00Click:|r Preview"
L["MINIMAP_BUTTON_TITLE"] = "Transmog Collection"

-- Collection Status
L["ACTIVE_TRANSMOG"] = "Transmog active:"
L["NO_ACTIVE_TRANSMOG"] = "No transmog active"
L["TRANSMOG_SLOT_ACTIVE"] = "|cff00ff00ACTIVE|r"
L["CLEAR_TRANSMOG"]= "|cffff0000Right-click to clear|r"
L["APPEARANCE_COLLECTED"] = "|cff00ff00Appearance collected|r"
L["APPEARANCE_NOT_COLLECTED"] = "|cffff0000Appearance not collected|r"
L["NEW_APPEARANCE"] = "|cffFFD700NEW APPEARANCE!|r"
L["NEW_APPEARANCE_UNLOCKED"] = "New appearance unlocked:"
L["RETROACTIVE_UNLOCKED"] = "%d appearances unlocked from completed quests."
L["TRANSMOG_APPLIED"] = "Transmog applied!"
L["TRANSMOG_REMOVED"] = "Transmog removed!"

-- Slot Names
L["Head"] = "Head"
L["Shoulder"] = "Shoulder"
L["Back"] = "Back"
L["Chest"] = "Chest"
L["Shirt"] = "Shirt"
L["Tabard"] = "Tabard"
L["Wrist"] = "Wrist"
L["Hands"] = "Hands"
L["Waist"] = "Waist"
L["Legs"] = "Legs"
L["Feet"] = "Feet"
L["MainHand"] = "Main Hand"
L["SecondaryHand"] = "Off Hand"
L["Ranged"] = "Ranged"

-- Armor Types
L["All"] = "All"
L["Cloth"] = "Cloth"
L["Leather"] = "Leather"
L["Mail"] = "Mail"
L["Plate"] = "Plate"
L["Miscellaneous"] = "Miscellaneous"

-- Weapon Types
L["Axe1H"] = "One-Handed Axe"
L["Mace1H"] = "One-Handed Mace"
L["Sword1H"] = "One-Handed Sword"
L["Dagger"] = "Dagger"
L["Fist"] = "Fist Weapon"
L["Axe2H"] = "Two-Handed Axe"
L["Mace2H"] = "Two-Handed Mace"
L["Sword2H"] = "Two-Handed Sword"
L["Polearm"] = "Polearm"
L["Staff"] = "Staff"
L["Shield"] = "Shield"
L["Held"] = "Held In Off-hand"
L["Bow"] = "Bow"
L["Crossbow"] = "Crossbow"
L["Gun"] = "Gun"
L["Wand"] = "Wand"
L["Thrown"] = "Thrown"
L["Fishing"] = "Fishing Pole"

-- Search
L["SEARCH"] = "Search"
L["SEARCH_TOOLTIP"] = "Search Options:"
L["SEARCH_CLEAR"] = "Clear"
L["SEARCH_NAME"] = "Name"
L["SEARCH_NAME_DESCRIPTION"] = ": Enter item name (english)" -- (for other locale (english or LOCALE USED))
L["SEARCH_ID"] = "ID"
L["SEARCH_ID_DESCRIPTION"] = ": Enter item ID"
L["SEARCH_DISPLAYID"] = "DisplayID"
L["SEARCH_DISPLAYID_DESCRIPTION"] = ": Enter display ID"
L["SEARCH_TOOLTIP"] = "Search by item name, ID, or display ID"
L["SEARCH_RESULTS"] = "Results: %d items"
L["SEARCH_SEARCH"] = "Search"
L["SEARCH_DESCRIPTION"] = "Press Enter to search"
L["SEARCH_CLEAR"] = "Clear"
L["SEARCH_CLEAR_DESCRIPTION"] = "Press Escape to clear"

-- Messages
L["COLLECTION_LOADED"] = "Collection loaded: %d appearances"
L["SLASH_TRANSMOG"] = "|cff00ff00[Transmog]|r Addon loaded. Type /transmog or /tmog to open."
L["HELP_1"] = "|cff00ff00[Transmog]|r Help:"
L["HELP_2"] = "  /transmog - Open/close transmogrification window"
L["HELP_3"] = "  /transmog help - Show this help"
--L["HELP_4"] = ""

-- Error Messages
L["APPEARANCE_NOT_COLLECTED"] = "You don't have this appearance"
L["ERROR_INVALID_SLOT_OR_ITEM"] = "Invalid slot or item"
L["ERROR_INVALID_SLOT"] = "Invalid equipment slot"

-- Filters
L["SELECT_ITEM_CLICK"] = "Click to select this item"

-- Set Management
L["SET_NEW"] = "New Set..."
L["SET_SELECT"] = "Select Set"
L["SET_DEFAULT_NAME"] = "Set %d"
L["SET_SAVE"] = "Save"
L["SET_DELETE"] = "Del"
L["SET_APPLY"] = "Apply"
L["SET_SAVE_PROMPT"] = "Enter set name:"
L["SET_SAVED"] = "Set '%s' saved!"
L["SET_LOADED"] = "Set '%s' loaded into preview"
L["SET_DELETED"] = "Set #%d deleted"
L["SET_APPLIED"] = "Set '%s' applied!"
L["SET_ERROR"] = "Set operation failed"
L["SET_FULL"] = "|cffff0000[Transmog]|r All set slots are full. Delete a set first."
L["SET_NO_SELECTION"] = "|cffff0000[Transmog]|r No items selected. Click items in the preview to select them first."
L["SET_SELECT_FIRST"] = "|cffff0000[Transmog]|r Select a set first."
L["SET_DELETE_CONFIRM"] = "Delete this set?"
L["SET_SAVE_TOOLTIP"] = "Save selected items as a new set"
L["SET_DELETE_TOOLTIP"] = "Delete the selected set"
L["SET_APPLY_TOOLTIP"] = "Apply this set as active transmog\n(Only collected appearances will be applied)"
L["APPLY_HINT"] = "Select an appearance and Shift+Click to apply"

-- Mode Toggle
L["MODE_ITEM"] = "Items"
L["MODE_ENCHANT"] = "Enchants"
L["MODE_TOGGLE_TOOLTIP_ITEM"] = "Item Transmog Mode"
L["MODE_TOGGLE_TOOLTIP_ENCHANT"] = "Enchant Transmog Mode"
L["MODE_TOGGLE_DESC_ITEM"] = "Click to switch to Enchant Transmog Mode"
L["MODE_TOGGLE_DESC_ENCHANT"] = "Click to switch to Item Transmog Mode"
L["MODE_ENCHANT_NOTE"] = "Only weapon slots can have enchant visuals"
L["ENCHANT_MODE"] = "Enchant Mode"

-- Enchantment Strings
L["ENCHANT_CATEGORY"] = "Category"
L["ENCHANT_ACTIVE"] = "|cff00ff00Currently Active|r"
L["CLEAR_ENCHANT"] = "|cffff0000Right-click to remove|r"
L["APPLY_ENCHANT_SHIFT_CLICK"] = "|cff00ff00Shift+Click:|r Apply enchant visual"
L["ENCHANT_APPLIED"] = "Enchant visual applied!"
L["ENCHANT_REMOVED"] = "Enchant visual removed!"
L["ENCHANT_COLLECTION_LOADED"] = "Enchant collection loaded: %d visuals"

-- Enchant Categories
L["Runeforge"] = "Runeforge"
L["Fire"] = "Fire"
L["Frost"] = "Frost"
L["Nature"] = "Nature"
L["Arcane"] = "Arcane"
L["Holy"] = "Holy"
L["Shadow"] = "Shadow"
L["Physical"] = "Physical"
L["Shaman"] = "Shaman"