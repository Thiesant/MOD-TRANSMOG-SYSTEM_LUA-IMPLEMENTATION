local ADDON_NAME, Transmog = ...

-- French Localization
Transmog.L = Transmog.L or {}
local L = Transmog.L

-- Only override if client is French
if GetLocale() ~= "frFR" then return end

-- UI Strings
L["ADDON_TITLE"] = "Transmogrification"
L["INSTRUCTIONS"] = "|cff00ff00Clic Gauche:|r rotation  |  |cff00ff00Clic Droit:|r déplacer  |  |cff00ff00Molette:|r zoom"
L["RESET"] = "Réinit."
L["UNDRESS"] = "Déshabiller"
L["PAGE"] = "Page %d/%d"
L["TAB_NAME"] = "Transmogrification"
L["APPLY"] = "Appliquer"
L["APPLY_APPEARANCE_SHIFT_CLICK"] = "|cff00ff00Shift+Clic:|r Appliquer l'apparence"
L["PREVIEW_APPEARANCE_CLICK"] = "|cff00ff00Clic:|r Aperçu"
L["MINIMAP_BUTTON_TITLE"] = "Transmo Collection"

-- Collection Status
L["ACTIVE_TRANSMOG"] = "Transmogrification utilisée:"
L["NO_ACTIVE_TRANSMOG"] = "Aucune transmogrification"
L["TRANSMOG_SLOT_ACTIVE"] = "|cff00ff00ACTIVE|r"
L["CLEAR_TRANSMOG"]= "|cffff0000Clic droit pour retirer|r"
L["APPEARANCE_COLLECTED"] = "|cff00ff00Apparence collectée|r"
L["APPEARANCE_NOT_COLLECTED"] = "|cffff0000Apparence non collectée|r"
L["NEW_APPEARANCE"] = "|cffFFD700NOUVELLE APPARENCE!|r"
L["NEW_APPEARANCE_UNLOCKED"] = "Nouvelle apparence débloquée:"
L["RETROACTIVE_UNLOCKED"] = "%d apparences débloquées depuis les quêtes terminées."
L["TRANSMOG_APPLIED"] = "Transmogrification appliquée!"
L["TRANSMOG_REMOVED"] = "Transmogrification retirée!"

-- Slot Names
L["Head"] = "Tête"
L["Shoulder"] = "Épaule"
L["Back"] = "Dos"
L["Chest"] = "Torse"
L["Shirt"] = "Chemise"
L["Tabard"] = "Tabard"
L["Wrist"] = "Poignets"
L["Hands"] = "Mains"
L["Waist"] = "Taille"
L["Legs"] = "Jambes"
L["Feet"] = "Pieds"
L["MainHand"] = "Main droite"
L["SecondaryHand"] = "Main gauche"
L["Ranged"] = "À distance"

-- Armor Types
L["All"] = "Tous"
L["Cloth"] = "Tissu"
L["Leather"] = "Cuir"
L["Mail"] = "Mailles"
L["Plate"] = "Plaques"
L["Miscellaneous"] = "Divers"

-- Weapon Types
L["Axe1H"] = "Hache à une main"
L["Mace1H"] = "Masse à une main"
L["Sword1H"] = "Épée à une main"
L["Dagger"] = "Dague"
L["Fist"] = "Arme de pugilat"
L["Axe2H"] = "Hache à deux mains"
L["Mace2H"] = "Masse à deux mains"
L["Sword2H"] = "Épée à deux mains"
L["Polearm"] = "Arme d'hast"
L["Staff"] = "Bâton"
L["Shield"] = "Bouclier"
L["Held"] = "Tenu en main gauche"
L["Bow"] = "Arc"
L["Crossbow"] = "Arbalète"
L["Gun"] = "Arme à feu"
L["Wand"] = "Baguette"
L["Thrown"] = "Arme de jet"
L["Fishing"] = "Canne à pêche"

-- Search
L["SEARCH"] = "Rechercher"
L["SEARCH_TOOLTIP"] = "Options de recherche:"
L["SEARCH_CLEAR"] = "Supprimer"
L["SEARCH_NAME"] = "Nom"
L["SEARCH_NAME_DESCRIPTION"] = ": Entrer le nom d'un objet (anglais ou français)"
L["SEARCH_ID"] = "ID"
L["SEARCH_ID_DESCRIPTION"] = ": Entrer l'ID de l'objet"
L["SEARCH_DISPLAYID"] = "DisplayID"
L["SEARCH_DISPLAYID_DESCRIPTION"] = ": Entrer le display ID"
L["SEARCH_TOOLTIP"] = "Recherche par nom, ID, ou display ID"
L["SEARCH_RESULTS"] = "Résultats: %d objets"
L["SEARCH_DESCRIPTION"] = "Taper entrer pour rechercher"
L["SEARCH_CLEAR"] = "Vider le champs"
L["SEARCH_CLEAR_DESCRIPTION"] = "Taper échappe pour vider le champs"


