-- [Author : Thiesant] This script is free, if you bought it you got scammed.
-- v0.6
    -- ============================================================================

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                   MOD-TRANSMOG-SYSTEM — LUA IMPLEMENTATION                   ║
-- ╠══════════════════════════════════════════════════════════════════════════════╣
-- ║ Requirements:                                                                ║
-- ║  • AzerothCore's "Eluna" Framework (mod-ale)                                 ║
-- ║  • AIO addon framework                                                       ║
-- ║  • Characters database tables (import .sql to Acore_characters)              ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝


-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                               TRANSMOG OPTIONS                               ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- Values  : true or false
-- Default : true

-- ──────────────────────────────────── SCRIPT ────────────────────────────────────

-- ENABLE_AIO_BRIDGE
-- Set to false if you need to desactivate full script
-- Client Addon will be unable to querry collected items or use/save transmog
local ENABLE_AIO_BRIDGE = true


-- ────────────────────────────────── LOGIN SCAN ──────────────────────────────────

-- ENABLE_SCAN_ITEMS
-- Workaround for missing hooks: scans full inventory on login (bags, bank, equipement)
local ENABLE_SCAN_ITEMS = true

-- ENABLE_SCAN_QUESTS
-- Sync quest items done prior to script installation
local ENABLE_SCAN_QUESTS = true


-- ────────────────────────── COLLECTION ON PLAYER LOGIN ──────────────────────────

-- COLLECTION_ON_CHARACTER_LOGIN_SCANNED_ITEMS
-- In pair with ENABLE_SCAN_ITEMS : allow to add items on collection from scan results
-- This is used for item from trade, mail, repurchased from vendor, item restoration
local COLLECTION_ON_CHARACTER_LOGIN_SCANNED_ITEMS = true

-- COLLECTION_ON_PREVIOUS_QUESTS
-- In pair with ENABLE_SCAN_QUESTS : allow to add items on collection from scan results
-- This is used to add items to collection from ongoing and turned quests prior to 
-- this script installation, containers rewards are skipped to avoid abuse
local COLLECTION_ON_PREVIOUS_QUESTS = true


-- ─────────────────────────────── COLLECTION RULES ───────────────────────────────
-- The following descriptions are not exhaustive, you should let them on true unless
-- You intend to make strict rules for new transmo aquisition

-- Item equipped on character slot
local COLLECTION_ON_EQUIP                  = true

-- Item from corpse, pickpocket
local COLLECTION_ON_LOOT_ITEM              = true

-- Item rewarded from quest
local COLLECTION_ON_QUEST_REWARD_ITEM      = true

-- Item crafted
local COLLECTION_ON_CREATE_ITEM            = true

-- Item obtained from character creation or master loot
local COLLECTION_ON_STORE_NEW_ITEM         = true

-- Item rewarded from quest and choices rewards
local COLLECTION_ON_COMPLETE_QUEST         = true

-- Item earned from dice roll
local COLLECTION_ON_GROUP_ROLL_REWARD_ITEM = true


-- ────────────────────────────── TRANSMOGRIFICATION ──────────────────────────────

-- OnPlayerLogin : Force to refresh actives transmog
local ENABLE_APPLY_ALL_TRANSMOGS = true

-- If set to false, player won't be able to use transmog appearance though,
-- they are still able to save them in server DB no matter the setting
local ENABLE_TRANSMOG_APPLY_TRANSMOG_VISUAL = true

-- ALLOW_UNCOLLECTED_TRANSMOG
-- Set to true to allow players to apply transmog from items they haven't collected
-- When true, players can use any valid transmog appearance (useful for testing or custom servers)
-- When false (default), players must have the item in their collection to use it
local ALLOW_UNCOLLECTED_TRANSMOG = false


-- ───────────────────────────────── MIRROR IMAGE ─────────────────────────────────

-- MIRROR_IMAGE_TRANSMOG_ENABLED
-- Shows player's transmog appearance on Mirror Image clones (Mage spell)
local MIRROR_IMAGE_TRANSMOG_ENABLED = true


-- ───────────────────────────────── ITEM QUALITY ─────────────────────────────────

-- Allowed item qualities for transmog (by quality ID)
-- 0 = Poor, 1 = Common, 2 = Uncommon, 3 = Rare, 4 = Epic, 5 = Legendary, 6 = Heirloom
local ALLOWED_QUALITIES = {
    [0] = true,
    [1] = true,
    [2] = true,
    [3] = true,
    [4] = true,
    [5] = true,
    [6] = true,
}


-- ──────────────────────────────── ITEM BLACKLIST ────────────────────────────────

