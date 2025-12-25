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
-- SavedVariables (minimal - just UI settings)
-- ============================================================================

TransmogDB = TransmogDB or {}  -- For minimap position only

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

-- Current UI state (initialized properly in PLAYER_ENTERING_WORLD)
local currentSlot = "Head"
local currentSubclass = "All"  -- TO DO, Currently use "ALL" as default
local currentQuality = "All"
local currentCollectionFilter = "Collected"  -- NEW: Default to Collected
local currentItems = {}
local currentPage = 1
local itemsPerPage = 15

-- Track selected items per slot (cyan border selection)
local slotSelectedItems = {}  -- key: slotName, value: itemId

-- ============================================================================
-- Set Management Data
-- ============================================================================

local transmogSets = {}  -- Cached sets from server: { [setNumber] = { name = "...", slots = {...} } }
local MAX_SETS = 10
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
local ENCHANT_VISUALS = {}

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
    return collectedAppearances[itemId] == true
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

local function RequestCollectionFromServer()
    AIO.Msg():Add("TRANSMOG", "RequestCollection"):Send()
end

local function RequestActiveTransmogsFromServer()
    AIO.Msg():Add("TRANSMOG", "RequestActiveTransmogs"):Send()
end

local function RequestSlotItemsFromServer(slotId, subclass, quality, collectionFilter)
    -- NEW: Include collection filter in request (default to "Collected")
    AIO.Msg():Add("TRANSMOG", "RequestSlotItems", slotId, subclass, quality, collectionFilter or "Collected"):Send()
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

-- Buffer for accumulating chunked search results
local searchResultsBuffer = {}
local searchSlotResultsBuffer = {}
local searchTotalChunks = 0
local searchReceivedChunks = 0