-- Messages
L["COLLECTION_LOADED"] = "Collection chargée: %d apparences"
L["SLASH_TRANSMOG"] = "Addon |cff00ff00[Transmog]|r chargé. Tapper /transmog ou /tmog pour l'ouvrir."
L["HELP_1"] = "|cff00ff00[Transmog]|r Aide:"
L["HELP_2"] = "  /transmog - Ouvre/ferme la fenêtre de transmogrification"
L["HELP_3"] = "  /transmog help - Montre ce message d'aide"
--L["HELP_4"] = ""

-- Error Messages
L["APPEARANCE_NOT_COLLECTED"] = "Vous n'avez pas cette apparence"
L["ERROR_INVALID_SLOT_OR_ITEM"] = "Emplacement ou objet invalide"
L["ERROR_INVALID_SLOT"] = "Emplacement d'équipement invalide"

-- Filters
L["SELECT_ITEM_CLICK"] = "Cliquez pour sélectionner cet objet"

-- Set Management
L["SET_NEW"] = "Nouvel ensemble..."
L["SET_SELECT"] = "Sélectionner"
L["SET_DEFAULT_NAME"] = "Ensemble %d"
L["SET_SAVE"] = "Sauver"
L["SET_DELETE"] = "Suppr"
L["SET_APPLY"] = "Appliquer"
L["SET_SAVE_PROMPT"] = "Nom de l'ensemble:"
L["SET_SAVED"] = "Ensemble '%s' sauvegardé!"
L["SET_LOADED"] = "Ensemble '%s' chargé dans l'aperçu"
L["SET_DELETED"] = "Ensemble #%d supprimé"
L["SET_APPLIED"] = "Ensemble '%s' appliqué!"
L["SET_ERROR"] = "Opération sur l'ensemble échouée"
L["SET_FULL"] = "|cffff0000[Transmog]|r Tous les emplacements sont pleins. Supprimez un ensemble d'abord."
L["SET_NO_SELECTION"] = "|cffff0000[Transmog]|r Aucun objet sélectionné. Cliquez sur des objets dans l'aperçu pour les sélectionner."
L["SET_SELECT_FIRST"] = "|cffff0000[Transmog]|r Sélectionnez un ensemble d'abord."
L["SET_DELETE_CONFIRM"] = "Supprimer cet ensemble?"
L["SET_SAVE_TOOLTIP"] = "Sauvegarder les objets sélectionnés comme nouvel ensemble"
L["SET_DELETE_TOOLTIP"] = "Supprimer l'ensemble sélectionné"
L["SET_APPLY_TOOLTIP"] = "Appliquer cet ensemble comme transmog actif\n(Seules les apparences collectées seront appliquées)"
L["APPLY_HINT"] = "Sélectionnez une apparence et Shift+Clic pour l'appliquer"

-- Mode Toggle
L["MODE_ITEM"] = "Objets"
L["MODE_ENCHANT"] = "Enchants"
L["MODE_TOGGLE_TOOLTIP_ITEM"] = "Mode Transmog Objets"
L["MODE_TOGGLE_TOOLTIP_ENCHANT"] = "Mode Transmog Enchantements"
L["MODE_TOGGLE_DESC_ITEM"] = "Cliquez pour passer au mode Enchantements"
L["MODE_TOGGLE_DESC_ENCHANT"] = "Cliquez pour passer au mode Objets"
L["MODE_ENCHANT_NOTE"] = "Seuls les emplacements d'armes peuvent avoir des visuels d'enchantement"
L["ENCHANT_MODE"] = "Mode Enchant"

-- Enchantment Strings
L["ENCHANT_CATEGORY"] = "Catégorie"
L["ENCHANT_ACTIVE"] = "|cff00ff00Actuellement Actif|r"
L["CLEAR_ENCHANT"] = "|cffff0000Clic droit pour retirer|r"
L["APPLY_ENCHANT_SHIFT_CLICK"] = "|cff00ff00Shift+Clic:|r Appliquer le visuel d'enchantement"
L["ENCHANT_APPLIED"] = "Visuel d'enchantement appliqué!"
L["ENCHANT_REMOVED"] = "Visuel d'enchantement retiré!"
L["ENCHANT_COLLECTION_LOADED"] = "Collection d'enchantements chargée: %d visuels"

-- Enchant Categories
L["Runeforge"] = "Forge de Rune"
L["Fire"] = "Feu"
L["Frost"] = "Givre"
L["Nature"] = "Nature"
L["Arcane"] = "Arcane"
L["Holy"] = "Sacré"
L["Shadow"] = "Ombre"
L["Physical"] = "Physique"
L["Shaman"] = "Chaman"