-- [Author : Thiesant] This sql is free, if you bought it you got scammed.

-- ============================================================================
-- mod-transmog-system Database Schema
-- Characters Database
-- ============================================================================

-- Drop existing tables if they exist (for clean reinstall)
DROP TABLE IF EXISTS `mod_transmog_system_collection`;
DROP TABLE IF EXISTS `mod_transmog_system_active`;
DROP TABLE IF EXISTS `mod_transmog_system_sets`;

-- ============================================================================
-- mod_transmog_system_collection: Account-wide appearance collection
-- Stores all item appearances unlocked by any character on the account
-- ============================================================================
CREATE TABLE IF NOT EXISTS `mod_transmog_system_collection` (
    `account_id` INT UNSIGNED NOT NULL COMMENT 'Account ID from auth.account',
    `item_id` INT UNSIGNED NOT NULL COMMENT 'Item entry from item_template',
    `item_class` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Item class (2=Weapon, 4=Armor)',
    `item_subclass` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Item subclass for filtering',
    `inventory_type` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Inventory type for slot mapping',
    `unlock_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the appearance was unlocked',
    PRIMARY KEY (`account_id`, `item_id`),
    KEY `idx_account` (`account_id`),
    KEY `idx_item` (`item_id`),
    KEY `idx_slot_filter` (`account_id`, `inventory_type`, `item_subclass`)
) ENGINE=INNODB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Account-wide transmog appearance collection';

-- ============================================================================
-- mod_transmog_system_active: Active transmog per character per slot
-- Stores the current fake appearance applied to each equipment slot
-- ============================================================================
CREATE TABLE IF NOT EXISTS `mod_transmog_system_active` (
    `guid` INT UNSIGNED NOT NULL COMMENT 'Character GUID',
    `slot` TINYINT UNSIGNED NOT NULL COMMENT 'Equipment slot (0-18)',
    `item_id` INT UNSIGNED NOT NULL COMMENT 'Item entry of the fake appearance',
    `apply_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`guid`, `slot`),
    KEY `idx_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Active transmog appearances per character';

-- ============================================================================
-- mod_transmog_system_sets: Saved transmog outfit sets
-- Allows players to save and load complete transmog sets
-- ============================================================================
CREATE TABLE IF NOT EXISTS `mod_transmog_system_sets` (
    `account_id` INT UNSIGNED NOT NULL COMMENT 'Account ID from auth.account',
    `set_number` TINYINT UNSIGNED NOT NULL COMMENT 'Set number (1-10)',
    `set_name` VARCHAR(64) NOT NULL DEFAULT 'Unnamed Set' COMMENT 'Custom set name',
    `slot_head` INT UNSIGNED NOT NULL DEFAULT 0,
    `slot_shoulder` INT UNSIGNED NOT NULL DEFAULT 0,
    `slot_back` INT UNSIGNED NOT NULL DEFAULT 0,
    `slot_chest` INT UNSIGNED NOT NULL DEFAULT 0,
    `slot_shirt` INT UNSIGNED NOT NULL DEFAULT 0,
    `slot_tabard` INT UNSIGNED NOT NULL DEFAULT 0,
    `slot_wrist` INT UNSIGNED NOT NULL DEFAULT 0,
    `slot_hands` INT UNSIGNED NOT NULL DEFAULT 0,
    `slot_waist` INT UNSIGNED NOT NULL DEFAULT 0,
    `slot_legs` INT UNSIGNED NOT NULL DEFAULT 0,
    `slot_feet` INT UNSIGNED NOT NULL DEFAULT 0,
    `slot_mainhand` INT UNSIGNED NOT NULL DEFAULT 0,
    `slot_offhand` INT UNSIGNED NOT NULL DEFAULT 0,
    `slot_ranged` INT UNSIGNED NOT NULL DEFAULT 0,
    `create_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`account_id`, `set_number`),
    KEY `idx_account` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Saved transmog outfit sets';

-- ============================================================================
-- Armor Subclass Reference (for filtering):
-- 0 = Miscellaneous (Shirts, Tabards)
-- 1 = Cloth
-- 2 = Leather
-- 3 = Mail
-- 4 = Plate
-- 6 = Shield
--
-- Weapon Subclass Reference:
-- 0 = Axe (1H)
-- 1 = Axe (2H)
-- 2 = Bow
-- 3 = Gun
-- 4 = Mace (1H)
-- 5 = Mace (2H)
-- 6 = Polearm
-- 7 = Sword (1H)
-- 8 = Sword (2H)
-- 10 = Staff
-- 13 = Fist Weapon
-- 14 = Miscellaneous (Fishing Pole)
-- 15 = Dagger
-- 16 = Thrown
-- 18 = Crossbow
-- 19 = Wand
-- 20 = Fishing Pole
-- ============================================================================

-- ============================================================================
-- Equipment Slot Reference (WoW 3.3.5):
-- 0  = Head (EQUIPMENT_SLOT_HEAD)
-- 1  = Neck (not transmogable)
-- 2  = Shoulder (EQUIPMENT_SLOT_SHOULDERS)
-- 3  = Shirt (EQUIPMENT_SLOT_BODY)
-- 4  = Chest (EQUIPMENT_SLOT_CHEST)
-- 5  = Waist (EQUIPMENT_SLOT_WAIST)
-- 6  = Legs (EQUIPMENT_SLOT_LEGS)
-- 7  = Feet (EQUIPMENT_SLOT_FEET)
-- 8  = Wrist (EQUIPMENT_SLOT_WRISTS)
-- 9  = Hands (EQUIPMENT_SLOT_HANDS)
-- 10 = Finger1 (not transmogable)
-- 11 = Finger2 (not transmogable)
-- 12 = Trinket1 (not transmogable)
-- 13 = Trinket2 (not transmogable)
-- 14 = Back (EQUIPMENT_SLOT_BACK)
-- 15 = Main Hand (EQUIPMENT_SLOT_MAINHAND)
-- 16 = Off Hand (EQUIPMENT_SLOT_OFFHAND)
-- 17 = Ranged (EQUIPMENT_SLOT_RANGED)
-- 18 = Tabard (EQUIPMENT_SLOT_TABARD)
-- ============================================================================