TRANSMOG_HANDLER.SearchResults = function(player, data)
    if not data then return end
    
    local chunk = data.chunk or 1
    local totalChunks = data.totalChunks or 1
    local totalResults = data.totalResults or #(data.allResults or {})
    
    -- Initialize buffers on first chunk
    if chunk == 1 then
        searchResultsBuffer = {}
        searchSlotResultsBuffer = {}
        searchTotalChunks = totalChunks
        searchReceivedChunks = 0
    end
    
    -- Accumulate results
    if data.allResults then
        for _, item in ipairs(data.allResults) do
            table.insert(searchResultsBuffer, item)
        end
    end
    
    if data.slotResults then
        for slot, items in pairs(data.slotResults) do
            searchSlotResultsBuffer[slot] = searchSlotResultsBuffer[slot] or {}
            for _, item in ipairs(items) do
                table.insert(searchSlotResultsBuffer[slot], item)
            end
        end
    end
    
    searchReceivedChunks = searchReceivedChunks + 1
    
    -- Update progress on main frame
    if mainFrame and mainFrame.pageText and searchReceivedChunks < searchTotalChunks then
        mainFrame.pageText:SetText(string.format("Loading search... %d/%d", searchReceivedChunks, searchTotalChunks))
    end
    
    -- When all chunks received, finalize
    if searchReceivedChunks >= searchTotalChunks then
        searchActive = true
        searchResults = searchResultsBuffer
        searchSlotResults = searchSlotResultsBuffer
        
        print(string.format("[Transmog] Search found %d total items", #searchResults))
        
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
            else
                mainFrame.pageText:SetText("No results found")
            end
        end
        
        -- Clear buffers
        searchResultsBuffer = {}
        searchSlotResultsBuffer = {}
    end
end

TRANSMOG_HANDLER.CollectionData = function(player, data)
    if data.chunk == 1 then
        collectedAppearances = {}
    end
    
    for _, itemId in ipairs(data.items) do
        collectedAppearances[itemId] = true
    end
    
    if data.chunk == data.totalChunks then
        isCollectionLoaded = true
        print(string.format(L["COLLECTION_LOADED"], GetCollectionCount()))
    end
end

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
    end
end

TRANSMOG_HANDLER.Removed = function(player, slot)
    activeTransmogs[slot] = nil
    print(L["TRANSMOG_REMOVED"])
    
    -- Update slot button icons
    UpdateSlotButtonIcons()
    -- Update grid to remove highlight
    UpdatePreviewGrid()
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
    end
end

TRANSMOG_HANDLER.AppearanceCheckBulk = function(player, results)
    for itemId, collected in pairs(results) do
        if collected then
            collectedAppearances[itemId] = true
        end
    end
end

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

-- Receive items for a specific slot
TRANSMOG_HANDLER.SlotItems = function(player, data)
    if not data then return end
    
    local slotId = data.slotId
    if slotId == nil then return end
    
    -- Only process if this is for the currently selected slot
    local currentSlotId = currentSlot and SLOT_NAME_TO_EQUIP_SLOT[currentSlot] or nil
    if currentSlotId ~= slotId then return end
    
    -- Initialize buffer on first chunk
    if data.chunk == 1 then
        currentItems = {}
    end
    
    -- Add items to buffer
    -- NEW: Items now come with collected status from server
    if data.items then
        for _, item in ipairs(data.items) do
            if item and item.itemId then
                -- Store as table with itemId and collected status
                table.insert(currentItems, {
                    itemId = item.itemId,
                    collected = item.collected ~= false  -- Default to true for backwards compatibility
                })
                -- Also update local collection cache if collected
                if item.collected ~= false then
                    collectedAppearances[item.itemId] = true
                end
            end
        end
    end
    
    -- When all chunks received, sort and update the display
    if data.chunk == data.totalChunks then
        -- NEW: Sort items - collected first, then uncollected
        table.sort(currentItems, function(a, b)
            if a.collected and not b.collected then
                return true
            elseif not a.collected and b.collected then
                return false
            else
                return a.itemId < b.itemId
            end
        end)
        
        currentPage = 1
        UpdatePreviewGrid()
        
        -- Update page text
        local totalPages = math.max(1, math.ceil(#currentItems / itemsPerPage))
        if mainFrame and mainFrame.pageText then
            mainFrame.pageText:SetText(string.format(L["PAGE"], currentPage, totalPages))
        end
    end
end

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
    
    -- Update dressing room model with loaded items
    -- Use mainFrame.dressingRoom since dressingRoom variable may not be in scope yet
    local dr = mainFrame and mainFrame.dressingRoom
    if dr and dr.model then
        dr.model:SetUnit("player")  -- Reset model first
        dr.model:Undress()
        -- Small delay to ensure model is ready
        C_Timer.After(0.1, function()
            for slotName, itemId in pairs(slotSelectedItems) do
                if itemId then
                    dr.model:TryOn(itemId)
                end
            end
        end)
    end
    
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
end

TRANSMOG_HANDLER.SetError = function(player, errorMsg)
    print(string.format("|cffff0000[Transmog]|r %s", errorMsg or L["SET_ERROR"]))
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
-- Tooltip Hook - Server-driven eligibility
-- ============================================================================

local function OnTooltipSetItem(tooltip)
    local _, link = tooltip:GetItem()
    if not link then return end
    
    local itemId = tonumber(link:match("item:(%d+)"))
    if not itemId then return end
    
    -- Check cache first
    local cached = appearanceCache[itemId]
    if cached then
        if not cached.eligible then return end
        if cached.collected then
            tooltip:AddLine(L["APPEARANCE_COLLECTED"])
        else
            tooltip:AddLine(L["NEW_APPEARANCE"])
        end
        tooltip:Show()
        return
    end
    
    -- Not in cache - ask server (only once per item per session)
    if not pendingTooltipChecks[itemId] then
        pendingTooltipChecks[itemId] = true
        AIO.Msg():Add("TRANSMOG", "CheckAppearance", itemId):Send()
    end
end

GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
ItemRefTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
ShoppingTooltip1:HookScript("OnTooltipSetItem", OnTooltipSetItem)
ShoppingTooltip2:HookScript("OnTooltipSetItem", OnTooltipSetItem)

-- Hook AtlasLoot tooltips if available (delayed to ensure addon is loaded)
local function HookAtlasLootTooltips()
    -- AtlasLoot uses AtlasLootTooltip
    if AtlasLootTooltip then
        AtlasLootTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
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
local previewSetupVersion = "classic"

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
    -- Items are loaded from server via RequestSlotItemsFromServer
    -- This function returns cached data
    local slotId = SLOT_NAME_TO_EQUIP_SLOT[slotName]
    if TransmogDB.slotCache and TransmogDB.slotCache[slotId] then
        return TransmogDB.slotCache[slotId]
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
                    ApplyEnchantTransmog(currentSlot, enchantData.id)
                    PlaySound("igCharacterInfoTab")
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
        
        -- Normal item mode
        if f.itemId and f.isLoaded then
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    if IsAppearanceCollected(f.itemId) then
                        ApplyTransmog(currentSlot, f.itemId)
                    else
                        print(L["APPEARANCE_NOT_COLLECTED"])
                    end
                else
                    -- Clear previous selection for this slot from ALL item frames
                    for _, itemFrame in ipairs(itemFrames) do
                        if itemFrame.itemId and itemFrame.selectionBorder then
                            -- If this frame was showing cyan border (not active transmog), clear it
                            if itemFrame.selectionBorder:IsShown() and not itemFrame.isActive then
                                itemFrame.selectionBorder:Hide()
                                itemFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                            end
                        end
                    end
                    
                    -- Store selection for this slot
                    slotSelectedItems[currentSlot] = f.itemId
                    selectedItemId = f.itemId
                    selectedItemFrame = f
                    f.selectionBorder:Show()
                    f:SetBackdropBorderColor(0, 1, 1, 1)  -- Cyan border
                    
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
            -- Only highlight on hover (white border), not cyan
            if not f.isActive then
                f:SetBackdropBorderColor(1, 1, 1, 1)
            end
            return
        end
        
        -- Normal item mode tooltip
        if f.itemId and f.isLoaded then
            GameTooltip:SetOwner(f, "ANCHOR_TOPRIGHT")
            GameTooltip:SetHyperlink("item:"..f.itemId)
            GameTooltip:AddLine(" ")
            if IsAppearanceCollected(f.itemId) then
                GameTooltip:AddLine(L["APPEARANCE_COLLECTED"])
                GameTooltip:AddLine(L["APPLY_APPEARANCE_SHIFT_CLICK"], 0.7, 0.7, 0.7)
            else
                GameTooltip:AddLine(L["NEW_APPEARANCE"])
            end
            GameTooltip:AddLine(L["PREVIEW_APPEARANCE_CLICK"], 0.7, 0.7, 0.7)
            
            -- Add selection hint if not selected
            if f.itemId ~= selectedItemId then
                GameTooltip:AddLine(L["SELECT_ITEM_CLICK"], 0.5, 1, 0.5)  -- Light green hint
            end
            
            GameTooltip:Show()
        end
        
        -- Highlight border on mouseover (unless it's already selected)
        if f.itemId ~= selectedItemId then
            f:SetBackdropBorderColor(1, 1, 1, 1)
        end
    end)
    
    btn:SetScript("OnLeave", function(self)
        local f = self:GetParent()
        GameTooltip:Hide()
        
        -- Handle enchant mode
        if f.enchantMode then
            if f.isActive then
                f:SetBackdropBorderColor(1, 0.4, 0.7, 1)  -- Pink for active enchant
            else
                f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)  -- Default gray
            end
            return
        end
        
        -- Restore border based on state for item mode
        if f.itemId == selectedItemId then
            f:SetBackdropBorderColor(0, 1, 1, 1)  -- Cyan for selected
        elseif f.isActive then
            f:SetBackdropBorderColor(0, 1, 0, 1)  -- Green for active
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
    
    model:SetPosition(cam.x, cam.y, cam.z)
    model:SetFacing(cam.facing)
    model:TryOn(frame.itemId)
    
    frame.freezeSequence = cam.sequence or 0
    model:SetScript("OnUpdateModel", function(self)
        self:SetSequence(frame.freezeSequence)
    end)
    
    frame.isLoaded = true
    
    -- Check if this item is selected for this slot
    local isSelected = (slotSelectedItems[slotName] and slotSelectedItems[slotName] == frame.itemId)
    
    if isSelected then
        frame.selectionBorder:Show()
        frame:SetBackdropBorderColor(0, 1, 1, 1)  -- Cyan border
        selectedItemFrame = frame
        selectedItemId = frame.itemId
    else
        frame.selectionBorder:Hide()
    end
    
    -- Check if this is the active transmog for current slot
    local slotId = SLOT_NAME_TO_EQUIP_SLOT[slotName]
    local activeItemId = activeTransmogs[slotId]
    local isActive = (activeItemId and activeItemId == frame.itemId)
    frame.isActive = isActive
    
    if isActive then
        frame.activeGlow:Show()
        frame.activeText:Show()
        frame:SetBackdropBorderColor(0, 1, 0, 1)
        frame:SetBackdropColor(0.1, 0.2, 0.1, 1)
    else
        frame.activeGlow:Hide()
        frame.activeText:Hide()
        frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    end
    
    if IsAppearanceCollected(frame.itemId) then
        frame.collectedIcon:Show()
        frame.newIcon:Hide()
        if not isActive then
            frame:SetBackdropColor(0.15, 0.15, 0.15, 1)
            frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end
        -- Full opacity for collected items
        model:SetAlpha(1.0)
    else
        frame.collectedIcon:Hide()
        frame.newIcon:Show()
        if not isActive then
            -- NEW: Grey/desaturated styling for uncollected items
            frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
            frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end
        -- NEW: Reduced opacity for uncollected items (greyed out effect)
        model:SetAlpha(0.5)
    end
    
    -- If this frame is selected but not active, ensure cyan border is shown
    if isSelected and not isActive then
        frame.selectionBorder:Show()
        frame:SetBackdropBorderColor(0, 1, 1, 1)
    end
end

local function UpdateItemFrame(frame, itemData, slotName)
    -- NEW: Handle both old format (just itemId) and new format (table with itemId and collected)
    local itemId, isCollected
    if type(itemData) == "table" then
        itemId = itemData.itemId
        isCollected = itemData.collected
    else
        itemId = itemData
        isCollected = IsAppearanceCollected(itemData)
    end
    
    frame.itemId = itemId
    frame.isCollected = isCollected  -- NEW: Store collected status on frame
    frame.isLoaded = false
    frame.model:SetScript("OnUpdateModel", nil)
    frame.collectedIcon:Hide()
    frame.newIcon:Hide()
    frame.selectionBorder:Hide()  -- Always hide selection border initially
    
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
            
            -- Set border color - use pink (1, 0.4, 0.7) for active
            local isActive = (activeEnchantId == enchantData.id)
            frame.isActive = isActive
            if isActive then
                frame:SetBackdropBorderColor(1, 0.4, 0.7, 1)  -- Pink for active enchant
                frame:SetBackdropColor(0.2, 0.1, 0.15, 1)    -- Slight pink background
            else
                frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                frame:SetBackdropColor(0.15, 0.15, 0.15, 1)
            end
            
            if frame.selectionBorder then frame.selectionBorder:Hide() end
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
                
                -- Request items from server with subclass filter
                local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
                currentItems = {}
                currentPage = 1
                UpdatePreviewGrid()  -- Clear grid immediately
                RequestSlotItemsFromServer(slotId, currentSubclass, currentQuality, currentCollectionFilter)
                
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
            
            -- Color the text according to quality (except "All")
            if quality == "All" then
                info.text = quality
            else
                local color = QUALITY_COLORS[quality] or "|cffffffff"
                info.text = color .. quality .. "|r"
            end
            
            info.value = quality
            info.func = function(self)
                currentQuality = self.value
                slotSelectedQuality[currentSlot] = currentQuality  -- Store the selection
                
                -- Update dropdown text with color
                if currentQuality == "All" then
                    UIDropDownMenu_SetText(qualityDropdown, "All")
                else
                    local color = QUALITY_COLORS[currentQuality] or "|cffffffff"
                    UIDropDownMenu_SetText(qualityDropdown, color .. currentQuality .. "|r")
                end
                
                -- Request items from server with quality filter
                local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
                currentItems = {}
                currentPage = 1
                UpdatePreviewGrid()  -- Clear grid immediately
                RequestSlotItemsFromServer(slotId, currentSubclass, currentQuality, currentCollectionFilter)
                
                CloseDropDownMenus()
            end
            info.checked = (quality == currentQuality)
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    -- Set initial text with color
    if currentQuality == "All" then
        UIDropDownMenu_SetText(qualityDropdown, "All")
    else
        local color = QUALITY_COLORS[currentQuality] or "|cffffffff"
        UIDropDownMenu_SetText(qualityDropdown, color .. currentQuality .. "|r")
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
                
                -- Request items from server with collection filter
                local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
                currentItems = {}
                currentPage = 1
                UpdatePreviewGrid()  -- Clear grid immediately
                RequestSlotItemsFromServer(slotId, currentSubclass, currentQuality, currentCollectionFilter)
                
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
    
    -- Create overlay icon for active transmog
    local transmogIcon = btn:CreateTexture(nil, "OVERLAY")
    transmogIcon:SetSize(28, 28)
    transmogIcon:SetPoint("CENTER")
    transmogIcon:Hide()
    btn.transmogIcon = transmogIcon
    
    -- Create active indicator border
    local activeBorder = btn:CreateTexture(nil, "OVERLAY")
    activeBorder:SetSize(48, 48)
    activeBorder:SetPoint("CENTER")
    activeBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    activeBorder:SetBlendMode("ADD")
    activeBorder:SetVertexColor(0, 1, 0, 0.7)
    activeBorder:Hide()
    btn.activeBorder = activeBorder
    
    btn.slotName = slotName
    
    -- Function to update slot appearance
    btn.UpdateTransmogIcon = function(self)
        local slotId = SLOT_NAME_TO_EQUIP_SLOT[self.slotName]
        local activeItemId = activeTransmogs[slotId]
        local activeEnchant = activeEnchantTransmogs[slotId]
        
        -- Update transmog icon
        if activeItemId then
            local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(activeItemId)
            if itemTexture then
                self.transmogIcon:SetTexture(itemTexture)
                self.transmogIcon:Show()
            else
                -- Item info not cached yet, try to get it
                local tooltip = CreateFrame("GameTooltip", "TransmogIconTooltip"..activeItemId, nil, "GameTooltipTemplate")
                tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
                tooltip:SetHyperlink("item:"..activeItemId)
                
                C_Timer.After(0.1, function()
                    local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(activeItemId)
                    if tex then
                        self.transmogIcon:SetTexture(tex)
                        self.transmogIcon:Show()
                    else
                        self.transmogIcon:Hide()
                    end
                end)
            end
        else
            self.transmogIcon:Hide()
        end
        
        -- Update border based on current state
        local hasSearchMatches = searchActive and searchSlotResults[slotId] and #searchSlotResults[slotId] > 0
        
        if hasSearchMatches then
            if self.activeBorder then
                self.activeBorder:Show()
                self.activeBorder:SetVertexColor(1, 0.5, 0, 0.7)  -- Orange for search matches
            end
        elseif activeEnchant and ENCHANT_ELIGIBLE_SLOTS[self.slotName] then
            -- BUG 4 FIX: Show pink border for active enchant transmog
            if self.activeBorder then
                self.activeBorder:Show()
                self.activeBorder:SetVertexColor(1, 0.4, 0.7, 0.7)  -- Pink for active enchant transmog
            end
        elseif activeItemId then
            if self.activeBorder then
                self.activeBorder:Show()
                self.activeBorder:SetVertexColor(0, 1, 0, 0.7)    -- Green for active item transmog
            end
        else
            if self.activeBorder then
                self.activeBorder:Hide()
            end
        end
    end
    
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            -- Right-click to clear transmog
            local slotId = SLOT_NAME_TO_EQUIP_SLOT[self.slotName]
            if activeTransmogs[slotId] then
                RemoveTransmog(self.slotName)
                PlaySound("igMainMenuOptionCheckBoxOn")
            end
            -- Also check for enchant transmog to remove
            if activeEnchantTransmogs[slotId] and ENCHANT_ELIGIBLE_SLOTS[self.slotName] then
                RemoveEnchantTransmog(self.slotName)
                PlaySound("igMainMenuOptionCheckBoxOn")
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
        
        -- Request items from server with current filters
        local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
        RequestSlotItemsFromServer(slotId, currentSubclass, currentQuality, currentCollectionFilter)  -- NEW: Include collection filter
        
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

local function CreateDressingRoom(parent)
    local frame = CreateFrame("Frame", "$parentDressingRoom", parent)
    frame:SetSize(280, 460)
    
    -- Create and set the class-specific background texture
    local bgTexture = frame:CreateTexture("$parentCustomTexture", "BACKGROUND")
    bgTexture:SetPoint("TOPLEFT", 4, -4)
    bgTexture:SetPoint("BOTTOMRIGHT", -4, 4)
    
    -- Get player class and set appropriate texture
    local _, playerClass = UnitClass("player")
    local texturePaths = {
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
    
    -- Set texture based on class, default to warlock if not found
    local texturePath = texturePaths[playerClass] or "Interface\\AddOns\\MOD-TRANSMOG-SYSTEM\\Assets\\dressingroomwarlock"
    bgTexture:SetTexture(texturePath)
    
    -- Calculate cropping for square texture in portrait frame
    local frameWidth, frameHeight = 280, 460
    local frameAspect = frameWidth / frameHeight
    
    local cropWidth = frameAspect
    local left = (1 - cropWidth) / 2
    local right = 1 - left
    
    bgTexture:SetTexCoord(left, right, 0, 1)
    
    frame.bgTexture = bgTexture
    
    frame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, 
        tileSize = 16, 
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    function frame:UpdateBackgroundTexture()
        local _, currentClass = UnitClass("player")
        local newTexturePath = texturePaths[currentClass] or "Interface\\AddOns\\MOD-TRANSMOG-SYSTEM\\Assets\\dressingroomwarlock"
        self.bgTexture:SetTexture(newTexturePath)
        self.bgTexture:SetTexCoord(left, right, 0, 1)
    end
    
    -- Create model frame
    local model = CreateFrame("DressUpModel", "$parentModel", frame)
    model:SetPoint("TOPLEFT", 4, -4)
    model:SetPoint("BOTTOMRIGHT", -4, 4)
    model:SetUnit("player")
    model:SetRotation(0)
    frame.model = model
    
    -- Mouse interaction for rotating/zooming
    local isDragging = false
    local isRotating = false
    local lastX, lastY = 0, 0
    
    model:EnableMouse(true)
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
        self.model:SetUnit("player")
        self.model:SetPosition(0, 0, 0)
        self.model:SetFacing(0)
        
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
    
    -- Create the PerformSearch function BEFORE using it
    local function PerformSearch()
        local searchText = searchEditBox:GetText():trim()
        if searchText and searchText ~= "" then
            lastSearchText = searchText
            local locale = GetLocale()
            -- Search with slot -1 to get all items
            AIO.Msg():Add("TRANSMOG", "SearchItems", -1, selectedSearchType, searchText, locale):Send()
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
        
        -- Reset to show all items for current slot
        local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
        currentItems = {}
        currentPage = 1
        UpdatePreviewGrid()
        RequestSlotItemsFromServer(slotId, currentSubclass, currentQuality, currentCollectionFilter)
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
            if subclassDropdown then subclassDropdown:Show() end
            if qualityDropdown then qualityDropdown:Show() end
            if collectionFilterDropdown then collectionFilterDropdown:Show() end  -- NEW
            if frame.searchBar then frame.searchBar:Show() end
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
            if collectionFilterDropdown then collectionFilterDropdown:Hide() end  -- NEW
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
    
    local resetBtn = CreateFrame("Button", "$parentReset", frame, "UIPanelButtonTemplate")
    resetBtn:SetSize(65, 22)
    resetBtn:SetPoint("TOPLEFT", dressingRoom, "BOTTOMLEFT", 10, -8)
    resetBtn:SetText(L["RESET"])
    resetBtn:SetScript("OnClick", function()
        dressingRoom:Reset()
        PlaySound("igMainMenuOptionCheckBoxOn")
    end)
    
    local undressBtn = CreateFrame("Button", "$parentUndress", frame, "UIPanelButtonTemplate")
    undressBtn:SetSize(65, 22)
    undressBtn:SetPoint("LEFT", resetBtn, "RIGHT", 5, 0)
    undressBtn:SetText(L["UNDRESS"])
    undressBtn:SetScript("OnClick", function()
        dressingRoom:Undress()
        PlaySound("igMainMenuOptionCheckBoxOn")
    end)
    
    -- Apply button for current slot
    local applyBtn = CreateFrame("Button", "$parentApply", frame, "UIPanelButtonTemplate")
    applyBtn:SetSize(80, 22)
    applyBtn:SetPoint("LEFT", undressBtn, "RIGHT", 5, 0)
    applyBtn:SetText(L["APPLY"])
    applyBtn:SetScript("OnClick", function()
        -- Apply currently selected transmog
        print("Select an appearance and Shift+Click to apply")
        print(L["APPLY_HINT"] or "Select an appearance and Shift+Click to apply")
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
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Initialize slot selected items table
        slotSelectedItems = {}
        
        -- Initialize quality and collection filter storage for all slots
        for _, slotName in ipairs(SLOT_ORDER) do
            slotSelectedQuality[slotName] = "All"
            slotSelectedCollectionFilter[slotName] = "Collected"  -- NEW: Default to Collected
        end
        
        -- Request fresh data from server after delay
        C_Timer.After(2, function()
            RequestCollectionFromServer()
            RequestActiveTransmogsFromServer()
            RequestSetsFromServer()
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
                -- Normal mode: request fresh data when window opens
                local slotId = SLOT_NAME_TO_EQUIP_SLOT[currentSlot]
                currentItems = {}
                RequestSlotItemsFromServer(slotId, currentSubclass, currentQuality, currentCollectionFilter)  -- NEW: Include collection filter
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