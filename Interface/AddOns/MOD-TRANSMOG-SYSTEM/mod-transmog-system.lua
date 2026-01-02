local ADDON_NAME, Transmog = ...

-- Localization
local L = Transmog.L or {}

-- ============================================================================
-- AIO Integration
-- ============================================================================

local AIO = AIO or require("AIO")

-- ============================================================================
-- SavedVariables
-- ============================================================================
-- TransmogDB: Cache and collection data
-- TransmogSettings: User preferences (separate file)
-- ============================================================================

TransmogDB = TransmogDB or {}  -- For cache, collection, minimap position
TransmogSettings = TransmogSettings or {}  -- For user preferences

-- ============================================================================
-- Settings System
-- ============================================================================
-- Settings are split into account-wide and character-specific
-- Character settings override account settings where applicable
-- ============================================================================

local function GetCharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. "-" .. realm
end

local function InitializeSettings()
    -- Initialize account-wide settings table
    TransmogSettings.account = TransmogSettings.account or {}
    
    -- Set defaults for each account-wide setting if not already set
    if TransmogSettings.account.showCollectedTooltip == nil then
        TransmogSettings.account.showCollectedTooltip = true
    end
    if TransmogSettings.account.showNewAppearanceTooltip == nil then
        TransmogSettings.account.showNewAppearanceTooltip = true
    end
    if TransmogSettings.account.showItemIdTooltip == nil then
        TransmogSettings.account.showItemIdTooltip = true
    end
    if TransmogSettings.account.showDisplayIdTooltip == nil then
        TransmogSettings.account.showDisplayIdTooltip = true
    end
    if TransmogSettings.account.hideHairOnCloakPreview == nil then
        TransmogSettings.account.hideHairOnCloakPreview = true
    end
    if TransmogSettings.account.hideHairOnChestPreview == nil then
        TransmogSettings.account.hideHairOnChestPreview = true
    end
    if TransmogSettings.account.hideHairOnShirtPreview == nil then
        TransmogSettings.account.hideHairOnShirtPreview = true
    end
    if TransmogSettings.account.hideHairOnTabardPreview == nil then
        TransmogSettings.account.hideHairOnTabardPreview = true
    end
    if TransmogSettings.account.mergeByDisplayId == nil then
        TransmogSettings.account.mergeByDisplayId = true
    end
    if TransmogSettings.account.showSharedAppearanceTooltip == nil then
        TransmogSettings.account.showSharedAppearanceTooltip = true
    end
    
    -- Character-specific defaults (keyed by character name-realm)
    TransmogSettings.characters = TransmogSettings.characters or {}
    
    local charKey = GetCharacterKey()
    TransmogSettings.characters[charKey] = TransmogSettings.characters[charKey] or {}
    
    -- Set defaults for each character-specific setting if not already set
    if TransmogSettings.characters[charKey].backgroundOverride == nil then
        TransmogSettings.characters[charKey].backgroundOverride = nil  -- nil = use class default
    end
    if TransmogSettings.characters[charKey].previewMode == nil then
        TransmogSettings.characters[charKey].previewMode = "classic"
    end
end

-- Get a setting value (character-specific if exists, else account-wide)
local function GetSetting(key)
    local charKey = GetCharacterKey()
    local charSettings = TransmogSettings.characters and TransmogSettings.characters[charKey]
    
    -- Check character-specific first
    if charSettings and charSettings[key] ~= nil then
        return charSettings[key]
    end
    
    -- Fall back to account-wide
    if TransmogSettings.account and TransmogSettings.account[key] ~= nil then
        return TransmogSettings.account[key]
    end
    
    return nil
end

-- Set a setting value
local function SetSetting(key, value, characterSpecific)
    if characterSpecific then
        local charKey = GetCharacterKey()
        TransmogSettings.characters = TransmogSettings.characters or {}
        TransmogSettings.characters[charKey] = TransmogSettings.characters[charKey] or {}
        TransmogSettings.characters[charKey][key] = value
    else
        TransmogSettings.account = TransmogSettings.account or {}
        TransmogSettings.account[key] = value
    end
end

-- Check if a setting is enabled (nil and true both mean enabled, only false means disabled)
local function IsSettingEnabled(key)
    local value = GetSetting(key)
    if value == nil then return true end  -- Default to enabled if not set
    if value == 1 then return true end    -- Handle old checkbox values (1/nil)
    return value == true
end

-- Export for use elsewhere
Transmog.GetSetting = GetSetting
Transmog.SetSetting = SetSetting
Transmog.IsSettingEnabled = IsSettingEnabled

-- ============================================================================
-- Search Bar variables
-- ============================================================================
local searchActive = false
local searchResults = {}
local searchSlotResults = {}  -- Items organized by slot
local lastSearchText = ""

-- ============================================================================
-- Player Info
-- ============================================================================

local playerGender = UnitSex("player") - 2
local RACE_TO_ID = {
    ["Human"]    = 1,
    ["Orc"]      = 2,
    ["Dwarf"]    = 3,
    ["NightElf"] = 4,
    ["Scourge"]  = 5,
    ["Tauren"]   = 6,
    ["Gnome"]    = 7,
    ["Troll"]    = 8,
    ["Goblin"]   = 9,
    ["BloodElf"] = 10,
    ["Draenei"]  = 11,
}
local _, playerRaceFile = UnitRace("player")
local playerRaceId = RACE_TO_ID[playerRaceFile] or 0
local _, playerClass = UnitClass("player")

-- ============================================================================
-- Slot Configuration
-- ============================================================================

-- id = InventorySlotId (1-based, for UI)
-- equipSlot = Equipment slot (0-based, for server/Eluna)
local SLOT_CONFIG = {
    Head          = { id = 1,  equipSlot = 0,  invType = {1},                  category = "armor",  texture = "Head" },
    Shoulder      = { id = 3,  equipSlot = 2,  invType = {3},                  category = "armor",  texture = "Shoulder" },
    Back          = { id = 15, equipSlot = 14, invType = {16},                 category = "armor",  texture = "Chest" },
    Chest         = { id = 5,  equipSlot = 4,  invType = {5, 20},              category = "armor",  texture = "Chest" },
    Shirt         = { id = 4,  equipSlot = 3,  invType = {4},                  category = "armor",  texture = "Shirt" },
    Tabard        = { id = 19, equipSlot = 18, invType = {19},                 category = "armor",  texture = "Tabard" },
    Wrist         = { id = 9,  equipSlot = 8,  invType = {9},                  category = "armor",  texture = "Wrists" },
    Hands         = { id = 10, equipSlot = 9,  invType = {10},                 category = "armor",  texture = "Hands" },
    Waist         = { id = 6,  equipSlot = 5,  invType = {6},                  category = "armor",  texture = "Waist" },
    Legs          = { id = 7,  equipSlot = 6,  invType = {7},                  category = "armor",  texture = "Legs" },
    Feet          = { id = 8,  equipSlot = 7,  invType = {8},                  category = "armor",  texture = "Feet" },
    MainHand      = { id = 16, equipSlot = 15, invType = {13, 17, 21},         category = "weapon", texture = "MainHand" },
    SecondaryHand = { id = 17, equipSlot = 16, invType = {13, 14, 17, 22, 23}, category = "weapon", texture = "SecondaryHand" },
    Ranged        = { id = 18, equipSlot = 17, invType = {15, 25, 26},         category = "weapon", texture = "Ranged" },
}

local SLOT_ORDER = {
    "Head", "Shoulder", "Back", "Chest", "Shirt", "Tabard",
    "Wrist", "Hands", "Waist", "Legs", "Feet",
    "MainHand", "SecondaryHand", "Ranged"
}

-- Map slot name to equipment slot (0-based, for server communication)
local SLOT_NAME_TO_EQUIP_SLOT = {}
for name, config in pairs(SLOT_CONFIG) do
    SLOT_NAME_TO_EQUIP_SLOT[name] = config.equipSlot
end

local SLOT_SUBCLASSES = {
    Head              = {"All", "Cloth", "Leather", "Mail", "Plate"},
    Shoulder          = {"All", "Cloth", "Leather", "Mail", "Plate"},
    Back              = {"All", "Cloth"},
    Chest             = {"All", "Cloth", "Leather", "Mail", "Plate"},
    Shirt             = {"All", "Miscellaneous"},
    Tabard            = {"All", "Miscellaneous"},
    Wrist             = {"All", "Cloth", "Leather", "Mail", "Plate"},
    Hands             = {"All", "Cloth", "Leather", "Mail", "Plate"},
    Waist             = {"All", "Cloth", "Leather", "Mail", "Plate"},
    Legs              = {"All", "Cloth", "Leather", "Mail", "Plate"},
    Feet              = {"All", "Cloth", "Leather", "Mail", "Plate"},
    MainHand          = {"All", "Axe1H", "Mace1H", "Sword1H", "Dagger", "Fist", "Axe2H", "Mace2H", "Sword2H", "Polearm", "Staff", "Fishing"},
    SecondaryHand     = {"All", "Axe1H", "Mace1H", "Sword1H", "Dagger", "Fist", "Shield", "Held", "Axe2H", "Mace2H", "Sword2H", "Polearm", "Staff"},
    Ranged            = {"All", "Bow", "Crossbow", "Gun", "Wand", "Thrown"},
}

-- Default to "All" for all slots to show everything initially
local slotSelectedSubclass = {}
local slotSelectedQuality = {}
local slotSelectedCollectionFilter = {}  -- NEW: Track collection filter per slot
for slotName, subclasses in pairs(SLOT_SUBCLASSES) do
    slotSelectedSubclass[slotName] = "All"
	slotSelectedQuality[slotName] = "All"
    slotSelectedCollectionFilter[slotName] = "Collected"  -- NEW: Default to Collected
end

-- ============================================================================
-- Collection Filter Definitions
-- ============================================================================

local COLLECTION_FILTER_OPTIONS = {
    "All", "Collected", "Uncollected"
}


-- ============================================================================
-- Quality Definitions
-- ============================================================================

-- Quality options with WotLK colors
local QUALITY_OPTIONS = {
    "All", "Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Heirloom", 
}

-- Quality colors (WotLK)
local QUALITY_COLORS = {
    Poor             = "|cff9d9d9d", -- Grey
    Common           = "|cffffffff", -- White
    Uncommon         = "|cff1eff00", -- Green
    Rare             = "|cff0070dd", -- Blue
    Epic             = "|cffa335ee", -- Purple
    Legendary        = "|cffff8000", -- Orange
    Heirloom         = "|cffe6cc80", -- Light Gold
}

-- ============================================================================
-- Collection Data
-- ============================================================================

local collectedAppearances = {}
local activeTransmogs = {}
local isCollectionLoaded = false

-- Cache for server tooltip responses: itemId -> {eligible=bool, collected=bool}
local appearanceCache = {}
local pendingTooltipChecks = {}

-- ============================================================================
-- CLIENT-SIDE ITEM CACHE SYSTEM
-- ============================================================================
-- Items are cached locally with a version number in SavedVariables.
-- If server version matches client version, no retransmission needed.
-- Client filters items locally instead of asking server every time.
-- ============================================================================

-- This will be populated from TransmogDB.itemCache on PLAYER_ENTERING_WORLD
local CLIENT_ITEM_CACHE = {
    version = 0,              -- Cache version from server (0 = no cache)
    isReady = false,          -- Flag indicating cache is loaded
    bySlot = {},              -- Items indexed by slot: bySlot[slotId] = { {itemId, class, subclass, quality, displayId}, ... }
    byDisplayId = {},         -- Items indexed by displayId: byDisplayId[displayId] = { itemId1, itemId2, ... }
    enchants = {},            -- All enchant visuals with version
    enchantVersion = 0,       -- Enchant cache version
}

-- Server settings (populated via RequestSettings)
local SERVER_SETTINGS = {
    hideSlots = {},           -- Slot IDs that allow hiding: hideSlots[slotId] = true
    allowDisplayId = true,    -- Whether display ID transmog is enabled
    isReady = false,          -- Flag indicating settings are loaded
}

-- Pending cache requests tracking
local pendingEnchantCacheRequest = false

-- Forward declaration for ENCHANT_VISUALS (actual declaration is later in the file)
local ENCHANT_VISUALS

-- ============================================================================
-- ITEM INFO PRELOADER SYSTEM
-- ============================================================================
-- Preloads item info for cached items so GetItemInfo works for search
-- Without this, name search only works after hovering over items
-- ============================================================================

local itemInfoPreloader = {
    isRunning = false,
    queue = {},           -- Items waiting to be preloaded
    batchSize = 50,       -- Items per frame (tunable for performance)
    totalItems = 0,
    processedItems = 0,
    scanTooltip = nil,    -- Hidden tooltip for triggering item cache
}

-- Create hidden tooltip for item info preloading
local function GetPreloadScanTooltip()
    if not itemInfoPreloader.scanTooltip then
        itemInfoPreloader.scanTooltip = CreateFrame("GameTooltip", "TransmogItemPreloadTooltip", nil, "GameTooltipTemplate")
        itemInfoPreloader.scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    return itemInfoPreloader.scanTooltip
end

-- Process a batch of items
local function ProcessPreloadBatch()
    if not itemInfoPreloader.isRunning or #itemInfoPreloader.queue == 0 then
        itemInfoPreloader.isRunning = false
        if itemInfoPreloader.processedItems > 0 then
            print(string.format("[Transmog] Item info preload complete: %d items ready for search", itemInfoPreloader.processedItems))
        end
        return
    end
    
    local tooltip = GetPreloadScanTooltip()
    local batchCount = 0
    
    while batchCount < itemInfoPreloader.batchSize and #itemInfoPreloader.queue > 0 do
        local itemId = table.remove(itemInfoPreloader.queue, 1)
        
        -- Try GetItemInfo first (might already be cached)
        local itemName = GetItemInfo(itemId)
        if not itemName then
            -- Not cached - use tooltip to request from server
            tooltip:ClearLines()
            tooltip:SetHyperlink("item:" .. itemId)
        end
        
        itemInfoPreloader.processedItems = itemInfoPreloader.processedItems + 1
        batchCount = batchCount + 1
    end
    
    -- Schedule next batch
    C_Timer.After(0.05, ProcessPreloadBatch)
end

-- Start preloading item info for all cached items
local function PreloadCachedItemInfo()
    if itemInfoPreloader.isRunning then
        return  -- Already running
    end
    
    if not CLIENT_ITEM_CACHE.isReady or not CLIENT_ITEM_CACHE.bySlot then
        return  -- No cache to preload
    end
    
    -- Build queue of all item IDs from cache
    itemInfoPreloader.queue = {}
    itemInfoPreloader.processedItems = 0
    
    for slotId, items in pairs(CLIENT_ITEM_CACHE.bySlot) do
        for _, itemData in ipairs(items) do
            local itemId = itemData[1]
            table.insert(itemInfoPreloader.queue, itemId)
        end
    end
    
    itemInfoPreloader.totalItems = #itemInfoPreloader.queue
    
    if itemInfoPreloader.totalItems > 0 then
        print(string.format("[Transmog] Preloading item info for %d cached items (enables name search)...", itemInfoPreloader.totalItems))
        itemInfoPreloader.isRunning = true
        -- Start processing after a short delay to not interfere with login
        C_Timer.After(1, ProcessPreloadBatch)
    end
end

