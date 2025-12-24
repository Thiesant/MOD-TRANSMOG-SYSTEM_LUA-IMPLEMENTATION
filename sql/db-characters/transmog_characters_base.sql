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
-- Note: item_class, item_subclass, inventory_type are queried from 
--       acore_world.item_template at runtime for filtering
-- ============================================================================
CREATE TABLE IF NOT EXISTS `mod_transmog_system_collection` (
    `account_id` INT UNSIGNED NOT NULL COMMENT 'Account ID from auth.account',
    `item_id` INT UNSIGNED NOT NULL COMMENT 'Item entry from item_template',
    `unlock_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the appearance was unlocked',
    PRIMARY KEY (`account_id`, `item_id`),
    KEY `idx_account` (`account_id`),
    KEY `idx_item` (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Account-wide transmog appearance collection';

-- ============================================================================
-- mod_transmog_system_active: Active transmog per character per slot
-- Stores the current fake appearance applied to each equipment slot
-- ============================================================================
CREATE TABLE IF NOT EXISTS `mod_transmog_system_active` (
    `guid` INT UNSIGNED NOT NULL COMMENT 'Character GUID',
    `slot` TINYINT UNSIGNED NOT NULL COMMENT 'Equipment slot (0-18)',
    `item_id` INT UNSIGNED NOT NULL COMMENT 'Item entry of the fake appearance',
    `enchant_id` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Enchant ID from mod_transmog_system_enchantment (0 = none)',
    `apply_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`guid`, `slot`),
    KEY `idx_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Active transmog appearances per character';

-- ============================================================================
-- mod_transmog_system_enchantment: Enchantment visual reference table
-- Static data for all available enchantment visuals
-- Only includes one representative enchant per unique ItemVisual to avoid duplicates
-- ============================================================================
DROP TABLE IF EXISTS `mod_transmog_system_enchantment`;
CREATE TABLE IF NOT EXISTS `mod_transmog_system_enchantment` (
    `id` INT UNSIGNED NOT NULL COMMENT 'Enchantment ID (SpellItemEnchantment)',
    `item_visual` INT UNSIGNED NOT NULL COMMENT 'ItemVisual ID for client display',
    `name_enUS` VARCHAR(64) NOT NULL COMMENT 'English name',
    `name_frFR` VARCHAR(64) NOT NULL COMMENT 'French name',
    `icon` VARCHAR(128) NOT NULL DEFAULT 'Interface\\Icons\\INV_Misc_QuestionMark' COMMENT 'Icon path',
    PRIMARY KEY (`id`),
    KEY `idx_visual` (`item_visual`)
) ENGINE=INNODB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Enchantment visual reference data';

-- Populate enchantment visuals (one per unique ItemVisual)
-- ItemVisual 1 = Frost/Rune effect (blue ice crystals)
INSERT INTO `mod_transmog_system_enchantment` (`id`, `item_visual`, `name_enUS`, `name_frFR`, `icon`) VALUES
(3370, 1, 'Rune of Razorice', 'Rune de Trancheglace', 'Interface\\Icons\\Spell_Frost_FrostArmor02'),
-- ItemVisual 2 = Blue glow (generic damage)
(963, 2, '+7 Weapon Damage', '+7 aux dégâts de l''arme', 'Interface\\Icons\\INV_Sword_04'),
-- ItemVisual 24 = Weapon Damage (subtle glow)
(1896, 24, '+9 Weapon Damage', '+9 aux dégâts de l''arme', 'Interface\\Icons\\INV_Sword_27'),
-- ItemVisual 25 = Fiery Weapon (orange flames)
(803, 25, 'Fiery Weapon', 'Arme flamboyante', 'Interface\\Icons\\Spell_Fire_FlameShock'),
-- ItemVisual 26 = Poison (green drip)
(7, 26, 'Deadly Poison', 'Poison mortel', 'Interface\\Icons\\Ability_Rogue_DualWeild'),
-- ItemVisual 27 = Frost Oil (icy blue)
(26, 27, 'Frost Oil', 'Huile glaciale', 'Interface\\Icons\\INV_Potion_20'),
-- ItemVisual 28 = Sharpened (metallic gleam)
(13, 28, 'Sharpened', 'Aiguisé', 'Interface\\Icons\\INV_Stone_SharpeningStone_01'),
-- ItemVisual 29 = Spirit/Intellect (yellow glow)
(1890, 29, 'Healing Power', 'Puissance de soin', 'Interface\\Icons\\Spell_Holy_GreaterHeal'),
-- ItemVisual 31 = Beastslaying (red glow)
(249, 31, 'Beastslaying', 'Tueur de bêtes', 'Interface\\Icons\\INV_Misc_MonsterScales_08'),
-- ItemVisual 32 = Flametongue (flame effect)
(3, 32, 'Flametongue', 'Langue de feu', 'Interface\\Icons\\Spell_Fire_FlameTounge'),
-- ItemVisual 33 = Frostbrand (frost effect)
(2, 33, 'Frostbrand', 'Arme de givre', 'Interface\\Icons\\Spell_Frost_FrostBrand'),
-- ItemVisual 42 = Blessed (holy glow)
(3265, 42, 'Blessed Weapon Coating', 'Enduit d''arme béni', 'Interface\\Icons\\Spell_Holy_BlessedRecovery'),
-- ItemVisual 61 = Rockbiter (earth/brown)
(1, 61, 'Rockbiter', 'Croque-roc', 'Interface\\Icons\\Spell_Nature_RockBiter'),
-- ItemVisual 81 = Windfury (wind swirls)
(283, 81, 'Windfury', 'Furie-des-vents', 'Interface\\Icons\\Spell_Nature_Cyclone'),
-- ItemVisual 101 = Attack Power (red aura)
(1606, 101, '+50 Attack Power', '+50 Puissance d''attaque', 'Interface\\Icons\\Ability_Marksmanship'),
-- ItemVisual 102 = Spell Power variant
(3846, 102, '+40 Spell Power', '+40 Puissance des sorts', 'Interface\\Icons\\Spell_Holy_MindVision'),
-- ItemVisual 103 = Crusader (holy white glow)
(1900, 103, 'Crusader', 'Croisé', 'Interface\\Icons\\Spell_Holy_HolyBolt'),
-- ItemVisual 104 = vs Undead/Demons (holy fire)
(3093, 104, 'Undead Slaying', 'Tueur de morts-vivants', 'Interface\\Icons\\Spell_Holy_ExorcismAlt'),
-- ItemVisual 105 = Test
(1743, 105, 'Test Enchant', 'Enchant de test', 'Interface\\Icons\\INV_Misc_QuestionMark'),
-- ItemVisual 106 = Earthliving (nature green)
(3345, 106, 'Earthliving', 'Viveterre', 'Interface\\Icons\\Spell_Nature_HealingWaveGreater'),
-- ItemVisual 107 = Lifestealing (purple drain)
(1898, 107, 'Lifestealing', 'Vampirique', 'Interface\\Icons\\Spell_Shadow_Lifedrain02'),
-- ItemVisual 125 = Agility (green glow)
(1103, 125, '+26 Agility', '+26 Agilité', 'Interface\\Icons\\Ability_Ambush'),
-- ItemVisual 126 = Icy Weapon (frost blue)
(1894, 126, 'Icy Weapon', 'Arme glacée', 'Interface\\Icons\\Spell_Frost_ColdHearted'),
-- ItemVisual 128 = Spell Power (purple aura)
(3855, 128, '+69 Spell Power', '+69 Puissance des sorts', 'Interface\\Icons\\Spell_Holy_GreaterBlessingofLight'),
-- ItemVisual 139 = Black Temple effect
(425, 139, 'Black Temple', 'Temple noir', 'Interface\\Icons\\INV_Misc_QuestionMark'),
-- ItemVisual 151 = Spell Power (bright)
(2343, 151, '+43 Spell Power', '+43 Puissance des sorts', 'Interface\\Icons\\Spell_Arcane_Arcane01'),
-- ItemVisual 155 = Mongoose (blue lightning)
(2673, 155, 'Mongoose', 'Mangouste', 'Interface\\Icons\\Spell_Nature_StoneClawTotem'),
-- ItemVisual 156 = Attack Power/Swordshattering (red)
(2667, 156, '+70 Attack Power', '+70 Puissance d''attaque', 'Interface\\Icons\\INV_Weapon_Shortblade_25'),
-- ItemVisual 157 = Shadow/Frost Spell Power
(2672, 157, 'Shadow and Frost Power', 'Puissance Ombre/Givre', 'Interface\\Icons\\Spell_Frost_FrostBolt02'),
-- ItemVisual 158 = Arcane/Fire Spell Power
(2671, 158, 'Arcane and Fire Power', 'Puissance Arcanes/Feu', 'Interface\\Icons\\Spell_Fire_SealOfFire'),
-- ItemVisual 159 = Battlemaster (versatile glow)
(2675, 159, 'Battlemaster', 'Maître de guerre', 'Interface\\Icons\\Spell_Holy_AshesToAshes'),
-- ItemVisual 160 = Spellsurge/Fallen Crusader (arcane burst)
(3368, 160, 'Rune of the Fallen Crusader', 'Rune du Croisé déchu', 'Interface\\Icons\\Spell_Arcane_Arcane04'),
-- ItemVisual 161 = Unholy (green skulls)
(1899, 161, 'Unholy Weapon', 'Arme impie', 'Interface\\Icons\\Spell_Shadow_ShadowWordDominate'),
-- ItemVisual 164 = Blood Draining (blood red)
(3870, 164, 'Blood Draining', 'Drain de sang', 'Interface\\Icons\\INV_Misc_Gem_BloodGem_03'),
-- ItemVisual 165 = Executioner (blade effect)
(3225, 165, 'Executioner', 'Bourreau', 'Interface\\Icons\\Ability_Warrior_Decisivestrike'),
-- ItemVisual 166 = Deathfrost (frost death)
(3273, 166, 'Deathfrost', 'Givre mortel', 'Interface\\Icons\\Spell_Shadow_DarkRitual'),
-- ItemVisual 172 = High Spell Power
(3854, 172, '+81 Spell Power', '+81 Puissance des sorts', 'Interface\\Icons\\Spell_Holy_SurgeOfLight'),
-- ItemVisual 173 = Empower Rune Weapon (DK rune)
(3364, 173, 'Empower Rune Weapon', 'Charge de la lame runique', 'Interface\\Icons\\INV_Sword_62'),
-- ItemVisual 178 = Berserking (rage red)
(3789, 178, 'Berserking', 'Berserker', 'Interface\\Icons\\Spell_Nature_AbolishMagic'),
-- ItemVisual 186 = Blade Ward (defensive)
(3869, 186, 'Blade Ward', 'Garde lame', 'Interface\\Icons\\Ability_Parry');

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

-- ============================================================================
-- Enchantment Visual ID Reference (WotLK 3.3.5):
-- These are the visual effect IDs used for weapon enchant appearances
-- 
-- Common Visual IDs:
-- 1   = Rune of Razorice (Death Knight)
-- 25  = Fiery Weapon
-- 26  = Poisoned (green drip)
-- 27  = Coldlight (blue glow)
-- 29  = Titanguard (yellow glow)
-- 31  = Beastslayer (red glow)
-- 32  = Flametongue (Shaman)
-- 33  = Frostbrand (Shaman)
-- 42  = Striking (blue glow)
-- 61  = Rockbiter (Shaman)
-- 81  = Windfury (Shaman)
-- 103 = Crusader (white glow)
-- 106 = Earthliving (Shaman)
-- 107 = Lifestealing (purple glow)
-- 125 = Agility (green glow)
-- 126 = Icy Chill (white flame)
-- 155 = Mongoose (special effect)
-- 157 = Soulfrost (frost effect)
-- 158 = Sunfire (fire effect)
-- 159 = Battlemaster (red gem effect)
-- 160 = Spellsurge (arcane effect)
-- 161 = Unholy Weapon (skulls)
-- 164 = Blood Draining
-- 165 = Executioner
-- 166 = Deathfrost
-- 172 = Greater Spellpower
-- 178 = Berserking
-- 186 = Blade Ward
-- ============================================================================