-- Items in this list will be excluded from:
-- - Transmog collection (won't be added when looted/equipped)
-- - Search results
-- - Grid display (even if somehow collected)
-- Format: [itemId] = true
local ITEM_BLACKLIST = {
--    [17182] = true, -- Sulfuras, Hand of Ragnaros
}

-- Helper function to check if item is blacklisted
local function IsItemBlacklisted(itemId)
    return ITEM_BLACKLIST[itemId] == true
end


-- ───────────────────────────────── DEBUG TOGGLE ─────────────────────────────────

-- ENABLE_DEBUG_MESSAGES
-- Set to false to disable debug messages in the server console
local ENABLE_DEBUG_MESSAGES = false

-- MIRROR_IMAGE_DEBUG
-- Enable debug prints for Mirror Image transmog (useful for troubleshooting)
local MIRROR_IMAGE_DEBUG = false


-- ──────────────────────────────── CACHE VERSION# ────────────────────────────────

-- CACHE_VERSION
-- Controls the client-side cache version. Clients compare their stored version
-- with this value - if different, they re-download the full item cache.
-- 
-- IMPORTANT: Only increment this number when the transmog item database changes:
--   - New items added to world database
--   - Items added/removed from ITEM_BLACKLIST
--   - ALLOWED_QUALITIES changes
--   - Any change affecting which items appear in the transmog grid
--
-- If not changed, clients keep their cached item list across server restarts,
-- significantly reducing login bandwidth and database load.
local CACHE_VERSION = 1

	
-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                                    SCRIPT                                    ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- Helper function for debug printing
local function DebugPrint(message)
    if ENABLE_DEBUG_MESSAGES then
        print(message)
    end
end



if ENABLE_AIO_BRIDGE then
    
    local AIO = AIO or require("AIO")
    
    -- ============================================================================
    -- SERVER STARTUP CACHE SYSTEM
    -- ============================================================================
    -- This cache is built ONCE on server startup and shared with all clients.
    -- Clients store this cache locally with a version number.
    -- If server version matches client version, no retransmission needed.
    -- ============================================================================

    -- Global cache storage (populated on server startup)
    local SERVER_ITEM_CACHE = {
        version = 0,              -- Cache version (uses CACHE_VERSION setting)
        isReady = false,          -- Flag indicating cache is built
        bySlot = {},              -- Items indexed by slot: bySlot[slotId] = { {itemId, class, subclass, quality, displayId}, ... }
        byItemId = {},            -- Items indexed by itemId: byItemId[itemId] = {class, subclass, quality, displayId}
        enchants = {},            -- All enchant visuals
    }

    -- Client cache versions (tracks what version each client has)
    local ClientCacheVersions = {}  -- [accountId] = {items = version, enchants = version}
    
    -- ============================================================================
    -- Transmog Slot Definitions
    -- ============================================================================
    
    local TRANSMOG_SLOTS = {
        [0]  = true,  -- Head
        [2]  = true,  -- Shoulder
        [3]  = true,  -- Shirt
        [4]  = true,  -- Chest
        [5]  = true,  -- Waist
        [6]  = true,  -- Legs
        [7]  = true,  -- Feet
        [8]  = true,  -- Wrist
        [9]  = true,  -- Hands
        [14] = true,  -- Back
        [15] = true,  -- MainHand
        [16] = true,  -- OffHand
        [17] = true,  -- Ranged
        [18] = true,  -- Tabard
    }
    
    -- ============================================================================
    -- Subclass Mappings (Name to DB ID)
    -- ============================================================================
    
    -- Armor subclass: name -> subclass ID
    local ARMOR_SUBCLASS = {
        ["Miscellaneous"] = 0,
        ["Cloth"]         = 1,
        ["Leather"]       = 2,
        ["Mail"]          = 3,
        ["Plate"]         = 4,
        ["Shield"]        = 6,
    }
    
    -- Weapon subclass: name -> subclass ID
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
    
    -- Combined lookup
    local function GetSubclassId(subclassName)
        if ARMOR_SUBCLASS[subclassName] then
            return 4, ARMOR_SUBCLASS[subclassName]  -- class 4 = Armor
        elseif WEAPON_SUBCLASS[subclassName] then
            return 2, WEAPON_SUBCLASS[subclassName] -- class 2 = Weapon
        end
        -- For other classes (like Miscellaneous), we determine by inventory type
        return nil, nil
    end
    
    -- Slot to inventory types mapping
    local SLOT_INV_TYPES = {
        [0]  = {1},                      -- Head
        [2]  = {3},                      -- Shoulder
        [3]  = {4},                      -- Shirt
        [4]  = {5, 20},                  -- Chest/Robe
        [5]  = {6},                      -- Waist
        [6]  = {7},                      -- Legs
        [7]  = {8},                      -- Feet
        [8]  = {9},                      -- Wrist
        [9]  = {10},                     -- Hands
        [14] = {16},                     -- Back (cloak)
        [18] = {19},                     -- Tabard
        [15] = {13, 17, 21},             -- MainHand
        [16] = {13, 14, 17, 21, 22, 23}, -- OffHand
        [17] = {15, 25, 26},             -- Ranged
    }
    
    -- Inventory type to slot mapping (reverse of above)
    local INV_TYPE_TO_SLOT = {
        [1]  = 0,   -- INVTYPE_HEAD
        [3]  = 2,   -- INVTYPE_SHOULDERS
        [4]  = 3,   -- INVTYPE_BODY (Shirt)
        [5]  = 4,   -- INVTYPE_CHEST
        [20] = 4,   -- INVTYPE_ROBE
        [6]  = 5,   -- INVTYPE_WAIST
        [7]  = 6,   -- INVTYPE_LEGS
        [8]  = 7,   -- INVTYPE_FEET
        [9]  = 8,   -- INVTYPE_WRISTS
        [10] = 9,   -- INVTYPE_HANDS
        [16] = 14,  -- INVTYPE_CLOAK
        [19] = 18,  -- INVTYPE_TABARD
        [13] = 15,  -- INVTYPE_WEAPON
        [17] = 15,  -- INVTYPE_2HWEAPON
        [21] = 15,  -- INVTYPE_WEAPONMAINHAND
        [14] = 16,  -- INVTYPE_SHIELD
        [22] = 16,  -- INVTYPE_WEAPONOFFHAND
        [23] = 16,  -- INVTYPE_HOLDABLE
        [15] = 17,  -- INVTYPE_RANGED
        [25] = 17,  -- INVTYPE_THROWN
        [26] = 17,  -- INVTYPE_RANGEDRIGHT
    }
    
    -- ============================================================================
    -- SERVER CACHE INITIALIZATION (Async)
    -- ============================================================================
    -- Build the full item cache on server startup using async queries
    -- This happens ONCE and the cache is shared with all clients
    -- ============================================================================
    
    -- Forward declaration for BuildServerEnchantCacheAsync
    local BuildServerEnchantCacheAsync
    
    local function BuildServerItemCacheAsync()
        DebugPrint("[mod-transmog-system] Building server item cache (async)...")
        
        -- Use configurable cache version (only changes when admin updates CACHE_VERSION setting)
        SERVER_ITEM_CACHE.version = CACHE_VERSION
        SERVER_ITEM_CACHE.bySlot = {}
        SERVER_ITEM_CACHE.byItemId = {}
        
        -- Initialize all slot tables
        for slotId, _ in pairs(SLOT_INV_TYPES) do
            SERVER_ITEM_CACHE.bySlot[slotId] = {}
        end
        
        -- Build quality filter for allowed qualities
        local qualityList = {}
        for q, allowed in pairs(ALLOWED_QUALITIES) do
            if allowed then
                table.insert(qualityList, q)
            end
        end
        local qualityFilter = table.concat(qualityList, ",")
        
        -- Query ALL transmog-eligible items at once (async) - includes displayid
        local sql = string.format(
            "SELECT entry, class, subclass, InventoryType, Quality, displayid FROM item_template " ..
            "WHERE displayid > 0 AND Quality IN (%s) ORDER BY entry",
            qualityFilter
        )
        
        WorldDBQueryAsync(sql, function(Q)
            if Q then
                local count = 0
                repeat
                    local itemId = Q:GetUInt32(0)
                    local itemClass = Q:GetUInt8(1)
                    local itemSubclass = Q:GetUInt8(2)
                    local invType = Q:GetUInt8(3)
                    local quality = Q:GetUInt8(4)
                    local displayId = Q:GetUInt32(5)
                    
                    -- Map inventory type to slot
                    local slotId = INV_TYPE_TO_SLOT[invType]
                    
                    -- Skip blacklisted items and items without a valid slot
                    if slotId and not IsItemBlacklisted(itemId) then
                        -- Store compact item data: {itemId, class, subclass, quality, displayId}
                        table.insert(SERVER_ITEM_CACHE.bySlot[slotId], {
                            itemId,
                            itemClass,
                            itemSubclass,
                            quality,
                            displayId
                        })
                        
                        -- Also store by itemId for fast lookup
                        SERVER_ITEM_CACHE.byItemId[itemId] = {
                            class = itemClass,
                            subclass = itemSubclass,
                            quality = quality,
                            displayid = displayId,
                            inventoryType = invType
                        }
                        
                        count = count + 1
                    end
                until not Q:NextRow()
                
                DebugPrint(string.format("[mod-transmog-system] Cached %d items across all slots", count))
                
                -- Now load enchants (also async)
                BuildServerEnchantCacheAsync()
            else
                print("[mod-transmog-system] ERROR: Failed to build item cache!")
                SERVER_ITEM_CACHE.isReady = false
            end
        end)
    end
    
    -- Define BuildServerEnchantCacheAsync (declared above)
    BuildServerEnchantCacheAsync = function()
        DebugPrint("[mod-transmog-system] Building enchant cache (async)...")
        
        CharDBQueryAsync(
            "SELECT id, item_visual, name_enUS, icon FROM mod_transmog_system_enchantment ORDER BY id",
            function(Q)
                SERVER_ITEM_CACHE.enchants = {}
                if Q then
                    repeat
                        table.insert(SERVER_ITEM_CACHE.enchants, {
                            id = Q:GetUInt32(0),
                            itemVisual = Q:GetUInt32(1),
                            name = Q:GetString(2),
                            icon = Q:GetString(3)
                        })
                    until not Q:NextRow()
                    
                    DebugPrint(string.format("[mod-transmog-system] Cached %d enchant visuals", #SERVER_ITEM_CACHE.enchants))
                end
                
                -- Mark cache as ready
                SERVER_ITEM_CACHE.isReady = true
                DebugPrint(string.format("[mod-transmog-system] Server cache ready! Version: %d", SERVER_ITEM_CACHE.version))
            end
        )
    end
       
    -- Helper function to get item template from cache (no DB query)
    local function GetItemTemplate(itemId)
        if SERVER_ITEM_CACHE.isReady and SERVER_ITEM_CACHE.byItemId[itemId] then
            return SERVER_ITEM_CACHE.byItemId[itemId]
        end
        return nil
    end
    
    -- ============================================================================
    -- Database Queries (Async Only)
    -- ============================================================================
    
    -- Get player collection async
    local function GetPlayerCollectionAsync(accountId, callback)
        CharDBQueryAsync(
            string.format("SELECT item_id FROM mod_transmog_system_collection WHERE account_id = %d", accountId),
            function(Q)
                local items = {}
                if Q then
                    repeat
                        local itemId = Q:GetUInt32(0)
                        if not IsItemBlacklisted(itemId) then
                            table.insert(items, itemId)
                        end
                    until not Q:NextRow()
                end
                callback(items)
            end
        )
    end
    
    -- Check if player has appearance async
    local function HasAppearanceAsync(accountId, itemId, callback)
        CharDBQueryAsync(
            string.format("SELECT 1 FROM mod_transmog_system_collection WHERE account_id = %d AND item_id = %d", accountId, itemId),
            function(Q)
                callback(Q ~= nil)
            end
        )
    end

    -- NOTE: Sync versions removed - use async only
    
    -- ============================================================================
    -- Session Cache for Active Transmogs
    -- Loaded async on login, updated on apply/remove to avoid sync DB queries
    -- ============================================================================
    
    local PlayerActiveTransmogCache = {}  -- [guid] = { transmogs = {slot=itemId}, enchants = {slot=enchantId} }
    
    local function GetCachedActiveTransmogs(guid)
        if PlayerActiveTransmogCache[guid] then
            return PlayerActiveTransmogCache[guid].transmogs or {}
        end
        return {}
    end
    
    local function GetCachedActiveEnchantTransmogs(guid)
        if PlayerActiveTransmogCache[guid] then
            return PlayerActiveTransmogCache[guid].enchants or {}
        end
        return {}
    end
    
    local function UpdateTransmogCache(guid, slot, itemId)
        if not PlayerActiveTransmogCache[guid] then
            PlayerActiveTransmogCache[guid] = { transmogs = {}, enchants = {} }
        end
        if itemId and itemId > 0 then
            PlayerActiveTransmogCache[guid].transmogs[slot] = itemId
        else
            PlayerActiveTransmogCache[guid].transmogs[slot] = nil
        end
    end
    
    local function UpdateEnchantCache(guid, slot, enchantId)
        if not PlayerActiveTransmogCache[guid] then
            PlayerActiveTransmogCache[guid] = { transmogs = {}, enchants = {} }
        end
        if enchantId and enchantId > 0 then
            PlayerActiveTransmogCache[guid].enchants[slot] = enchantId
        else
            PlayerActiveTransmogCache[guid].enchants[slot] = nil
        end
    end
    
    local function ClearPlayerCache(guid)
        PlayerActiveTransmogCache[guid] = nil
    end

    -- Get active transmogs async (also updates session cache)
    local function GetActiveTransmogsAsync(guid, callback)
        CharDBQueryAsync(
            string.format("SELECT slot, item_id FROM mod_transmog_system_active WHERE guid = %d", guid),
            function(Q)
                local transmogs = {}
                if Q then
                    repeat
                        local slot = Q:GetUInt8(0)
                        local itemId = Q:GetUInt32(1)
                        if itemId > 0 then
                            transmogs[slot] = itemId
                        end
                    until not Q:NextRow()
                end
                -- Update session cache
                if not PlayerActiveTransmogCache[guid] then
                    PlayerActiveTransmogCache[guid] = { transmogs = {}, enchants = {} }
                end
                PlayerActiveTransmogCache[guid].transmogs = transmogs
                callback(transmogs)
            end
        )
    end
    
    local function SaveActiveTransmog(guid, slot, itemId)
        CharDBExecute(string.format(
            "REPLACE INTO mod_transmog_system_active (guid, slot, item_id) VALUES (%d, %d, %d)",
            guid, slot, itemId
        ))
        -- Update cache
        UpdateTransmogCache(guid, slot, itemId)
    end
    
    local function RemoveActiveTransmog(guid, slot)
        CharDBExecute(string.format(
            "DELETE FROM mod_transmog_system_active WHERE guid = %d AND slot = %d",
            guid, slot
        ))
        -- Update cache
        UpdateTransmogCache(guid, slot, nil)
    end
    
    -- ============================================================================
    -- Visual Application - Using SetUInt32Value for proper visual override
    -- ============================================================================
    
    -- UpdateFields.h
    -- OBJECT_END = 0x0006
    -- UNIT_END = OBJECT_END + 0x008E
    -- PLAYER_VISIBLE_ITEM_1_ENTRYID             = UNIT_END + 0x0087,
    -- PLAYER_VISIBLE_ITEM_1_ENCHANTMENT         = UNIT_END + 0x0088,
    -- PLAYER_VISIBLE_ITEM_2_ENTRYID             = UNIT_END + 0x0089,
    -- PLAYER_VISIBLE_ITEM_2_ENCHANTMENT         = UNIT_END + 0x008A,
    -- PLAYER_VISIBLE_ITEM_3_ENTRYID             = UNIT_END + 0x008B,
    -- PLAYER_VISIBLE_ITEM_3_ENCHANTMENT         = UNIT_END + 0x008C,
    -- PLAYER_VISIBLE_ITEM_4_ENTRYID             = UNIT_END + 0x008D,
    -- PLAYER_VISIBLE_ITEM_4_ENCHANTMENT         = UNIT_END + 0x008E,
    -- PLAYER_VISIBLE_ITEM_5_ENTRYID             = UNIT_END + 0x008F,
    -- PLAYER_VISIBLE_ITEM_5_ENCHANTMENT         = UNIT_END + 0x0090,
    -- PLAYER_VISIBLE_ITEM_6_ENTRYID             = UNIT_END + 0x0091,
    -- PLAYER_VISIBLE_ITEM_6_ENCHANTMENT         = UNIT_END + 0x0092,
    -- PLAYER_VISIBLE_ITEM_7_ENTRYID             = UNIT_END + 0x0093,
    -- PLAYER_VISIBLE_ITEM_7_ENCHANTMENT         = UNIT_END + 0x0094,
    -- PLAYER_VISIBLE_ITEM_8_ENTRYID             = UNIT_END + 0x0095,
    -- PLAYER_VISIBLE_ITEM_8_ENCHANTMENT         = UNIT_END + 0x0096,
    -- PLAYER_VISIBLE_ITEM_9_ENTRYID             = UNIT_END + 0x0097,
    -- PLAYER_VISIBLE_ITEM_9_ENCHANTMENT         = UNIT_END + 0x0098,
    -- PLAYER_VISIBLE_ITEM_10_ENTRYID            = UNIT_END + 0x0099,
    -- PLAYER_VISIBLE_ITEM_10_ENCHANTMENT        = UNIT_END + 0x009A,
    -- PLAYER_VISIBLE_ITEM_11_ENTRYID            = UNIT_END + 0x009B,
    -- PLAYER_VISIBLE_ITEM_11_ENCHANTMENT        = UNIT_END + 0x009C,
    -- PLAYER_VISIBLE_ITEM_12_ENTRYID            = UNIT_END + 0x009D,
    -- PLAYER_VISIBLE_ITEM_12_ENCHANTMENT        = UNIT_END + 0x009E,
    -- PLAYER_VISIBLE_ITEM_13_ENTRYID            = UNIT_END + 0x009F,
    -- PLAYER_VISIBLE_ITEM_13_ENCHANTMENT        = UNIT_END + 0x00A0,
    -- PLAYER_VISIBLE_ITEM_14_ENTRYID            = UNIT_END + 0x00A1,
    -- PLAYER_VISIBLE_ITEM_14_ENCHANTMENT        = UNIT_END + 0x00A2,
    -- PLAYER_VISIBLE_ITEM_15_ENTRYID            = UNIT_END + 0x00A3,
    -- PLAYER_VISIBLE_ITEM_15_ENCHANTMENT        = UNIT_END + 0x00A4,
    -- PLAYER_VISIBLE_ITEM_16_ENTRYID            = UNIT_END + 0x00A5,
    -- PLAYER_VISIBLE_ITEM_16_ENCHANTMENT        = UNIT_END + 0x00A6,
    -- PLAYER_VISIBLE_ITEM_17_ENTRYID            = UNIT_END + 0x00A7,
    -- PLAYER_VISIBLE_ITEM_17_ENCHANTMENT        = UNIT_END + 0x00A8,
    -- PLAYER_VISIBLE_ITEM_18_ENTRYID            = UNIT_END + 0x00A9,
    -- PLAYER_VISIBLE_ITEM_18_ENCHANTMENT        = UNIT_END + 0x00AA,
    -- PLAYER_VISIBLE_ITEM_19_ENTRYID            = UNIT_END + 0x00AB,
    -- PLAYER_VISIBLE_ITEM_19_ENCHANTMENT        = UNIT_END + 0x00AC,
    
    -- Visual field constants for each equipment slot
    local PLAYER_VISIBLE_ITEM_FIELDS = {
        [0]  = 283,  -- Head
        [2]  = 287,  -- Shoulder
        [3]  = 289,  -- Shirt
        [4]  = 291,  -- Chest
        [5]  = 293,  -- Waist
        [6]  = 295,  -- Legs
        [7]  = 297,  -- Feet
        [8]  = 299,  -- Wrist
        [9]  = 301,  -- Hands
        [14] = 311,  -- Back (Cloak)
        [15] = 313,  -- Main Hand
        [16] = 315,  -- Off Hand
        [17] = 317,  -- Ranged
        [18] = 319,  -- Tabard
    }
    
    local PLAYER_VISIBLE_ENCHANTMENT_FIELDS = {
        [0]  = 284,  -- Head
        [2]  = 288,  -- Shoulder
        [3]  = 290,  -- Shirt
        [4]  = 292,  -- Chest
        [5]  = 294,  -- Waist
        [6]  = 296,  -- Legs
        [7]  = 298,  -- Feet
        [8]  = 300,  -- Wrist
        [9]  = 302,  -- Hands
        [14] = 312,  -- Back (Cloak)
        [15] = 314,  -- Main Hand
        [16] = 316,  -- Off Hand
        [17] = 318,  -- Ranged
        [18] = 320,  -- Tabard
    }
    
    -- Slots eligible for enchantment visual transmog (weapons only show enchants)
    local ENCHANT_ELIGIBLE_SLOTS = {
        [15] = true,  -- Main Hand
        [16] = true,  -- Off Hand
        -- Ranged (17) does NOT show enchant visuals in WotLK
    }
    
    -- Get the visual field for an equipment slot
    local function GetVisualField(equipSlot)
        return PLAYER_VISIBLE_ITEM_FIELDS[equipSlot]
    end
    
    -- Get the enchantment visual field for an equipment slot
    local function GetEnchantmentVisualField(equipSlot)
        return PLAYER_VISIBLE_ENCHANTMENT_FIELDS[equipSlot]
    end
    
    -- Check if slot is eligible for enchant transmog
    local function IsEnchantEligibleSlot(slot)
        return ENCHANT_ELIGIBLE_SLOTS[slot] == true
    end
    
    local function ApplyTransmogVisual(player, slot, fakeItemId)
        if not player or not TRANSMOG_SLOTS[slot] then
            DebugPrint("[Transmog Debug] ApplyTransmogVisual failed: invalid player or slot " .. tostring(slot))
            return false
        end
        
        -- Check if player has an item equipped in this slot
        local item = player:GetItemByPos(255, slot)
        if not item then
            DebugPrint("[Transmog Debug] ApplyTransmogVisual failed: no item in slot " .. tostring(slot))
            return false  -- Can only transmog if item is equipped
        end
        
        -- Get item template to verify it exists
        local itemTemplate = GetItemTemplate(fakeItemId)
        if not itemTemplate then
            DebugPrint("[Transmog Debug] ApplyTransmogVisual failed: item template not found for " .. tostring(fakeItemId))
            return false
        end
        
        -- Get the correct visual field for this slot
        local field = GetVisualField(slot)
        if not field then
            DebugPrint("[Transmog Debug] ApplyTransmogVisual failed: no visual field for slot " .. tostring(slot))
            return false
        end
        
        DebugPrint(string.format("[Transmog Debug] Applying visual: slot=%d, field=%d, fakeItemId=%d, displayId=%d", 
            slot, field, fakeItemId, itemTemplate.displayid or 0))
        
        -- Apply the visual using SetUInt32Value with the CORRECT field
        player:SetUInt32Value(field, fakeItemId)
        
        return true
    end
    
    local function RemoveTransmogVisual(player, slot)
        if not player or not TRANSMOG_SLOTS[slot] then
            return false
        end
        
        -- Get equipped item to restore original appearance
        local item = player:GetItemByPos(255, slot)
        if not item then
            return true  -- No item, nothing to restore
        end
        
        -- Get the correct visual field for this slot
        local field = GetVisualField(slot)
        if not field then
            return false
        end
        
        -- Restore original item appearance
        local originalItemId = item:GetEntry()
        player:SetUInt32Value(field, originalItemId)
        
       return true
    end
    
    -- ============================================================================
    -- Enchantment Visual Transmog Functions
    -- ============================================================================
    
    local function ApplyEnchantVisual(player, slot, visualId)
        if not player or not IsEnchantEligibleSlot(slot) then
            DebugPrint("[Transmog Debug] ApplyEnchantVisual failed: invalid player or slot " .. tostring(slot))
            return false
        end
        
        -- Check if player has an item equipped in this slot
        local item = player:GetItemByPos(255, slot)
        if not item then
            DebugPrint("[Transmog Debug] ApplyEnchantVisual failed: no item in slot " .. tostring(slot))
            return false
        end
        
        -- Get the correct enchantment visual field for this slot
        local field = GetEnchantmentVisualField(slot)
        if not field then
            DebugPrint("[Transmog Debug] ApplyEnchantVisual failed: no enchant field for slot " .. tostring(slot))
            return false
        end
        
        DebugPrint(string.format("[Transmog Debug] Applying enchant visual: slot=%d, field=%d, visualId=%d", 
            slot, field, visualId))
        
        -- Apply the enchant visual using SetUInt32Value
        player:SetUInt32Value(field, visualId)
        
        return true
    end
    
    local function RemoveEnchantVisual(player, slot)
        if not player or not IsEnchantEligibleSlot(slot) then
            return false
        end
        
        -- Get equipped item to get its real enchant
        local item = player:GetItemByPos(255, slot)
        if not item then
            return true  -- No item, nothing to restore
        end
        
        -- Get the correct enchantment visual field for this slot
        local field = GetEnchantmentVisualField(slot)
        if not field then
            return false
        end
        
        -- Get the original enchant from the item (if any)
        local originalEnchant = item:GetEnchantmentId(0)  -- PERM_ENCHANTMENT_SLOT = 0
        player:SetUInt32Value(field, originalEnchant or 0)
        
        return true
    end
    
    -- Get active enchant transmogs async (also updates session cache)
    local function GetActiveEnchantTransmogsAsync(guid, callback)
        CharDBQueryAsync(
            string.format("SELECT slot, enchant_id FROM mod_transmog_system_active WHERE guid = %d AND enchant_id > 0", guid),
            function(Q)
                local transmogs = {}
                if Q then
                    repeat
                        local slot = Q:GetUInt32(0)
                        local enchantId = Q:GetUInt32(1)
                        transmogs[slot] = enchantId
                    until not Q:NextRow()
                end
                -- Update session cache
                if not PlayerActiveTransmogCache[guid] then
                    PlayerActiveTransmogCache[guid] = { transmogs = {}, enchants = {} }
                end
                PlayerActiveTransmogCache[guid].enchants = transmogs
                callback(transmogs)
            end
        )
    end
    
    -- Save enchant transmog to database (uses INSERT OR REPLACE pattern)
    local function SaveEnchantTransmog(guid, slot, enchantId)
        -- Use REPLACE with all columns to handle both insert and update
        local currentItemId = 0
        local cached = GetCachedActiveTransmogs(guid)
        if cached[slot] then
            currentItemId = cached[slot]
        end
        
        CharDBExecute(string.format(
            "REPLACE INTO mod_transmog_system_active (guid, slot, item_id, enchant_id) VALUES (%d, %d, %d, %d)",
            guid, slot, currentItemId, enchantId
        ))
        -- Update cache
        UpdateEnchantCache(guid, slot, enchantId)
    end
    
    -- Remove enchant transmog from database
    local function RemoveEnchantTransmogFromDB(guid, slot)
        CharDBExecute(string.format(
            "UPDATE mod_transmog_system_active SET enchant_id = 0 WHERE guid = %d AND slot = %d",
            guid, slot
        ))
        -- Update cache
        UpdateEnchantCache(guid, slot, nil)
    end
    
    -- Get enchant info from SERVER_ITEM_CACHE (no DB query needed)
    local function GetEnchantFromCache(enchantId)
        if SERVER_ITEM_CACHE.isReady and SERVER_ITEM_CACHE.enchants then
            for _, enchant in ipairs(SERVER_ITEM_CACHE.enchants) do
                if enchant.id == enchantId then
                    return enchant
                end
            end
        end
        return nil
    end
    
    -- Apply all enchant transmogs for a player (uses session cache)
    local function ApplyAllEnchantTransmogsFromCache(player)
        if not player then return end
        
        local guid = player:GetGUIDLow()
        local enchantTransmogs = GetCachedActiveEnchantTransmogs(guid)
        
        local appliedCount = 0
        for slot, enchantId in pairs(enchantTransmogs) do
            if IsEnchantEligibleSlot(slot) then
                local equippedItem = player:GetItemByPos(255, slot)
                if equippedItem then
                    if ApplyEnchantVisual(player, slot, enchantId) then
                        appliedCount = appliedCount + 1
                    end
                end
            end
        end
        
        if appliedCount > 0 then
            DebugPrint(string.format("[Transmog] Applied %d enchant transmogs for %s", appliedCount, player:GetName()))
        end
    end
    
    -- Apply all transmogs for a player (uses session cache)
    local function ApplyAllTransmogsFromCache(player)
        if not player then return end
        
        local guid = player:GetGUIDLow()
        local transmogs = GetCachedActiveTransmogs(guid)
        
        local appliedCount = 0
        for slot, itemId in pairs(transmogs) do
            local equippedItem = player:GetItemByPos(255, slot)
            if equippedItem then
                if ENABLE_TRANSMOG_APPLY_TRANSMOG_VISUAL then
                    if ApplyTransmogVisual(player, slot, itemId) then
                        appliedCount = appliedCount + 1
                    end
                end
            end
        end
        
        if appliedCount > 0 then
            DebugPrint(string.format("[Transmog] Applied %d transmogs for %s", appliedCount, player:GetName()))
        end
    end
    
    -- ============================================================================
    -- Collection Management - Item unlocking with notifications
    -- ============================================================================
    
    -- Notify player of new appearance via AIO (must be defined before AddToCollection)
    local function NotifyNewAppearance(player, itemId)
        if player and itemId then
            AIO.Msg():Add("TRANSMOG", "NewAppearance", { itemId = itemId }):Send(player)
        end
    end
    
    -- Player's notifications cache to avoid multiple notification on same Item from different event triggered
    local SessionNotifiedItems = {}
    
    -- Track which players have had their collection loaded (to prevent premature notifications)
    local SessionCollectionLoaded = {}
    
    local function GetSessionCache(player)
        local guid = player:GetGUIDLow()
        if not SessionNotifiedItems[guid] then
            SessionNotifiedItems[guid] = {}
        end
        return SessionNotifiedItems[guid]
    end
    
    local function IsCollectionLoaded(player)
        local guid = player:GetGUIDLow()
        return SessionCollectionLoaded[guid] == true
    end
    
    local function SetCollectionLoaded(player)
        local guid = player:GetGUIDLow()
        SessionCollectionLoaded[guid] = true
    end
    
    -- Check if item can be transmogged using SERVER_ITEM_CACHE
    local function CanTransmogItem(itemId)
        -- Use cached item data if available
        if SERVER_ITEM_CACHE.isReady then
            for slotId, items in pairs(SERVER_ITEM_CACHE.bySlot) do
                for _, itemData in ipairs(items) do
                    if itemData[1] == itemId then  -- itemData[1] is itemId
                        return true  -- Item is in cache, so it's transmog-eligible
                    end
                end
            end
            return false
        end
        
        return false
    end
    
    local function AddToCollection(player, itemId, notifyPlayer)
        if not player or not itemId then return false end
        
        -- Check blacklist first
        if IsItemBlacklisted(itemId) then
            return false
        end
        
        if not CanTransmogItem(itemId) then
            return false
        end
        
        -- Check session cache first - already processed this session
        local cache = GetSessionCache(player)
        if cache[itemId] then
            return true  -- Already processed, skip DB write and notification
        end
        
        -- Mark as processed in session cache
        cache[itemId] = true
        
        local accountId = player:GetAccountId()
        
        -- Add to database using INSERT IGNORE (handles duplicates)
        CharDBExecute(string.format(
            "INSERT IGNORE INTO mod_transmog_system_collection (account_id, item_id) VALUES (%d, %d)",
            accountId, itemId
        ))
        
        -- Only notify if:
        -- 1. notifyPlayer is true
        -- 2. Collection has been loaded (prevents notifications before we know what's already collected)
        if notifyPlayer ~= false and IsCollectionLoaded(player) then
            NotifyNewAppearance(player, itemId)
        end
        
        return true
    end
    
    -- Export for global access
    _G.TransmogNotifyNewAppearance = NotifyNewAppearance
    _G.TransmogAddToCollection = AddToCollection
    
    -- ============================================================================
    -- Helper function for safe async messaging
    -- ============================================================================
    -- When using async queries, the player object may become invalid by the time
    -- the callback executes. This helper stores player name and retrieves fresh
    -- reference in the callback.
    -- ============================================================================
    
    local function SafeSendToPlayer(playerName, msgBuilder)
        -- Get fresh player reference by name
        local player = GetPlayerByName(playerName)
        if player then
            msgBuilder:Send(player)
        end
        -- If player is nil, they logged off - silently ignore
    end
    
    -- ============================================================================
    -- AIO Handlers - Matching Client Format
    -- ============================================================================
    
    local TRANSMOG_HANDLER = AIO.AddHandlers("TRANSMOG", {})
    
    -- ============================================================================
    -- Cache-based handlers
    -- ============================================================================
    
    -- Request FULL item cache (ALL slots at once)
    -- This is called once on login - client stores in SavedVariables
    TRANSMOG_HANDLER.RequestFullCache = function(player, clientVersion)
        if not SERVER_ITEM_CACHE.isReady then
            AIO.Msg():Add("TRANSMOG", "FullCacheNotReady", {}):Send(player)
            return
        end
        
        -- Check if client already has current version
        if clientVersion and clientVersion == SERVER_ITEM_CACHE.version then
            AIO.Msg():Add("TRANSMOG", "FullCacheUpToDate", { 
                version = SERVER_ITEM_CACHE.version 
            }):Send(player)
            return
        end
        
        DebugPrint(string.format("[Transmog] Sending full cache to %s (client version: %s, server version: %d)", 
            player:GetName(), tostring(clientVersion), SERVER_ITEM_CACHE.version))
        
        -- Count total items across all slots for chunking
        local allItems = {}  -- { {slotId, itemId, class, subclass, quality, displayId}, ... }
        for slotId, items in pairs(SERVER_ITEM_CACHE.bySlot) do
            for _, itemData in ipairs(items) do
                -- itemData is {itemId, class, subclass, quality, displayId}
                table.insert(allItems, {
                    slotId,
                    itemData[1],  -- itemId
                    itemData[2],  -- class
                    itemData[3],  -- subclass
                    itemData[4],  -- quality
                    itemData[5]   -- displayId
                })
            end
        end
        
        -- Send in chunks of 200
        local chunkSize = 200
        local totalChunks = math.ceil(#allItems / chunkSize)
        if totalChunks == 0 then totalChunks = 1 end
        
        for chunk = 1, totalChunks do
            local startIdx = (chunk - 1) * chunkSize + 1
            local endIdx = math.min(chunk * chunkSize, #allItems)
            local chunkItems = {}
            
            for i = startIdx, endIdx do
                table.insert(chunkItems, allItems[i])
            end
            
            AIO.Msg():Add("TRANSMOG", "FullCacheData", {
                version = SERVER_ITEM_CACHE.version,
                chunk = chunk,
                totalChunks = totalChunks,
                items = chunkItems
            }):Send(player)
        end
        
        DebugPrint(string.format("[Transmog] Sent %d items in %d chunks to %s", 
            #allItems, totalChunks, player:GetName()))
    end
    
    -- Request full enchant cache (only sent if client cache is outdated)
    TRANSMOG_HANDLER.RequestEnchantCache = function(player, clientVersion)
        if not SERVER_ITEM_CACHE.isReady then
            AIO.Msg():Add("TRANSMOG", "EnchantCacheNotReady", {}):Send(player)
            return
        end
        
        -- Check if client already has current version
        if clientVersion and clientVersion == SERVER_ITEM_CACHE.version then
            AIO.Msg():Add("TRANSMOG", "EnchantCacheUpToDate", { 
                version = SERVER_ITEM_CACHE.version 
            }):Send(player)
            return
        end
        
        local enchants = SERVER_ITEM_CACHE.enchants
        
        -- Send in chunks of 30
        local chunkSize = 30
        local totalChunks = math.ceil(#enchants / chunkSize)
        if totalChunks == 0 then totalChunks = 1 end
        
        for chunk = 1, totalChunks do
            local startIdx = (chunk - 1) * chunkSize + 1
            local endIdx = math.min(chunk * chunkSize, #enchants)
            local chunkEnchants = {}
            
            for i = startIdx, endIdx do
                table.insert(chunkEnchants, enchants[i])
            end
            
            AIO.Msg():Add("TRANSMOG", "EnchantCacheData", {
                version = SERVER_ITEM_CACHE.version,
                chunk = chunk,
                totalChunks = totalChunks,
                enchants = chunkEnchants
            }):Send(player)
        end
    end
    
    -- Request player's collection status (small payload - just item IDs they own)
    -- This is the only player-specific data that needs to be sent frequently
    TRANSMOG_HANDLER.RequestCollectionStatus = function(player)
        local accountId = player:GetAccountId()
        local playerName = player:GetName()  -- Store name for callback
        
        -- Use async query for collection
        CharDBQueryAsync(
            string.format("SELECT item_id FROM mod_transmog_system_collection WHERE account_id = %d", accountId),
            function(Q)
                local items = {}
                if Q then
                    repeat
                        local itemId = Q:GetUInt32(0)
                        if not IsItemBlacklisted(itemId) then
                            table.insert(items, itemId)
                        end
                    until not Q:NextRow()
                end
                
                -- Send in chunks of 200 (just item IDs, very compact)
                local chunkSize = 200
                local totalChunks = math.ceil(#items / chunkSize)
                if totalChunks == 0 then totalChunks = 1 end
                
                for chunk = 1, totalChunks do
                    local startIdx = (chunk - 1) * chunkSize + 1
                    local endIdx = math.min(chunk * chunkSize, #items)
                    local chunkItems = {}
                    
                    for i = startIdx, endIdx do
                        table.insert(chunkItems, items[i])
                    end
                    
                    SafeSendToPlayer(playerName, AIO.Msg():Add("TRANSMOG", "CollectionStatus", {
                        chunk = chunk,
                        totalChunks = totalChunks,
                        items = chunkItems
                    }))
                end
            end
        )
    end
    
    -- ============================================================================
    -- Client Request Handlers
    -- ============================================================================
    
    -- Request full collection (async version)
    TRANSMOG_HANDLER.RequestCollection = function(player)
        local accountId = player:GetAccountId()
        local playerName = player:GetName()  -- Store name for callback
        
        GetPlayerCollectionAsync(accountId, function(collection)
            -- Send in chunks of 100
            local chunkSize = 100
            local totalChunks = math.ceil(#collection / chunkSize)
            if totalChunks == 0 then totalChunks = 1 end
            
            for chunk = 1, totalChunks do
                local startIdx = (chunk - 1) * chunkSize + 1
                local endIdx = math.min(chunk * chunkSize, #collection)
                local items = {}
                
                for i = startIdx, endIdx do
                    table.insert(items, collection[i])
                end
                
                SafeSendToPlayer(playerName, AIO.Msg():Add("TRANSMOG", "CollectionData", {
                    chunk = chunk,
                    totalChunks = totalChunks,
                    items = items
                }))
            end
        end)
    end

    -- Request active transmogs (async version)
    TRANSMOG_HANDLER.RequestActiveTransmogs = function(player)
        local guid = player:GetGUIDLow()
        local playerName = player:GetName()  -- Store name for callback
        
        GetActiveTransmogsAsync(guid, function(transmogs)
            SafeSendToPlayer(playerName, AIO.Msg():Add("TRANSMOG", "ActiveTransmogs", transmogs))
        end)
    end
    
    -- NOTE: RequestSlotItems handler removed - client uses local cache filtering
    
    -- Apply transmog (async version)
    TRANSMOG_HANDLER.ApplyTransmog = function(player, slotId, itemId)
        if not slotId or not itemId then
            AIO.Msg():Add("TRANSMOG", "Error", "INVALID_SLOT_OR_ITEM"):Send(player)
            return
        end
        
        -- Validate slot
        if not TRANSMOG_SLOTS[slotId] then
            AIO.Msg():Add("TRANSMOG", "Error", "INVALID_SLOT"):Send(player)
            return
        end
        
        local accountId = player:GetAccountId()
        local guid = player:GetGUIDLow()
        local playerName = player:GetName()  -- Store name for callback
        
        -- Debug: log the check
        DebugPrint(string.format("[Transmog] ApplyTransmog: player=%s, slot=%d, item=%d, ALLOW_UNCOLLECTED=%s", 
            playerName, slotId, itemId, tostring(ALLOW_UNCOLLECTED_TRANSMOG)))
        
        -- If ALLOW_UNCOLLECTED_TRANSMOG is true, skip collection check
        if ALLOW_UNCOLLECTED_TRANSMOG then
            -- Save to database (always - even if no item equipped)
            SaveActiveTransmog(guid, slotId, itemId)
            
            -- Get fresh player reference
            local onlinePlayer = GetPlayerByName(playerName)
            if onlinePlayer then
                -- Check if player has an item equipped in the slot
                local equippedItem = onlinePlayer:GetItemByPos(255, slotId)
                if equippedItem then
                    if ENABLE_TRANSMOG_APPLY_TRANSMOG_VISUAL then
                        -- Apply visual only if item is equipped
                        ApplyTransmogVisual(onlinePlayer, slotId, itemId)
                    end
                end
            end
            
            -- Always report success since it's saved in mod_transmog_system_active DB even for empty slot
            SafeSendToPlayer(playerName, AIO.Msg():Add("TRANSMOG", "Applied", { slot = slotId, itemId = itemId }))
            return
        end
        
        -- Verify player has the appearance (async)
        HasAppearanceAsync(accountId, itemId, function(hasItem)
            if not hasItem then
                DebugPrint(string.format("[Transmog] ApplyTransmog BLOCKED: item %d not in collection for account %d", itemId, accountId))
                SafeSendToPlayer(playerName, AIO.Msg():Add("TRANSMOG", "Error", "APPEARANCE_NOT_COLLECTED"))
                return
            end
            
            -- Save to database (always - even if no item equipped)
            SaveActiveTransmog(guid, slotId, itemId)
            
            -- Get fresh player reference (they may have disconnected during async)
            local onlinePlayer = GetPlayerByName(playerName)
            if onlinePlayer then
                -- Check if player has an item equipped in the slot
                local equippedItem = onlinePlayer:GetItemByPos(255, slotId)
                if equippedItem then
                    if ENABLE_TRANSMOG_APPLY_TRANSMOG_VISUAL then
                        -- Apply visual only if item is equipped
                        ApplyTransmogVisual(onlinePlayer, slotId, itemId)
                    end
                end
            end
            
            -- Always report success since it's saved in mod_transmog_system_active DB even for empty slot
            SafeSendToPlayer(playerName, AIO.Msg():Add("TRANSMOG", "Applied", { slot = slotId, itemId = itemId }))
        end)
    end
    
    -- Remove transmog
    TRANSMOG_HANDLER.RemoveTransmog = function(player, slotId)
        if not slotId or not TRANSMOG_SLOTS[slotId] then
            AIO.Msg():Add("TRANSMOG", "Error", "INVALID_SLOT"):Send(player)
            return
        end
        
        local guid = player:GetGUIDLow()
        
        -- Remove from database
        RemoveActiveTransmog(guid, slotId)
        
        -- Remove visual (only matters if item equipped)
        RemoveTransmogVisual(player, slotId)
        
        AIO.Msg():Add("TRANSMOG", "Removed", slotId):Send(player)
    end
    
    -- Check if appearance is collected and eligible for transmog (async version)
    TRANSMOG_HANDLER.CheckAppearance = function(player, itemId)
        local accountId = player:GetAccountId()
        local playerName = player:GetName()  -- Store name for callback
        local eligible = CanTransmogItem(itemId)
        
        if not eligible then
            AIO.Msg():Add("TRANSMOG", "AppearanceCheck", {
                itemId = itemId,
                eligible = false,
                collected = false
            }):Send(player)
            return
        end
        
        HasAppearanceAsync(accountId, itemId, function(collected)
            SafeSendToPlayer(playerName, AIO.Msg():Add("TRANSMOG", "AppearanceCheck", {
                itemId = itemId,
                eligible = eligible,
                collected = collected
            }))
        end)
    end
    
    -- NOTE: CheckAppearances (bulk) handler removed - client uses local cache
    
    -- ============================================================================
    -- Enchantment Transmog - AIO Handlers
    -- ============================================================================
    
    -- Request all available enchant visuals (uses server cache)
    TRANSMOG_HANDLER.RequestEnchantCollection = function(player)
        -- Use server cache (always loaded on startup)
        if SERVER_ITEM_CACHE.isReady and #SERVER_ITEM_CACHE.enchants > 0 then
            local enchants = SERVER_ITEM_CACHE.enchants
            
            -- Send in chunks
            local chunkSize = 20
            local totalChunks = math.ceil(#enchants / chunkSize)
            if totalChunks == 0 then totalChunks = 1 end
            
            for chunk = 1, totalChunks do
                local startIdx = (chunk - 1) * chunkSize + 1
                local endIdx = math.min(chunk * chunkSize, #enchants)
                local chunkEnchants = {}
                
                for i = startIdx, endIdx do
                    table.insert(chunkEnchants, enchants[i])
                end
                
                AIO.Msg():Add("TRANSMOG", "EnchantCollectionData", {
                    chunk = chunk,
                    totalChunks = totalChunks,
                    enchants = chunkEnchants
                }):Send(player)
            end
            return
        end
        
        -- Cache not ready yet
        AIO.Msg():Add("TRANSMOG", "Error", "ENCHANT_CACHE_NOT_READY"):Send(player)
    end
    
    -- Request active enchant transmogs (async version)
    TRANSMOG_HANDLER.RequestActiveEnchantTransmogs = function(player)
        local guid = player:GetGUIDLow()
        local playerName = player:GetName()  -- Store name for callback
        
        GetActiveEnchantTransmogsAsync(guid, function(enchantTransmogs)
            SafeSendToPlayer(playerName, AIO.Msg():Add("TRANSMOG", "ActiveEnchantTransmogs", enchantTransmogs))
        end)
    end
    
    -- Apply enchant transmog
    TRANSMOG_HANDLER.ApplyEnchantTransmog = function(player, slotId, enchantId)
        if not slotId or not enchantId then
            AIO.Msg():Add("TRANSMOG", "Error", "INVALID_SLOT_OR_ENCHANT"):Send(player)
            return
        end
        
        -- Validate slot is enchant-eligible
        if not IsEnchantEligibleSlot(slotId) then
            AIO.Msg():Add("TRANSMOG", "Error", "SLOT_NOT_ENCHANT_ELIGIBLE"):Send(player)
            return
        end
        
        -- Validate enchant exists (cache must be ready)
        if not SERVER_ITEM_CACHE.isReady then
            AIO.Msg():Add("TRANSMOG", "Error", "ENCHANT_CACHE_NOT_READY"):Send(player)
            return
        end
        
        local enchantValid = false
        for _, enchant in ipairs(SERVER_ITEM_CACHE.enchants) do
            if enchant.id == enchantId then
                enchantValid = true
                break
            end
        end
        
        if not enchantValid then
            AIO.Msg():Add("TRANSMOG", "Error", "INVALID_ENCHANT_ID"):Send(player)
            return
        end
        
        local guid = player:GetGUIDLow()
        
        -- Save to database (stores enchant_id)
        SaveEnchantTransmog(guid, slotId, enchantId)
        
        -- Check if player has an item equipped in the slot
        local equippedItem = player:GetItemByPos(255, slotId)
        if equippedItem then
            -- Apply visual using the enchant ID directly
            ApplyEnchantVisual(player, slotId, enchantId)
        end
        
        -- Report success
        AIO.Msg():Add("TRANSMOG", "EnchantApplied", { slot = slotId, visualId = enchantId }):Send(player)
    end
    
    -- Remove enchant transmog
    TRANSMOG_HANDLER.RemoveEnchantTransmog = function(player, slotId)
        if not slotId or not IsEnchantEligibleSlot(slotId) then
            AIO.Msg():Add("TRANSMOG", "Error", "INVALID_SLOT"):Send(player)
            return
        end
        
        local guid = player:GetGUIDLow()
        
        -- Remove from database
        RemoveEnchantTransmogFromDB(guid, slotId)
        
        -- Remove visual
        RemoveEnchantVisual(player, slotId)
        
        AIO.Msg():Add("TRANSMOG", "EnchantRemoved", slotId):Send(player)
    end
    
    -- ============================================================================
    -- Set Management - Database Functions
    -- ============================================================================
    
    -- Slot name to database column mapping
    local SLOT_TO_COLUMN = {
        [0]  = "slot_head",
        [2]  = "slot_shoulder",
        [3]  = "slot_shirt",
        [4]  = "slot_chest",
        [5]  = "slot_waist",
        [6]  = "slot_legs",
        [7]  = "slot_feet",
        [8]  = "slot_wrist",
        [9]  = "slot_hands",
        [14] = "slot_back",
        [15] = "slot_mainhand",
        [16] = "slot_offhand",
        [17] = "slot_ranged",
        [18] = "slot_tabard",
    }
    
    local COLUMN_TO_SLOT = {}
    for slot, column in pairs(SLOT_TO_COLUMN) do
        COLUMN_TO_SLOT[column] = slot
    end
    
    -- Get player sets async (sync version removed)
    local function GetPlayerSetsAsync(accountId, callback)
        CharDBQueryAsync(
            string.format(
                "SELECT set_number, set_name, slot_head, slot_shoulder, slot_back, slot_chest, " ..
                "slot_shirt, slot_tabard, slot_wrist, slot_hands, slot_waist, slot_legs, slot_feet, " ..
                "slot_mainhand, slot_offhand, slot_ranged FROM mod_transmog_system_sets WHERE account_id = %d",
                accountId
            ),
            function(Q)
                local sets = {}
                if Q then
                    repeat
                        local setNumber = Q:GetUInt8(0)
                        local setName = Q:GetString(1)
                        local slots = {
                            [0]  = Q:GetUInt32(2),   -- head
                            [2]  = Q:GetUInt32(3),   -- shoulder
                            [14] = Q:GetUInt32(4),   -- back
                            [4]  = Q:GetUInt32(5),   -- chest
                            [3]  = Q:GetUInt32(6),   -- shirt
                            [18] = Q:GetUInt32(7),   -- tabard
                            [8]  = Q:GetUInt32(8),   -- wrist
                            [9]  = Q:GetUInt32(9),   -- hands
                            [5]  = Q:GetUInt32(10),  -- waist
                            [6]  = Q:GetUInt32(11),  -- legs
                            [7]  = Q:GetUInt32(12),  -- feet
                            [15] = Q:GetUInt32(13),  -- mainhand
                            [16] = Q:GetUInt32(14),  -- offhand
                            [17] = Q:GetUInt32(15),  -- ranged
                        }
                        sets[setNumber] = {
                            name = setName,
                            slots = slots
                        }
                    until not Q:NextRow()
                end
                callback(sets)
            end
        )
    end
    
    local function SavePlayerSet(accountId, setNumber, setName, slotData)
        -- Build the INSERT/REPLACE query
        local columns = {"account_id", "set_number", "set_name"}
        local values = {accountId, setNumber, "'" .. setName:gsub("'", "''") .. "'"}
        
        -- Add slot columns and values
        for slot, column in pairs(SLOT_TO_COLUMN) do
            table.insert(columns, column)
            local itemId = slotData[slot] or 0
            table.insert(values, itemId)
        end
        
        local sql = string.format(
            "REPLACE INTO mod_transmog_system_sets (%s) VALUES (%s)",
            table.concat(columns, ", "),
            table.concat(values, ", ")
        )
        
        CharDBExecute(sql)
    end
    
    local function DeletePlayerSet(accountId, setNumber)
        CharDBExecute(string.format(
            "DELETE FROM mod_transmog_system_sets WHERE account_id = %d AND set_number = %d",
            accountId, setNumber
        ))
    end
    
    -- ============================================================================
    -- Set Management - AIO Handlers
    -- ============================================================================
    
    -- Request all sets for account (async version)
    TRANSMOG_HANDLER.RequestSets = function(player)
        local accountId = player:GetAccountId()
        local playerName = player:GetName()  -- Store name for callback
        
        GetPlayerSetsAsync(accountId, function(sets)
            SafeSendToPlayer(playerName, AIO.Msg():Add("TRANSMOG", "SetsData", sets))
        end)
    end
    
    -- Save a new set or update existing
    TRANSMOG_HANDLER.SaveSet = function(player, setNumber, setName, slotData)
        if not setNumber or setNumber < 1 or setNumber > 12 then
            AIO.Msg():Add("TRANSMOG", "SetError", "Invalid set number"):Send(player)
            return
        end
        
        if not setName or setName == "" then
            setName = "Set " .. setNumber
        end
        
        -- Sanitize setName (max 64 chars)
        setName = setName:sub(1, 64)
        
        local accountId = player:GetAccountId()
        
        -- Convert slot data keys to numbers if needed
        local convertedSlotData = {}
        if slotData then
            for slot, itemId in pairs(slotData) do
                local slotNum = tonumber(slot)
                if slotNum and itemId and itemId > 0 then
                    convertedSlotData[slotNum] = itemId
                end
            end
        end
        
        SavePlayerSet(accountId, setNumber, setName, convertedSlotData)
        
        AIO.Msg():Add("TRANSMOG", "SetSaved", {
            setNumber = setNumber,
            setName = setName,
            slots = convertedSlotData
        }):Send(player)
    end
    
    -- Load a set (preview only, returns data to client) - async version
    TRANSMOG_HANDLER.LoadSet = function(player, setNumber)
        if not setNumber or setNumber < 1 or setNumber > 12 then
            AIO.Msg():Add("TRANSMOG", "SetError", "Invalid set number"):Send(player)
            return
        end
        
        local accountId = player:GetAccountId()
        local playerName = player:GetName()  -- Store name for callback
        
        GetPlayerSetsAsync(accountId, function(sets)
            if not sets[setNumber] then
                SafeSendToPlayer(playerName, AIO.Msg():Add("TRANSMOG", "SetError", "Set not found"))
                return
            end
            
            SafeSendToPlayer(playerName, AIO.Msg():Add("TRANSMOG", "SetLoaded", {
                setNumber = setNumber,
                setName = sets[setNumber].name,
                slots = sets[setNumber].slots
            }))
        end)
    end
    
    -- Delete a set
    TRANSMOG_HANDLER.DeleteSet = function(player, setNumber)
        if not setNumber or setNumber < 1 or setNumber > 12 then
            AIO.Msg():Add("TRANSMOG", "SetError", "Invalid set number"):Send(player)
            return
        end
        
        local accountId = player:GetAccountId()
        DeletePlayerSet(accountId, setNumber)
        
        AIO.Msg():Add("TRANSMOG", "SetDeleted", { setNumber = setNumber }):Send(player)
    end
    
    -- Apply a set (only items in collection will be applied) - async version
    TRANSMOG_HANDLER.ApplySet = function(player, setNumber)
        if not setNumber or setNumber < 1 or setNumber > 12 then
            AIO.Msg():Add("TRANSMOG", "SetError", "Invalid set number"):Send(player)
            return
        end
        
        local accountId = player:GetAccountId()
        local guid = player:GetGUIDLow()
        local playerName = player:GetName()  -- Store name for callback
        
        -- First get the sets (async)
        GetPlayerSetsAsync(accountId, function(sets)
            if not sets[setNumber] then
                SafeSendToPlayer(playerName, AIO.Msg():Add("TRANSMOG", "SetError", "Set not found"))
                return
            end
            
            -- Then get the collection (async) to check appearances
            GetPlayerCollectionAsync(accountId, function(collectionList)
                -- Convert to set for O(1) lookup
                local collectionSet = {}
                for _, itemId in ipairs(collectionList) do
                    collectionSet[itemId] = true
                end
                
                -- Get player reference
                local onlinePlayer = GetPlayerByName(playerName)
                if not onlinePlayer then
                    DebugPrint(string.format("[Transmog] ApplySet: Player %s disconnected", playerName))
                    return
                end
                
                local setData = sets[setNumber]
                local appliedSlots = {}
                local skippedCount = 0
                
                for slot, itemId in pairs(setData.slots) do
                    if itemId and itemId > 0 then
                        -- Check if player has this appearance in collection (skip if ALLOW_UNCOLLECTED_TRANSMOG)
                        if ALLOW_UNCOLLECTED_TRANSMOG or collectionSet[itemId] then
                            -- Save to active transmogs
                            SaveActiveTransmog(guid, slot, itemId)
                            
                            -- Apply visual if item equipped
                            local equippedItem = onlinePlayer:GetItemByPos(255, slot)
                            if equippedItem and ENABLE_TRANSMOG_APPLY_TRANSMOG_VISUAL then
                                ApplyTransmogVisual(onlinePlayer, slot, itemId)
                            end
                            
                            appliedSlots[slot] = itemId
                        else
                            skippedCount = skippedCount + 1
                        end
                    end
                end
                
                SafeSendToPlayer(playerName, AIO.Msg():Add("TRANSMOG", "SetApplied", {
                    setNumber = setNumber,
                    setName = setData.name,
                    appliedSlots = appliedSlots,
                    skippedCount = skippedCount
                }))
            end)
        end)
    end
    
    -- Copy another player's visible appearance
    TRANSMOG_HANDLER.CopyPlayerAppearance = function(player, targetPlayerName)
        if not targetPlayerName or targetPlayerName == "" then
            AIO.Msg():Add("TRANSMOG", "PlayerAppearanceCopied", { error = "Invalid player name" }):Send(player)
            return
        end
        
        -- Find the target player
        local targetPlayer = GetPlayerByName(targetPlayerName)
        if not targetPlayer then
            AIO.Msg():Add("TRANSMOG", "PlayerAppearanceCopied", { error = "Player not found or offline: " .. targetPlayerName }):Send(player)
            return
        end
        
        -- Non-transmog eligible ranged subclasses (relics: libram, idol, totem, sigil)
        -- These are Armor class (4) subclasses 7-10
        local RELIC_SUBCLASSES = { [7] = true, [8] = true, [9] = true, [10] = true }
        
        -- Helper to check if an item is transmog-eligible for ranged slot
        local function IsRangedTransmogEligible(item)
            if not item then return false end
            local itemClass = item:GetClass()
            local itemSubclass = item:GetSubClass()
            
            -- Armor class with relic subclass = not eligible
            if itemClass == 4 and RELIC_SUBCLASSES[itemSubclass] then
                return false
            end
            return true
        end
        
        -- Get target player's visible equipment
        local slots = {}
        local equipmentSlots = {0, 2, 3, 4, 5, 6, 7, 8, 9, 14, 15, 16, 17, 18}  -- All transmog-eligible slots
        
        for _, slotId in ipairs(equipmentSlots) do
            local item = targetPlayer:GetItemByPos(255, slotId)
            if item then
                -- Skip ranged slot if item is a relic (not transmog-eligible)
                if slotId == 17 and not IsRangedTransmogEligible(item) then
                    -- Skip this slot - relics can't be transmogged
                else
                    -- Check if target has an active transmog on this slot
                    local transmogEntry = nil
                    local field = PLAYER_VISIBLE_ITEM_FIELDS[slotId]
                    if field then
                        transmogEntry = targetPlayer:GetUInt32Value(field)
                        if transmogEntry and transmogEntry > 0 then
                            slots[slotId] = transmogEntry
                        else
                            -- No transmog, use the actual item
                            slots[slotId] = item:GetEntry()
                        end
                    else
                        -- No visual field, use actual item
                        slots[slotId] = item:GetEntry()
                    end
                end
            end
        end
        
        -- Send the copied appearance to the requesting player
        AIO.Msg():Add("TRANSMOG", "PlayerAppearanceCopied", {
            playerName = targetPlayerName,
            slots = slots
        }):Send(player)
        
        DebugPrint(string.format("[Transmog] %s copied appearance from %s", player:GetName(), targetPlayerName))
    end
   
    -- ============================================================================
    -- Player Events - Mod-Ale - Event IDs from Hooks.h
    -- ============================================================================
    
    -- Event IDs from Hooks.h (mod-ale/Eluna for AzerothCore)

    -- player event
    local PLAYER_EVENT_ON_LOGIN                     = 3  -- (event, player) 
    local PLAYER_EVENT_ON_LOGOUT                    = 4  -- (event, player)
    local PLAYER_EVENT_ON_EQUIP                     = 29 -- (event, player, item, bag, slot)
    local PLAYER_EVENT_ON_LOOT_ITEM                 = 32 -- (event, player, item, count)
    local PLAYER_EVENT_ON_COMMAND                   = 42 -- (event, player, command, chatHandler) - player is nil if command used from console. Can return false
    local PLAYER_EVENT_ON_QUEST_REWARD_ITEM         = 51 -- (event, player, item, count)
    local PLAYER_EVENT_ON_CREATE_ITEM               = 52 -- (event, player, item, count)
    local PLAYER_EVENT_ON_STORE_NEW_ITEM            = 53 -- (event, player, item, count)
    local PLAYER_EVENT_ON_COMPLETE_QUEST            = 54 -- (event, player, quest)
    local PLAYER_EVENT_ON_GROUP_ROLL_REWARD_ITEM    = 56 -- (event, player, item, count, voteType, roll)    

    -- creature_event
    local CREATURE_EVENT_ON_DIED                    = 4  -- (event, creature, killer)
    local CREATURE_EVENT_ON_SUMMONED                = 22 -- (event, creature, summoner)
    
    -- ============================================================================
    -- Helper Function - Scan Items and Quests
    -- ============================================================================  
    
    -- ScanAllItems is a workaround for items not detected by the PLAYER_EVENT_X hooks
    -- It scans all possible item slots on login
    -- This is required to catch items received via mail, trade, or repurchased from vendors
    local function ScanAllItems(player)
        -- Scan equipment and backpack (slots 0-38)
        for slot = 0, 38 do
            local item = player:GetItemByPos(255, slot)
            if item then
                if COLLECTION_ON_CHARACTER_LOGIN_SCANNED_ITEMS then
                    AddToCollection(player, item:GetEntry(), false)
                end
            end
        end
    
        -- Scan regular bags (19-22)
        for bag = 0, 3 do
            local bagSlot = 19 + bag
            local bagItem = player:GetItemByPos(255, bagSlot)
            if bagItem then
                local bagSize = bagItem:GetBagSize()
                if bagSize and bagSize > 0 then
                    for slotInBag = 0, bagSize - 1 do
                        local item = player:GetItemByPos(bagSlot, slotInBag)
                        if item then
                            if COLLECTION_ON_CHARACTER_LOGIN_SCANNED_ITEMS then
                                AddToCollection(player, item:GetEntry(), false)
                            end
                        end
                    end
                end
            end
        end
    
        -- Scan bank main slots (39-66)
        for slot = 39, 66 do
            local item = player:GetItemByPos(255, slot)
            if item then
                if COLLECTION_ON_CHARACTER_LOGIN_SCANNED_ITEMS then
                    AddToCollection(player, item:GetEntry(), false)
                end
            end
        end
    
        -- Scan bank bags (67-73)
        for bankBag = 0, 6 do
            local bankBagSlot = 67 + bankBag
            local bankBagItem = player:GetItemByPos(255, bankBagSlot)
            if bankBagItem then
                local bankBagSize = bankBagItem:GetBagSize()
                if bankBagSize and bankBagSize > 0 then
                    for slotInBankBag = 0, bankBagSize - 1 do
                        local item = player:GetItemByPos(bankBagSlot, slotInBankBag)
                        if item then
                            if COLLECTION_ON_CHARACTER_LOGIN_SCANNED_ITEMS then
                                AddToCollection(player, item:GetEntry(), false)
                            end
                        end
                    end
                end
            end
        end
    end


    -- ScanAllQuests is a helper function used to resynchronize item collections from quests completed before the script was installed
    -- Uses async queries to avoid blocking the server
    local function ScanAllQuests(player)
        if not player then
            return
        end
        
        local guid = player:GetGUIDLow()
        local playerName = player:GetName()
        
        -- 1. Scan completed quests (already turned in) - get ALL items
        CharDBQueryAsync(
            string.format("SELECT quest FROM character_queststatus_rewarded WHERE guid = %d", guid),
            function(completedQuery)
                if completedQuery then
                    local questIds = {}
                    repeat
                        table.insert(questIds, completedQuery:GetUInt32(0))
                    until not completedQuery:NextRow()
                    
                    -- Process each quest async
                    for _, questId in ipairs(questIds) do
                        WorldDBQueryAsync(
                            string.format(
                                "SELECT RewardItem1, RewardItem2, RewardItem3, RewardItem4, " ..
                                "RewardChoiceItemID1, RewardChoiceItemID2, RewardChoiceItemID3, " ..
                                "RewardChoiceItemID4, RewardChoiceItemID5, RewardChoiceItemID6, " ..
                                "StartItem, " ..
                                "RequiredItemId1, RequiredItemId2, RequiredItemId3, " ..
                                "RequiredItemId4, RequiredItemId5, RequiredItemId6, " ..
                                "ItemDrop1, ItemDrop2, ItemDrop3, ItemDrop4 " ..
                                "FROM quest_template WHERE ID = %d",
                                questId
                            ),
                            function(questQuery)
                                if questQuery then
                                    local p = GetPlayerByName(playerName)
                                    if p then
                                        for i = 0, 20 do
                                            local itemId = questQuery:GetUInt32(i)
                                            if itemId and itemId > 0 then
                                                if COLLECTION_ON_PREVIOUS_QUESTS then
                                                    AddToCollection(p, itemId, false)  -- Don't notify for retroactive
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        )
                    end
                end
                
                -- 2. Scan quests in journal - only get StartItem
                CharDBQueryAsync(
                    string.format("SELECT quest FROM character_queststatus WHERE guid = %d AND status > 0", guid),
                    function(activeQuestsQuery)
                        if activeQuestsQuery then
                            local activeQuestIds = {}
                            repeat
                                table.insert(activeQuestIds, activeQuestsQuery:GetUInt32(0))
                            until not activeQuestsQuery:NextRow()
                            
                            for _, questId in ipairs(activeQuestIds) do
                                WorldDBQueryAsync(
                                    string.format("SELECT StartItem FROM quest_template WHERE ID = %d", questId),
                                    function(startItemQuery)
                                        if startItemQuery then
                                            local startItem = startItemQuery:GetUInt32(0)
                                            if startItem and startItem > 0 then
                                                local p = GetPlayerByName(playerName)
                                                if p and COLLECTION_ON_PREVIOUS_QUESTS then
                                                    AddToCollection(p, startItem, false)
                                                end
                                            end
                                        end
                                    end
                                )
                            end
                        end
                    end
                )
            end
        )
    end
    
    -- ============================================================================
    -- PLAYER_EVENT_ON_LOGIN - Scan inventory, quests and apply transmogs
    -- ============================================================================    
    local function OnPlayerLogin(event, player)
        local guid = player:GetGUIDLow()
        local playerName = player:GetName()
        local accountId = player:GetAccountId()
        
        -- Initialize session cache
        if not PlayerActiveTransmogCache[guid] then
            PlayerActiveTransmogCache[guid] = { transmogs = {}, enchants = {} }
        end
        
        -- Pre-populate session notification cache with existing collection
        -- This prevents notifications for items already in the collection from previous sessions
        GetPlayerCollectionAsync(accountId, function(collection)
            local p = GetPlayerByName(playerName)
            if not p then return end
            
            -- Mark all existing collection items as already processed
            local cache = GetSessionCache(p)
            for _, itemId in ipairs(collection) do
                cache[itemId] = true
            end
            
            -- Mark collection as loaded - now notifications are allowed
            SetCollectionLoaded(p)
            
            -- Now run scans AFTER cache is populated
            if ENABLE_SCAN_ITEMS then
                ScanAllItems(p)
            end
            if ENABLE_SCAN_QUESTS then
                ScanAllQuests(p)
            end
        end)
        
        -- Load active transmogs and enchants async, then apply
        if ENABLE_APPLY_ALL_TRANSMOGS then
            GetActiveTransmogsAsync(guid, function(transmogs)
                -- Cache is updated by GetActiveTransmogsAsync
                -- Now load enchants
                GetActiveEnchantTransmogsAsync(guid, function(enchants)
                    -- Get player again (may have logged out during async)
                    local p = GetPlayerByName(playerName)
                    if p then
                        ApplyAllTransmogsFromCache(p)
                        ApplyAllEnchantTransmogsFromCache(p)
                    end
                end)
            end)
        end
    end
    
    RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, OnPlayerLogin)

    -- ============================================================================
    -- PLAYER_EVENT_ON_LOGOUT - Clear session caches
    -- ============================================================================
    
    local function OnPlayerLogout(event, player)
        local guid = player:GetGUIDLow()
        SessionNotifiedItems[guid] = nil
        SessionCollectionLoaded[guid] = nil
        ClearPlayerCache(guid)
    end
    
    RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT, OnPlayerLogout)
    
    -- ============================================================================
    -- PLAYER_EVENT_ON_EQUIP - Equipment Changes (uses session cache)
    -- ============================================================================
    
    local function OnPlayerEquip(event, player, item, bagOrSlot, slot)
        if not player or not item then return end
        
        -- Get the actual slot (bagOrSlot is 255 for equipment slots, slot is the equipment slot)
        local equipSlot = slot
        if bagOrSlot ~= 255 then return end  -- Not an equipment slot
        
        if not TRANSMOG_SLOTS[equipSlot] then return end
        
        -- Add to collection
        local itemId = item:GetEntry()
        if COLLECTION_ON_EQUIP then
            AddToCollection(player, itemId, true)
        end
        
        -- Apply transmog if one is active for this slot (from session cache)
        local guid = player:GetGUIDLow()
        local transmogs = GetCachedActiveTransmogs(guid)
        local activeItemId = transmogs[equipSlot]
        
        if activeItemId then
            if ENABLE_TRANSMOG_APPLY_TRANSMOG_VISUAL then
                ApplyTransmogVisual(player, equipSlot, activeItemId)
            end
        end
        
        -- Also apply enchant transmog if one is active for this slot (from session cache)
        if IsEnchantEligibleSlot(equipSlot) then
            local enchantTransmogs = GetCachedActiveEnchantTransmogs(guid)
            local activeEnchantId = enchantTransmogs[equipSlot]
            if activeEnchantId then
                ApplyEnchantVisual(player, equipSlot, activeEnchantId)
            end
        end
    end
    
    RegisterPlayerEvent(PLAYER_EVENT_ON_EQUIP, OnPlayerEquip)
    
    -- ============================================================================
    -- PLAYER_EVENT_ON_LOOT_ITEM - from corpses/chests
    -- ============================================================================
    
    local function OnPlayerLootItem(event, player, item, count)
        if not player or not item then return end
        if COLLECTION_ON_LOOT_ITEM then
            AddToCollection(player, item:GetEntry(), true)
        end
    end
    
    RegisterPlayerEvent(PLAYER_EVENT_ON_LOOT_ITEM, OnPlayerLootItem)

    -- ============================================================================
    -- PLAYER_EVENT_ON_COMMAND
    -- ============================================================================
    
    -- TO DO - GM Command

    -- ============================================================================
    -- PLAYER_EVENT_ON_QUEST_REWARD_ITEM - when pick a reward
    -- ============================================================================
    
    local function OnPlayerQuestRewardItem(event, player, item, count)
        if not player or not item then return end
        if COLLECTION_ON_QUEST_REWARD_ITEM then
            AddToCollection(player, item:GetEntry(), true)
        end
    end
    
    RegisterPlayerEvent(PLAYER_EVENT_ON_QUEST_REWARD_ITEM, OnPlayerQuestRewardItem)

    -- ============================================================================
    -- PLAYER_EVENT_ON_CREATE_ITEM - craft
    -- ============================================================================
    
    local function OnPlayerCreateItem(event, player, item, count)
        if not player or not item then return end
        if COLLECTION_ON_CREATE_ITEM then
            AddToCollection(player, item:GetEntry(), true)
        end
    end
    
    RegisterPlayerEvent(PLAYER_EVENT_ON_CREATE_ITEM, OnPlayerCreateItem)

    -- ============================================================================
    -- PLAYER_EVENT_ON_STORE_NEW_ITEM - eg. character creation and master loot
    -- ============================================================================
    
    -- Store new items (catches master loot rule and items from new characters created)
    local function OnPlayerStoreNewItem(event, player, item, count)
        if not player or not item then return end
        if COLLECTION_ON_STORE_NEW_ITEM then
            AddToCollection(player, item:GetEntry(), true)
        end
    end
    
    RegisterPlayerEvent(PLAYER_EVENT_ON_STORE_NEW_ITEM, OnPlayerStoreNewItem)

    -- ============================================================================
    -- PLAYER_EVENT_ON_COMPLETE_QUEST - when quest is turned 
    -- ============================================================================
    
    -- Quest completion - scan for choice rewards the player may have selected (async)
    local function OnPlayerQuestComplete(event, player, quest)
        if not player or not quest then return end
        
        local questId = quest:GetId()
        local playerName = player:GetName()
        
        WorldDBQueryAsync(
            string.format(
                "SELECT RewardItem1, RewardItem2, RewardItem3, RewardItem4, " ..
                "RewardChoiceItemID1, RewardChoiceItemID2, RewardChoiceItemID3, " ..
                "RewardChoiceItemID4, RewardChoiceItemID5, RewardChoiceItemID6 " ..
                "FROM quest_template WHERE ID = %d",
                questId
            ),
            function(query)
                if query then
                    local p = GetPlayerByName(playerName)
                    if p then
                        -- Add guaranteed quest rewards to collection
                        for i = 0, 3 do
                            local itemId = query:GetUInt32(i)
                            if itemId and itemId > 0 then
                                if COLLECTION_ON_COMPLETE_QUEST then
                                    AddToCollection(p, itemId, true)
                                end
                            end
                        end
                        
                        -- Add choices rewards to collection
                        for i = 4, 9 do
                            local itemId = query:GetUInt32(i)
                            if itemId and itemId > 0 then
                                if COLLECTION_ON_COMPLETE_QUEST then
                                    AddToCollection(p, itemId, true)
                                end
                            end
                        end
                    end
                end
            end
        )
    end
    
    RegisterPlayerEvent(PLAYER_EVENT_ON_COMPLETE_QUEST, OnPlayerQuestComplete)
   
    -- ============================================================================
    -- PLAYER_EVENT_ON_GROUP_ROLL_REWARD_ITEM - when winning dice roll
    -- ============================================================================
    
    local function OnPlayerGroupRollRewardItem(event, player, item, count, voteType, roll)
        if not player or not item then return end
        if COLLECTION_ON_GROUP_ROLL_REWARD_ITEM then
            AddToCollection(player, item:GetEntry(), true)
        end
    end
    
    RegisterPlayerEvent(PLAYER_EVENT_ON_GROUP_ROLL_REWARD_ITEM, OnPlayerGroupRollRewardItem)
    
    -- ============================================================================
    -- Spell support - Mirror Image
    -- ============================================================================
    -- Mirror Image (spell 55342) summons creature entry 31216
    -- Shows player's transmog appearance on mirror image clones
    -- 
    -- Settings (defined at top of file):
    --   MIRROR_IMAGE_TRANSMOG_ENABLED - Enable/disable the feature
    --   MIRROR_IMAGE_DEBUG - Enable/disable debug prints
    -- ============================================================================
    
    local function MirrorDebug(msg)
        if MIRROR_IMAGE_DEBUG then
            print(msg)
        end
    end
    
    if MIRROR_IMAGE_TRANSMOG_ENABLED then
        local MIRROR_IMAGE_ENTRY = 31216
        
        -- Creature events
        local CREATURE_EVENT_ON_SUMMONED  = 22
        local CREATURE_EVENT_ON_MOVE_IN_LOS = 27
        local CREATURE_EVENT_ON_DIED = 4
        local CREATURE_EVENT_ON_REMOVE = 37
        local CREATURE_EVENT_ON_CORPSE_REMOVED = 26
        
        -- Equipment slots for SMSG_MIRRORIMAGE_DATA
        local MirrorArmorSlots = {0, 2, 3, 4, 5, 6, 7, 8, 9, 14, 18}
        local MirrorWeaponSlots = {15, 16, 17}
        
        -- Cache: [creatureGUID] = { PacketStore, PlayerCache }
        local MirrorCache = {}
        
        -- ========================================
        -- Get item display ID
        -- ========================================
        local function GetMirrorDisplayId(itemId)
            if not itemId or itemId == 0 then return 0 end
            if SERVER_ITEM_CACHE.isReady and SERVER_ITEM_CACHE.byItemId[itemId] then
                return SERVER_ITEM_CACHE.byItemId[itemId].displayid or 0
            end
            local template = GetItemTemplate(itemId)
            return template and template.displayid or 0
        end
        
        -- ========================================
        -- Send stored packet via creature broadcast
        -- ========================================
        local function SendMirrorPacket(target)
            if not target then 
                MirrorDebug("[Mirror Image] ERROR: target is nil in SendMirrorPacket")
                return 
            end
            
            local tGUID = target:GetGUID()
            if not tGUID then
                MirrorDebug("[Mirror Image] ERROR: Could not get GUID from target")
                return
            end
            
            if not MirrorCache[tGUID] then
                MirrorDebug(string.format("[Mirror Image] ERROR: No cache for GUID %s", tostring(tGUID)))
                return
            end
            
            if not MirrorCache[tGUID].PacketStore then
                MirrorDebug("[Mirror Image] ERROR: No packet stored")
                return
            end
            
            MirrorDebug(string.format("[Mirror Image] Broadcasting packet for GUID %s", tostring(tGUID)))
            target:SendPacket(MirrorCache[tGUID].PacketStore)
        end
        
        -- ========================================
        -- ON_SUMMONED - Build packet and apply transmog appearance
        -- ========================================
        local function OnMirrorImageSummoned(event, creature, summoner)
            MirrorDebug("[Mirror Image] === ON_SUMMONED EVENT ===")
            
            if not creature then
                MirrorDebug("[Mirror Image] ERROR: creature is nil")
                return
            end
            if not summoner then
                MirrorDebug("[Mirror Image] ERROR: summoner is nil")
                return
            end
            if summoner:GetObjectType() ~= "Player" then
                MirrorDebug("[Mirror Image] ERROR: summoner is not a player")
                return
            end
            
            local player = summoner
            local target = creature
            local tGUID = target:GetGUID()
            
            if not tGUID then
                MirrorDebug("[Mirror Image] ERROR: Could not get creature GUID")
                return
            end
            
            MirrorDebug(string.format("[Mirror Image] Summoned for %s, Creature GUID: %s", player:GetName(), tostring(tGUID)))
            MirrorDebug(string.format("[Mirror Image] Player DisplayID: %d, Race: %d, Gender: %d, Class: %d", 
                player:GetDisplayId(), player:GetRace(), player:GetGender(), player:GetClass()))
            
            -- Initialize cache
            MirrorCache[tGUID] = {
                PacketStore = nil,
                PlayerCache = {}
            }
            
            -- Build SMSG_MIRRORIMAGE_DATA packet
            local packet = CreatePacket(0x402, 68)
            
            packet:WriteGUID(tGUID)
            packet:WriteULong(player:GetDisplayId())
            packet:WriteUByte(player:GetRace())
            packet:WriteUByte(player:GetGender())
            packet:WriteUByte(player:GetClass())
            packet:WriteUByte(player:GetByteValue(153, 0))  -- Skin
            packet:WriteUByte(player:GetByteValue(153, 1))  -- Face
            packet:WriteUByte(player:GetByteValue(153, 2))  -- Hair Style
            packet:WriteUByte(player:GetByteValue(153, 3))  -- Hair Color
            packet:WriteUByte(player:GetByteValue(154, 0))  -- Facial Hair
            
            if player:IsInGuild() then
                packet:WriteULong(player:GetGuildId())
            else
                packet:WriteULong(0)
            end
            
            -- Armor display IDs (with transmog support)
            MirrorDebug("[Mirror Image] === ARMOR DISPLAY IDS ===")
            for i, slot in ipairs(MirrorArmorSlots) do
                local displayId = 0
                local source = "none"
                
                -- Get equipped item's display ID first
                local item = player:GetEquippedItemBySlot(slot)
                if item then
                    displayId = item:GetDisplayId()
                    source = string.format("item %d", item:GetEntry())
                end
                
                -- Check for transmog override
                local field = PLAYER_VISIBLE_ITEM_FIELDS[slot]
                if field then
                    local transmogEntry = player:GetUInt32Value(field)
                    if transmogEntry and transmogEntry > 0 then
                        local transmogDisplayId = GetMirrorDisplayId(transmogEntry)
                        if transmogDisplayId > 0 then
                            displayId = transmogDisplayId
                            source = string.format("transmog %d", transmogEntry)
                        end
                    end
                end
                
                MirrorDebug(string.format("[Mirror Image] Slot %d: DisplayID = %d (%s)", slot, displayId, source))
                packet:WriteULong(displayId)
            end
            MirrorDebug("[Mirror Image] === END ARMOR ===")
            
            -- Store packet
            MirrorCache[tGUID].PacketStore = packet
            MirrorCache[tGUID].PlayerCache[player:GetGUID()] = true
            
            -- Set creature visuals
            target:SetUInt32Value(60, 16)  -- Mirror Image flag
            target:SetDisplayId(player:GetDisplayId())
            
            -- Weapons (with transmog support)
            MirrorDebug("[Mirror Image] === WEAPONS ===")
            for i, slot in ipairs(MirrorWeaponSlots) do
                local itemEntry = 0
                local source = "none"
                
                -- Get equipped item entry first
                local item = player:GetEquippedItemBySlot(slot)
                if item then
                    itemEntry = item:GetEntry()
                    source = "equipped"
                end
                
                -- Check for transmog override
                local field = PLAYER_VISIBLE_ITEM_FIELDS[slot]
                if field then
                    local transmogEntry = player:GetUInt32Value(field)
                    if transmogEntry and transmogEntry > 0 then
                        itemEntry = transmogEntry
                        source = "transmog"
                    end
                end
                
                MirrorDebug(string.format("[Mirror Image] Weapon slot %d: Entry = %d (%s)", slot, itemEntry, source))
                target:SetUInt32Value(56 + (i - 1), itemEntry)
            end
            MirrorDebug("[Mirror Image] === END WEAPONS ===")
            
            -- Send packet with delay and immediately
            MirrorDebug("[Mirror Image] Sending initial packet...")
            CreateLuaEvent(function() SendMirrorPacket(target) end, player:GetLatency() + 100, 1)
            
            MirrorDebug("[Mirror Image] Also sending packet immediately...")
            target:SendPacket(packet)
            
            MirrorDebug("[Mirror Image] === SUMMONED COMPLETE ===")
        end
        
        -- ========================================
        -- ON_MOVE_IN_LOS - Handle players entering range
        -- ========================================
        local function OnMirrorImageLOS(event, creature, unit)
            if not creature or not unit then return end
            
            local unitType = unit:GetObjectType()
            MirrorDebug(string.format("[Mirror Image] LOS: unit type = %s", tostring(unitType)))
            
            if unitType ~= "Player" then return end
            
            local player = unit
            local tGUID = creature:GetGUID()
            
            MirrorDebug(string.format("[Mirror Image] LOS: Player %s, Creature GUID %s", player:GetName(), tostring(tGUID)))
            
            if not tGUID or not MirrorCache[tGUID] then 
                MirrorDebug("[Mirror Image] LOS: No cache for this creature")
                return 
            end
            
            local playerGUID = player:GetGUID()
            if MirrorCache[tGUID].PlayerCache[playerGUID] == true then 
                MirrorDebug(string.format("[Mirror Image] LOS: %s already in cache, skipping", player:GetName()))
                return 
            end
            
            MirrorCache[tGUID].PlayerCache[playerGUID] = true
            MirrorDebug(string.format("[Mirror Image] LOS: Sending packet to %s", player:GetName()))
            CreateLuaEvent(function() SendMirrorPacket(creature) end, player:GetLatency() + 100, 1)
        end
        
        -- ========================================
        -- Cleanup
        -- ========================================
        local function CleanupMirrorCache(creatureGUID)
            if MirrorCache[creatureGUID] then
                MirrorCache[creatureGUID] = nil
                MirrorDebug(string.format("[Mirror Image] Cache cleaned: %s", tostring(creatureGUID)))
            end
        end
        
        local function OnMirrorImageDied(event, creature, killer)
            MirrorDebug("[Mirror Image] === DIED EVENT ===")
            if creature then
                local guid = creature:GetGUID()
                if guid then CleanupMirrorCache(guid) end
            end
        end
        
        local function OnMirrorImageRemove(event, creature)
            MirrorDebug("[Mirror Image] === REMOVE EVENT ===")
            if creature then
                local guid = creature:GetGUID()
                if guid then CleanupMirrorCache(guid) end
            end
        end
        
        local function OnMirrorImageCorpseRemoved(event, creature, respawnDelay)
            MirrorDebug("[Mirror Image] === CORPSE_REMOVED EVENT ===")
            if creature then
                local guid = creature:GetGUID()
                if guid then CleanupMirrorCache(guid) end
            end
        end
        
        -- Player logout - clear from cache
        local function OnPlayerLogoutMirror(event, player)
            if not player then return end
            local playerGUID = player:GetGUID()
            for _, cache in pairs(MirrorCache) do
                if cache.PlayerCache and cache.PlayerCache[playerGUID] then
                    cache.PlayerCache[playerGUID] = nil
                end
            end
        end
        
        RegisterPlayerEvent(4, OnPlayerLogoutMirror)
        
        -- Register creature events
        MirrorDebug("[Mirror Image] Registering creature events for entry " .. MIRROR_IMAGE_ENTRY)
        RegisterCreatureEvent(MIRROR_IMAGE_ENTRY, CREATURE_EVENT_ON_SUMMONED, OnMirrorImageSummoned)
        RegisterCreatureEvent(MIRROR_IMAGE_ENTRY, CREATURE_EVENT_ON_MOVE_IN_LOS, OnMirrorImageLOS)
        RegisterCreatureEvent(MIRROR_IMAGE_ENTRY, CREATURE_EVENT_ON_DIED, OnMirrorImageDied)
        RegisterCreatureEvent(MIRROR_IMAGE_ENTRY, CREATURE_EVENT_ON_REMOVE, OnMirrorImageRemove)
        RegisterCreatureEvent(MIRROR_IMAGE_ENTRY, CREATURE_EVENT_ON_CORPSE_REMOVED, OnMirrorImageCorpseRemoved)
        
        print("[Transmog] Mirror Image transmog support enabled" .. (MIRROR_IMAGE_DEBUG and " (debug ON)" or ""))
    end
    
    -- ============================================================================
    -- SERVER STARTUP - Build Cache
    -- ============================================================================
    -- Build the item cache on server startup (called once when script loads)
    -- ============================================================================
    
    BuildServerItemCacheAsync()
       
    print("[mod-transmog-system] AIO Server Bridge loaded")
    print(string.format("[mod-transmog-system] Settings: ALLOW_UNCOLLECTED_TRANSMOG=%s, DEBUG=%s, CACHE_VERSION=%d", 
        tostring(ALLOW_UNCOLLECTED_TRANSMOG), tostring(ENABLE_DEBUG_MESSAGES), CACHE_VERSION))
end