-- Helper to load cache from SavedVariables
local function LoadCacheFromSavedVariables()
    if TransmogDB then
        -- Load item cache
        if TransmogDB.itemCache then
            CLIENT_ITEM_CACHE.version = TransmogDB.itemCache.version or 0
            CLIENT_ITEM_CACHE.bySlot = TransmogDB.itemCache.bySlot or {}
            CLIENT_ITEM_CACHE.enchants = TransmogDB.itemCache.enchants or {}
            CLIENT_ITEM_CACHE.enchantVersion = TransmogDB.itemCache.enchantVersion or 0
            CLIENT_ITEM_CACHE.isReady = (CLIENT_ITEM_CACHE.version > 0)
            
            if CLIENT_ITEM_CACHE.isReady then
                -- Build byDisplayId index for display ID merging feature
                CLIENT_ITEM_CACHE.byDisplayId = {}
                local slotCount = 0
                local itemCount = 0
                for slotId, items in pairs(CLIENT_ITEM_CACHE.bySlot) do
                    slotCount = slotCount + 1
                    for _, itemData in ipairs(items) do
                        itemCount = itemCount + 1
                        local itemId = itemData[1]
                        local displayId = itemData[5]
                        if displayId and displayId > 0 then
                            if not CLIENT_ITEM_CACHE.byDisplayId[displayId] then
                                CLIENT_ITEM_CACHE.byDisplayId[displayId] = {}
                            end
                            table.insert(CLIENT_ITEM_CACHE.byDisplayId[displayId], itemId)
                        end
                    end
                end
                print(string.format("[Transmog] Loaded item cache from SavedVariables: version=%d, %d slots, %d items, %d enchants",
                    CLIENT_ITEM_CACHE.version, slotCount, itemCount, #CLIENT_ITEM_CACHE.enchants))
            end
            
            -- Also populate ENCHANT_VISUALS from cache for enchant mode
            if CLIENT_ITEM_CACHE.enchants and #CLIENT_ITEM_CACHE.enchants > 0 then
                ENCHANT_VISUALS = CLIENT_ITEM_CACHE.enchants
                print(string.format("[Transmog] Loaded %d enchant visuals from cache", #ENCHANT_VISUALS))
            end
        end
        
        -- Load collection from SavedVariables (fallback when server doesn't send it)
        if TransmogDB.collection then
            local count = 0
            for itemId, _ in pairs(TransmogDB.collection) do
                collectedAppearances[itemId] = true
                count = count + 1
            end
            if count > 0 then
                isCollectionLoaded = true
                print(string.format("[Transmog] Loaded %d collected items from SavedVariables", count))
            end
        end
        
        -- Preload item info for search functionality (if cache is ready)
        if CLIENT_ITEM_CACHE.isReady then
            C_Timer.After(2, PreloadCachedItemInfo)
        end
    end
end

-- Helper to save cache to SavedVariables
local function SaveCacheToSavedVariables()
    TransmogDB = TransmogDB or {}
    TransmogDB.itemCache = {
        version = CLIENT_ITEM_CACHE.version,
        bySlot = CLIENT_ITEM_CACHE.bySlot,
        enchants = CLIENT_ITEM_CACHE.enchants,
        enchantVersion = CLIENT_ITEM_CACHE.enchantVersion,
    }
    
    -- Debug: count what we saved
    local slotCount = 0
    local itemCount = 0
    for slotId, items in pairs(CLIENT_ITEM_CACHE.bySlot) do
        slotCount = slotCount + 1
        itemCount = itemCount + #items
    end
    print(string.format("[Transmog] Saved cache to SavedVariables: version=%d, %d slots, %d items, %d enchants",
        CLIENT_ITEM_CACHE.version, slotCount, itemCount, #CLIENT_ITEM_CACHE.enchants))
end

-- ============================================================================
-- Current UI state (initialized properly in PLAYER_ENTERING_WORLD)
-- ============================================================================

local currentSlot = "Head"
local currentSubclass = "All"  -- TO DO, Currently use "ALL" as default
local currentQuality = "All"
local currentCollectionFilter = "Collected"  -- NEW: Default to Collected
local currentItems = {}
local currentPage = 1
local itemsPerPage = 15

-- Track selected items per slot (cyan border selection)
local slotSelectedItems = {}  -- key: slotName, value: itemId

-- Track selected enchants per slot (cyan border selection in enchant mode)
local slotSelectedEnchants = {}  -- key: slotName, value: enchantId
local selectedEnchantId = nil
local selectedEnchantFrame = nil

-- ============================================================================
-- Set Management Data
-- ============================================================================

local transmogSets = {}  -- Cached sets from server: { [setNumber] = { name = "...", slots = {...} } }
local MAX_SETS = 12
local selectedSetNumber = nil  -- Track currently selected set number

-- ============================================================================
-- Transmog Mode (Item vs Enchantment)
-- ============================================================================

local TRANSMOG_MODE_ITEM = 1
local TRANSMOG_MODE_ENCHANT = 2
local currentTransmogMode = TRANSMOG_MODE_ITEM

-- Slots eligible for enchantment transmog (weapons only)
local ENCHANT_ELIGIBLE_SLOTS = {
    MainHand = true,
    SecondaryHand = true,
}

-- Enchantment collection data
local collectedEnchantments = {}
local activeEnchantTransmogs = {}

-- Enchantment data received from server (populated by AIO handler)
-- Structure: { id = number, itemVisual = number, name = string, icon = string }
ENCHANT_VISUALS = {}

local ENCHANT_CATEGORIES = { "All" }  -- Categories will be populated from server data
local currentEnchantCategory = "All"

-- Forward declarations for functions used by AIO handlers
local UpdatePreviewGrid
local UpdateSlotButtonIcons
local UpdateSetDropdown
local UpdateEnchantGrid
local UpdateCollectionFilterDropdown  -- NEW
local modeToggleButton
local collectionFilterDropdown  -- NEW: Reference to the dropdown

-- ============================================================================
-- C_Timer Polyfill
-- ============================================================================

if not C_Timer then
    C_Timer = {}
    function C_Timer.After(seconds, func)
        local frame = CreateFrame("Frame")
        local elapsed = 0
        frame:SetScript("OnUpdate", function(self, delta)
            elapsed = elapsed + delta
            if elapsed >= seconds then
                func()
                self:SetScript("OnUpdate", nil)
                self:Hide()
            end
        end)
    end
end

-- ============================================================================
-- Collection Functions
-- ============================================================================

local function IsAppearanceCollected(itemId)
    -- Check runtime cache first
    if collectedAppearances[itemId] == true then
        return true
    end
    -- Fallback to SavedVariables
    if TransmogDB and TransmogDB.collection and TransmogDB.collection[itemId] == true then
        -- Sync to runtime cache
        collectedAppearances[itemId] = true
        return true
    end
    return false
end

local function MarkAppearanceCollected(itemId)
    collectedAppearances[itemId] = true
    TransmogDB.collection = TransmogDB.collection or {}
    TransmogDB.collection[itemId] = true
end

local function GetCollectionCount()
    local count = 0
    for _ in pairs(collectedAppearances) do
        count = count + 1
    end
    return count
end

-- Get display ID for an item from cache
local function GetDisplayIdForItem(itemId)
    if CLIENT_ITEM_CACHE.isReady then
        for slotId, items in pairs(CLIENT_ITEM_CACHE.bySlot) do
            for _, itemData in ipairs(items) do
                if itemData[1] == itemId then
                    return itemData[5]  -- displayId is at index 5
                end
            end
        end
    end
    return nil
end

-- Get all items sharing the same display ID
local function GetSharedAppearanceItems(itemId)
    if not CLIENT_ITEM_CACHE.isReady then
        return nil
    end
    
    local displayId = GetDisplayIdForItem(itemId)
    if not displayId or displayId == 0 then
        return nil
    end
    
    local sharedItems = CLIENT_ITEM_CACHE.byDisplayId[displayId]
    if sharedItems and #sharedItems > 1 then
        return sharedItems
    end
    
    return nil
end

-- Check if any item with the same display ID is collected
-- Returns: hasCollected (bool), collectedItemId (number or nil)
local function HasCollectedAppearanceByDisplayId(itemId)
    if not CLIENT_ITEM_CACHE.isReady then
        return false, nil
    end
    
    local displayId = GetDisplayIdForItem(itemId)
    if not displayId or displayId == 0 then
        return false, nil
    end
    
    local sharedItems = CLIENT_ITEM_CACHE.byDisplayId[displayId]
    if not sharedItems then
        return false, nil
    end
    
    for _, sharedItemId in ipairs(sharedItems) do
        if IsAppearanceCollected(sharedItemId) then
            return true, sharedItemId
        end
    end
    
    return false, nil
end

-- Check if an appearance is available (either exact item or shared display ID)
-- Returns: isAvailable (bool), itemIdToUse (number - the collected item ID to use)
local function IsAppearanceAvailable(itemId)
    -- First check exact item
    if IsAppearanceCollected(itemId) then
        return true, itemId
    end
    
    -- Then check by display ID if setting enabled
    if IsSettingEnabled("mergeByDisplayId") then
        local hasShared, collectedItemId = HasCollectedAppearanceByDisplayId(itemId)
        if hasShared then
            return true, collectedItemId
        end
    end
    
    return false, nil
end

-- Add shared appearance lines to a tooltip for a given itemId
local function AddSharedAppearanceToTooltip(tooltip, itemId, settingKey)
    if not IsSettingEnabled(settingKey) then
        return
    end
    
    local sharedItems = GetSharedAppearanceItems(itemId)
    if not sharedItems or #sharedItems <= 1 then
        return
    end
    
    tooltip:AddLine(" ")
    tooltip:AddLine(L["SHARED_APPEARANCE"] or "|cffFFD700Appearance shared on items:|r")
    
    for _, sharedItemId in ipairs(sharedItems) do
        local itemName, _, itemQuality = GetItemInfo(sharedItemId)
        local isItemCollected = IsAppearanceCollected(sharedItemId)
        
        if itemName then
            if isItemCollected then
                -- Use quality color for collected items
                local color = ITEM_QUALITY_COLORS[itemQuality or 1]
                if color then
                    tooltip:AddLine(string.format("  %s", itemName), color.r, color.g, color.b)
                else
                    tooltip:AddLine(string.format("  %s", itemName), 1, 1, 1)
                end
            else
                -- Grey for uncollected items
                tooltip:AddLine(string.format("  %s", itemName), 0.5, 0.5, 0.5)
            end
        else
            -- Item info not loaded yet, show item ID
            if isItemCollected then
                tooltip:AddLine(string.format("  [Item %d]", sharedItemId), 0.7, 0.7, 0.7)
            else
                tooltip:AddLine(string.format("  [Item %d]", sharedItemId), 0.4, 0.4, 0.4)
            end
        end
    end
end

local function RequestCollectionFromServer()
    AIO.Msg():Add("TRANSMOG", "RequestCollection"):Send()
end

local function RequestActiveTransmogsFromServer()
    AIO.Msg():Add("TRANSMOG", "RequestActiveTransmogs"):Send()
end

-- ============================================================================
-- CLIENT-SIDE CACHE FUNCTIONS
-- ============================================================================
-- These functions handle the cache-based system for optimal performance.
-- Instead of asking the server for filtered items, we:
-- 1. Download the full item cache once (versioned, stored in SavedVariables)
-- 2. Download player's collection status (small payload)
-- 3. Filter items locally on the client
-- ============================================================================

-- Subclass name to ID mappings (must match server)
local ARMOR_SUBCLASS = {
    ["Miscellaneous"] = 0,
    ["Cloth"]         = 1,
    ["Leather"]       = 2,
    ["Mail"]          = 3,
    ["Plate"]         = 4,
    ["Shield"]        = 6,
}

local WEAPON_SUBCLASS = {
    ["Axe1H"]    = 0,
    ["Axe2H"]    = 1,
    ["Bow"]      = 2,
    ["Gun"]      = 3,
    ["Mace1H"]   = 4,
    ["Mace2H"]   = 5,
    ["Polearm"]  = 6,
    ["Sword1H"]  = 7,
    ["Sword2H"]  = 8,
    ["Staff"]    = 10,
    ["Fist"]     = 13,
    ["Dagger"]   = 15,
    ["Thrown"]   = 16,
    ["Crossbow"] = 18,
    ["Wand"]     = 19,
    ["Fishing"]  = 20,
}

-- Quality name to ID mapping
local QUALITY_NAME_TO_ID = {
    ["Poor"]      = 0,
    ["Common"]    = 1,
    ["Uncommon"]  = 2,
    ["Rare"]      = 3,
    ["Epic"]      = 4,
    ["Legendary"] = 5,
    ["Heirloom"]  = 6,
}

-- Track if we're currently requesting full cache
local pendingFullCacheRequest = false

-- Request FULL cache from server (all slots at once)
-- Called once on login - server sends all items, client stores in SavedVariables
local function RequestFullCacheFromServer()
    if pendingFullCacheRequest then
        return  -- Already requesting
    end
    
    pendingFullCacheRequest = true
    local clientVersion = CLIENT_ITEM_CACHE.version or 0
    print(string.format("[Transmog] Requesting full cache from server (client version: %d)", clientVersion))
    AIO.Msg():Add("TRANSMOG", "RequestFullCache", clientVersion):Send()
end

-- Request enchant cache from server (only if version differs)
local function RequestEnchantCacheFromServer()
    if pendingEnchantCacheRequest then
        return  -- Already requesting
    end
    
    pendingEnchantCacheRequest = true
    local clientVersion = CLIENT_ITEM_CACHE.enchantVersion or 0
    AIO.Msg():Add("TRANSMOG", "RequestEnchantCache", clientVersion):Send()
end

-- Request collection status from server (player's owned items - small payload)
local function RequestCollectionStatusFromServer()
    AIO.Msg():Add("TRANSMOG", "RequestCollectionStatus"):Send()
end

local function RequestSettingsFromServer()
    AIO.Msg():Add("TRANSMOG", "RequestSettings"):Send()
end

-- Check if we have cache for a specific slot
local function HasSlotCache(slotId)
    local hasItems = CLIENT_ITEM_CACHE.bySlot[slotId] and #CLIENT_ITEM_CACHE.bySlot[slotId] > 0
    -- SecondaryHand (16) can also use MainHand (15) items
    if slotId == 16 and not hasItems then
        hasItems = CLIENT_ITEM_CACHE.bySlot[15] and #CLIENT_ITEM_CACHE.bySlot[15] > 0
    end
    return hasItems
end

-- Check if full cache is ready (all slots loaded)
local function IsFullCacheReady()
    return CLIENT_ITEM_CACHE.isReady and CLIENT_ITEM_CACHE.version > 0
end

-- LOCAL FILTERING: Filter cached items by subclass, quality, and collection status
-- This is the key performance improvement - filtering happens on client, not server
local function FilterCachedItemsForSlot(slotId, subclassName, qualityName, collectionFilter)
    local cachedItems = CLIENT_ITEM_CACHE.bySlot[slotId]
    if not cachedItems then
        cachedItems = {}
    end
    
    -- SecondaryHand (slot 16) should also show MainHand items (slot 15) for transmog
    -- This allows players to use main hand weapon appearances in off-hand slot
    if slotId == 16 then  -- SecondaryHand equipSlot
        local mainHandItems = CLIENT_ITEM_CACHE.bySlot[15]  -- MainHand equipSlot
        if mainHandItems then
            -- Combine both tables
            local combinedItems = {}
            for _, item in ipairs(cachedItems) do
                table.insert(combinedItems, item)
            end
            for _, item in ipairs(mainHandItems) do
                table.insert(combinedItems, item)
            end
            cachedItems = combinedItems
        end
    end
    
    if #cachedItems == 0 then
        return {}
    end
    
    -- Check if merge by display ID is enabled
    local mergeByDisplayId = GetSetting("mergeByDisplayId") == true
    
    -- Determine subclass filter
    local filterClass, filterSubclass
    if subclassName and subclassName ~= "" and subclassName ~= "All" then
        if ARMOR_SUBCLASS[subclassName] then
            filterClass = 4  -- Armor class
            filterSubclass = ARMOR_SUBCLASS[subclassName]
        elseif WEAPON_SUBCLASS[subclassName] then
            filterClass = 2  -- Weapon class
            filterSubclass = WEAPON_SUBCLASS[subclassName]
        end
    end
    
    -- Determine quality filter
    local filterQuality
    if qualityName and qualityName ~= "" and qualityName ~= "All" then
        filterQuality = QUALITY_NAME_TO_ID[qualityName]
    end
    
    -- Determine collection filter
    local showCollected = (collectionFilter == "All" or collectionFilter == "Collected")
    local showUncollected = (collectionFilter == "All" or collectionFilter == "Uncollected")
    
    -- Helper function to check if an item is collected
    local function IsItemCollected(itemId)
        if collectedAppearances[itemId] == true then
            return true
        end
        if TransmogDB and TransmogDB.collection and TransmogDB.collection[itemId] == true then
            collectedAppearances[itemId] = true
            return true
        end
        return false
    end
    
    if mergeByDisplayId then
        -- MERGE MODE: Group items by display ID
        local displayIdGroups = {}  -- displayId -> { items = {itemId1, itemId2, ...}, quality = quality, hasCollected = bool, collectedItemId = itemId }
        local displayIdOrder = {}   -- Track order of first appearance
        
        for _, itemData in ipairs(cachedItems) do
            local itemId = itemData[1]
            local itemClass = itemData[2]
            local itemSubclass = itemData[3]
            local itemQuality = itemData[4]
            local displayId = itemData[5]
            
            -- Apply subclass filter
            local passSubclass = true
            if filterClass and filterSubclass then
                passSubclass = (itemClass == filterClass and itemSubclass == filterSubclass)
            end
            
            -- Apply quality filter
            local passQuality = true
            if filterQuality then
                passQuality = (itemQuality == filterQuality)
            end
            
            if passSubclass and passQuality and displayId and displayId > 0 then
                if not displayIdGroups[displayId] then
                    displayIdGroups[displayId] = {
                        items = {},
                        quality = itemQuality,
                        hasCollected = false,
                        collectedItemId = nil,
                        representativeItemId = itemId,
                    }
                    table.insert(displayIdOrder, displayId)
                end
                
                local group = displayIdGroups[displayId]
                table.insert(group.items, itemId)
                
                -- Check if this item is collected
                local isCollected = IsItemCollected(itemId)
                if isCollected then
                    group.hasCollected = true
                    -- Use first collected item as representative
                    if not group.collectedItemId then
                        group.collectedItemId = itemId
                        group.representativeItemId = itemId
                    end
                end
            end
        end
        
        -- Build result: collected first, then uncollected
        local collectedItems = {}
        local uncollectedItems = {}
        
        for _, displayId in ipairs(displayIdOrder) do
            local group = displayIdGroups[displayId]
            local isCollected = group.hasCollected
            
            local item = {
                itemId = group.representativeItemId,
                collected = isCollected,
                displayId = displayId,
                sharedItems = group.items,  -- All items sharing this display ID
                collectedItemId = group.collectedItemId,  -- The collected item if any
            }
            
            if isCollected and showCollected then
                table.insert(collectedItems, item)
            elseif not isCollected and showUncollected then
                table.insert(uncollectedItems, item)
            end
        end
        
        -- Combine: collected first, then uncollected
        local result = {}
        
        -- Add "Hide" option at the beginning if allowed for this slot
        if SERVER_SETTINGS.isReady and SERVER_SETTINGS.hideSlots[slotId] then
            table.insert(result, { itemId = 0, collected = true, displayId = 0, isHideOption = true })
        end
        
        for _, item in ipairs(collectedItems) do
            table.insert(result, item)
        end
        for _, item in ipairs(uncollectedItems) do
            table.insert(result, item)
        end
        
        return result
    else
        -- NORMAL MODE: Each item is separate
        local collectedItems = {}
        local uncollectedItems = {}
        
        for _, itemData in ipairs(cachedItems) do
            local itemId = itemData[1]
            local itemClass = itemData[2]
            local itemSubclass = itemData[3]
            local itemQuality = itemData[4]
            local displayId = itemData[5]
            
            -- Apply subclass filter
            local passSubclass = true
            if filterClass and filterSubclass then
                passSubclass = (itemClass == filterClass and itemSubclass == filterSubclass)
            end
            
            -- Apply quality filter
            local passQuality = true
            if filterQuality then
                passQuality = (itemQuality == filterQuality)
            end
            
            local isCollected = IsItemCollected(itemId)
            
            -- Apply all filters
            if passSubclass and passQuality then
                if isCollected and showCollected then
                    table.insert(collectedItems, { itemId = itemId, collected = true, displayId = displayId })
                elseif not isCollected and showUncollected then
                    table.insert(uncollectedItems, { itemId = itemId, collected = false, displayId = displayId })
                end
            end
        end
        
        -- Combine: collected first, then uncollected
        local result = {}
        
        -- Add "Hide" option at the beginning if allowed for this slot
        if SERVER_SETTINGS.isReady and SERVER_SETTINGS.hideSlots[slotId] then
            table.insert(result, { itemId = 0, collected = true, displayId = 0, isHideOption = true })
        end
        
        for _, item in ipairs(collectedItems) do
            table.insert(result, item)
        end
        for _, item in ipairs(uncollectedItems) do
            table.insert(result, item)
        end
        
        return result
    end
end

-- Get items for slot using local cache with filtering
-- Get filtered items from local cache
-- Returns nil if cache is not ready
local function GetFilteredItemsFromCache(slotId, subclassName, qualityName, collectionFilter)
    if IsFullCacheReady() and HasSlotCache(slotId) then
        -- Use local cache and filter - NO server request
        return FilterCachedItemsForSlot(slotId, subclassName, qualityName, collectionFilter)
    else
        return nil  -- Cache not ready
    end
end

-- Helper function to load items for a slot using local cache
-- This is the main function to call when changing slots/filters
-- ALL filtering is done locally - NO server requests for filtering
local function LoadItemsForSlot(slotId, subclassName, qualityName, collectionFilter)
    if IsFullCacheReady() then
        -- Use local cache - instant filtering, NO server request
        local cachedItems = FilterCachedItemsForSlot(slotId, subclassName, qualityName, collectionFilter)
        currentItems = cachedItems or {}
        currentPage = 1
        UpdatePreviewGrid()
        
        -- Update page text
        local totalPages = math.max(1, math.ceil(#currentItems / itemsPerPage))
        if mainFrame and mainFrame.pageText then
            mainFrame.pageText:SetText(string.format(L["PAGE"], currentPage, totalPages))
        end
    else
        -- Cache not ready - request full cache if not already pending
        currentItems = {}
        currentPage = 1
        UpdatePreviewGrid()
        
        if mainFrame and mainFrame.pageText then
            mainFrame.pageText:SetText("Loading cache...")
        end
        
        if not pendingFullCacheRequest then
            RequestFullCacheFromServer()
        end
    end
end

-- ============================================================================
-- Set Management Functions
-- ============================================================================

local function RequestSetsFromServer()
    AIO.Msg():Add("TRANSMOG", "RequestSets"):Send()
end

local function SaveSetToServer(setNumber, setName)
    -- Gather currently selected items from slotSelectedItems
    local slotData = {}
    for slotName, itemId in pairs(slotSelectedItems) do
        local equipSlot = SLOT_NAME_TO_EQUIP_SLOT[slotName]
        if equipSlot and itemId then
            slotData[equipSlot] = itemId
        end
    end
    AIO.Msg():Add("TRANSMOG", "SaveSet", setNumber, setName, slotData):Send()
end

local function LoadSetFromServer(setNumber)
    AIO.Msg():Add("TRANSMOG", "LoadSet", setNumber):Send()
end

local function DeleteSetFromServer(setNumber)
    AIO.Msg():Add("TRANSMOG", "DeleteSet", setNumber):Send()
end

local function ApplySetToServer(setNumber)
    AIO.Msg():Add("TRANSMOG", "ApplySet", setNumber):Send()
end

-- ============================================================================
-- AIO Handlers
-- ============================================================================

local TRANSMOG_HANDLER = AIO.AddHandlers("TRANSMOG", {})

-- ============================================================================
-- NEW: Full Cache AIO Handlers
-- ============================================================================

-- Buffer for accumulating full cache chunks
local fullCacheBuffer = {}
local fullCacheTotalChunks = 0
local fullCacheReceivedChunks = 0
local fullCacheVersion = 0

-- Full cache data received (chunked) - ALL slots at once
TRANSMOG_HANDLER.FullCacheData = function(player, data)
    if not data then return end
    
    local chunk = data.chunk or 1
    local totalChunks = data.totalChunks or 1
    
    -- Initialize on first chunk
    if chunk == 1 then
        fullCacheBuffer = {}
        fullCacheTotalChunks = totalChunks
        fullCacheReceivedChunks = 0
        fullCacheVersion = data.version
        print(string.format("[Transmog] Receiving full cache (version %d, %d chunks)", data.version, totalChunks))
    end
    
    -- Accumulate items: each item is {slotId, itemId, class, subclass, quality, displayId}
    if data.items then
        for _, itemData in ipairs(data.items) do
            local slotId = itemData[1]
            if not fullCacheBuffer[slotId] then
                fullCacheBuffer[slotId] = {}
            end
            -- Store as {itemId, class, subclass, quality, displayId}
            table.insert(fullCacheBuffer[slotId], {
                itemData[2],  -- itemId
                itemData[3],  -- class
                itemData[4],  -- subclass
                itemData[5],  -- quality
                itemData[6]   -- displayId
            })
        end
    end
    
    fullCacheReceivedChunks = fullCacheReceivedChunks + 1
    
    -- Show loading progress
    if mainFrame and mainFrame.pageText then
        mainFrame.pageText:SetText(string.format("Loading cache... %d/%d", 
            fullCacheReceivedChunks, fullCacheTotalChunks))
    end
    
    -- When all chunks received, store in cache
    if fullCacheReceivedChunks >= fullCacheTotalChunks then
        CLIENT_ITEM_CACHE.bySlot = fullCacheBuffer
        CLIENT_ITEM_CACHE.version = fullCacheVersion
        CLIENT_ITEM_CACHE.isReady = true
        pendingFullCacheRequest = false
        
        -- Build byDisplayId index for display ID merging feature
        CLIENT_ITEM_CACHE.byDisplayId = {}
        local totalItems = 0
        local slotCount = 0
        for slotId, items in pairs(fullCacheBuffer) do
            slotCount = slotCount + 1
            for _, itemData in ipairs(items) do
                totalItems = totalItems + 1
                local itemId = itemData[1]
                local displayId = itemData[5]
                if displayId and displayId > 0 then
                    if not CLIENT_ITEM_CACHE.byDisplayId[displayId] then
                        CLIENT_ITEM_CACHE.byDisplayId[displayId] = {}
                    end
                    table.insert(CLIENT_ITEM_CACHE.byDisplayId[displayId], itemId)
                end
            end
        end
        
        print(string.format("[Transmog] Full cache complete: %d items across %d slots (version %d)", 
            totalItems, slotCount, fullCacheVersion))
        
        -- Clear buffer
        fullCacheBuffer = {}
        fullCacheTotalChunks = 0
        fullCacheReceivedChunks = 0
        
        -- Save to SavedVariables
        SaveCacheToSavedVariables()
        
        -- Preload item info for search functionality
        PreloadCachedItemInfo()
        
        -- Update the display using local filtering
        local currentSlotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
        if currentSlotId then
            currentItems = FilterCachedItemsForSlot(currentSlotId, currentSubclass, currentQuality, currentCollectionFilter)
            currentPage = 1
            UpdatePreviewGrid()
            
            local totalPages = math.max(1, math.ceil(#currentItems / itemsPerPage))
            if mainFrame and mainFrame.pageText then
                mainFrame.pageText:SetText(string.format(L["PAGE"], currentPage, totalPages))
            end
        end
    end
end

-- Full cache is already up to date
TRANSMOG_HANDLER.FullCacheUpToDate = function(player, data)
    pendingFullCacheRequest = false
    print(string.format("[Transmog] Cache is up to date (version %d)", data and data.version or CLIENT_ITEM_CACHE.version))
    
    -- Use existing cache for display
    local currentSlotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
    if currentSlotId and IsFullCacheReady() then
        currentItems = FilterCachedItemsForSlot(currentSlotId, currentSubclass, currentQuality, currentCollectionFilter)
        currentPage = 1
        UpdatePreviewGrid()
    end
end

-- Full cache not ready on server
TRANSMOG_HANDLER.FullCacheNotReady = function(player, data)
    pendingFullCacheRequest = false
    print("[Transmog] Server cache not ready yet - please try again shortly")
    
    if mainFrame and mainFrame.pageText then
        mainFrame.pageText:SetText("Server cache building... please wait")
    end
end

-- Collection status received (player's owned items - compact)
TRANSMOG_HANDLER.CollectionStatus = function(player, data)
    if not data then return end
    
    -- Clear on first chunk
    if data.chunk == 1 then
        collectedAppearances = {}
        TransmogDB = TransmogDB or {}
        TransmogDB.collection = {}
    end
    
    -- Add items to collection (both runtime and SavedVariables)
    for _, itemId in ipairs(data.items or {}) do
        collectedAppearances[itemId] = true
        TransmogDB.collection[itemId] = true
    end
    
    -- When all chunks received
    if data.chunk == data.totalChunks then
        isCollectionLoaded = true
        print(string.format(L["COLLECTION_LOADED"], GetCollectionCount()))
        
        -- If we have cached items for current slot, re-filter with updated collection
        local currentSlotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
        if HasSlotCache(currentSlotId) then
            currentItems = FilterCachedItemsForSlot(currentSlotId, currentSubclass, currentQuality, currentCollectionFilter)
            UpdatePreviewGrid()
        end
    end
end

-- Enchant cache data received
TRANSMOG_HANDLER.EnchantCacheData = function(player, data)
    if not data then return end
    
    local chunk = data.chunk or 1
    local totalChunks = data.totalChunks or 1
    
    -- Initialize on first chunk
    if chunk == 1 then
        CLIENT_ITEM_CACHE.enchants = {}
    end
    
    -- Accumulate enchants
    for _, enchant in ipairs(data.enchants or {}) do
        table.insert(CLIENT_ITEM_CACHE.enchants, enchant)
    end
    
    -- When all chunks received
    if chunk >= totalChunks then
        CLIENT_ITEM_CACHE.enchantVersion = data.version
        ENCHANT_VISUALS = CLIENT_ITEM_CACHE.enchants
        pendingEnchantCacheRequest = false
        
        print(string.format("[Transmog] Cached %d enchant visuals", #ENCHANT_VISUALS))
        
        -- Save to SavedVariables
        SaveCacheToSavedVariables()
        
        -- Update enchant grid if in enchant mode
        if currentTransmogMode == TRANSMOG_MODE_ENCHANT then
            UpdateEnchantGrid()
        end
    end
end

-- Enchant cache up to date
TRANSMOG_HANDLER.EnchantCacheUpToDate = function(player, data)
    pendingEnchantCacheRequest = false
    -- Use existing cache
    if #CLIENT_ITEM_CACHE.enchants > 0 then
        ENCHANT_VISUALS = CLIENT_ITEM_CACHE.enchants
    end
end

-- Enchant cache not ready
TRANSMOG_HANDLER.EnchantCacheNotReady = function(player, data)
    pendingEnchantCacheRequest = false
    -- Fall back to legacy request
    RequestEnchantCollectionFromServer()
end

-- ============================================================================
-- Legacy Handlers (kept for backwards compatibility)
-- ============================================================================

-- NOTE: SearchResults handler removed - client uses local cache filtering

-- Error handler for server-side errors
TRANSMOG_HANDLER.Error = function(player, errorCode)
    local errorMessages = {
        ["INVALID_SLOT"] = L["INVALID_SLOT"] or "Invalid slot",
        ["INVALID_SLOT_OR_ITEM"] = L["INVALID_SLOT_OR_ITEM"] or "Invalid slot or item",
        ["INVALID_SLOT_OR_ENCHANT"] = L["INVALID_SLOT_OR_ENCHANT"] or "Invalid slot or enchant",
        ["SLOT_NOT_ENCHANT_ELIGIBLE"] = L["SLOT_NOT_ENCHANT_ELIGIBLE"] or "This slot cannot have enchant transmog",
        ["INVALID_ENCHANT_ID"] = L["INVALID_ENCHANT_ID"] or "Invalid enchant ID",
        ["ENCHANT_CACHE_NOT_READY"] = L["ENCHANT_CACHE_NOT_READY"] or "Enchant cache not ready, please wait",
        ["NOT_IN_COLLECTION"] = L["NOT_IN_COLLECTION"] or "Appearance not in collection",
        ["ITEM_NOT_ELIGIBLE"] = L["ITEM_NOT_ELIGIBLE"] or "Item not eligible for transmog",
        ["HIDE_NOT_ALLOWED"] = L["HIDE_NOT_ALLOWED"] or "Hiding is not allowed for this slot",
        ["SHARED_DISPLAY_ID_BLOCKED"] = L["SHARED_DISPLAY_ID_BLOCKED"] or "This appearance shares a display with uncollected items",
    }
    
    local message = errorMessages[errorCode] or errorCode
    print(string.format("|cffFF0000[Transmog] %s|r", message))
end

-- Receive server settings (hide slots config, etc.)
TRANSMOG_HANDLER.Settings = function(player, data)
    if not data then return end
    
    -- Reset hide slots
    SERVER_SETTINGS.hideSlots = {}
    
    -- Populate hide slots lookup table
    if data.hideSlots then
        for _, slotId in ipairs(data.hideSlots) do
            SERVER_SETTINGS.hideSlots[slotId] = true
        end
    end
    
    -- Store other settings
    if data.allowDisplayId ~= nil then
        SERVER_SETTINGS.allowDisplayId = data.allowDisplayId
    end
    
    SERVER_SETTINGS.isReady = true
    
    print(string.format("[Transmog] Settings loaded: %d slots allow hiding", #(data.hideSlots or {})))
end

TRANSMOG_HANDLER.CollectionData = function(player, data)
    if data.chunk == 1 then
        collectedAppearances = {}
        TransmogDB = TransmogDB or {}
        TransmogDB.collection = {}
    end
    
    for _, itemId in ipairs(data.items) do
        collectedAppearances[itemId] = true
        TransmogDB.collection[itemId] = true
    end
    
    if data.chunk == data.totalChunks then
        isCollectionLoaded = true
        print(string.format(L["COLLECTION_LOADED"], GetCollectionCount()))
    end
end

-- Forward declaration for RefreshDressingRoomModel (defined later after mainFrame declaration)
local RefreshDressingRoomModel

TRANSMOG_HANDLER.ActiveTransmogs = function(player, data)
    activeTransmogs = data or {}
    
    -- Update slot button icons after receiving active transmogs
    C_Timer.After(0, function()
        UpdateSlotButtonIcons()
    end)
end

TRANSMOG_HANDLER.Applied = function(player, data)
    if data then
        activeTransmogs[data.slot] = data.itemId
        print(L["TRANSMOG_APPLIED"])
        
        -- Update slot button icons
        UpdateSlotButtonIcons()
        -- Update grid to show highlight
        UpdatePreviewGrid()
        
        -- Refresh dressing room model
        RefreshDressingRoomModel()
    end
end

TRANSMOG_HANDLER.Removed = function(player, slot)
    activeTransmogs[slot] = nil
    print(L["TRANSMOG_REMOVED"])
    
    -- Update slot button icons
    UpdateSlotButtonIcons()
    -- Update grid to remove highlight
    UpdatePreviewGrid()
    
    -- Refresh dressing room model
    RefreshDressingRoomModel()
end


TRANSMOG_HANDLER.AppearanceCheck = function(player, data)
    if not data or not data.itemId then return end
    
    -- Cache the server response (eligibility + collected status)
    appearanceCache[data.itemId] = {
        eligible = data.eligible or false,
        collected = data.collected or false
    }
    pendingTooltipChecks[data.itemId] = nil
    
    if data.collected then
        collectedAppearances[data.itemId] = true
        TransmogDB.collection = TransmogDB.collection or {}
        TransmogDB.collection[data.itemId] = true
    end
end

-- NOTE: AppearanceCheckBulk handler removed - client uses local cache

-- New appearance unlocked notification
TRANSMOG_HANDLER.NewAppearance = function(player, data)
    if not data or not data.itemId then return end
    
    -- Add to local collection cache
    collectedAppearances[data.itemId] = true
    TransmogDB.collection = TransmogDB.collection or {}
    TransmogDB.collection[data.itemId] = true
    
    -- Update appearance cache
    appearanceCache[data.itemId] = { eligible = true, collected = true }
    
    -- Get item name for display
    local itemName, itemLink = GetItemInfo(data.itemId)
    if itemLink then
        print(string.format("|cffFFD700%s|r %s", L["NEW_APPEARANCE_UNLOCKED"], itemLink))
    else
        -- Item not in cache, queue for later
        local tooltip = CreateFrame("GameTooltip", "TransmogNewAppearanceTooltip", nil, "GameTooltipTemplate")
        tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
        tooltip:SetHyperlink("item:" .. data.itemId)
        
        C_Timer.After(0.5, function()
            local name, link = GetItemInfo(data.itemId)
            if link then
                print(string.format("|cffFFD700%s|r %s", L["NEW_APPEARANCE_UNLOCKED"], link))
            else
                print(string.format("|cffFFD700%s|r [Item %d]", L["NEW_APPEARANCE_UNLOCKED"], data.itemId))
            end
        end)
    end
end

-- Retroactive unlock notification (from completed quests scan)
TRANSMOG_HANDLER.RetroactiveUnlock = function(player, count)
    if count and count > 0 then
        print(string.format("|cff00ff00[Transmog]|r %s", string.format(L["RETROACTIVE_UNLOCKED"], count)))
        -- Request fresh collection data
        RequestCollectionFromServer()
    end
end

-- NOTE: SlotItems handler removed - client uses local cache filtering

-- ============================================================================
-- Set Management AIO Handlers
-- ============================================================================

TRANSMOG_HANDLER.SetsData = function(player, data)
    if not data then return end
    transmogSets = data or {}
    
    -- Update dropdown if it exists
    C_Timer.After(0, function()
        if UpdateSetDropdown then
            UpdateSetDropdown()
        end
        -- Refresh sets preview panel if visible
        if setsPreviewPanel and setsPreviewPanel:IsShown() then
            setsPreviewPanel:RefreshSetsPreview()
        end
    end)
end

TRANSMOG_HANDLER.SetSaved = function(player, data)
    if not data then return end
    
    -- Update local cache
    transmogSets[data.setNumber] = {
        name = data.setName,
        slots = data.slots or {}
    }
    
    print(string.format(L["SET_SAVED"], data.setName))
    
    -- Update dropdown
    if UpdateSetDropdown then
        UpdateSetDropdown()
    end
    
    -- Refresh sets preview panel if visible
    if setsPreviewPanel and setsPreviewPanel:IsShown() then
        setsPreviewPanel:RefreshSetsPreview()
    end
end

TRANSMOG_HANDLER.SetLoaded = function(player, data)
    if not data then return end
    
    local setData = data.slots or {}
    
    -- Clear current selections
    slotSelectedItems = {}
    
    -- Apply loaded set items to preview and selection
    for slotName, config in pairs(SLOT_CONFIG) do
        local equipSlot = config.equipSlot
        local itemId = setData[equipSlot]
        if itemId and itemId > 0 then
            slotSelectedItems[slotName] = itemId
        end
    end
    
    -- Update dressing room model with loaded set items for preview
    RefreshDressingRoomModel(slotSelectedItems)
    
    -- Update grid to show cyan highlights
    UpdatePreviewGrid()
    
    print(string.format(L["SET_LOADED"], data.setName or "Set"))
end

TRANSMOG_HANDLER.SetDeleted = function(player, data)
    if not data then return end
    
    -- Clear selection if this was the selected set
    if selectedSetNumber == data.setNumber then
        selectedSetNumber = nil
    end
    
    transmogSets[data.setNumber] = nil
    print(string.format(L["SET_DELETED"], data.setNumber))
    
    -- Update dropdown
    if UpdateSetDropdown then
        UpdateSetDropdown()
    end
    
    -- Refresh sets preview panel if visible
    if setsPreviewPanel and setsPreviewPanel:IsShown() then
        setsPreviewPanel:RefreshSetsPreview()
    end
end

TRANSMOG_HANDLER.SetApplied = function(player, data)
    if not data then return end
    
    -- Update active transmogs with applied set
    if data.appliedSlots then
        for slot, itemId in pairs(data.appliedSlots) do
            activeTransmogs[slot] = itemId
        end
    end
    
    print(string.format(L["SET_APPLIED"], data.setName or "Set"))
    
    -- Update UI
    UpdateSlotButtonIcons()
    UpdatePreviewGrid()
    
    -- Refresh dressing room model
    RefreshDressingRoomModel()
end

TRANSMOG_HANDLER.SetError = function(player, errorMsg)
    print(string.format("|cffff0000[Transmog]|r %s", errorMsg or L["SET_ERROR"]))
end

-- Copy Player Appearance Handler
TRANSMOG_HANDLER.PlayerAppearanceCopied = function(player, data)
    if not data then return end
    
    if data.error then
        print(string.format("|cffff0000[Transmog]|r %s", data.error))
        return
    end
    
    -- Clear current selections
    slotSelectedItems = {}
    
    -- Apply copied items to preview selection
    local copiedCount = 0
    for slotName, config in pairs(SLOT_CONFIG) do
        local equipSlot = config.equipSlot
        local itemId = data.slots and data.slots[equipSlot]
        if itemId and itemId > 0 then
            slotSelectedItems[slotName] = itemId
            copiedCount = copiedCount + 1
        end
    end
    
    -- Update dressing room with copied appearance
    RefreshDressingRoomModel(slotSelectedItems)
    
    -- Update grid to show cyan highlights
    UpdatePreviewGrid()
    
    -- Show success message
    print(string.format(L["COPY_PLAYER_SUCCESS"] or "|cff00ff00[Transmog]|r Copied %d items from %s's appearance.", copiedCount, data.playerName or "player"))
    print(L["COPY_PLAYER_HINT"] or "|cff00ff00[Transmog]|r Use the Save button to save this as a set.")
end

-- ============================================================================
-- Enchantment AIO Handlers
-- ============================================================================

TRANSMOG_HANDLER.EnchantCollectionData = function(player, data)
    if not data then return end
    if data.chunk == 1 then
        collectedEnchantments = {}
        ENCHANT_VISUALS = {}  -- Reset the enchant list
    end
    
    -- Receive enchant data from server
    for _, enchant in ipairs(data.enchants or {}) do
        -- Structure: { id, itemVisual, name, icon }
        table.insert(ENCHANT_VISUALS, {
            id = enchant.id,
            itemVisual = enchant.itemVisual,
            name = enchant.name,
            icon = enchant.icon
        })
        collectedEnchantments[enchant.id] = true
    end
    
    if data.chunk == data.totalChunks then
        print(string.format("|cff00ff00[Transmog]|r Loaded %d enchant visuals", #ENCHANT_VISUALS))
        -- Update grid if in enchant mode
        if currentTransmogMode == TRANSMOG_MODE_ENCHANT then
            UpdateEnchantGrid()
        end
    end
end

TRANSMOG_HANDLER.ActiveEnchantTransmogs = function(player, data)
    activeEnchantTransmogs = data or {}
    C_Timer.After(0, function()
        UpdateSlotButtonIcons()
    end)
end

TRANSMOG_HANDLER.EnchantApplied = function(player, data)
    if data then
        activeEnchantTransmogs[data.slot] = data.visualId
        print("|cff00ff00[Transmog]|r Enchant visual applied!")
        UpdateSlotButtonIcons()
        if UpdateEnchantGrid then UpdateEnchantGrid() end
    end
end

TRANSMOG_HANDLER.EnchantRemoved = function(player, slot)
    activeEnchantTransmogs[slot] = nil
    print("|cff00ff00[Transmog]|r Enchant visual removed")
    UpdateSlotButtonIcons()
    if UpdateEnchantGrid then UpdateEnchantGrid() end
end

-- ============================================================================
-- Enchantment Helper Functions
-- ============================================================================

local function RequestEnchantCollectionFromServer()
    AIO.Msg():Add("TRANSMOG", "RequestEnchantCollection"):Send()
end

local function RequestActiveEnchantTransmogsFromServer()
    AIO.Msg():Add("TRANSMOG", "RequestActiveEnchantTransmogs"):Send()
end

local function ApplyEnchantTransmog(slotName, enchantId)
    local slotId = SLOT_NAME_TO_EQUIP_SLOT[slotName]
    if slotId then
        AIO.Msg():Add("TRANSMOG", "ApplyEnchantTransmog", slotId, enchantId):Send()
    end
end

local function RemoveEnchantTransmog(slotName)
    local slotId = SLOT_NAME_TO_EQUIP_SLOT[slotName]
    if slotId then
        AIO.Msg():Add("TRANSMOG", "RemoveEnchantTransmog", slotId):Send()
    end
end

local function GetFilteredEnchantVisuals(category)
    -- Return all enchants since we no longer have categories from server
    return ENCHANT_VISUALS
end

-- ============================================================================
-- Transmog Application Functions
-- ============================================================================

local function ApplyTransmog(slotName, itemId)
    local slotId = SLOT_NAME_TO_EQUIP_SLOT[slotName]
    if not slotId then return end
    
    AIO.Msg():Add("TRANSMOG", "ApplyTransmog", slotId, itemId):Send()
end

local function RemoveTransmog(slotName)
    local slotId = SLOT_NAME_TO_EQUIP_SLOT[slotName]
    if not slotId then return end
    
    AIO.Msg():Add("TRANSMOG", "RemoveTransmog", slotId):Send()
end

local function GetActiveTransmog(slotName)
    local slotId = SLOT_NAME_TO_EQUIP_SLOT[slotName]
    if not slotId then return nil end
    return activeTransmogs[slotId]
end

-- ============================================================================
-- Tooltip Hook - Server-driven eligibility with deduplication
-- ============================================================================

-- Track which tooltips have already been processed for which item to avoid duplicates
local tooltipProcessedItem = {}

local function OnTooltipSetItem(tooltip)
    local _, link = tooltip:GetItem()
    if not link then return end
    
    local itemId = tonumber(link:match("item:(%d+)"))
    if not itemId then return end
    
    -- Deduplication: check if we already processed this exact item on this tooltip
    local tooltipName = tooltip:GetName() or tostring(tooltip)
    if tooltipProcessedItem[tooltipName] == itemId then
        return  -- Already added our lines, skip
    end
    tooltipProcessedItem[tooltipName] = itemId
    
    -- Check cache first
    local cached = appearanceCache[itemId]
    if cached then
        if not cached.eligible then return end
        if cached.collected then
            if IsSettingEnabled("showCollectedTooltip") then
                tooltip:AddLine(L["APPEARANCE_COLLECTED"])
            end
        else
            if IsSettingEnabled("showNewAppearanceTooltip") then
                tooltip:AddLine(L["NEW_APPEARANCE"])
            end
        end
        -- Add shared appearance info
        AddSharedAppearanceToTooltip(tooltip, itemId, "showSharedAppearanceTooltip")
        tooltip:Show()
        return
    end
    
    -- Check local collection (from SavedVariables/runtime cache)
    if IsAppearanceCollected(itemId) then
        if IsSettingEnabled("showCollectedTooltip") then
            tooltip:AddLine(L["APPEARANCE_COLLECTED"])
        end
    else
        if IsSettingEnabled("showNewAppearanceTooltip") then
            tooltip:AddLine(L["NEW_APPEARANCE"])
        end
    end
    
    -- Add shared appearance info
    AddSharedAppearanceToTooltip(tooltip, itemId, "showSharedAppearanceTooltip")
    tooltip:Show()
    
    -- Not in cache - ask server (only once per item per session)
    if not pendingTooltipChecks[itemId] then
        pendingTooltipChecks[itemId] = true
        AIO.Msg():Add("TRANSMOG", "CheckAppearance", itemId):Send()
    end
end

-- Clear deduplication tracking when tooltip is hidden
local function OnTooltipCleared(tooltip)
    local tooltipName = tooltip:GetName() or tostring(tooltip)
    tooltipProcessedItem[tooltipName] = nil
end

GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
ItemRefTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
ItemRefTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
ShoppingTooltip1:HookScript("OnTooltipSetItem", OnTooltipSetItem)
ShoppingTooltip1:HookScript("OnTooltipCleared", OnTooltipCleared)
ShoppingTooltip2:HookScript("OnTooltipSetItem", OnTooltipSetItem)
ShoppingTooltip2:HookScript("OnTooltipCleared", OnTooltipCleared)

-- Hook AtlasLoot tooltips if available (delayed to ensure addon is loaded)
local function HookAtlasLootTooltips()
    -- AtlasLoot uses AtlasLootTooltip
    if AtlasLootTooltip then
        AtlasLootTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
        AtlasLootTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
    end
    -- Some versions use GameTooltip but we already hooked that
end

-- Try to hook AtlasLoot tooltips after a delay
local atlasHookFrame = CreateFrame("Frame")
atlasHookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
atlasHookFrame:SetScript("OnEvent", function(self, event)
    C_Timer.After(2, HookAtlasLootTooltips)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)

-- Also hook any tooltip that sets an item via SetHyperlink (catches most addon tooltips)
local function HookSetHyperlink(tooltip)
    local originalSetHyperlink = tooltip.SetHyperlink
    if originalSetHyperlink then
        tooltip.SetHyperlink = function(self, link, ...)
            originalSetHyperlink(self, link, ...)
            if link then
                local itemId = tonumber(link:match("item:(%d+)"))
                if itemId then
                    OnTooltipSetItem(self)
                end
            end
        end
    end
end

-- Hook SetHyperlink on main tooltips
HookSetHyperlink(GameTooltip)
HookSetHyperlink(ItemRefTooltip)

-- ============================================================================
-- Frame References
-- ============================================================================

local mainFrame
local dressingRoom
local slotButtons = {}
local itemFrames = {}
local subclassDropdown
local qualityDropdown

-- ============================================================================
-- Dressing Room Model Refresh Helper
-- ============================================================================

-- Refreshes dressing room model with current equipped gear + active transmogs
-- @param previewItems: optional table of {slotName = itemId} for preview mode (e.g., loaded set)
RefreshDressingRoomModel = function(previewItems)
    -- Wait for mainFrame to be initialized
    if not mainFrame or not mainFrame.dressingRoom then
        return
    end
    
    local mdl = mainFrame.dressingRoom.model
    if not mdl then return end
    
    -- Reset position first
    mdl:SetFacing(0)
    mdl:SetPosition(0, 0, 0)
    
    C_Timer.After(0.01, function()
        mdl:SetUnit("player")
        
        if previewItems then
            -- Preview mode: undress and show only preview items
            mdl:Undress()
            C_Timer.After(0.05, function()
                for slotName, itemId in pairs(previewItems) do
                    if itemId then
                        mdl:TryOn(itemId)
                    end
                end
                mdl:SetPosition(0, 0, 0)
                mdl:SetFacing(0)
            end)
        else
            -- Normal mode: show equipped gear + active transmogs
            C_Timer.After(0.05, function()
                for slotId, itemId in pairs(activeTransmogs) do
                    if itemId then
                        mdl:TryOn(itemId)
                    end
                end
                mdl:SetPosition(0, 0, 0)
                mdl:SetFacing(0)
            end)
        end
    end)
end

-- ============================================================================
-- Camera Functions
-- ============================================================================

local function IsWeaponSubclass(subclass)
    local weaponTypes = {
        Axe1H = true, Mace1H = true, Sword1H = true,
        Dagger = true, Fist = true,
        Axe2H = true, Mace2H = true, Sword2H = true,
        Polearm = true, Staff = true,
        Shield = true, Held = true,
        Bow = true, Crossbow = true, Gun = true,
        Wand = true, Thrown = true,
    }
    return weaponTypes[subclass] or false
end

-- Preview setup version: "classic" for old models, "hd" for HD models
local previewSetupVersion = "classic"  -- Will be updated from settings

-- Function to update preview mode from settings
local function UpdatePreviewMode()
    previewSetupVersion = GetSetting("previewMode") or "classic"
end

-- Get preview setup from database
local function GetPreviewSetup(slotName, subclass)
    -- Check if RACE_CAMERA is loaded
    if not Transmog.RACE_CAMERA then return nil end
    
    local versionData = Transmog.RACE_CAMERA[previewSetupVersion]
    if not versionData then return nil end
    
    -- Try player's race first, then fallback to race 0
    local raceData = versionData[playerRaceId] or versionData[0]
    if not raceData then return nil end
    
    local genderData = raceData[playerGender]
    if not genderData then return nil end
    
    -- Determine category based on slot
    local config = SLOT_CONFIG[slotName]
    if not config then return nil end
    
    if config.category == "armor" then
        -- Armor slots: lookup in genderData.Armor[slot]
        if genderData.Armor and genderData.Armor[slotName] then
            return genderData.Armor[slotName]
        end
    else
        -- Weapon slots: lookup based on slot type
        if slotName == "MainHand" and genderData.MainHand then
            return genderData.MainHand[subclass]
        elseif slotName == "SecondaryHand" and genderData.OffHand then
            return genderData.OffHand[subclass]
        elseif slotName == "Ranged" and genderData.Ranged then
            return genderData.Ranged[subclass]
        end
    end
    
    return nil
end

local function GetCameraForSlot(slotName)
    local subclass = slotSelectedSubclass[slotName]
    
    -- Get from RACE_CAMERA (Grid-Preview-DB has fallback at race 0)
    local dbSetup = GetPreviewSetup(slotName, subclass)
    if dbSetup then
        return dbSetup
    end
    
    -- Ultimate fallback if Grid-Preview-DB not loaded or missing setting
    return { width = 150, height = 100, x =  1.7000, y = -0.2517, z =  0.2074, facing =  1.4368, sequence =  3 }
end

-- ============================================================================
-- Get Items for Slot
-- ============================================================================

local function GetItemsForSlotAndSubclass(slotName, subclass)
    -- Items are loaded from local cache (no server request)
    local slotId = SLOT_NAME_TO_EQUIP_SLOT[slotName]
    if CLIENT_ITEM_CACHE.isReady and CLIENT_ITEM_CACHE.bySlot[slotId] then
        return CLIENT_ITEM_CACHE.bySlot[slotId]
    end
    return {}
end

-- ============================================================================
-- Item Preview Frame
-- ============================================================================

-- Add tracking for currently selected item
local selectedItemId = nil
local selectedItemFrame = nil

local function CreateItemFrame(parent, index)
    local frame = CreateFrame("Frame", "$parentItem"..index, parent)
    frame:SetSize(100, 120)
    
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(0.15, 0.15, 0.15, 1)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    local model = CreateFrame("DressUpModel", "$parentModel", frame)
    model:SetPoint("TOPLEFT", 4, -4)
    model:SetPoint("BOTTOMRIGHT", -4, 4)
    model:SetUnit("player")
    frame.model = model
    
    local collectedIcon = frame:CreateTexture(nil, "OVERLAY")
    collectedIcon:SetSize(16, 16)
    collectedIcon:SetPoint("TOPRIGHT", -2, -2)
    collectedIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    collectedIcon:Hide()
    frame.collectedIcon = collectedIcon
    
    local newIcon = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    newIcon:SetPoint("TOPLEFT", 4, -4)
    newIcon:SetText("|cffFFD700NEW|r")
    newIcon:Hide()
    frame.newIcon = newIcon
    
    -- Active transmog indicator
    local activeGlow = frame:CreateTexture(nil, "OVERLAY")
    activeGlow:SetPoint("CENTER")
    activeGlow:SetBlendMode("ADD")
    activeGlow:SetVertexColor(0, 1, 0, 0.8) -- green
    activeGlow:Hide()
    frame.activeGlow = activeGlow
    
    local activeText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    activeText:SetPoint("BOTTOM", 0, 6)
    activeText:SetText(L["TRANSMOG_SLOT_ACTIVE"])
    activeText:Hide()
    frame.activeText = activeText
    
    local btn = CreateFrame("Button", "$parentButton", frame)
    btn:SetAllPoints()
    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame.button = btn
    
    frame.freezeSequence = 0
    frame.itemId = nil
    frame.displayId = nil
    frame.isLoaded = false
 
    -- Selection highlight border
    local selectionBorder = frame:CreateTexture(nil, "OVERLAY")
    selectionBorder:SetAllPoints()
    selectionBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    selectionBorder:SetBlendMode("ADD")
    selectionBorder:SetVertexColor(0, 1, 1, 0.7)  -- Cyan color
    selectionBorder:Hide()
    frame.selectionBorder = selectionBorder
	
    btn:SetScript("OnClick", function(self, button)
        local f = self:GetParent()
        
        -- Handle enchant mode
        if f.enchantMode and f.enchantData then
            local enchantData = f.enchantData
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    -- Shift+Left click: Apply enchant transmog
                    ApplyEnchantTransmog(currentSlot, enchantData.id)
                    PlaySound("igCharacterInfoTab")
                else
                    -- Left click: Select enchant with cyan highlight
                    -- Clear previous selection for all enchant frames
                    for _, itemFrame in ipairs(itemFrames) do
                        if itemFrame.enchantMode and itemFrame.selectionBorder then
                            -- Clear selection border (may still show active border via backdrop)
                            itemFrame.selectionBorder:Hide()
                            -- Restore backdrop border based on active state
                            if itemFrame.isActive then
                                itemFrame:SetBackdropBorderColor(1, 0.4, 0.7, 1)  -- Pink for active
                            else
                                itemFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)  -- Default gray
                            end
                        end
                    end
                    
                    -- Store selection for this slot
                    slotSelectedEnchants[currentSlot] = enchantData.id
                    selectedEnchantId = enchantData.id
                    selectedEnchantFrame = f
                    f.selectionBorder:Show()
                    
                    -- Set backdrop border - active takes priority over selected
                    if f.isActive then
                        f:SetBackdropBorderColor(1, 0.4, 0.7, 1)  -- Pink for active
                    else
                        f:SetBackdropBorderColor(0, 1, 1, 1)  -- Cyan for selected
                    end
                    
                    PlaySound("igMainMenuOptionCheckBoxOn")
                    
                end
            elseif button == "RightButton" then
                local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
                if activeEnchantTransmogs[slotId] then
                    RemoveEnchantTransmog(currentSlot)
                    PlaySound("igMainMenuOptionCheckBoxOn")
                end
            end
            return
        end
        
        -- Handle "Hide" option
        if f.isHideOption and f.isLoaded then
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    -- Apply hide transmog (itemId = 0)
                    ApplyTransmog(currentSlot, 0)
                    PlaySound("igMainMenuOptionCheckBoxOn")
                else
                    -- Select hide option
                    slotSelectedItems[currentSlot] = 0
                    selectedItemId = 0
                    selectedItemFrame = f
                    f.selectionBorder:Show()
                    f:SetBackdropBorderColor(0, 1, 1, 1)  -- Cyan for selected
                    
                    if dressingRoom then
                        -- Undress the slot to preview hide
                        local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
                        if slotId then
                            dressingRoom:UndressSlot(slotId + 1)  -- WoW slots are 1-indexed for UndressSlot
                        end
                        PlaySound("igMainMenuOptionCheckBoxOn")
                    end
                end
            end
            return
        end
        
        -- Normal item mode
        if f.itemId and f.isLoaded then
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    -- Clear selection for this slot when applying
                    slotSelectedItems[currentSlot] = nil
                    selectedItemId = nil
                    selectedItemFrame = nil
                    
                    -- Clear cyan borders from all visible item frames
                    for _, itemFrame in ipairs(itemFrames) do
                        if itemFrame.selectionBorder then
                            itemFrame.selectionBorder:Hide()
                        end
                    end
                    
                    -- Determine which item ID to use for transmog
                    -- Priority: 1) frame.collectedItemId (merge mode), 2) IsAppearanceAvailable check, 3) original itemId
                    local transmogItemId = f.itemId
                    if f.collectedItemId and f.collectedItemId > 0 then
                        -- Merge mode: use the stored collected item ID
                        transmogItemId = f.collectedItemId
                    else
                        -- Non-merge mode: check if we have a shared appearance collected
                        local isAvailable, availableItemId = IsAppearanceAvailable(f.itemId)
                        if isAvailable and availableItemId then
                            transmogItemId = availableItemId
                        end
                    end
                    
                    -- Let server validate collection status (respects ALLOW_UNCOLLECTED_TRANSMOG setting)
                    ApplyTransmog(currentSlot, transmogItemId)
                else
                    -- Clear previous selection for this slot from ALL item frames
                    for _, itemFrame in ipairs(itemFrames) do
                        if itemFrame.itemId and itemFrame.selectionBorder then
                            itemFrame.selectionBorder:Hide()
                            -- Restore backdrop border based on active state
                            if itemFrame.isActive then
                                itemFrame:SetBackdropBorderColor(0, 1, 0, 1)  -- Green for active
                            else
                                itemFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)  -- Default gray
                            end
                        end
                    end
                    
                    -- Store selection for this slot
                    slotSelectedItems[currentSlot] = f.itemId
                    selectedItemId = f.itemId
                    selectedItemFrame = f
                    f.selectionBorder:Show()
                    
                    -- Set backdrop border - active takes priority over selected
                    if f.isActive then
                        f:SetBackdropBorderColor(0, 1, 0, 1)  -- Green for active
                    else
                        f:SetBackdropBorderColor(0, 1, 1, 1)  -- Cyan for selected
                    end
                    
                    if dressingRoom then
                        PlaySound("igMainMenuOptionCheckBoxOn")
                        dressingRoom.model:TryOn(f.itemId)
                    end
                end
            end
        end
    end)
    
    btn:SetScript("OnEnter", function(self)
        local f = self:GetParent()
        
        -- Handle enchant mode tooltip
        if f.enchantMode and f.enchantData then
            local enchantData = f.enchantData
            GameTooltip:SetOwner(f, "ANCHOR_TOPRIGHT")
            GameTooltip:SetText(enchantData.name)
            GameTooltip:AddLine("Visual ID: " .. (enchantData.itemVisual or "?"), 0.5, 0.5, 0.5)
            GameTooltip:AddLine(" ")
            local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
            if activeEnchantTransmogs[slotId] == enchantData.id then
                GameTooltip:AddLine(L["ENCHANT_ACTIVE"] or "|cffff66b2Currently Active|r")
                GameTooltip:AddLine(L["CLEAR_ENCHANT"] or "|cffff0000Right-click to remove|r", 1, 1, 1)
            else
                GameTooltip:AddLine(L["APPLY_ENCHANT_SHIFT_CLICK"] or "|cff00ff00Shift+Click:|r Apply", 1, 1, 1)
            end
            GameTooltip:Show()
            -- Only highlight on hover if not active and not selected
            local isEnchantSelected = (slotSelectedEnchants[currentSlot] == enchantData.id)
            if not f.isActive and not isEnchantSelected then
                f:SetBackdropBorderColor(1, 1, 1, 1)
            end
            return
        end
        
        -- Handle "Hide" option specially
        if f.isHideOption then
            GameTooltip:SetOwner(f, "ANCHOR_TOPRIGHT")
            GameTooltip:SetText(L["HIDE_APPEARANCE"] or "Hide Appearance", 1, 1, 1)
            GameTooltip:AddLine(L["HIDE_APPEARANCE_DESC"] or "Make this equipment slot invisible", 0.7, 0.7, 0.7, true)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["APPLY_APPEARANCE_SHIFT_CLICK"] or "Shift+Click to apply", 0.7, 0.7, 0.7)
            GameTooltip:Show()
            if not f.isActive then
                f:SetBackdropBorderColor(1, 1, 1, 1)
            end
            return
        end
        
        -- Normal item mode tooltip
        if f.itemId and f.isLoaded then
            GameTooltip:SetOwner(f, "ANCHOR_TOPRIGHT")
            GameTooltip:SetHyperlink("item:"..f.itemId)
            
            -- Add Item ID and Display ID for cross-locale sharing (if enabled)
            if IsSettingEnabled("showItemIdTooltip") then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(string.format("Item ID: %d", f.itemId), 0.6, 0.6, 0.6)
            end
            if f.displayId and IsSettingEnabled("showDisplayIdTooltip") then
                GameTooltip:AddLine(string.format("Display ID: %d", f.displayId), 0.6, 0.6, 0.6)
            end
            
            -- Check if appearance is available (exact item or shared display ID)
            local isAvailable, _ = IsAppearanceAvailable(f.itemId)
            
            -- Grid-specific action hints
            GameTooltip:AddLine(" ")
            if isAvailable then
                GameTooltip:AddLine(L["APPLY_APPEARANCE_SHIFT_CLICK"], 0.7, 0.7, 0.7)
            end
            GameTooltip:AddLine(L["PREVIEW_APPEARANCE_CLICK"], 0.7, 0.7, 0.7)
            
            -- Add selection hint if not selected
            if f.itemId ~= selectedItemId then
                GameTooltip:AddLine(L["SELECT_ITEM_CLICK"], 0.5, 1, 0.5)  -- Light green hint
            end
            
            GameTooltip:Show()
        end
        
        -- Highlight border on mouseover (only if not active and not selected)
        if not f.isActive and f.itemId ~= selectedItemId then
            f:SetBackdropBorderColor(1, 1, 1, 1)
        end
    end)
    
    btn:SetScript("OnLeave", function(self)
        local f = self:GetParent()
        GameTooltip:Hide()
        
        -- Handle enchant mode
        if f.enchantMode then
            local isEnchantSelected = f.enchantData and (slotSelectedEnchants[currentSlot] == f.enchantData.id)
            if f.isActive then
                f:SetBackdropBorderColor(1, 0.4, 0.7, 1)  -- Pink for active enchant
            elseif isEnchantSelected then
                f:SetBackdropBorderColor(0, 1, 1, 1)  -- Cyan for selected enchant
            else
                f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)  -- Default gray
            end
            return
        end
        
        -- Restore border based on state for item mode
        -- Priority: Active (green) > Selected (cyan) > Default (gray)
        if f.isActive then
            f:SetBackdropBorderColor(0, 1, 0, 1)  -- Green for active
        elseif f.itemId == selectedItemId then
            f:SetBackdropBorderColor(0, 1, 1, 1)  -- Cyan for selected
        else
            f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)  -- Default gray
        end
    end)
    
    return frame
end

local function SetupItemModel(frame, slotName)
    local cam = GetCameraForSlot(slotName)
    local model = frame.model
    
    model:SetPosition(0, 0, 0)
    model:SetFacing(0)
    model:ClearModel()
    model:SetUnit("player")
    model:Undress()
    
    -- Handle hair/beard hiding for specific slots using helmet items
    -- Item 12185 = Bloodsail Admiral's Hat (hides hair only)
    -- Item 16026 = Judgement Helm replica (hides hair + beard)
    if slotName == "Back" and GetSetting("hideHairOnCloakPreview") == true then
        model:TryOn(12185)  -- Hide hair only for cloaks
    elseif slotName == "Chest" and GetSetting("hideHairOnChestPreview") == true then
        model:TryOn(16026)  -- Hide hair + beard for chests	
    elseif slotName == "Shirt" and GetSetting("hideHairOnShirtPreview") == true then
        model:TryOn(16026)  -- Hide hair + beard for shirts
    elseif slotName == "Tabard" and GetSetting("hideHairOnTabardPreview") == true then
        model:TryOn(16026)  -- Hide hair + beard for tabards
    end
    
    model:SetPosition(cam.x, cam.y, cam.z)
    model:SetFacing(cam.facing)
    model:TryOn(frame.itemId)
    
    frame.freezeSequence = cam.sequence or 0
    model:SetScript("OnUpdateModel", function(self)
        self:SetSequence(frame.freezeSequence)
    end)
    
    frame.isLoaded = true
    
    -- Check if this is the active transmog for current slot
    local slotId = SLOT_NAME_TO_EQUIP_SLOT[slotName]
    local activeItemId = activeTransmogs[slotId]
    local isActive = (activeItemId and activeItemId == frame.itemId)
    frame.isActive = isActive
    
    -- Check if this item is selected for this slot
    local isSelected = (slotSelectedItems[slotName] and slotSelectedItems[slotName] == frame.itemId)
    
    -- Handle selection border - show if selected (regardless of active state)
    if isSelected then
        frame.selectionBorder:Show()
        selectedItemFrame = frame
        selectedItemId = frame.itemId
    else
        frame.selectionBorder:Hide()
    end
    
    -- Handle active state - backdrop border color takes priority
    -- Priority for backdrop border: Active (green) > Selected (cyan) > Default (gray)
    if isActive then
        -- Active transmog gets green backdrop border
        frame.activeGlow:Show()
        frame.activeText:Show()
        frame:SetBackdropBorderColor(0, 1, 0, 1)
        frame:SetBackdropColor(0.1, 0.2, 0.1, 1)
    elseif isSelected then
        -- Selected but not active gets cyan backdrop border
        frame.activeGlow:Hide()
        frame.activeText:Hide()
        frame:SetBackdropBorderColor(0, 1, 1, 1)
        frame:SetBackdropColor(0.15, 0.15, 0.15, 1)
    else
        -- Not active and not selected
        frame.activeGlow:Hide()
        frame.activeText:Hide()
        frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        frame:SetBackdropColor(0.15, 0.15, 0.15, 1)
    end
    
    local isCollected = frame.isCollected
    if isCollected == nil then
        -- Check if available via exact item or shared display ID
        local isAvailable, _ = IsAppearanceAvailable(frame.itemId)
        isCollected = isAvailable
    end
    if isCollected then
        frame.collectedIcon:Show()
        frame.newIcon:Hide()
        model:SetAlpha(1.0)
    else
        frame.collectedIcon:Hide()
        frame.newIcon:Show()
        model:SetAlpha(0.5)
        if not isActive then
            -- Grey/desaturated styling for uncollected items
            frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
            frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end
    end
end

local function UpdateItemFrame(frame, itemData, slotName)
    -- Handle both old format (just itemId) and new format (table with itemId, collected, displayId)
    local itemId, isCollected, displayId, sharedItems, collectedItemId, isHideOption
    if type(itemData) == "table" then
        itemId = itemData.itemId
        isCollected = itemData.collected
        displayId = itemData.displayId
        sharedItems = itemData.sharedItems  -- For mergeByDisplayId mode
        collectedItemId = itemData.collectedItemId  -- The collected item in the group
        isHideOption = itemData.isHideOption  -- Special "Hide" option
    else
        itemId = itemData
        -- Check if available via exact item or shared display ID
        local isAvailable, availableItemId = IsAppearanceAvailable(itemId)
        isCollected = isAvailable
        displayId = nil  -- Legacy format has no displayId
        sharedItems = nil
        collectedItemId = availableItemId  -- Store the collected item ID for transmog
        isHideOption = false
    end
    
    frame.itemId = itemId
    frame.displayId = displayId  -- Store displayId for tooltip
    frame.isCollected = isCollected
    frame.sharedItems = sharedItems  -- Store for tooltip display
    frame.collectedItemId = collectedItemId  -- Store for transmog application
    frame.isHideOption = isHideOption  -- Store hide option flag
    frame.isLoaded = false
    frame.model:SetScript("OnUpdateModel", nil)
    frame.collectedIcon:Hide()
    frame.newIcon:Hide()
    frame.selectionBorder:Hide()  -- Always hide selection border initially
    
    -- Special handling for "Hide" option
    if isHideOption then
        frame.model:ClearModel()
        frame:Show()
        frame.isLoaded = true
        
        -- Show a "hidden/invisible" icon texture instead of model
        if not frame.hideIcon then
            local hideIcon = frame:CreateTexture(nil, "ARTWORK")
            hideIcon:SetPoint("CENTER", 0, 0)
            hideIcon:SetSize(48, 48)
            -- Use a cancel/hide icon - INV_Misc_QuestionMark works as placeholder
            hideIcon:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-LeaveItem-Transparent")
            frame.hideIcon = hideIcon
        end
        frame.hideIcon:Show()
        frame.model:Hide()
        
        -- Mark as collected (always available)
        frame.collectedIcon:Show()
        
        return
    end
    
    -- Hide the hideIcon if it exists (for normal items)
    if frame.hideIcon then
        frame.hideIcon:Hide()
    end
    frame.model:Show()
    
    if itemId then
        frame.model:ClearModel()
        frame:Show()
        
        local name = GetItemInfo(itemId)
        if name then
            SetupItemModel(frame, slotName)
        else
            local tooltip = CreateFrame("GameTooltip", "TransmogScanTooltip"..itemId, nil, "GameTooltipTemplate")
            tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
            tooltip:SetHyperlink("item:"..itemId)
            
            C_Timer.After(0.0, function()
                if frame.itemId == itemId then
                    SetupItemModel(frame, slotName)
                end
            end)
        end
    else
        frame:Hide()
    end
end

-- ============================================================================
-- Preview Grid
-- ============================================================================

local GRID_WIDTH = 620
local GRID_HEIGHT = 460
local GRID_SPACING = 4
local SCROLLBAR_WIDTH = 20

local GRID_LAYOUT = {
    armor = { cols = 5, rows = 4 },
    weapon = { cols = 4, rows = 4 },
}

local function CalculateGridLayout()
    local subclass = currentSubclass
    local isWeapon = IsWeaponSubclass(subclass)
    local layout = isWeapon and GRID_LAYOUT.weapon or GRID_LAYOUT.armor
    local cols, rows = layout.cols, layout.rows
    local availableWidth = GRID_WIDTH - SCROLLBAR_WIDTH - GRID_SPACING
    local itemWidth = math.floor((availableWidth - (cols - 1) * GRID_SPACING) / cols)
    local itemHeight = math.floor((GRID_HEIGHT - (rows - 1) * GRID_SPACING) / rows)
    return cols, rows, itemWidth, itemHeight
end

local gridScrollbar

UpdatePreviewGrid = function()
    -- Safety check - don't run if UI not created yet
    if not itemFrames or #itemFrames == 0 then return end
    
    -- Handle enchant mode separately
    if currentTransmogMode == TRANSMOG_MODE_ENCHANT then
        UpdateEnchantGrid()
        return
    end
    
    local cols, rows, itemWidth, itemHeight = CalculateGridLayout()
    itemsPerPage = cols * rows
    
    for _, frame in ipairs(itemFrames) do
        frame:Hide()
        frame.enchantMode = nil
        frame.enchantData = nil
        -- Hide enchant-specific elements when returning to item mode
        if frame.enchantIcon then frame.enchantIcon:Hide() end
        if frame.enchantName then frame.enchantName:Hide() end
        -- Show model again for item mode
        if frame.model then frame.model:Show() end
    end
    
    local startIndex = (currentPage - 1) * itemsPerPage + 1
    local endIndex = math.min(startIndex + itemsPerPage - 1, #currentItems)
    
    local gridIndex = 1
    for i = startIndex, endIndex do
        local itemData = currentItems[i]
        local frame = itemFrames[gridIndex]
        
        if frame and itemData then
            frame:SetSize(itemWidth, itemHeight)
            local col = (gridIndex - 1) % cols
            local row = math.floor((gridIndex - 1) / cols)
            local x = col * (itemWidth + GRID_SPACING)
            local y = -row * (itemHeight + GRID_SPACING)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", x, y)
            -- NEW: Pass entire itemData (which may be table with collected status)
            UpdateItemFrame(frame, itemData, currentSlot)
            gridIndex = gridIndex + 1
        end
    end

    -- Clear selection if selected item is no longer in current view
    if selectedItemId and slotSelectedItems[currentSlot] then
        local found = false
        for i = startIndex, endIndex do
            local itemData = currentItems[i]
            local itemId = type(itemData) == "table" and itemData.itemId or itemData
            if itemId == slotSelectedItems[currentSlot] then
                found = true
                break
            end
        end
        
        if not found then
            selectedItemId = nil
            selectedItemFrame = nil
        end
    end
    
    local totalPages = math.max(1, math.ceil(#currentItems / itemsPerPage))
    if gridScrollbar then
        gridScrollbar:SetMinMaxValues(1, math.max(1, totalPages))
        gridScrollbar:SetValue(currentPage)
    end
    
    if mainFrame and mainFrame.pageText then
        mainFrame.pageText:SetText(string.format(L["PAGE"], currentPage, totalPages))
    end
end

-- ============================================================================
-- Enchant Grid Display
-- ============================================================================

local currentEnchantPage = 1

UpdateEnchantGrid = function()
    if not itemFrames or #itemFrames == 0 then return end
    
    local enchantList = GetFilteredEnchantVisuals(currentEnchantCategory)
    local cols, rows, itemWidth, itemHeight = CalculateGridLayout()
    local enchantPerPage = cols * rows
    
    for _, frame in ipairs(itemFrames) do
        frame:Hide()
        frame.enchantMode = nil
        frame.enchantData = nil
    end
    
    local startIndex = (currentEnchantPage - 1) * enchantPerPage + 1
    local endIndex = math.min(startIndex + enchantPerPage - 1, #enchantList)
    
    local currentSlotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
    local activeEnchantId = activeEnchantTransmogs[currentSlotId]
    
    local gridIndex = 1
    for i = startIndex, endIndex do
        local enchantData = enchantList[i]
        local frame = itemFrames[gridIndex]
        
        if frame and enchantData then
            frame:SetSize(itemWidth, itemHeight)
            local col = (gridIndex - 1) % cols
            local row = math.floor((gridIndex - 1) / cols)
            local x = col * (itemWidth + GRID_SPACING)
            local y = -row * (itemHeight + GRID_SPACING)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", x, y)
            
            -- Mark frame as enchant mode
            frame.enchantMode = true
            frame.enchantData = enchantData
            frame.itemId = nil
            frame.displayId = nil
            
            -- Hide model, show icon instead
            if frame.model then frame.model:Hide() end
            
            -- Create or update enchant icon
            if not frame.enchantIcon then
                frame.enchantIcon = frame:CreateTexture(nil, "ARTWORK")
                frame.enchantIcon:SetSize(itemWidth - 20, itemWidth - 20)
                frame.enchantIcon:SetPoint("TOP", 0, -10)
            end
            frame.enchantIcon:SetTexture(enchantData.icon)
            frame.enchantIcon:Show()
            
            -- Create or update enchant name
            if not frame.enchantName then
                frame.enchantName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                frame.enchantName:SetPoint("BOTTOM", 0, 8)
                frame.enchantName:SetWidth(itemWidth - 8)
            end
            frame.enchantName:SetText(enchantData.name)
            frame.enchantName:Show()
            
            -- Set border color - use pink (1, 0.4, 0.7) for active, cyan for selected
            local isActive = (activeEnchantId == enchantData.id)
            local isSelected = (slotSelectedEnchants[currentSlot] == enchantData.id)
            frame.isActive = isActive
            
            -- Handle selection border - show if selected (regardless of active state)
            if isSelected then
                if frame.selectionBorder then frame.selectionBorder:Show() end
            else
                if frame.selectionBorder then frame.selectionBorder:Hide() end
            end
            
            -- Handle backdrop border color - priority: Active (pink) > Selected (cyan) > Default (gray)
            if isActive then
                frame:SetBackdropBorderColor(1, 0.4, 0.7, 1)  -- Pink for active enchant
                frame:SetBackdropColor(0.2, 0.1, 0.15, 1)    -- Slight pink background
            elseif isSelected then
                frame:SetBackdropBorderColor(0, 1, 1, 1)  -- Cyan for selected
                frame:SetBackdropColor(0.1, 0.15, 0.15, 1)  -- Slight cyan background
            else
                frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                frame:SetBackdropColor(0.15, 0.15, 0.15, 1)
            end
            
            if frame.collectedIcon then frame.collectedIcon:Hide() end
            if frame.activeText then frame.activeText:Hide() end
            if frame.newIcon then frame.newIcon:Hide() end
            
            frame:Show()
            gridIndex = gridIndex + 1
        end
    end
    
    local totalPages = math.max(1, math.ceil(#enchantList / enchantPerPage))
    if gridScrollbar then
        gridScrollbar:SetMinMaxValues(1, math.max(1, totalPages))
        gridScrollbar:SetValue(currentEnchantPage)
    end
    
    if mainFrame and mainFrame.pageText then
        mainFrame.pageText:SetText(string.format(L["PAGE"], currentEnchantPage, totalPages) .. 
            " | " .. (L["ENCHANT_MODE"] or "Enchant Mode"))
    end
end

local function CreatePreviewGrid(parent)
    local frame = CreateFrame("Frame", "$parentPreviewGrid", parent)
    frame:SetSize(GRID_WIDTH, GRID_HEIGHT)
    
    local maxItems = 20
    for i = 1, maxItems do
        local itemFrame = CreateItemFrame(frame, i)
        itemFrame:Hide()
        itemFrames[i] = itemFrame
    end
    
    local scrollFrame = CreateFrame("Frame", nil, frame)
    scrollFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    scrollFrame:SetWidth(20)
    
    local upBtn = CreateFrame("Button", nil, scrollFrame)
    upBtn:SetSize(20, 20)
    upBtn:SetPoint("TOP", 0, 0)
    upBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
    upBtn:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
    upBtn:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
    
    local downBtn = CreateFrame("Button", nil, scrollFrame)
    downBtn:SetSize(20, 20)
    downBtn:SetPoint("BOTTOM", 0, 0)
    downBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    downBtn:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
    downBtn:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
    
    local track = scrollFrame:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("TOP", upBtn, "BOTTOM", 0, 0)
    track:SetPoint("BOTTOM", downBtn, "TOP", 0, 0)
    track:SetWidth(20)
    track:SetTexture("Interface\\Buttons\\UI-ScrollBar-Track")
    track:SetTexCoord(0, 1, 0.1, 0.9)
    
    local slider = CreateFrame("Slider", nil, scrollFrame)
    slider:SetPoint("TOP", upBtn, "BOTTOM", 0, 0)
    slider:SetPoint("BOTTOM", downBtn, "TOP", 0, 0)
    slider:SetWidth(20)
    slider:SetOrientation("VERTICAL")
    slider:SetMinMaxValues(1, 1)
    slider:SetValueStep(1)
    slider:SetValue(1)
    slider:EnableMouse(true)
    slider:EnableMouseWheel(true)
    
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    thumb:SetSize(20, 24)
    slider:SetThumbTexture(thumb)
    
    gridScrollbar = slider
    
    local function ChangePage(delta)
        -- Handle enchant mode pagination
        if currentTransmogMode == TRANSMOG_MODE_ENCHANT then
            local enchantList = GetFilteredEnchantVisuals(currentEnchantCategory)
            local cols, rows = CalculateGridLayout()
            local enchantPerPage = cols * rows
            local totalPages = math.max(1, math.ceil(#enchantList / enchantPerPage))
            local newPage = currentEnchantPage + delta
            newPage = math.max(1, math.min(totalPages, newPage))
            if newPage ~= currentEnchantPage then
                currentEnchantPage = newPage
                UpdateEnchantGrid()
            end
        else
            -- Item mode pagination
            local totalPages = math.max(1, math.ceil(#currentItems / itemsPerPage))
            local newPage = currentPage + delta
            newPage = math.max(1, math.min(totalPages, newPage))
            if newPage ~= currentPage then
                currentPage = newPage
                UpdatePreviewGrid()
            end
        end
    end
    
    upBtn:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
    upBtn:SetScript("OnClick", function() ChangePage(-1) end)
    
    downBtn:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
    downBtn:SetScript("OnClick", function() ChangePage(1) end)
    
    slider:SetScript("OnValueChanged", function(self, value)
        local newPage = math.floor(value + 0.5)
        -- Handle enchant mode
        if currentTransmogMode == TRANSMOG_MODE_ENCHANT then
            if newPage ~= currentEnchantPage then
                currentEnchantPage = newPage
                UpdateEnchantGrid()
            end
        else
            if newPage ~= currentPage then
                currentPage = newPage
                UpdatePreviewGrid()
            end
        end
    end)
    
    slider:SetScript("OnMouseWheel", function(self, delta) ChangePage(-delta) end)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(self, delta) ChangePage(-delta) end)
    
    return frame
end

-- ============================================================================
-- Subclass Dropdown
-- ============================================================================

local function CreateSubclassDropdown(parent)
    local dropdown = CreateFrame("Frame", "TransmogSubclassDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", 320, -25)
    UIDropDownMenu_SetWidth(dropdown, 150)
    UIDropDownMenu_SetText(dropdown, currentSubclass)
    return dropdown
end

local function UpdateSubclassDropdown()
    local subclasses = SLOT_SUBCLASSES[currentSlot] or {}
    
    UIDropDownMenu_Initialize(subclassDropdown, function(self, level)
        for _, subclass in ipairs(subclasses) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = L[subclass] or subclass
            info.value = subclass
            info.func = function(self)
                currentSubclass = self.value
                slotSelectedSubclass[currentSlot] = currentSubclass  -- Store the selection
                UIDropDownMenu_SetText(subclassDropdown, L[self.value] or self.value)
                
                -- NEW: Use cache-based loading with local filtering
                local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
                LoadItemsForSlot(slotId, currentSubclass, currentQuality, currentCollectionFilter)
                
                CloseDropDownMenus()
            end
            info.checked = (subclass == currentSubclass)
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    UIDropDownMenu_SetText(subclassDropdown, L[currentSubclass] or currentSubclass)
end

local function UpdateQualityDropdown()
    if not qualityDropdown then return end
    
    UIDropDownMenu_Initialize(qualityDropdown, function(self, level)
        for _, quality in ipairs(QUALITY_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            
            -- Get localized name
            local localizedName = L["QUALITY_" .. string.upper(quality)] or quality
            
            -- Color the text according to quality (except "All")
            if quality == "All" then
                info.text = L["FILTER_ALL"] or "All"
            else
                local color = QUALITY_COLORS[quality] or "|cffffffff"
                info.text = color .. localizedName .. "|r"
            end
            
            info.value = quality
            info.func = function(self)
                currentQuality = self.value
                slotSelectedQuality[currentSlot] = currentQuality  -- Store the selection
                
                -- Update dropdown text with color and localized name
                if currentQuality == "All" then
                    UIDropDownMenu_SetText(qualityDropdown, L["FILTER_ALL"] or "All")
                else
                    local color = QUALITY_COLORS[currentQuality] or "|cffffffff"
                    local localName = L["QUALITY_" .. string.upper(currentQuality)] or currentQuality
                    UIDropDownMenu_SetText(qualityDropdown, color .. localName .. "|r")
                end
                
                -- NEW: Use cache-based loading with local filtering
                local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
                LoadItemsForSlot(slotId, currentSubclass, currentQuality, currentCollectionFilter)
                
                CloseDropDownMenus()
            end
            info.checked = (quality == currentQuality)
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    -- Set initial text with color and localized name
    if currentQuality == "All" then
        UIDropDownMenu_SetText(qualityDropdown, L["FILTER_ALL"] or "All")
    else
        local color = QUALITY_COLORS[currentQuality] or "|cffffffff"
        local localName = L["QUALITY_" .. string.upper(currentQuality)] or currentQuality
        UIDropDownMenu_SetText(qualityDropdown, color .. localName .. "|r")
    end
end

-- ============================================================================
-- Collection Filter Dropdown
-- ============================================================================

UpdateCollectionFilterDropdown = function()
    if not collectionFilterDropdown then return end
    
    UIDropDownMenu_Initialize(collectionFilterDropdown, function(self, level)
        for _, filter in ipairs(COLLECTION_FILTER_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            
            -- Color based on filter type
            if filter == "Collected" then
                info.text = "|cff00ff00" .. (L["FILTER_COLLECTED"] or "Collected") .. "|r"
            elseif filter == "Uncollected" then
                info.text = "|cff888888" .. (L["FILTER_UNCOLLECTED"] or "Uncollected") .. "|r"
            else
                info.text = L["FILTER_ALL"] or "All"
            end
            
            info.value = filter
            info.func = function(self)
                currentCollectionFilter = self.value
                slotSelectedCollectionFilter[currentSlot] = currentCollectionFilter
                
                -- Update dropdown text with color
                if currentCollectionFilter == "Collected" then
                    UIDropDownMenu_SetText(collectionFilterDropdown, "|cff00ff00" .. (L["FILTER_COLLECTED"] or "Collected") .. "|r")
                elseif currentCollectionFilter == "Uncollected" then
                    UIDropDownMenu_SetText(collectionFilterDropdown, "|cff888888" .. (L["FILTER_UNCOLLECTED"] or "Uncollected") .. "|r")
                else
                    UIDropDownMenu_SetText(collectionFilterDropdown, L["FILTER_ALL"] or "All")
                end
                
                -- NEW: Use cache-based loading with local filtering
                local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
                LoadItemsForSlot(slotId, currentSubclass, currentQuality, currentCollectionFilter)
                
                CloseDropDownMenus()
            end
            info.checked = (filter == currentCollectionFilter)
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    -- Set initial text with color
    if currentCollectionFilter == "Collected" then
        UIDropDownMenu_SetText(collectionFilterDropdown, "|cff00ff00" .. (L["FILTER_COLLECTED"] or "Collected") .. "|r")
    elseif currentCollectionFilter == "Uncollected" then
        UIDropDownMenu_SetText(collectionFilterDropdown, "|cff888888" .. (L["FILTER_UNCOLLECTED"] or "Uncollected") .. "|r")
    else
        UIDropDownMenu_SetText(collectionFilterDropdown, L["FILTER_ALL"] or "All")
    end
end

-- ============================================================================
-- Slot Buttons
-- ============================================================================

local function CreateSlotButton(parent, slotName)
    local btn = CreateFrame("CheckButton", "$parent"..slotName, parent)
    btn:SetSize(32, 32)
    
    local config = SLOT_CONFIG[slotName]
    local textureName = config and config.texture or slotName
    btn:SetNormalTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-"..textureName)
    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    btn:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
    
    -- Create a separate frame for overlays to ensure they're on top
    local overlayFrame = CreateFrame("Frame", nil, btn)
    overlayFrame:SetAllPoints(btn)
    overlayFrame:SetFrameLevel(btn:GetFrameLevel() + 10)
    
    -- Create overlay icon for active transmog
    local transmogIcon = overlayFrame:CreateTexture(nil, "ARTWORK")
    transmogIcon:SetSize(28, 28)
    transmogIcon:SetPoint("CENTER")
    transmogIcon:Hide()
    btn.transmogIcon = transmogIcon
    
    -- Create active indicator border
    local activeBorder = overlayFrame:CreateTexture(nil, "OVERLAY")
    activeBorder:SetSize(48, 48)
    activeBorder:SetPoint("CENTER")
    activeBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    activeBorder:SetBlendMode("ADD")
    activeBorder:SetVertexColor(0, 1, 0, 1)
    activeBorder:Hide()
    btn.activeBorder = activeBorder
    
    btn.slotName = slotName
    
    -- Helper to find enchant icon by ID
    local function GetEnchantIcon(enchantId)
        for _, enchantData in ipairs(ENCHANT_VISUALS) do
            if enchantData.id == enchantId then
                return enchantData.icon
            end
        end
        return nil
    end
    
    -- Function to update slot appearance based on current mode
    btn.UpdateTransmogIcon = function(self)
        local slotId = SLOT_NAME_TO_EQUIP_SLOT[self.slotName]
        local activeItemId = activeTransmogs[slotId]
        local activeEnchant = activeEnchantTransmogs[slotId]
        local isWeapon = ENCHANT_ELIGIBLE_SLOTS[self.slotName]
        
        -- -- Debug output
        -- if isWeapon then
        --     print(string.format("[Transmog Debug] UpdateTransmogIcon: slot=%s, slotId=%s, mode=%s, hasItem=%s, hasEnchant=%s",
        --         self.slotName, tostring(slotId), 
        --         currentTransmogMode == TRANSMOG_MODE_ITEM and "ITEM" or "ENCHANT",
        --         tostring(activeItemId), tostring(activeEnchant)))
        -- end
        
        -- Search override
        local hasSearchMatches = searchActive and searchSlotResults[slotId] and #searchSlotResults[slotId] > 0
        
        -- Reset state
        self.transmogIcon:Hide()
        if self.activeBorder then
            self.activeBorder:Hide()
        end
        
        if currentTransmogMode == TRANSMOG_MODE_ITEM then
            -- =====================
            -- ITEM MODE
            -- =====================
            if isWeapon then
                -- WEAPON SLOT
                if activeItemId then
                    -- Show item icon
                    local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(activeItemId)
                    -- print("[Transmog Debug] ITEM MODE weapon slot, itemId=" .. activeItemId .. ", texture=" .. tostring(itemTexture))
                    if itemTexture then
                        self.transmogIcon:SetTexture(itemTexture)
                        self.transmogIcon:Show()
                    else
                        GameTooltip:SetHyperlink("item:"..activeItemId)
                        GameTooltip:Hide()
                        C_Timer.After(0.2, function()
                            if currentTransmogMode == TRANSMOG_MODE_ITEM and activeTransmogs[slotId] then
                                local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(activeItemId)
                                if tex then
                                    self.transmogIcon:SetTexture(tex)
                                    self.transmogIcon:Show()
                                end
                            end
                        end)
                    end
                    -- Border: pink if enchant, green if no enchant
                    if self.activeBorder then
                        self.activeBorder:Show()
                        if hasSearchMatches then
                            self.activeBorder:SetVertexColor(1, 0.5, 0, 1)
                        elseif activeEnchant then
                            self.activeBorder:SetVertexColor(1, 0.4, 0.7, 1)  -- Pink
                        else
                            self.activeBorder:SetVertexColor(0, 1, 0, 1)  -- Green
                        end
                    end
                else
                    -- No item: check for enchant or search matches
                    if self.activeBorder then
                        self.activeBorder:Show()
                        if hasSearchMatches then
                            self.activeBorder:SetVertexColor(1, 0.5, 0, 1)
                        elseif activeEnchant then
                            self.activeBorder:SetVertexColor(1, 0.4, 0.7, 1)  -- Pink (enchant without item in ITEM MODE)
                        else
                            self.activeBorder:Hide()  -- No item, no enchant, no search - hide border
                        end
                    end
                end
            else
                -- ARMOR SLOT
                if activeItemId then
                    -- Show item icon + green border
                    local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(activeItemId)
                    if itemTexture then
                        self.transmogIcon:SetTexture(itemTexture)
                        self.transmogIcon:Show()
                    else
                        GameTooltip:SetHyperlink("item:"..activeItemId)
                        GameTooltip:Hide()
                        C_Timer.After(0.2, function()
                            if currentTransmogMode == TRANSMOG_MODE_ITEM and activeTransmogs[slotId] then
                                local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(activeItemId)
                                if tex then
                                    self.transmogIcon:SetTexture(tex)
                                    self.transmogIcon:Show()
                                end
                            end
                        end)
                    end
                    if self.activeBorder then
                        self.activeBorder:Show()
                        if hasSearchMatches then
                            self.activeBorder:SetVertexColor(1, 0.5, 0, 1)
                        else
                            self.activeBorder:SetVertexColor(0, 1, 0, 1)  -- Green
                        end
                    end
                else
                    -- No item: nothing
                    if hasSearchMatches and self.activeBorder then
                        self.activeBorder:Show()
                        self.activeBorder:SetVertexColor(1, 0.5, 0, 1)
                    end
                end
            end
        else
            -- =====================
            -- ENCHANT MODE
            -- =====================
            if isWeapon then
                -- WEAPON SLOT
                if activeItemId and activeEnchant then
                    -- Has both: enchant icon + green border
                    local enchantIcon = GetEnchantIcon(activeEnchant)
                    if enchantIcon then
                        self.transmogIcon:SetTexture(enchantIcon)
                        self.transmogIcon:Show()
                    end
                    if self.activeBorder then
                        self.activeBorder:Show()
                        if hasSearchMatches then
                            self.activeBorder:SetVertexColor(1, 0.5, 0, 1)
                        else
                            self.activeBorder:SetVertexColor(0, 1, 0, 1)  -- Green
                        end
                    end
                elseif activeItemId and not activeEnchant then
                    -- Has item, no enchant: no icon + green border
                    if self.activeBorder then
                        self.activeBorder:Show()
                        if hasSearchMatches then
                            self.activeBorder:SetVertexColor(1, 0.5, 0, 1)
                        else
                            self.activeBorder:SetVertexColor(0, 1, 0, 1)  -- Green
                        end
                    end
                elseif not activeItemId and activeEnchant then
                    -- No item, has enchant: enchant icon + pink border
                    -- print("[Transmog Debug] Weapon no item + enchant: showing pink border for " .. self.slotName)
                    local enchantIcon = GetEnchantIcon(activeEnchant)
                    if enchantIcon then
                        self.transmogIcon:SetTexture(enchantIcon)
                        self.transmogIcon:Show()
                    --     print("[Transmog Debug] Enchant icon set: " .. enchantIcon)
                    -- else
                    --     print("[Transmog Debug] No enchant icon found for enchant: " .. tostring(activeEnchant))
                    end
                    if self.activeBorder then
                        self.activeBorder:Show()
                        if hasSearchMatches then
                            self.activeBorder:SetVertexColor(1, 0.5, 0, 1)
                        else
                            self.activeBorder:SetVertexColor(1, 0.4, 0.7, 1)  -- Pink, full alpha
                        end
                    end
                else
                    -- No item, no enchant: nothing
                    if hasSearchMatches and self.activeBorder then
                        self.activeBorder:Show()
                        self.activeBorder:SetVertexColor(1, 0.5, 0, 1)
                    end
                end
            else
                -- ARMOR SLOT
                if activeItemId then
                    -- Has item: NO icon + green border
                    if self.activeBorder then
                        self.activeBorder:Show()
                        if hasSearchMatches then
                            self.activeBorder:SetVertexColor(1, 0.5, 0, 1)
                        else
                            self.activeBorder:SetVertexColor(0, 1, 0, 1)  -- Green
                        end
                    end
                else
                    -- No item: nothing
                    if hasSearchMatches and self.activeBorder then
                        self.activeBorder:Show()
                        self.activeBorder:SetVertexColor(1, 0.5, 0, 1)
                    end
                end
            end
        end
    end
    
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            -- Right-click to clear transmog
            local slotId = SLOT_NAME_TO_EQUIP_SLOT[self.slotName]
            local hadTransmog = false
            
            if activeTransmogs[slotId] then
                RemoveTransmog(self.slotName)
                activeTransmogs[slotId] = nil
                hadTransmog = true
            end
            -- Also check for enchant transmog to remove
            if activeEnchantTransmogs[slotId] and ENCHANT_ELIGIBLE_SLOTS[self.slotName] then
                RemoveEnchantTransmog(self.slotName)
                activeEnchantTransmogs[slotId] = nil
                hadTransmog = true
            end
            
            if hadTransmog then
                PlaySound("igMainMenuOptionCheckBoxOn")
                -- Clear selection for this slot to avoid ghost highlight
                slotSelectedItems[self.slotName] = nil
                slotSelectedEnchants[self.slotName] = nil
                -- If clearing transmog for the current slot, also clear global selection
                if self.slotName == currentSlot then
                    selectedItemFrame = nil
                    selectedItemId = nil
                    selectedEnchantFrame = nil
                    selectedEnchantId = nil
                end
                self:UpdateTransmogIcon()
                -- Refresh the grid to clear any highlight
                if currentTransmogMode == TRANSMOG_MODE_ENCHANT then
                    if UpdateEnchantGrid then UpdateEnchantGrid() end
                else
                    UpdatePreviewGrid()
                end
                
                -- Refresh dressing room model
                RefreshDressingRoomModel()
            end
            
            for name, slotBtn in pairs(slotButtons) do
                slotBtn:SetChecked(name == currentSlot)
            end
            return
        end
        
        -- Left-click to select slot
        for name, btn in pairs(slotButtons) do
            btn:SetChecked(name == self.slotName)
        end
        
        -- Get the stored subclass and quality for this slot, or default to "All"
        currentSlot = self.slotName
        currentSubclass = slotSelectedSubclass[currentSlot] or "All"
        currentQuality = slotSelectedQuality[currentSlot] or "All"
        -- NEW: Reset collection filter to "Collected" when changing slots
        currentCollectionFilter = "Collected"
        slotSelectedCollectionFilter[currentSlot] = "Collected"
        
        -- If search is active, show search results for this slot
        if searchActive then
            local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
            if searchSlotResults[slotId] then
                currentItems = searchSlotResults[slotId]
                print(string.format("[Transmog] Switching to search results for slot %s: %d items", currentSlot, #currentItems))
            else
                currentItems = {}
                print(string.format("[Transmog] No search results for slot %s", currentSlot))
            end
            
            currentPage = 1
            
            -- Update dropdowns to show current selection
            UpdateSubclassDropdown()
            UpdateQualityDropdown()
            UpdateCollectionFilterDropdown()  -- NEW
            UpdatePreviewGrid()
            
            -- Update page text
            local totalPages = math.max(1, math.ceil(#currentItems / itemsPerPage))
            if mainFrame and mainFrame.pageText then
                if #searchResults > 0 then
                    mainFrame.pageText:SetText(string.format(L["PAGE"], currentPage, totalPages) .. " | " .. 
                        string.format("Search: %d items (%d in %s)", #searchResults, #currentItems, currentSlot))
                end
            end
            
            PlaySound("igMainMenuOptionCheckBoxOn")
            return
        end
        
        -- Normal mode: update dropdowns and request items
        currentPage = 1
        currentItems = {}
        
        UpdateSubclassDropdown()
        UpdateQualityDropdown()
        UpdateCollectionFilterDropdown()  -- NEW
        UpdatePreviewGrid()
        
        -- NEW: Use cache-based loading with local filtering
        local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
        LoadItemsForSlot(slotId, currentSubclass, currentQuality, currentCollectionFilter)
        
        PlaySound("igMainMenuOptionCheckBoxOn")
    end)
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        
        local slotId = SLOT_NAME_TO_EQUIP_SLOT[self.slotName]
        local activeItemId = activeTransmogs[slotId]
        
        if activeItemId then
            GameTooltip:SetText(L[slotName])
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["ACTIVE_TRANSMOG"], 0, 1, 0)
            local itemName, itemLink = GetItemInfo(activeItemId)
            if itemLink then
                GameTooltip:AddLine(itemLink)
            else
                GameTooltip:AddLine("Item #" .. activeItemId, 1, 1, 1)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["CLEAR_TRANSMOG"], 1, 1, 1)
        else
            GameTooltip:SetText(L[slotName])
            GameTooltip:AddLine(L["NO_ACTIVE_TRANSMOG"], 0.5, 0.5, 0.5)
        end
        
        GameTooltip:Show()
    end)
    
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return btn
end

-- Function to update all slot button icons
UpdateSlotButtonIcons = function()
    if not slotButtons or not next(slotButtons) then return end
    for slotName, btn in pairs(slotButtons) do
        if btn and btn.UpdateTransmogIcon then
            btn:UpdateTransmogIcon()
        end
    end
end

-- ============================================================================
-- Dressing Room
-- ============================================================================

-- Available background options for settings
local BACKGROUND_OPTIONS = {
    { value = nil, label = "Auto (Class)" },
    { value = "WARRIOR", label = "Warrior" },
    { value = "PALADIN", label = "Paladin" },
    { value = "HUNTER", label = "Hunter" },
    { value = "ROGUE", label = "Rogue" },
    { value = "PRIEST", label = "Priest" },
    { value = "DEATHKNIGHT", label = "Death Knight" },
    { value = "SHAMAN", label = "Shaman" },
    { value = "MAGE", label = "Mage" },
    { value = "WARLOCK", label = "Warlock" },
    { value = "DRUID", label = "Druid" },
}
Transmog.BACKGROUND_OPTIONS = BACKGROUND_OPTIONS

local TEXTURE_PATHS = {
    WARRIOR = "Interface\\AddOns\\MOD-TRANSMOG-SYSTEM\\Assets\\dressingroomwarrior",
    PALADIN = "Interface\\AddOns\\MOD-TRANSMOG-SYSTEM\\Assets\\dressingroompaladin",
    HUNTER = "Interface\\AddOns\\MOD-TRANSMOG-SYSTEM\\Assets\\dressingroomhunter",
    ROGUE = "Interface\\AddOns\\MOD-TRANSMOG-SYSTEM\\Assets\\dressingroomrogue",
    PRIEST = "Interface\\AddOns\\MOD-TRANSMOG-SYSTEM\\Assets\\dressingroompriest",
    DEATHKNIGHT = "Interface\\AddOns\\MOD-TRANSMOG-SYSTEM\\Assets\\dressingroomdeathknight",
    SHAMAN = "Interface\\AddOns\\MOD-TRANSMOG-SYSTEM\\Assets\\dressingroomshaman",
    MAGE = "Interface\\AddOns\\MOD-TRANSMOG-SYSTEM\\Assets\\dressingroommage",
    WARLOCK = "Interface\\AddOns\\MOD-TRANSMOG-SYSTEM\\Assets\\dressingroomwarlock",
    DRUID = "Interface\\AddOns\\MOD-TRANSMOG-SYSTEM\\Assets\\dressingroomdruid"
}
Transmog.TEXTURE_PATHS = TEXTURE_PATHS

local function CreateDressingRoom(parent)
    local frame = CreateFrame("Frame", "$parentDressingRoom", parent)
    frame:SetSize(280, 460)
    
    -- Create and set the class-specific background texture
    local bgTexture = frame:CreateTexture("$parentCustomTexture", "BACKGROUND")
    bgTexture:SetPoint("TOPLEFT", 4, -4)
    bgTexture:SetPoint("BOTTOMRIGHT", -4, 4)
    
    -- Get player class
    local _, playerClass = UnitClass("player")
    
    -- Check for background override setting
    local backgroundClass = GetSetting("backgroundOverride") or playerClass
    
    -- Set texture based on class or override
    local texturePath = TEXTURE_PATHS[backgroundClass] or TEXTURE_PATHS[playerClass] or TEXTURE_PATHS.WARLOCK
    bgTexture:SetTexture(texturePath)
    
    -- Calculate cropping for square texture in portrait frame
    local frameWidth, frameHeight = 280, 460
    local frameAspect = frameWidth / frameHeight
    
    local cropWidth = frameAspect
    local left = (1 - cropWidth) / 2
    local right = 1 - left
    
    bgTexture:SetTexCoord(left, right, 0, 1)
    
    frame.bgTexture = bgTexture
    frame.texCoordLeft = left
    frame.texCoordRight = right
    
    frame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, 
        tileSize = 16, 
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    function frame:UpdateBackgroundTexture(overrideClass)
        local _, currentClass = UnitClass("player")
        local backgroundClass = overrideClass or GetSetting("backgroundOverride") or currentClass
        local newTexturePath = TEXTURE_PATHS[backgroundClass] or TEXTURE_PATHS[currentClass] or TEXTURE_PATHS.WARLOCK
        self.bgTexture:SetTexture(newTexturePath)
        self.bgTexture:SetTexCoord(self.texCoordLeft, self.texCoordRight, 0, 1)
    end
    
    -- Create model frame
    local model = CreateFrame("DressUpModel", "$parentModel", frame)
    model:SetPoint("TOPLEFT", 4, -4)
    model:SetPoint("BOTTOMRIGHT", -4, 4)
    model:SetUnit("player")
    model:SetRotation(0)
    frame.model = model
    
    -- Store initial position for proper reset
    local initialCameraDistance = 0
    
    -- Mouse interaction for rotating/zooming
    local isDragging = false
    local isRotating = false
    local lastX, lastY = 0, 0
    
    model:EnableMouse(true)
    model:EnableMouseWheel(true)  -- Enable mouse wheel for zoom
    
    model:SetScript("OnMouseDown", function(self, button)
        lastX, lastY = GetCursorPosition()
        if button == "LeftButton" then
            isRotating = true
        elseif button == "RightButton" then
            isDragging = true
        end
    end)
    
    model:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            isRotating = false
        elseif button == "RightButton" then
            isDragging = false
        end
    end)
    
    model:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local dx = x - lastX
        local dy = y - lastY
        
        if isRotating then
            local rotation = self:GetFacing() + dx * 0.02
            self:SetFacing(rotation)
        elseif isDragging then
            local px, py, pz = self:GetPosition()
            self:SetPosition(px, py + dx * 0.01, pz + dy * 0.01)
        end
        
        lastX, lastY = x, y
    end)
    
    model:SetScript("OnMouseWheel", function(self, delta)
        local x, y, z = self:GetPosition()
        x = x + delta * 0.3
        x = math.max(-1, math.min(5, x))
        self:SetPosition(x, y, z)
    end)
    
    function frame:Undress()
        self.model:Undress()
    end
    
    function frame:Reset()
        -- Store reference to model
        local mdl = self.model
        
        -- First reset position and facing
        mdl:SetFacing(0)
        mdl:SetPosition(0, 0, 0)
        
        -- Refresh model with current equipped gear on next frame
        -- This restores the player's current appearance (gear + transmogs)
        C_Timer.After(0.01, function()
            mdl:SetUnit("player")
            -- Apply active transmogs after model loads
            C_Timer.After(0.05, function()
                -- Apply all active transmogs to the model
                for slotId, itemId in pairs(activeTransmogs) do
                    if itemId then
                        mdl:TryOn(itemId)
                    end
                end
                -- Reset position again after everything is applied
                mdl:SetPosition(0, 0, 0)
                mdl:SetFacing(0)
            end)
        end)
        
        -- Clear all cyan selections when reset is clicked
        slotSelectedItems = {}
        selectedItemId = nil
        selectedItemFrame = nil
        
        -- Clear cyan borders from all visible item frames
        for _, itemFrame in ipairs(itemFrames) do
            if itemFrame.selectionBorder and itemFrame.selectionBorder:IsShown() then
                itemFrame.selectionBorder:Hide()
                if itemFrame.isActive then
                    itemFrame:SetBackdropBorderColor(0, 1, 0, 1)
                else
                    itemFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                end
            end
        end
    end
    
    return frame
end

-- ============================================================================
-- Set Management UI
-- ============================================================================

local setDropdown

local function CreateSetDropdown(parent)
    local dropdown = CreateFrame("Frame", "TransmogSetDropdown", parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, 120)
    return dropdown
end

UpdateSetDropdown = function()
    if not setDropdown then return end
    
    UIDropDownMenu_Initialize(setDropdown, function(self, level)
        -- Add "New Set" option
        local newInfo = UIDropDownMenu_CreateInfo()
        newInfo.text = L["SET_NEW"] or "New Set..."
        newInfo.value = 0
        newInfo.func = function()
            -- Show dialog to create new set
            StaticPopup_Show("TRANSMOG_SAVE_SET")
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(newInfo, level)
        
        -- Add existing sets
        for i = 1, MAX_SETS do
            local setData = transmogSets[i]
            if setData then
                local info = UIDropDownMenu_CreateInfo()
                info.text = setData.name or string.format(L["SET_DEFAULT_NAME"] or "Set %d", i)
                info.value = i
                info.func = function(self)
                    selectedSetNumber = self.value  -- Track selected set
                    LoadSetFromServer(self.value)
                    UIDropDownMenu_SetText(setDropdown, self:GetText())
                    CloseDropDownMenus()
                end
                info.checked = (selectedSetNumber == i)
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)
    
    -- Update text based on selected set
    if selectedSetNumber and transmogSets[selectedSetNumber] then
        UIDropDownMenu_SetText(setDropdown, transmogSets[selectedSetNumber].name or string.format("Set %d", selectedSetNumber))
    else
        UIDropDownMenu_SetText(setDropdown, L["SET_SELECT"] or "Select Set")
    end
end

-- Static popup for saving sets
StaticPopupDialogs["TRANSMOG_SAVE_SET"] = {
    text = L["SET_SAVE_PROMPT"] or "Enter set name:",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 32,
    OnAccept = function(self)
        local setName = self.editBox:GetText()
        if setName and setName ~= "" then
            -- Find first available slot
            local setNumber = nil
            for i = 1, MAX_SETS do
                if not transmogSets[i] then
                    setNumber = i
                    break
                end
            end
            
            if not setNumber then
                print(L["SET_FULL"] or "|cffff0000[Transmog]|r All set slots are full. Delete a set first.")
                return
            end
            
            SaveSetToServer(setNumber, setName)
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        StaticPopupDialogs["TRANSMOG_SAVE_SET"].OnAccept(parent)
        parent:Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Static popup for deleting sets
StaticPopupDialogs["TRANSMOG_DELETE_SET"] = {
    text = L["SET_DELETE_CONFIRM"] or "Delete this set?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        if data then
            DeleteSetFromServer(data)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function CreateSetControls(parent, dressingRoomFrame)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(280, 30)
    container:SetPoint("TOP", dressingRoomFrame, "BOTTOM", 0, -5)
    
    -- Set dropdown
    setDropdown = CreateSetDropdown(container)
    setDropdown:SetPoint("LEFT", container, "LEFT", -10, 0)
    
    -- Save button
    local saveBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    saveBtn:SetSize(45, 22)
    saveBtn:SetPoint("LEFT", setDropdown, "RIGHT", -5, 2)
    saveBtn:SetText(L["SET_SAVE"] or "Save")
    saveBtn:SetScript("OnClick", function()
        -- Check if any items are selected
        local hasSelection = false
        for _, itemId in pairs(slotSelectedItems) do
            if itemId then
                hasSelection = true
                break
            end
        end
        
        if not hasSelection then
            print(L["SET_NO_SELECTION"] or "|cffff0000[Transmog]|r No items selected. Click items in the preview to select them first.")
            return
        end
        
        StaticPopup_Show("TRANSMOG_SAVE_SET")
    end)
    saveBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["SET_SAVE_TOOLTIP"] or "Save selected items as a new set")
        GameTooltip:Show()
    end)
    saveBtn:SetScript("OnLeave", GameTooltip_Hide)
    
    -- Delete button
    local deleteBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    deleteBtn:SetSize(45, 22)
    deleteBtn:SetPoint("LEFT", saveBtn, "RIGHT", 2, 0)
    deleteBtn:SetText(L["SET_DELETE"] or "Del")
    deleteBtn:SetScript("OnClick", function()
        -- Use our tracked selectedSetNumber instead of UIDropDownMenu_GetSelectedValue
        if selectedSetNumber and selectedSetNumber > 0 and transmogSets[selectedSetNumber] then
            local dialog = StaticPopup_Show("TRANSMOG_DELETE_SET")
            if dialog then
                dialog.data = selectedSetNumber
            end
        else
            print(L["SET_SELECT_FIRST"] or "|cffff0000[Transmog]|r Select a set first.")
        end
    end)
    deleteBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["SET_DELETE_TOOLTIP"] or "Delete the selected set")
        GameTooltip:Show()
    end)
    deleteBtn:SetScript("OnLeave", GameTooltip_Hide)
    
    -- Apply button
    local applyBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    applyBtn:SetSize(50, 22)
    applyBtn:SetPoint("LEFT", deleteBtn, "RIGHT", 2, 0)
    applyBtn:SetText(L["SET_APPLY"] or "Apply")
    applyBtn:SetScript("OnClick", function()
        -- Use our tracked selectedSetNumber instead of UIDropDownMenu_GetSelectedValue
        if selectedSetNumber and selectedSetNumber > 0 and transmogSets[selectedSetNumber] then
            ApplySetToServer(selectedSetNumber)
        else
            print(L["SET_SELECT_FIRST"] or "|cffff0000[Transmog]|r Select a set first.")
        end
    end)
    applyBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["SET_APPLY_TOOLTIP"] or "Apply this set as active transmog\n(Only collected appearances will be applied)")
        GameTooltip:Show()
    end)
    applyBtn:SetScript("OnLeave", GameTooltip_Hide)
    
    container.dropdown = setDropdown
    container.saveBtn = saveBtn
    container.deleteBtn = deleteBtn
    container.applyBtn = applyBtn
    
    return container
end

-- ============================================================================
-- Search Bar Functions
-- ============================================================================

-- Function to create search bar
local function CreateSearchBar(parent, previewGrid)
    local searchContainer = CreateFrame("Frame", "$parentSearchContainer", parent)
    searchContainer:SetSize(620, 40)
    searchContainer:SetPoint("BOTTOM", previewGrid, "BOTTOM", 0, -70)
    
    -- Set background and border
    searchContainer:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    searchContainer:SetBackdropColor(0, 0, 0, 0.7)
    searchContainer:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Search type dropdown (LEFT side, anchored to container)
    local searchTypeDropdown = CreateFrame("Frame", "$parentSearchTypeDropdown", searchContainer, "UIDropDownMenuTemplate")
    searchTypeDropdown:SetPoint("LEFT", searchContainer, "LEFT", 10, 0)
    UIDropDownMenu_SetWidth(searchTypeDropdown, 80)
    
    -- Initialize search type dropdown
    local searchTypes = {
        {text = L["SEARCH_NAME"] or "Name", value = "name"},
        {text = L["SEARCH_ID"] or "ID", value = "id"},
        {text = L["SEARCH_DISPLAYID"] or "DisplayID", value = "displayid"}
    }
    local selectedSearchType = "name"
    
    UIDropDownMenu_Initialize(searchTypeDropdown, function(self, level)
        for _, typeInfo in ipairs(searchTypes) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = typeInfo.text
            info.value = typeInfo.value
            info.func = function(self)
                selectedSearchType = self.value
                UIDropDownMenu_SetText(searchTypeDropdown, self:GetText())
                CloseDropDownMenus()
            end
            info.checked = (selectedSearchType == typeInfo.value)
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    UIDropDownMenu_SetText(searchTypeDropdown, L["SEARCH_NAME"] or "Name")
    
    -- Search label (to the right of dropdown)
    local searchLabel = searchContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("LEFT", searchTypeDropdown, "RIGHT", 10, 0)
    searchLabel:SetText(L["SEARCH"] and L["SEARCH"] .. ":" or "Search:")
    
    -- Search input box (wider since we removed buttons)
    local searchEditBox = CreateFrame("EditBox", "$parentSearchEditBox", searchContainer, "InputBoxTemplate")
    searchEditBox:SetSize(320, 20)
    searchEditBox:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
    searchEditBox:SetAutoFocus(false)
    searchEditBox:SetMaxLetters(100)
    
    -- Local search function using cached data
    local function PerformLocalSearch(searchText, searchType)
        if not CLIENT_ITEM_CACHE.isReady then
            print("[Transmog] Cache not ready for local search")
            return false
        end
        
        local allResults = {}
        local slotResults = {}
        local searchLower = searchText:lower()
        local searchNumber = tonumber(searchText)
        
        -- Search through all slots in cache
        for slotId, items in pairs(CLIENT_ITEM_CACHE.bySlot) do
            slotResults[slotId] = slotResults[slotId] or {}
            
            for _, itemData in ipairs(items) do
                local itemId = itemData[1]
                local displayId = itemData[5]  -- displayId is now cached
                local match = false
                
                if searchType == "id" then
                    -- Match by item ID
                    if searchNumber and itemId == searchNumber then
                        match = true
                    elseif tostring(itemId):find(searchText, 1, true) then
                        match = true
                    end
                elseif searchType == "name" then
                    -- Match by item name (requires GetItemInfo)
                    -- Note: GetItemInfo returns nil until item is cached by WoW client
                    -- The preloader runs after cache load to populate item info
                    local itemName = GetItemInfo(itemId)
                    if itemName and itemName:lower():find(searchLower, 1, true) then
                        match = true
                    end
                elseif searchType == "displayid" then
                    -- Match by display ID (now cached!)
                    if displayId then
                        if searchNumber and displayId == searchNumber then
                            match = true
                        elseif tostring(displayId):find(searchText, 1, true) then
                            match = true
                        end
                    end
                end
                
                if match then
                    local isCollected = collectedAppearances[itemId] == true
                    local resultItem = { itemId = itemId, collected = isCollected, displayId = displayId }
                    table.insert(allResults, resultItem)
                    table.insert(slotResults[slotId], resultItem)
                end
            end
        end
        
        -- Set search results
        searchActive = true
        searchResults = allResults
        searchSlotResults = slotResults
        
        print(string.format("[Transmog] Local search found %d total items", #searchResults))
        
        -- Warn if name search found no results while preload is still running
        if searchType == "name" and #searchResults == 0 and itemInfoPreloader.isRunning then
            print("[Transmog] Item info still loading - try searching again in a moment")
        end
        
        -- Count matches per slot for debugging
        if slotButtons then
            for slotName, btn in pairs(slotButtons) do
                local slotId = SLOT_NAME_TO_EQUIP_SLOT[slotName]
                local hasMatches = searchSlotResults[slotId] and #searchSlotResults[slotId] > 0
                if hasMatches then
                    print(string.format("[Transmog] Slot %s (id: %d) has %d matches", 
                        slotName, slotId, #searchSlotResults[slotId]))
                end
            end
        end
        
        -- Update slot button icons to show search highlights
        C_Timer.After(0, function()
            UpdateSlotButtonIcons()
        end)
        
        -- If current slot has matches, show them
        local currentSlotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
        if searchSlotResults[currentSlotId] then
            currentItems = searchSlotResults[currentSlotId]
            print(string.format("[Transmog] Showing %d matches for current slot %s", #currentItems, currentSlot))
        else
            currentItems = {}
            print(string.format("[Transmog] No matches for current slot %s", currentSlot))
        end
        
        currentPage = 1
        UpdatePreviewGrid()
        
        -- Update page text
        local totalPages = math.max(1, math.ceil(#currentItems / itemsPerPage))
        if mainFrame and mainFrame.pageText then
            if #searchResults > 0 then
                mainFrame.pageText:SetText(string.format(L["PAGE"], currentPage, totalPages) .. " | " .. 
                    string.format("Search: %d items (%d in %s)", #searchResults, #currentItems, currentSlot))
            elseif searchType == "name" and itemInfoPreloader.isRunning then
                mainFrame.pageText:SetText("Loading item names... try again shortly")
            else
                mainFrame.pageText:SetText("No results found")
            end
        end
        
        -- Return number of results
        return #searchResults
    end
    
    -- Create the PerformSearch function BEFORE using it
    local function PerformSearch()
        local searchText = searchEditBox:GetText():trim()
        if searchText and searchText ~= "" then
            lastSearchText = searchText
            
            -- Use local cache for search (cache is authoritative)
            if CLIENT_ITEM_CACHE.isReady then
                PerformLocalSearch(searchText, selectedSearchType)
            else
                -- Cache not ready yet
                print("[Transmog] Item cache not ready - please wait")
                if mainFrame and mainFrame.pageText then
                    mainFrame.pageText:SetText("Cache loading... please wait")
                end
            end
        else
            ClearSearch()
        end
    end
    
    local function ClearSearch()
        searchEditBox:SetText("")
        searchActive = false
        searchResults = {}
        searchSlotResults = {}
        lastSearchText = ""
        
        print("[Transmog] Search cleared")
        
        -- Update slot button icons to remove search highlights
        C_Timer.After(0, function()
            UpdateSlotButtonIcons()
        end)
        
        -- Reset to show all items for current slot using cache
        local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
        LoadItemsForSlot(slotId, currentSubclass, currentQuality, currentCollectionFilter)
    end
    
    -- Set up event handlers
    searchEditBox:SetScript("OnEscapePressed", function(self)
        local text = self:GetText()
        if text and text:trim() ~= "" then
            ClearSearch()
            self:ClearFocus()
        else
            self:ClearFocus()
            if mainFrame and mainFrame:IsShown() then
                mainFrame:Hide()
                PlaySound("igCharacterInfoClose")
            end
        end
    end)
    
    -- Enter key triggers search
    searchEditBox:SetScript("OnEnterPressed", PerformSearch)
    
    -- Add search hint
    searchEditBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["SEARCH_TOOLTIP"] or "Search Options:")
        GameTooltip:AddLine(L["SEARCH_NAME"] and 
            "• " .. L["SEARCH_NAME"] .. L["SEARCH_NAME_DESCRIPTION"], 1, 1, 1)
        GameTooltip:AddLine(L["SEARCH_ID"] and 
            "• " .. L["SEARCH_ID"] .. L["SEARCH_ID_DESCRIPTION"], 1, 1, 1)
        GameTooltip:AddLine(L["SEARCH_DISPLAYID"] and 
            "• " .. L["SEARCH_DISPLAYID"] .. L["SEARCH_DISPLAYID_DESCRIPTION"], 1, 1, 1)
        GameTooltip:AddLine(" ")
        if searchActive then
            GameTooltip:AddLine("Active search: " .. lastSearchText, 0, 1, 0)
            GameTooltip:AddLine("Click slots to filter search results", 1, 1, 1)
        end
        GameTooltip:AddLine(L["SEARCH_DESCRIPTION"], 0.7, 0.7, 0.7)
        GameTooltip:AddLine(L["SEARCH_CLEAR_DESCRIPTION"], 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    
    searchEditBox:SetScript("OnLeave", GameTooltip_Hide)
    
    -- Store references
    searchContainer.searchEditBox = searchEditBox
    searchContainer.ClearSearch = ClearSearch
    searchContainer.PerformSearch = PerformSearch
    
    return searchContainer
end

-- ============================================================================
-- Settings Panel
-- ============================================================================

local settingsPanel = nil
local isSettingsVisible = false

local function CreateSettingsPanel(parent)
    local frame = CreateFrame("Frame", "$parentSettingsPanel", parent)
    frame:SetSize(620, 460)  -- Same size as preview grid
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, 
        tileSize = 16, 
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    frame:Hide()  -- Hidden by default
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText(L["SETTINGS_TITLE"] or "Transmog Settings")
    title:SetTextColor(1, 0.82, 0)
    
    -- Scrollable content area
    local scrollFrame = CreateFrame("ScrollFrame", "$parentScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -45)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    
    local content = CreateFrame("Frame", "$parentContent", scrollFrame)
    content:SetSize(560, 600)  -- Height will expand as needed
    scrollFrame:SetScrollChild(content)
    
    local yOffset = 0
    local sectionSpacing = 25
    local itemSpacing = 30
    
    -- Helper function to create section header
    local function CreateSectionHeader(text)
        local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", 10, yOffset)
        header:SetText(text)
        header:SetTextColor(1, 0.82, 0)
        yOffset = yOffset - 20
        
        local line = content:CreateTexture(nil, "ARTWORK")
        line:SetPoint("TOPLEFT", 10, yOffset)
        line:SetSize(540, 1)
        line:SetColorTexture(0.5, 0.5, 0.5, 0.5)
        yOffset = yOffset - 10
        
        return header
    end
    
    -- Helper function to create checkbox
    local function CreateCheckbox(label, settingKey, isCharacterSpecific)
        local check = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", 20, yOffset)
        check:SetSize(24, 24)
        
        local text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("LEFT", check, "RIGHT", 5, 0)
        text:SetText(label)
        
        -- Store the setting key for later reference
        check.settingKey = settingKey
        check.isCharacterSpecific = isCharacterSpecific
        
        -- Set initial state
        local currentValue = GetSetting(settingKey)
        check:SetChecked(currentValue == true or currentValue == nil)  -- Default to true if nil
        
        check:SetScript("OnClick", function(self)
            -- WoW 3.3.5: GetChecked() returns 1 or nil, convert to boolean
            local checked = self:GetChecked() == 1 or self:GetChecked() == true
            SetSetting(self.settingKey, checked, self.isCharacterSpecific)
            PlaySound("igMainMenuOptionCheckBoxOn")
        end)
        
        -- Update state when parent (settings panel) is shown
        check:SetScript("OnShow", function(self)
            local value = GetSetting(self.settingKey)
            self:SetChecked(value == true or value == nil)  -- Default to true if nil
        end)
        
        yOffset = yOffset - itemSpacing
        return check
    end
    
    -- Helper function to create dropdown
    local function CreateSettingsDropdown(label, options, settingKey, isCharacterSpecific, onChangeCallback)
        local labelText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        labelText:SetPoint("TOPLEFT", 20, yOffset)
        labelText:SetText(label)
        yOffset = yOffset - 20
        
        local dropdown = CreateFrame("Frame", "$parentDropdown" .. settingKey, content, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", 10, yOffset)
        UIDropDownMenu_SetWidth(dropdown, 200)
        
        -- Store references for OnShow updates
        dropdown.settingKey = settingKey
        dropdown.options = options
        
        -- Helper to get label for current value (stored on dropdown for reuse)
        dropdown.GetLabelForValue = function(self, value)
            for _, opt in ipairs(self.options) do
                if opt.value == value then
                    return opt.label
                end
            end
            return self.options[1].label  -- Default to first option
        end
        
        -- Set initial text
        local currentValue = GetSetting(settingKey)
        UIDropDownMenu_SetText(dropdown, dropdown:GetLabelForValue(currentValue))
        
        UIDropDownMenu_Initialize(dropdown, function(self, level)
            -- Fetch current value EACH time dropdown is opened
            local nowValue = GetSetting(settingKey)
            
            for _, opt in ipairs(options) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = opt.label
                info.value = opt.value
                info.checked = (nowValue == opt.value)
                info.func = function()
                    SetSetting(settingKey, opt.value, isCharacterSpecific)
                    UIDropDownMenu_SetText(dropdown, opt.label)
                    PlaySound("igMainMenuOptionCheckBoxOn")
                    if onChangeCallback then
                        onChangeCallback(opt.value)
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        
        -- Update displayed text when dropdown becomes visible
        dropdown:SetScript("OnShow", function(self)
            local value = GetSetting(self.settingKey)
            local labelForValue = self:GetLabelForValue(value)
            UIDropDownMenu_SetText(self, labelForValue)
        end)
        
        yOffset = yOffset - 35
        return dropdown
    end
    
    -- ========================================
    -- SECTION: Display Settings
    -- ========================================
    CreateSectionHeader(L["SETTINGS_DISPLAY"] or "Display Settings")
    yOffset = yOffset - 5
    
    -- Background dropdown (character-specific) with localized options
    local backgroundOptions = {
        { value = nil, label = L["SETTING_BG_AUTO"] or "Auto (Class)" },
        { value = "WARRIOR", label = L["CLASS_WARRIOR"] or "Warrior" },
        { value = "PALADIN", label = L["CLASS_PALADIN"] or "Paladin" },
        { value = "HUNTER", label = L["CLASS_HUNTER"] or "Hunter" },
        { value = "ROGUE", label = L["CLASS_ROGUE"] or "Rogue" },
        { value = "PRIEST", label = L["CLASS_PRIEST"] or "Priest" },
        { value = "DEATHKNIGHT", label = L["CLASS_DEATHKNIGHT"] or "Death Knight" },
        { value = "SHAMAN", label = L["CLASS_SHAMAN"] or "Shaman" },
        { value = "MAGE", label = L["CLASS_MAGE"] or "Mage" },
        { value = "WARLOCK", label = L["CLASS_WARLOCK"] or "Warlock" },
        { value = "DRUID", label = L["CLASS_DRUID"] or "Druid" },
    }
    CreateSettingsDropdown(
        L["SETTING_BACKGROUND"] or "Dressing Room Background:",
        backgroundOptions,
        "backgroundOverride",
        true,  -- Character-specific
        function(value)
            -- Update dressing room background immediately
            if mainFrame and mainFrame.dressingRoom then
                mainFrame.dressingRoom:UpdateBackgroundTexture(value)
            end
        end
    )
    
    yOffset = yOffset - 10
    
    -- Set Preview Background dropdown (character-specific)
    local setPreviewBgOptions = {
        { value = nil, label = L["SETTING_BG_AUTO"] or "Auto (Class)" },
        { value = "WARRIOR", label = L["CLASS_WARRIOR"] or "Warrior" },
        { value = "PALADIN", label = L["CLASS_PALADIN"] or "Paladin" },
        { value = "HUNTER", label = L["CLASS_HUNTER"] or "Hunter" },
        { value = "ROGUE", label = L["CLASS_ROGUE"] or "Rogue" },
        { value = "PRIEST", label = L["CLASS_PRIEST"] or "Priest" },
        { value = "DEATHKNIGHT", label = L["CLASS_DEATHKNIGHT"] or "Death Knight" },
        { value = "SHAMAN", label = L["CLASS_SHAMAN"] or "Shaman" },
        { value = "MAGE", label = L["CLASS_MAGE"] or "Mage" },
        { value = "WARLOCK", label = L["CLASS_WARLOCK"] or "Warlock" },
        { value = "DRUID", label = L["CLASS_DRUID"] or "Druid" },
    }
    CreateSettingsDropdown(
        L["SETTING_SET_PREVIEW_BG"] or "Set Preview Background:",
        setPreviewBgOptions,
        "setPreviewBackground",
        true,  -- Character-specific
        function(value)
            -- Update all set preview backgrounds immediately
            if mainFrame and mainFrame.setsPreviewPanel then
                mainFrame.setsPreviewPanel:UpdateAllBackgrounds(value)
            end
        end
    )
    
    yOffset = yOffset - 10
    
    -- Preview mode dropdown (character-specific)
    local previewModeOptions = {
        { value = "classic", label = L["SETTING_PREVIEW_CLASSIC"] or "Classic (WoW 3.3.5)" },
        { value = "hd", label = L["SETTING_PREVIEW_HD"] or "HD (Higher Detail)" },
    }
    CreateSettingsDropdown(
        L["SETTING_PREVIEW_MODE"] or "Grid Preview Mode:",
        previewModeOptions,
        "previewMode",
        true,  -- Character-specific
        function(value)
            previewSetupVersion = value
            -- Refresh grid if visible
            if mainFrame and mainFrame.previewGrid and mainFrame.previewGrid:IsVisible() then
                UpdatePreviewGrid()
            end
        end
    )
    
    -- ========================================
    -- SECTION: Tooltip Settings
    -- ========================================
    yOffset = yOffset - sectionSpacing
    CreateSectionHeader(L["SETTINGS_TOOLTIP_SECTION"] or "Tooltip Settings")
    yOffset = yOffset - 5
    
    CreateCheckbox(L["SETTING_SHOW_ITEM_ID"] or "Show Item ID in tooltip", "showItemIdTooltip", false)
    CreateCheckbox(L["SETTING_SHOW_DISPLAY_ID"] or "Show Display ID in tooltip", "showDisplayIdTooltip", false)
    CreateCheckbox(L["SETTING_SHOW_COLLECTED"] or 'Show "Appearance Collected" in tooltip', "showCollectedTooltip", false)
    CreateCheckbox(L["SETTING_SHOW_NEW"] or 'Show "New Appearance" in tooltip', "showNewAppearanceTooltip", false)
    CreateCheckbox(L["SETTING_SHOW_SHARED_APPEARANCE"] or "Show shared appearances in tooltips", "showSharedAppearanceTooltip", false)
    
    -- ========================================
    -- SECTION: Grid Preview Settings
    -- ========================================
    yOffset = yOffset - sectionSpacing
    CreateSectionHeader(L["SETTINGS_GRID_PREVIEW"] or "Grid Preview Settings")
    yOffset = yOffset - 5
    
    CreateCheckbox(L["SETTING_HIDE_HAIR_CLOAK"] or "Hide hair on Cloak slot preview", "hideHairOnCloakPreview", false)
    CreateCheckbox(L["SETTING_HIDE_HAIR_CHEST"] or "Hide hair/beard on Chest slot preview", "hideHairOnChestPreview", false)
    CreateCheckbox(L["SETTING_HIDE_HAIR_SHIRT"] or "Hide hair/beard on Shirt slot preview", "hideHairOnShirtPreview", false)
    CreateCheckbox(L["SETTING_HIDE_HAIR_TABARD"] or "Hide hair/beard on Tabard slot preview", "hideHairOnTabardPreview", false)
    CreateCheckbox(L["SETTING_MERGE_BY_DISPLAY_ID"] or "Merge items by appearance (Display ID)", "mergeByDisplayId", false)
    
    -- ========================================
    -- SECTION: Info
    -- ========================================
    yOffset = yOffset - sectionSpacing
    CreateSectionHeader(L["SETTINGS_INFO"] or "Information")
    yOffset = yOffset - 5
    
    local infoText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoText:SetPoint("TOPLEFT", 20, yOffset)
    infoText:SetWidth(520)
    infoText:SetJustifyH("LEFT")
    infoText:SetText(
        L["SETTINGS_INFO_TEXT"] or 
        "|cff888888Account-wide settings|r apply to all characters.\n" ..
        "|cff888888Character-specific settings|r (background, preview mode) are saved per character.\n\n" ..
        "Settings are saved automatically when changed."
    )
    
    -- Update content height based on items added
    content:SetHeight(math.abs(yOffset) + 50)
    
    return frame
end

-- ============================================================================
-- Sets Preview Panel
-- ============================================================================

local setsPreviewPanel = nil
local isSetsPreviewVisible = false
local setsPreviewModels = {}
local setsPreviewSlotFrames = {}

-- Slot order for set preview display
local SET_PREVIEW_SLOT_ORDER = {
    { name = "Head",          equipSlot = 0 },
    { name = "Shoulder",      equipSlot = 2 },
    { name = "Back",          equipSlot = 14 },
    { name = "Chest",         equipSlot = 4 },
    { name = "Shirt",         equipSlot = 3 },
    { name = "Tabard",        equipSlot = 18 },
    { name = "Wrist",         equipSlot = 8 },
    { name = "Hands",         equipSlot = 9 },
    { name = "Waist",         equipSlot = 5 },
    { name = "Legs",          equipSlot = 6 },
    { name = "Feet",          equipSlot = 7 },
    { name = "MainHand",      equipSlot = 15 },
    { name = "SecondaryHand", equipSlot = 16 },
    { name = "Ranged",        equipSlot = 17 },
}

local function CreateSetPreviewEntry(parent, index, setNumber, setData)
    -- Each entry: Dressing room model (left) + Slot grid with icons and names (right)
    local entryFrame = CreateFrame("Frame", nil, parent)
    entryFrame:SetSize(295, 200)
    entryFrame.setNumber = setNumber
    
    -- Set name label at top
    local nameLabel = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOP", entryFrame, "TOP", -40, 0)
    nameLabel:SetText(setData and setData.name or (L["SET_DEFAULT_NAME"] and string.format(L["SET_DEFAULT_NAME"], setNumber) or string.format("Set %d", setNumber)))
    nameLabel:SetTextColor(1, 0.82, 0)
    entryFrame.nameLabel = nameLabel
    
    -- Dressing room model frame with background
    local modelFrame = CreateFrame("Frame", nil, entryFrame)
    modelFrame:SetSize(130, 175)
    modelFrame:SetPoint("TOPLEFT", 5, -18)
    
    -- Background texture (class-based)
    local _, playerClass = UnitClass("player")
    local backgroundClass = GetSetting("setPreviewBackground") or playerClass
    local texturePath = TEXTURE_PATHS[backgroundClass] or TEXTURE_PATHS[playerClass] or TEXTURE_PATHS.WARLOCK
    
    local bgTexture = modelFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetPoint("TOPLEFT", 2, -2)
    bgTexture:SetPoint("BOTTOMRIGHT", -2, 2)
    bgTexture:SetTexture(texturePath)
    
    -- Calculate cropping for the smaller frame (130x175)
    local frameWidth, frameHeight = 130, 175
    local frameAspect = frameWidth / frameHeight  -- ~0.74
    local cropWidth = frameAspect
    local left = (1 - cropWidth) / 2
    local right = 1 - left
    bgTexture:SetTexCoord(left, right, 0, 1)
    
    modelFrame.bgTexture = bgTexture
    modelFrame.texCoordLeft = left
    modelFrame.texCoordRight = right
    
    -- Border only (no background fill since we have texture)
    modelFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    modelFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Update background function
    function modelFrame:UpdateBackground(overrideClass)
        local _, currentClass = UnitClass("player")
        local bgClass = overrideClass or GetSetting("setPreviewBackground") or currentClass
        local newTexturePath = TEXTURE_PATHS[bgClass] or TEXTURE_PATHS[currentClass] or TEXTURE_PATHS.WARLOCK
        self.bgTexture:SetTexture(newTexturePath)
        self.bgTexture:SetTexCoord(self.texCoordLeft, self.texCoordRight, 0, 1)
    end
    
    -- Create dress up model with proper positioning
    local model = CreateFrame("DressUpModel", nil, modelFrame)
    model:SetPoint("TOPLEFT", modelFrame, "TOPLEFT", 2, -2)
    model:SetPoint("BOTTOMRIGHT", modelFrame, "BOTTOMRIGHT", -2, 2)
    model:SetUnit("player")
    model:SetRotation(0)
    -- Position model up and back to fit in frame (x=zoom, y=horizontal, z=vertical)
    model:SetPosition(-0.2, 0, -0.1)
    
    -- Mouse interaction for rotating
    local isRotating = false
    local lastX = 0
    
    model:EnableMouse(true)
    model:EnableMouseWheel(true)
    
    model:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isRotating = true
            lastX = GetCursorPosition()
        end
    end)
    
    model:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            isRotating = false
        end
    end)
    
    model:SetScript("OnUpdate", function(self)
        if isRotating then
            local x = GetCursorPosition()
            local dx = x - lastX
            local rotation = self:GetFacing() + dx * 0.02
            self:SetFacing(rotation)
            lastX = x
        end
    end)
    
    model:SetScript("OnMouseWheel", function(self, delta)
        -- Zoom by adjusting camera distance
        local x, y, z = self:GetPosition()
        x = x + delta * 0.3
        x = math.max(-1, math.min(3, x))
        self:SetPosition(x, y, z)
    end)
    
    entryFrame.model = model
    entryFrame.modelFrame = modelFrame
    
    -- Slot icons and names container (right side of model)
    local slotsContainer = CreateFrame("Frame", nil, entryFrame)
    slotsContainer:SetSize(145, 180)
    slotsContainer:SetPoint("LEFT", modelFrame, "RIGHT", 5, 0)
    
    entryFrame.slotIcons = {}
    entryFrame.slotNames = {}
    
    local slotHeight = 13
    local slotSpacing = 0
    
    for i, slotInfo in ipairs(SET_PREVIEW_SLOT_ORDER) do
        local yPos = -((i - 1) * (slotHeight + slotSpacing))
        
        -- Slot icon
        local iconFrame = CreateFrame("Frame", nil, slotsContainer)
        iconFrame:SetSize(13, 13)
        iconFrame:SetPoint("TOPLEFT", 0, yPos)
        
        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        
        -- Get item from set data
        local itemId = setData and setData.slots and setData.slots[slotInfo.equipSlot]
        if itemId and itemId > 0 then
            local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
            if itemTexture then
                icon:SetTexture(itemTexture)
            else
                icon:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-" .. (SLOT_CONFIG[slotInfo.name] and SLOT_CONFIG[slotInfo.name].texture or "Chest"))
                -- Queue item info load
                GameTooltip:SetHyperlink("item:" .. itemId)
                GameTooltip:Hide()
            end
            
            -- Tooltip on hover
            iconFrame:EnableMouse(true)
            iconFrame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. itemId)
                GameTooltip:Show()
            end)
            iconFrame:SetScript("OnLeave", GameTooltip_Hide)
        else
            -- Empty slot - show slot texture
            icon:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-" .. (SLOT_CONFIG[slotInfo.name] and SLOT_CONFIG[slotInfo.name].texture or "Chest"))
            icon:SetVertexColor(0.3, 0.3, 0.3, 0.5)
        end
        
        iconFrame.icon = icon
        entryFrame.slotIcons[slotInfo.equipSlot] = iconFrame
        
        -- Item name
        local nameText = slotsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameText:SetPoint("LEFT", iconFrame, "RIGHT", 3, 0)
        nameText:SetWidth(120)
        nameText:SetJustifyH("LEFT")
        nameText:SetWordWrap(false)
        
        if itemId and itemId > 0 then
            local itemName, itemLink = GetItemInfo(itemId)
            if itemName then
                -- Get quality color
                local _, _, quality = GetItemInfo(itemId)
                local color = ITEM_QUALITY_COLORS[quality or 1]
                nameText:SetText(itemName)
                if color then
                    nameText:SetTextColor(color.r, color.g, color.b)
                end
            else
                nameText:SetText("Loading...")
                nameText:SetTextColor(0.5, 0.5, 0.5)
                -- Try to load item info
                C_Timer.After(0.5, function()
                    local name, link, q = GetItemInfo(itemId)
                    if name then
                        nameText:SetText(name)
                        local c = ITEM_QUALITY_COLORS[q or 1]
                        if c then nameText:SetTextColor(c.r, c.g, c.b) end
                    else
                        nameText:SetText("[Item " .. itemId .. "]")
                    end
                end)
            end
        else
            nameText:SetText("|cff666666" .. (L[slotInfo.name] or slotInfo.name) .. "|r")
        end
        
        entryFrame.slotNames[slotInfo.equipSlot] = nameText
    end
    
    entryFrame.slotsContainer = slotsContainer
    
    -- Function to apply set items to model
    function entryFrame:ApplySetToModel(setDataToApply)
        if not setDataToApply or not setDataToApply.slots then return end
        
        -- Reset model
        self.model:Undress()
        self.model:SetUnit("player")
        
        -- Apply each item via TryOn
        C_Timer.After(0.05, function()
            for equipSlot, itemId in pairs(setDataToApply.slots) do
                if itemId and itemId > 0 then
                    self.model:TryOn(itemId)
                end
            end
        end)
        
        -- Update name
        if setDataToApply.name then
            self.nameLabel:SetText(setDataToApply.name)
        end
        
        -- Update slot icons and names
        for _, slotInfo in ipairs(SET_PREVIEW_SLOT_ORDER) do
            local itemId = setDataToApply.slots[slotInfo.equipSlot]
            local iconFrame = self.slotIcons[slotInfo.equipSlot]
            local nameText = self.slotNames[slotInfo.equipSlot]
            
            if itemId and itemId > 0 then
                local _, _, quality, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
                if itemTexture then
                    iconFrame.icon:SetTexture(itemTexture)
                    iconFrame.icon:SetVertexColor(1, 1, 1, 1)
                end
                
                local itemName = GetItemInfo(itemId)
                if itemName then
                    nameText:SetText(itemName)
                    local c = ITEM_QUALITY_COLORS[quality or 1]
                    if c then nameText:SetTextColor(c.r, c.g, c.b) end
                end
                
                -- Enable tooltip
                iconFrame:EnableMouse(true)
                iconFrame.itemId = itemId  -- Store itemId for tooltip
                iconFrame:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink("item:" .. self.itemId)
                    GameTooltip:Show()
                end)
                iconFrame:SetScript("OnLeave", GameTooltip_Hide)
            else
                iconFrame.icon:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-" .. (SLOT_CONFIG[slotInfo.name] and SLOT_CONFIG[slotInfo.name].texture or "Chest"))
                iconFrame.icon:SetVertexColor(0.3, 0.3, 0.3, 0.5)
                nameText:SetText("|cff666666" .. (L[slotInfo.name] or slotInfo.name) .. "|r")
                iconFrame:EnableMouse(false)
            end
        end
    end
    
    -- Apply initial set data
    if setData then
        entryFrame:ApplySetToModel(setData)
    end
    
    return entryFrame
end

local function CreateSetsPreviewPanel(parent)
    local frame = CreateFrame("Frame", "$parentSetsPreviewPanel", parent)
    frame:SetSize(620, 460)  -- Same size as preview grid
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, 
        tileSize = 16, 
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    frame:Hide()  -- Hidden by default
    
    -- Title - centered
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText(L["SETS_PREVIEW_TITLE"] or "Saved Sets Preview")
    title:SetTextColor(1, 0.82, 0)
    
    -- Copy Player button (aligned with title on left)
    local copyPlayerBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    copyPlayerBtn:SetSize(100, 20)
    copyPlayerBtn:SetPoint("LEFT", frame, "TOPLEFT", 10, -17)
    copyPlayerBtn:SetText(L["COPY_PLAYER"] or "Copy Player")
    copyPlayerBtn:SetScript("OnClick", function()
        StaticPopup_Show("TRANSMOG_COPY_PLAYER")
    end)
    copyPlayerBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["COPY_PLAYER_TOOLTIP"] or "Copy Player Appearance")
        GameTooltip:AddLine(L["COPY_PLAYER_DESC"] or "Target a player and click to copy their visible equipment to your preview selection.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    copyPlayerBtn:SetScript("OnLeave", GameTooltip_Hide)
    frame.copyPlayerBtn = copyPlayerBtn
    
    -- Direct content frame (NO scroll - models break in scroll frames)
    local content = CreateFrame("Frame", "TransmogSetsPreviewContent", frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -35)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5)
    content:SetFrameLevel(frame:GetFrameLevel() + 1)
    content:Show()
    
    frame.content = content
    frame.setEntries = {}
    frame.sortedSets = {}
    frame.currentSetPage = 1
    frame.setsPerPage = 4
    
    -- Function to update all entry backgrounds
    function frame:UpdateAllBackgrounds(overrideClass)
        for _, entry in ipairs(self.setEntries) do
            if entry.modelFrame and entry.modelFrame.UpdateBackground then
                entry.modelFrame:UpdateBackground(overrideClass)
            end
        end
    end
    
    -- Function to refresh sets preview
    function frame:RefreshSetsPreview()
        -- Clear sorted sets
        wipe(self.sortedSets)
        
        -- Collect sets
        for i = 1, MAX_SETS do
            if transmogSets[i] then
                table.insert(self.sortedSets, { number = i, data = transmogSets[i] })
            end
        end
        
        -- Show first page
        self.currentSetPage = 1
        self:ShowSetPage(1)
    end
    
    -- Function to show a specific page of sets
    function frame:ShowSetPage(pageNum)
        -- Clear existing entries
        for _, entry in ipairs(self.setEntries) do
            entry:Hide()
            entry:SetParent(nil)
        end
        wipe(self.setEntries)
        
        local setCount = #self.sortedSets
        local totalPages = math.max(1, math.ceil(setCount / self.setsPerPage))
        
        -- Clamp page
        pageNum = math.max(1, math.min(pageNum, totalPages))
        self.currentSetPage = pageNum
        
        -- Handle empty state
        if setCount == 0 then
            if not self.noSetsText then
                self.noSetsText = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                self.noSetsText:SetPoint("CENTER", self.content, "CENTER", 0, 0)
                self.noSetsText:SetText(L["NO_SETS_SAVED"] or "No sets saved.\nUse the Save button to save your current selections as a set.")
                self.noSetsText:SetTextColor(0.7, 0.7, 0.7)
            end
            self.noSetsText:Show()
            if mainFrame and mainFrame.pageText then
                mainFrame.pageText:SetText(string.format(L["SETS_COUNT"] or "%d sets", 0))
            end
            return
        end
        
        if self.noSetsText then
            self.noSetsText:Hide()
        end
        
        -- Calculate range for this page
        local startIdx = (pageNum - 1) * self.setsPerPage + 1
        local endIdx = math.min(startIdx + self.setsPerPage - 1, setCount)
        
        -- Grid layout
        local entriesPerRow = 2
        local entryWidth = 300
        local entryHeight = 205
        local colSpacing = 5
        local rowSpacing = 5
        
        local pageIdx = 0
        for idx = startIdx, endIdx do
            local setInfo = self.sortedSets[idx]
            local row = math.floor(pageIdx / entriesPerRow)
            local col = pageIdx % entriesPerRow
            
            local entry = CreateSetPreviewEntry(self.content, pageIdx + 1, setInfo.number, setInfo.data)
            entry:SetPoint("TOPLEFT", self.content, "TOPLEFT", col * (entryWidth + colSpacing), -(row * (entryHeight + rowSpacing)))
            entry:Show()
            
            table.insert(self.setEntries, entry)
            pageIdx = pageIdx + 1
        end
        
        -- Update external page text
        if mainFrame and mainFrame.pageText then
            if totalPages > 1 then
                mainFrame.pageText:SetText(string.format(L["PAGE"] or "Page %d/%d", pageNum, totalPages) .. " | " .. string.format(L["SETS_COUNT"] or "%d sets", setCount))
            else
                mainFrame.pageText:SetText(string.format(L["SETS_COUNT"] or "%d sets", setCount))
            end
        end
    end
    
    -- Page change function
    function frame:ChangeSetPage(delta)
        local totalPages = math.max(1, math.ceil(#self.sortedSets / self.setsPerPage))
        local newPage = self.currentSetPage + delta
        if newPage >= 1 and newPage <= totalPages then
            self:ShowSetPage(newPage)
        end
    end
    
    -- Mouse wheel for page navigation
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(self, delta)
        self:ChangeSetPage(-delta)
    end)
    
    return frame
end

-- ============================================================================
-- Copy Player Appearance Dialog
-- ============================================================================

StaticPopupDialogs["TRANSMOG_COPY_PLAYER"] = {
    text = L["COPY_PLAYER_PROMPT"] or "Enter player name to copy appearance\n(or target a player first):",
    button1 = L["COPY"] or "Copy",
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 32,
    OnShow = function(self)
        -- Pre-fill with target name if targeting a player
        local targetName = UnitName("target")
        if targetName and UnitIsPlayer("target") then
            self.editBox:SetText(targetName)
        else
            self.editBox:SetText("")
        end
        self.editBox:SetFocus()
    end,
    OnAccept = function(self)
        local playerName = self.editBox:GetText():trim()
        if playerName and playerName ~= "" then
            -- Request copy from server
            AIO.Msg():Add("TRANSMOG", "CopyPlayerAppearance", playerName):Send()
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        StaticPopupDialogs["TRANSMOG_COPY_PLAYER"].OnAccept(parent)
        parent:Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- ============================================================================
-- Main Frame
-- ============================================================================

local function CreateMainFrame()
    local frame = CreateFrame("Frame", "TransmogMainFrame", UIParent)
    frame:SetSize(1020, 700)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, 30)
    title:SetText(L["ADDON_TITLE"])
    
    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructions:SetPoint("TOP", title, "BOTTOM", 0, -2)
    instructions:SetText(L["INSTRUCTIONS"])
    
    local closeBtn = CreateFrame("Button", "$parentClose", frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    
    local slotContainer = CreateFrame("Frame", "$parentSlots", frame)
    slotContainer:SetPoint("TOPLEFT", 12, -55)
    slotContainer:SetSize(40, 460)
    
    local numSlots = #SLOT_ORDER
    local buttonSize = 32
    local totalButtonHeight = numSlots * buttonSize
    local remainingSpace = 460 - totalButtonHeight
    local gap = remainingSpace / (numSlots - 1)
    local slotSpacing = buttonSize + gap
    
    for i, slotName in ipairs(SLOT_ORDER) do
        local btn = CreateSlotButton(slotContainer, slotName)
        btn:SetPoint("TOPLEFT", 0, -math.floor((i - 1) * slotSpacing))
        slotButtons[slotName] = btn
    end
    
    -- ============================================================================
    -- Mode Toggle Button (Item/Enchant)
    -- ============================================================================
    modeToggleButton = CreateFrame("Button", "$parentModeToggle", frame, "ItemButtonTemplate")
    modeToggleButton:SetSize(18, 18)
    modeToggleButton:SetPoint("TOP", slotContainer, "BOTTOM", 4, -10)
    
    local modeNormal = modeToggleButton:GetNormalTexture()
    if modeNormal then modeNormal:SetTexture(nil) end
    
    modeToggleButton.BG = modeToggleButton:CreateTexture(nil, "BACKGROUND")
    modeToggleButton.BG:SetTexture("Interface\\AddOns\\MOD-TRANSMOG-SYSTEM\\Assets\\uiframediamondmetalclassicborder")
    modeToggleButton.BG:SetTexCoord(0, 0.5625, 0, 0.5625)
    modeToggleButton.BG:SetSize(29, 29)
    modeToggleButton.BG:SetPoint("CENTER")
    
    modeToggleButton.Icon = modeToggleButton:CreateTexture(nil, "ARTWORK")
    modeToggleButton.Icon:SetTexture("Interface\\Icons\\INV_Fabric_Silk_02")
    modeToggleButton.Icon:SetSize(17, 17)
    modeToggleButton.Icon:SetPoint("CENTER")
    
    modeToggleButton.Border = modeToggleButton:CreateTexture(nil, "OVERLAY")
    modeToggleButton.Border:SetTexture("Interface\\CharacterFrame\\UI-Character-Slot-Border")
    modeToggleButton.Border:SetAllPoints()
    modeToggleButton.Border:SetDrawLayer("OVERLAY", 6)
    
    modeToggleButton.ModeText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeToggleButton.ModeText:SetPoint("TOP", modeToggleButton, "BOTTOM", 0, -2)
    modeToggleButton.ModeText:SetText(L["MODE_ITEM"] or "Items")
    
    local function UpdateModeUI()
        if currentTransmogMode == TRANSMOG_MODE_ITEM then
            modeToggleButton.Icon:SetTexture("Interface\\Icons\\INV_Fabric_Silk_02")
            modeToggleButton.ModeText:SetText(L["MODE_ITEM"] or "Items")
            modeToggleButton.ModeText:SetTextColor(1, 1, 1)
            -- Only show dropdowns/searchbar if settings or sets preview is not visible
            if not isSettingsVisible and not isSetsPreviewVisible then
                if subclassDropdown then subclassDropdown:Show() end
                if qualityDropdown then qualityDropdown:Show() end
                if collectionFilterDropdown then collectionFilterDropdown:Show() end
                if frame.searchBar then frame.searchBar:Show() end
            end
            for slotName, btn in pairs(slotButtons) do
                btn:SetAlpha(1.0)
                btn:Enable()
            end
        else
            modeToggleButton.Icon:SetTexture("Interface\\Icons\\Trade_Engraving")
            modeToggleButton.ModeText:SetText(L["MODE_ENCHANT"] or "Enchants")
            modeToggleButton.ModeText:SetTextColor(0.5, 0.8, 1)
            if subclassDropdown then subclassDropdown:Hide() end
            if qualityDropdown then qualityDropdown:Hide() end
            if collectionFilterDropdown then collectionFilterDropdown:Hide() end
            if frame.searchBar then frame.searchBar:Hide() end
            for slotName, btn in pairs(slotButtons) do
                if ENCHANT_ELIGIBLE_SLOTS[slotName] then
                    btn:SetAlpha(1.0)
                    btn:Enable()
                else
                    btn:SetAlpha(0.3)
                    btn:Disable()
                end
            end
            if not ENCHANT_ELIGIBLE_SLOTS[currentSlot] then
                currentSlot = "MainHand"
                for name, btn in pairs(slotButtons) do
                    btn:SetChecked(name == currentSlot)
                end
            end
        end
        UpdatePreviewGrid()
        UpdateSlotButtonIcons()  -- Update slot icons/borders for new mode
    end
    
    modeToggleButton:SetScript("OnClick", function()
        if currentTransmogMode == TRANSMOG_MODE_ITEM then
            currentTransmogMode = TRANSMOG_MODE_ENCHANT
        else
            currentTransmogMode = TRANSMOG_MODE_ITEM
        end
        UpdateModeUI()
        PlaySound("igMainMenuOptionCheckBoxOn")
    end)
    
    modeToggleButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if currentTransmogMode == TRANSMOG_MODE_ITEM then
            GameTooltip:SetText(L["MODE_TOGGLE_TOOLTIP_ITEM"] or "Item Transmog Mode")
            GameTooltip:AddLine(L["MODE_TOGGLE_DESC_ITEM"] or "Click to switch to Enchant Mode", 1, 1, 1)
        else
            GameTooltip:SetText(L["MODE_TOGGLE_TOOLTIP_ENCHANT"] or "Enchant Transmog Mode")
            GameTooltip:AddLine(L["MODE_TOGGLE_DESC_ENCHANT"] or "Click to switch to Item Mode", 1, 1, 1)
            GameTooltip:AddLine(L["MODE_ENCHANT_NOTE"] or "Only weapons show enchant visuals", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)
    modeToggleButton:SetScript("OnLeave", GameTooltip_Hide)
    
    frame.modeToggleButton = modeToggleButton
    frame.UpdateModeUI = UpdateModeUI
    
    dressingRoom = CreateDressingRoom(frame)
    dressingRoom:SetPoint("TOPLEFT", 55, -55)
    frame.dressingRoom = dressingRoom
    
    -- Subclass dropdown
    subclassDropdown = CreateSubclassDropdown(frame)
    subclassDropdown:SetPoint("TOPLEFT", 320, -25)
    frame.subclassDropdown = subclassDropdown
    
    -- Quality dropdown - REMOVE THE "local" keyword here
    qualityDropdown = CreateFrame("Frame", "TransmogQualityDropdown", frame, "UIDropDownMenuTemplate")
    qualityDropdown:SetPoint("LEFT", subclassDropdown, "RIGHT", 10, 0)
    UIDropDownMenu_SetWidth(qualityDropdown, 100)
    frame.qualityDropdown = qualityDropdown
    
    -- NEW: Collection Filter dropdown (next to quality dropdown)
    collectionFilterDropdown = CreateFrame("Frame", "TransmogCollectionFilterDropdown", frame, "UIDropDownMenuTemplate")
    collectionFilterDropdown:SetPoint("LEFT", qualityDropdown, "RIGHT", 10, 0)
    UIDropDownMenu_SetWidth(collectionFilterDropdown, 100)
    frame.collectionFilterDropdown = collectionFilterDropdown
    
    local previewGrid = CreatePreviewGrid(frame)
    previewGrid:SetPoint("TOPLEFT", 355, -55)
    frame.previewGrid = previewGrid
    
    -- Create settings panel (same position as grid, hidden by default)
    settingsPanel = CreateSettingsPanel(frame)
    settingsPanel:SetPoint("TOPLEFT", 355, -55)
    frame.settingsPanel = settingsPanel
    
    -- Create sets preview panel (same position as grid, hidden by default)
    setsPreviewPanel = CreateSetsPreviewPanel(frame)
    setsPreviewPanel:SetPoint("TOPLEFT", 355, -55)
    frame.setsPreviewPanel = setsPreviewPanel
    
    local resetBtn = CreateFrame("Button", "$parentReset", frame, "UIPanelButtonTemplate")
    resetBtn:SetSize(65, 22)
    resetBtn:SetPoint("TOPLEFT", dressingRoom, "BOTTOMLEFT", 10, -8)
    resetBtn:SetText(L["RESET"])
    resetBtn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            -- Right-Click: Clear ALL active transmogs (like right-clicking slots individually)
            local clearedCount = 0
            for _, slotName in ipairs(SLOT_ORDER) do
                local slotId = SLOT_NAME_TO_EQUIP_SLOT[slotName]
                if slotId then
                    -- Check if slot has active transmog (activeTransmogs uses slotId as key)
                    if activeTransmogs[slotId] then
                        RemoveTransmog(slotName)
                        clearedCount = clearedCount + 1
                    end
                    -- Also clear enchant if applicable
                    if activeEnchantTransmogs[slotId] then
                        RemoveEnchantTransmog(slotName)
                        clearedCount = clearedCount + 1
                    end
                end
            end
            -- Also reset the dressing room
            dressingRoom:Reset()
            -- Clear all selections
            slotSelectedItems = {}
            slotSelectedEnchants = {}
            PlaySound("igMainMenuOptionCheckBoxOn")
            if clearedCount > 0 then
                print(string.format(L["CLEAR_ALL_SUCCESS"] or "|cff00ff00[Transmog]|r Cleared %d transmog slots", clearedCount))
            else
                print(L["CLEAR_ALL_NONE"] or "|cff00ff00[Transmog]|r No active transmogs to clear")
            end
        else
            -- Left-Click: Reset dressing room preview only
            dressingRoom:Reset()
            PlaySound("igMainMenuOptionCheckBoxOn")
        end
    end)
    resetBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    resetBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["RESET_TOOLTIP"] or "Reset Preview", 1, 1, 1)
        GameTooltip:AddLine(L["RESET_DESC"] or "Resets the dressing room to your current appearance", 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["RESET_RIGHTCLICK_HINT"] or "|cffff0000Right-Click|r to clear ALL active transmogs", 1, 0.8, 0, true)
        GameTooltip:Show()
    end)
    resetBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    local undressBtn = CreateFrame("Button", "$parentUndress", frame, "UIPanelButtonTemplate")
    undressBtn:SetSize(65, 22)
    undressBtn:SetPoint("LEFT", resetBtn, "RIGHT", 5, 0)
    undressBtn:SetText(L["UNDRESS"])
    undressBtn:SetScript("OnClick", function()
        dressingRoom:Undress()
        PlaySound("igMainMenuOptionCheckBoxOn")
    end)
    
    -- Apply button - applies ALL selected items/enchants (cyan preview)
    local applyBtn = CreateFrame("Button", "$parentApply", frame, "UIPanelButtonTemplate")
    applyBtn:SetSize(80, 22)
    applyBtn:SetPoint("LEFT", undressBtn, "RIGHT", 5, 0)
    applyBtn:SetText(L["APPLY"])
    applyBtn:SetScript("OnClick", function()
        local appliedCount = 0
        
        if currentTransmogMode == TRANSMOG_MODE_ENCHANT then
            -- Apply ALL selected enchants across all weapon slots
            for _, slotName in ipairs(SLOT_ORDER) do
                local selectedEnchant = slotSelectedEnchants[slotName]
                if selectedEnchant then
                    ApplyEnchantTransmog(slotName, selectedEnchant)
                    appliedCount = appliedCount + 1
                end
            end
        else
            -- Apply ALL selected items across all slots
            for _, slotName in ipairs(SLOT_ORDER) do
                local selectedItem = slotSelectedItems[slotName]
                if selectedItem then
                    local itemIdToApply = selectedItem
                    
                    -- Skip display ID resolution for hide option (itemId = 0)
                    if selectedItem ~= 0 then
                        -- Check if we need to use a shared display ID item instead
                        local isAvailable, availableItemId = IsAppearanceAvailable(selectedItem)
                        if isAvailable and availableItemId then
                            itemIdToApply = availableItemId
                        end
                    end
                    
                    ApplyTransmog(slotName, itemIdToApply)
                    appliedCount = appliedCount + 1
                end
            end
        end
        
        if appliedCount > 0 then
            PlaySound("igCharacterInfoTab")
            print(string.format(L["APPLY_ALL_SUCCESS"] or "|cff00ff00[Transmog]|r Applied %d appearances", appliedCount))
        else
            print(L["APPLY_ALL_NONE"] or "|cffff0000[Transmog]|r No appearances selected to apply")
        end
    end)
    applyBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["APPLY_ALL_TOOLTIP"] or "Apply All Selected", 1, 1, 1)
        GameTooltip:AddLine(L["APPLY_ALL_DESC"] or "Applies all items shown with cyan border to your character", 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["APPLY_SINGLE_HINT"] or "|cff00ff00Shift+Click|r on a grid item to apply only that appearance", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    applyBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Set management controls (below dressing room buttons)
    local setControls = CreateSetControls(frame, dressingRoom)
    setControls:SetPoint("TOP", resetBtn, "BOTTOM", 70, -10)
    frame.setControls = setControls
    
    -- Add search bar after preview grid
    local searchBar = CreateSearchBar(frame, previewGrid)
    searchBar:SetPoint("BOTTOM", previewGrid, "BOTTOM", 0, -70)
    frame.searchBar = searchBar
    
    -- close search bar on key escape
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
            PlaySound("igCharacterInfoClose")
        end
    end)
    frame:EnableKeyboard(true)
    
    -- Create a container frame for the page text with background and border
    local pageContainer = CreateFrame("Frame", nil, frame)
    pageContainer:SetSize(620, 30)
    pageContainer:SetPoint("BOTTOM", previewGrid, "BOTTOM", 0, -35)
    
    -- Set background and border for the container
    pageContainer:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    pageContainer:SetBackdropColor(0, 0, 0, 0.6)
    pageContainer:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Create the page text inside the container
    local pageText = pageContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageText:SetPoint("CENTER", pageContainer, "CENTER", 0, 0)
    pageText:SetText(L["PAGE"] and string.format(L["PAGE"], 1, 1))
    frame.pageText = pageText
    frame.pageContainer = pageContainer
    
    -- ========================================
    -- Settings Button (top right corner of grid area)
    -- ========================================
    local settingsBtn = CreateFrame("Button", "TransmogSettingsButton", frame, "UIPanelButtonTemplate")
    settingsBtn:SetSize(80, 22)
    settingsBtn:SetPoint("TOPRIGHT", previewGrid, "TOPRIGHT", 0, 25)
    settingsBtn:SetText(L["SETTINGS"] or "Settings")
    
    -- ========================================
    -- Sets Preview Button (left of Settings button)
    -- ========================================
    local setsPreviewBtn = CreateFrame("Button", "TransmogSetsPreviewButton", frame, "UIPanelButtonTemplate")
    setsPreviewBtn:SetSize(50, 22)
    setsPreviewBtn:SetPoint("RIGHT", settingsBtn, "LEFT", -5, 0)
    setsPreviewBtn:SetText(L["SETS_PREVIEW"] or "Sets")
    
    -- Helper function to return to grid view
    local function ShowGridView()
        -- Hide all panels
        settingsPanel:Hide()
        setsPreviewPanel:Hide()
        
        -- Show grid elements
        previewGrid:Show()
        searchBar:Show()
        pageContainer:Show()
        
        -- Show dropdowns (only in item mode)
        if currentTransmogMode == TRANSMOG_MODE_ITEM then
            if subclassDropdown then subclassDropdown:Show() end
            if qualityDropdown then qualityDropdown:Show() end
            if collectionFilterDropdown then collectionFilterDropdown:Show() end
        end
        
        -- Reset button texts
        settingsBtn:SetText(L["SETTINGS"] or "Settings")
        setsPreviewBtn:SetText(L["SETS_PREVIEW"] or "Sets")
        
        -- Reset visibility states
        isSettingsVisible = false
        isSetsPreviewVisible = false
        
        -- Refresh grid
        UpdatePreviewGrid()
    end
    
    -- Toggle function for settings
    local function ToggleSettings()
        if isSettingsVisible then
            -- Going back to grid
            ShowGridView()
        else
            -- Show settings
            isSetsPreviewVisible = false
            isSettingsVisible = true
            
            previewGrid:Hide()
            setsPreviewPanel:Hide()
            settingsPanel:Show()
            searchBar:Hide()
            pageContainer:Hide()
            
            -- Hide dropdowns
            if subclassDropdown then subclassDropdown:Hide() end
            if qualityDropdown then qualityDropdown:Hide() end
            if collectionFilterDropdown then collectionFilterDropdown:Hide() end
            
            -- Update button texts
            settingsBtn:SetText(L["BACK"] or "Back")
            setsPreviewBtn:SetText(L["SETS_PREVIEW"] or "Sets")
        end
        
        PlaySound("igMainMenuOptionCheckBoxOn")
    end
    
    -- Toggle function for sets preview
    local function ToggleSetsPreview()
        if isSetsPreviewVisible then
            -- Going back to grid
            ShowGridView()
        else
            -- Show sets preview
            isSettingsVisible = false
            isSetsPreviewVisible = true
            
            previewGrid:Hide()
            settingsPanel:Hide()
            setsPreviewPanel:Show()
            searchBar:Hide()
            pageContainer:Show()  -- Show page container below sets panel
            
            -- Hide dropdowns
            if subclassDropdown then subclassDropdown:Hide() end
            if qualityDropdown then qualityDropdown:Hide() end
            if collectionFilterDropdown then collectionFilterDropdown:Hide() end
            
            -- Update button texts
            settingsBtn:SetText(L["SETTINGS"] or "Settings")
            setsPreviewBtn:SetText(L["BACK"] or "Back")
            
            -- Refresh sets preview (handles pageText update)
            setsPreviewPanel:RefreshSetsPreview()
        end
        
        PlaySound("igMainMenuOptionCheckBoxOn")
    end
    
    settingsBtn:SetScript("OnClick", ToggleSettings)
    settingsBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        if isSettingsVisible then
            GameTooltip:SetText(L["BACK_TOOLTIP"] or "Back to Items")
            GameTooltip:AddLine(L["BACK_DESC"] or "Click to return to item grid", 1, 1, 1)
        else
            GameTooltip:SetText(L["SETTINGS_TOOLTIP"] or "Settings")
            GameTooltip:AddLine(L["SETTINGS_DESC"] or "Click to open settings", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    settingsBtn:SetScript("OnLeave", GameTooltip_Hide)
    
    setsPreviewBtn:SetScript("OnClick", ToggleSetsPreview)
    setsPreviewBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        if isSetsPreviewVisible then
            GameTooltip:SetText(L["BACK_TOOLTIP"] or "Back to Items")
            GameTooltip:AddLine(L["BACK_DESC"] or "Click to return to item grid", 1, 1, 1)
        else
            GameTooltip:SetText(L["SETS_PREVIEW_TOOLTIP"] or "Saved Sets Preview")
            GameTooltip:AddLine(L["SETS_PREVIEW_DESC"] or "View all your saved transmog sets with dressing room preview", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    setsPreviewBtn:SetScript("OnLeave", GameTooltip_Hide)
    
    frame.settingsBtn = settingsBtn
    frame.setsPreviewBtn = setsPreviewBtn
    frame.ToggleSettings = ToggleSettings
    frame.ToggleSetsPreview = ToggleSetsPreview
    frame.ShowGridView = ShowGridView
    
    tinsert(UISpecialFrames, frame:GetName())
    
    return frame
end

-- ============================================================================
-- Character Frame Tab
-- ============================================================================

local function CreateCharacterFrameTab()
    local tab = CreateFrame("Button", nil, CharacterFrame, "ItemButtonTemplate")
    tab:SetSize(36, 36)
    tab:SetPoint("BOTTOMLEFT", CharacterModelFrame, "BOTTOMLEFT", 0, -20)
    tab:EnableMouse(true)
    tab:SetMovable(false)
    tab:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Strata aligned on CharacterFrame
    tab:SetFrameStrata(CharacterFrame:GetFrameStrata())
    tab:SetFrameLevel(CharacterFrame:GetFrameLevel() + 5)

    -- Hide default normal texture
    local normal = tab:GetNormalTexture()
    if normal then
        normal:SetTexture(nil)
    end
    -- Second background ornament to replace wrists for smoother ui
    tab.BG2 = tab:CreateTexture(nil, "BACKGROUND")
    tab.BG2:SetTexture("Interface\\AddOns\\MOD-TRANSMOG-SYSTEM\\Assets\\uiframediamondmetalclassicborder")
    tab.BG2:SetTexCoord(0, 0.5625, 0, 0.5625)
	tab.BG2:SetPoint("center", CharacterFrame, "center", -152, -124)
    tab.BG2:SetSize(58, 58)
	
    -- Background ornament
    tab.BG = tab:CreateTexture(nil, "BACKGROUND")
    tab.BG:SetTexture("Interface\\AddOns\\MOD-TRANSMOG-SYSTEM\\Assets\\uiframediamondmetalclassicborder")
    tab.BG:SetTexCoord(0, 0.5625, 0, 0.5625)
    tab.BG:SetSize(58, 58)
    tab.BG:SetPoint("CENTER")

    -- Icon
    tab.Icon = tab:CreateTexture(nil, "ARTWORK")
    tab.Icon:SetTexture("Interface\\Icons\\Spell_holy_divineprovidence")
    tab.Icon:SetSize(37, 37)
    tab.Icon:SetPoint("CENTER")

    -- Blizzard slot border
    tab.Border = tab:CreateTexture(nil, "OVERLAY")
    tab.Border:SetTexture("Interface\\CharacterFrame\\UI-Character-Slot-Border")
    tab.Border:SetAllPoints()
    tab.Border:SetDrawLayer("OVERLAY", 6)

    -- Click handler
    tab:SetScript("OnClick", function(self)
        PlaySound("igCharacterInfoTab")
        if mainFrame then
            if mainFrame:IsShown() then
                mainFrame:Hide()
            else
                mainFrame:Show()
            end
        end
    end)

    -- Mouse feedback
    tab:SetScript("OnMouseDown", function(self)
        self.Icon:SetAlpha(0.7)
    end)

    tab:SetScript("OnMouseUp", function(self)
        self.Icon:SetAlpha(1.0)
    end)

    -- Tooltip
    tab:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["TAB_NAME"])
        GameTooltip:Show()
    end)

    tab:SetScript("OnLeave", GameTooltip_Hide)
    tab:Hide()

    local function UpdateTabVisibility()
        local selectedTab = PanelTemplates_GetSelectedTab(CharacterFrame) or 1
        if selectedTab == 1 then
            tab:Show()
        else
            tab:Hide()
        end
    end

    -- Hook on CharacterFrame opening
    CharacterFrame:HookScript("OnShow", UpdateTabVisibility)

    -- Update when changing tab
    hooksecurefunc("CharacterFrame_ShowSubFrame", UpdateTabVisibility)

    return tab
end

-- ============================================================================
-- Initialization
-- ============================================================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:RegisterEvent("PLAYER_LOGOUT")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGOUT" then
        -- Save cache to SavedVariables on logout
        SaveCacheToSavedVariables()
        return
    end
    
    if event == "PLAYER_ENTERING_WORLD" then
        -- Initialize settings system
        InitializeSettings()
        UpdatePreviewMode()
        
        -- Load cache from SavedVariables first
        LoadCacheFromSavedVariables()
        
        -- Initialize slot selected items table
        slotSelectedItems = {}
        
        -- Initialize quality and collection filter storage for all slots
        for _, slotName in ipairs(SLOT_ORDER) do
            slotSelectedQuality[slotName] = "All"
            slotSelectedCollectionFilter[slotName] = "Collected"  -- NEW: Default to Collected
        end
        
        -- Request fresh data from server after delay
        -- NEW: Use cache-based system for better performance
        C_Timer.After(2, function()
            -- Request server settings (hide slots, etc.)
            RequestSettingsFromServer()
            
            -- Request player's collection status (small payload)
            RequestCollectionStatusFromServer()
            -- Also support legacy for backwards compatibility
            RequestCollectionFromServer()
            
            RequestActiveTransmogsFromServer()
            RequestSetsFromServer()
            
            -- Request FULL item cache (all slots at once)
            -- This is the key performance improvement - only done once
            RequestFullCacheFromServer()
            
            -- Request enchant cache (versioned)
            RequestEnchantCacheFromServer()
            -- Fallback to legacy if cache not supported
            RequestEnchantCollectionFromServer()
            RequestActiveEnchantTransmogsFromServer()
        end)
        
        mainFrame = CreateMainFrame()
        CreateCharacterFrameTab()
        
        currentSlot = "Head"
        currentSubclass = slotSelectedSubclass["Head"] or "All"
        currentQuality = slotSelectedQuality["Head"] or "All"
        currentCollectionFilter = "Collected"  -- NEW: Default to Collected
        currentItems = {}
        
        if slotButtons["Head"] then
            slotButtons["Head"]:SetChecked(true)
        end
        
        mainFrame:SetScript("OnShow", function()
            UpdateSubclassDropdown()
            UpdateQualityDropdown()
            UpdateCollectionFilterDropdown()  -- NEW
            UpdateSetDropdown()
            
            -- If search is active, show search results
            if searchActive and lastSearchText ~= "" then
                local currentSlotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
                if searchSlotResults[currentSlotId] then
                    currentItems = searchSlotResults[currentSlotId]
                end
            else
                -- Use local cache for filtering (no server request)
                local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
                
                if IsFullCacheReady() then
                    -- Use locally filtered cache - NO server request
                    currentItems = FilterCachedItemsForSlot(slotId, currentSubclass, currentQuality, currentCollectionFilter)
                else
                    -- Cache not ready yet, request it (will update display when received)
                    currentItems = {}
                    if not pendingFullCacheRequest then
                        RequestFullCacheFromServer()
                    end
                    
                    if mainFrame and mainFrame.pageText then
                        mainFrame.pageText:SetText("Loading cache...")
                    end
                end
            end
            
            -- Ensure preview grid is updated
            UpdatePreviewGrid()
        end)
        
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

-- ============================================================================
-- Slash Commands
-- ============================================================================

SLASH_TRANSMOG1 = "/transmog"
SLASH_TRANSMOG2 = "/tmog"
SlashCmdList["TRANSMOG"] = function(msg)
    local cmd = msg:lower():trim()
    PlaySound("igCharacterInfoOpen")
    if cmd == "help" then
        print(L["HELP_1"])
        print(L["HELP_2"])
        print(L["HELP_3"])
        return
    end
    
    -- Default: toggle window
    if mainFrame then
        if mainFrame:IsShown() then
            mainFrame:Hide()
        else
            mainFrame:Show()
        end
    end
end

-- Export functions to addon namespace
Transmog.IsAppearanceCollected = IsAppearanceCollected
Transmog.ApplyTransmog = ApplyTransmog
Transmog.RemoveTransmog = RemoveTransmog
Transmog.GetActiveTransmog = GetActiveTransmog
Transmog.GetCollectionCount = GetCollectionCount

print(L["SLASH_TRANSMOG"])